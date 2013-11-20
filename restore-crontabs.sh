#!/bin/sh

# Compatibility note: This script has only been tested on Debian 7 (wheezy).

# This script should be placed in /var/backups/crontabs/.
# It will restore all crontab backups that have been saved to /var/backups/crontabs/.

# --------------------------------------------------#

suffix=.crontab
prefix=/crontabs-backup/

for path in /crontabs-backup/*.crontab
do
	file=${path#$prefix}
	user=${file%$suffix}
	crontab -u $user $path
done
