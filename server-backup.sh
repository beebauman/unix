#!/bin/sh

# Get the command line arguments.
crontabs=0
databases=0
while [ "$1" != "" ]; do
    case $1 in
        -c | --crontabs )    crontabs=1
                             ;;
        -d | --databases )   databases=1
                             ;;
        -h | --host )        shift
                             host=$1
                             ;;
        -p | --path )        shift
                             path=$1
                             ;;
        -f | --filters )    shift
                             filters=$1
                             ;;
    esac
    shift
done

# Get the backup path.
backupPath=$(eval "echo $path")
echo "Your backup will be saved to ${backupPath}."

# Get the ~/.ssh/config entry for the specified host.
hostEntry=$(cat ~/.ssh/config | \
            sed -n -e '/Host '"${host}"'/,$p' | \
            tail -n +2 | \
            sed -e '/Host /,$d')

# Retrieve a value from the host's SSH configuration entry.
function hostParameter () {
	result=$(echo "$hostEntry" | \
           sed -n -e '/'"$1"'/,$p' | \
           sed -n 1p | awk '{print $2}')
    echo "$result"
}

# Get the hostname.
hostname=$(hostParameter Hostname)

if [ -z "$hostname" ]
then
    echo "Hostname not found. Exiting."
    exit 1
else
	echo "Found Host '${host}' with Hostname '${hostname}'."
fi

# Get the port.
port=$(hostParameter Port)
if [ -z "$port" ]
then
    echo "Custom port not found in host's SSH configuration. We'll use the default port for SSH (22)."
    port=22;
else
	echo "Using custom port ${port}."
fi

# Get the path to the filter rules file.
if [ -z "$filters" ]
then
    scriptDirectory=$( cd "$( dirname "$0" )" && pwd )
    filters=$(eval "echo ${scriptDirectory}/backup-server-default-filters.txt")
    echo "No filter rules file specified. We'll use the default one at ${filters}."
else
	echo "filters list will be read from ${filters}."
	filters=$(eval "echo $filters")
fi

# Delete .DS_Store files in the local backup so that rsync won't need to.
echo "Looking for local .DS_Store files..."
echo "backupPath is $backupPath"
fileCount=$(find "${backupPath}" -name '*.DS_Store' -type f -exec rm {} \; -print | wc -l)
fileCount=$(echo $fileCount) # Just to strip leading whitespace from wc output.
if [ $fileCount -lt 1 ]
then
	echo "There were no .DS_Store files to delete."
else
	echo "Deleted ${fileCount} .DS_Store file(s)."
fi

# Cron
if [ $crontabs -eq 1 ]
then
	echo "Running crontab backup script..."
	ssh -t -p $port $host sudo /unixme/crontabs-backup.sh
fi

# MySQL
if [ $databases -eq 1 ]
then
	echo "Running MySQL databases backup script..."
	ssh -t -p $port $host sudo /unixme/mysql-backup.sh
fi

# Synchronize the local backup directory with the backup items on the server.
rsync --archive --recursive --compress --prune-empty-dirs --delete --relative --ignore-errors --rsync-path="sudo rsync" \
	--filter="merge ${filters}" -e "ssh -p $port" "${host}":/ "$backupPath"
