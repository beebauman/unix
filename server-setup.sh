#!/bin/sh

cp iptables-load /etc/network/if-pre-up.d/
chmod 755 /etc/network/if-pre-up.d/iptables-load
/etc/network/if-pre-up.d/iptables-load

ln -s print-www-error-logs /etc/cron.daily/

mkdir -p /var/backups/crontabs

mkdir -p /var/backups/mysql
