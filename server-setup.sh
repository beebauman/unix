#!/bin/sh

cp -f /unixme/iptables-load /etc/network/if-pre-up.d/
/etc/network/if-pre-up.d/iptables-load

ln -sf /unixme/print-www-error-logs /etc/cron.daily/

mkdir -p /var/backups/crontabs

mkdir -p /var/backups/mysql
