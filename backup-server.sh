#!/bin/sh

# This script requires the following scripts on the server being backed up:
# 1. The database backup script, saved to /var/backups/mysql/backup-mysql.sh.
# 2. The crontab backup script, saved to /var/backups/crontabs/backup-crontabs.sh.
# 3. The firewall rules file, saved to /etc/iptables.firewall.rules.
# 4. The firewall boot load script, saved to /etc/network/if-pre-up.d/iptables

# You'll need to supply the script with the short name of a Host whose Hostname
#  and User parameters are defined in ~/.ssh/config. For example:
# Host widget
# 	Hostname widget.acme.come
# 	User johnsusername

# Your User must have sudo privileges on the server, and they must be able to
#  run the command 'sudo rsync' without a password. This can be accomplished
#  by adding the following line to /etc/sudoers:
# johnsusername ALL = NOPASSWD: /usr/bin/rsync

# --------------------------------------------------#

# Get the Host and Hostname
read -p "Host to back up: " HOST
HOSTNAME=$(cat ~/.ssh/config | grep Hostname | awk '{print $2}' | grep $HOST)

# Get the backup directory
read -e -p "Local backup directory: " INPUT_DIR
# Expand tilde to absolute path to home directory
BACKUP_DIR=$(eval echo $INPUT_DIR)

# Delete all .DS_Store files so that rsync won't need to later
find "$BACKUP_DIR" -name '*.DS_Store' -type f -delete

# Create an array to store the locations we're going to back up
backupfiles=()

# Websites
backupfiles+=('/var/www')

# Apache config
backupfiles+=('/etc/apache2/sites-available')
backupfiles+=('/etc/apache2/apache2.conf')

# Networking
backupfiles+=('/etc/hostname')
backupfiles+=('/etc/hosts')
backupfiles+=('/etc/network/interfaces')
backupfiles+=('/etc/resolv.conf')

# Postfix configuration
backupfiles+=('/etc/postfix/main.cf')

# Firewall

backupfiles+=('/etc/iptables.firewall.rules')
backupfiles+=('/etc/network/if-pre-up.d/iptables')

# Sudoers
backupfiles+=('/etc/sudoers')

# SSH
backupfiles+=('/home/beebauman/.ssh')

# Cron

# Run crontabs backup script
ssh -t $HOST sudo /var/backups/crontabs/backup-crontabs.sh

# Add crontabs backup files (includes backup and restore scripts)
backupfiles+=('/var/backups/crontabs')

# Add cron* system files
backupfiles+=('/etc/crontab')
backupfiles+=('/etc/cron.d')
backupfiles+=('/etc/cron.hourly')
backupfiles+=('/etc/cron.daily')
backupfiles+=('/etc/cron.weekly')
backupfiles+=('/etc/cron.monthly')

# MySQL

# Run MySQL databases backup script
ssh -t $HOST sudo /var/backups/mysql/backup-mysql.sh

# Add mysql backup files (includes backup script)
backupfiles+=('/var/backups/mysql')

# Perform the backup

# Get the array elements (we need to double-bag the array to use it with rsync)
ARG="${backupfiles[@]}"

# Synchronize the local backup with the final list of directories and files on the remote server
rsync -avz --delete --relative --progress --rsync-path="sudo rsync" $HOST:"$ARG" "$BACKUP_DIR"
