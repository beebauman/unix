#!/bin/sh

# Compatibility note: This script has only been tested on Debian 7 (wheezy).

# This script requires the following scripts on the server:
# 1. The database backup script at /var/backups/mysql/backup-mysql.sh.
# 2. The crontab backup script at /var/backups/crontabs/backup-crontabs.sh.
# 3. The firewall rules file at /etc/iptables.firewall.rules.
# 4. The firewall boot load script at /etc/network/if-pre-up.d/iptables.

# You'll need to supply the script with the short name of a Host whose Hostname
#  and User parameters are defined in your local machine's ~/.ssh/config. For example:
# Host widget
# 	Hostname widget.acme.come
# 	User johnsusername

# Your User account on the server must have sudo privileges, and must be configured with
#  permission to run the rsync command using sudo without a password. You can do this
#  by adding the following line to /etc/sudoers:
# johnsusername ALL = NOPASSWD: /usr/bin/rsync

# --------------------------------------------------#

# Enter your username on the server:
username=""

# Get the Host and Hostname of the server being backed up.
read -p "Host to back up: " host
hostname=$(cat ~/.ssh/config | grep Hostname | awk '{print $2}' | grep $host)
echo "Found Host '${host}' with Hostname '${hostname}'."

# Get the directory path on the local machine where you want the backup saved.
read -e -p "Local backup directory: " input_dir

# Expand tilde to absolute path for $HOME directory
# backup_dir=$(echo $input_dir | sed "s#~#$HOME#")
backup_dir=$(eval "echo $input_dir")
echo "Absolute path to backup directory is ${backup_dir}."

# Delete .DS_Store files in the local backup so that rsync won't need to.
echo "Looking for local .DS_Store files..."
wc_found=$(find "$backup_dir" -name '*.DS_Store' -type f -exec rm {} \; -print | wc -l)
found=$(echo $wc_found) # Just to strip leading whitespace from wc output.
if [ $found -lt 1 ]
then
	echo "There were no .DS_Store files to delete."
else
	echo "${found} .DS_Store file(s) deleted."
fi

# Create an array to store paths to the directories and files on the server that
#  we're going to back up.
backup_items=()

# Websites
backup_items+=('/var/www')

# Apache config
backup_items+=('/etc/apache2/sites-available')
backup_items+=('/etc/apache2/apache2.conf')

# Networking
backup_items+=('/etc/hostname')
backup_items+=('/etc/hosts')
backup_items+=('/etc/network/interfaces')
backup_items+=('/etc/resolv.conf')

# Postfix configuration
backup_items+=('/etc/postfix/main.cf')

# Firewall
backup_items+=('/etc/iptables.firewall.rules')
backup_items+=('/etc/network/if-pre-up.d/iptables')

# Sudo
backup_items+=('/etc/sudoers')

# Home folder
backup_items+=('/home/${username}')

# Cron

echo "Running crontab backup script..."
ssh -t $host sudo /var/backups/crontabs/backup-crontabs.sh

# User crontabs (includes backup script and restore script)
backup_items+=('/var/backups/crontabs')

# System crontab
backup_items+=('/etc/crontab')

# Cronjob directories
backup_items+=('/etc/cron.d')
backup_items+=('/etc/cron.hourly')
backup_items+=('/etc/cron.daily')
backup_items+=('/etc/cron.weekly')
backup_items+=('/etc/cron.monthly')

# MySQL

echo "Running MySQL databases backup script..."
ssh -t $host sudo /var/backups/mysql/backup-mysql.sh

# MySQL databases (includes backup script)
backup_items+=('/var/backups/mysql')

# We're done adding locations to back up. Let's perform the actual backup:

# Get the backup items array as a string. We will supply this variable to rsync in
#  quotes. We need to double-bag like this or rsync won't interpret it correctly.
backup_items_string="${backup_items[@]}"

# Synchronize the local backup directory with the backup items on the server.
rsync -avz --delete --relative --progress --rsync-path="sudo rsync" \
	$host:"$backup_items_string" "$backup_dir"
