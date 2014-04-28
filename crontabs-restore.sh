#!/bin/sh

# This script restores all crontabs from backups in /var/backups/crontabs/.

# --------------------------------------------------#

suffix=.crontab
prefix=/var/backups/crontabs/

for path in /var/backups/crontabs/*.crontab
do
	file=${path#$prefix}
	user=${file%$suffix}
	crontab -u $user $path
done
