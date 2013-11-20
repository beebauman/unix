#!/bin/bash

# This script should be placed in /var/backups/mysql/.
# It will back up all the MySQL databases on the server.

# --------------------------------------------------#

# Parent backup directory
backup_dir="/var/backups/mysql/databases"

# MySQL settings
mysql_user=""
mysql_password=""

# Read MySQL username from stdin if empty
if [ -z "${mysql_user}" ]
then
  read -p "MySQL username: " mysql_user
fi

# Read MySQL password from stdin if empty
if [ -z "${mysql_password}" ]
then
  read -s -p "MySQL password: " mysql_password
fi

# Check MySQL password
echo exit | mysql --user=${mysql_user} --password=${mysql_password} -B 2>/dev/null
if [ "$?" -gt 0 ]
then
  echo "Incorrect password for MySQL user ${mysql_user}."
  exit 1
else
  echo "Password for MySQL user ${mysql_user} verified as correct."
fi

# Delete old backup
rm -rf "${backup_dir}"

# Recreate backup directory and set permissions
mkdir -p "${backup_dir}"
chmod 700 "${backup_dir}"

# Get MySQL databases
mysql_databases=`echo 'show databases' | mysql --user=${mysql_user} --password=${mysql_password} -B | sed /^Database$/d`

# Backup and compress each database
for database in $mysql_databases
do
  if [ "${database}" == "information_schema" ] || [ "${database}" == "performance_schema" ]
  then
        additional_mysqldump_params="--skip-lock-tables"
  else
        additional_mysqldump_params=""
  fi
  echo "Creating backup of \"${database}\" database."
  mysqldump ${additional_mysqldump_params} --user=${mysql_user} --password=${mysql_password} ${database} | gzip > "${backup_dir}/${database}.gz"
  chmod 600 "${backup_dir}/${database}.gz"
done
