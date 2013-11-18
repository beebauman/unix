#!/bin/sh

# This script should be placed in /var/backups/crontabs
# It can be run manually to restore crontabs backed up to /var/backups/crontabs

suffix=.crontab
prefix=/crontabs-backup/

for path in /crontabs-backup/*.crontab
do
	file=${path#$prefix}
	user=${file%$suffix}
	crontab -u $user $path
done
