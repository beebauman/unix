#!/bin/sh

# Compatibility note: This script has only been tested on Debian 7 (wheezy).

# This script should be placed in /var/backups/crontabs/.
# It will back up the crontab for every user on the server.

# --------------------------------------------------#

for user in $(cut -f1 -d: /etc/passwd)
do
	crontab=`crontab -u $user -l 2>&1`
	if [ "$crontab" != "no crontab for $user" ] && [ "$crontab" != "must be privileged to use -u" ] ; then
    		echo "writing $user.crontab backup file"
		echo "$crontab" > /var/backups/crontabs/$user.crontab
	fi
done
