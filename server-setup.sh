#!/bin/sh

cp iptables /etc/network/if-pre-up.d/iptables-load
chmod 755 /etc/network/if-pre-up.d/iptables-load
/etc/network/if-pre-up.d/iptables-load

ln -s print-www-error-logs /etc/cron.daily/

mkdir /var/backups/crontabs

mkdir /var/backups/mysql

