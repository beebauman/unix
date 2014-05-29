#!/bin/bash

# Backs up all MySQL databases to /var/backups/mysql/databases.

# --------------------------------------------------#

# If you don't want to enter your MySQL username and/or password every time you run this script, save them here.
################
mysqlUser=""
mysqlPassword=""
################

# Read MySQL username from stdin if empty
if [ -z "${mysqlUser}" ]
then
  read -p "MySQL username: " mysqlUser
fi

# Read MySQL password from stdin if empty
if [ -z "${mysqlPassword}" ]
then
  read -s -p "MySQL password: " mysqlPassword
fi

# Check MySQL password
echo exit | mysql --user=${mysqlUser} --password=${mysqlPassword} -B 2>/dev/null
if [ "$?" -gt 0 ]
then
  echo "Incorrect password for MySQL user ${mysqlUser}."
  exit 1
else
  echo "Password for MySQL user ${mysqlUser} verified as correct."
fi

# Parent backup directory
backupDirectory="/var/backups/mysql/databases"

# Delete old backup
rm -rf "${backupDirectory}"

# Recreate backup directory and set permissions
mkdir -p "${backupDirectory}"
chmod 700 "${backupDirectory}"

# Get MySQL databases
mysql_databases=`echo 'show databases' | mysql --user=${mysqlUser} --password=${mysqlPassword} -B | sed /^Database$/d`

# Backup and compress each database
for database in $mysql_databases
do
  if [ "${database}" == "information_schema" ] || [ "${database}" == "performance_schema" ] then
        additional_mysqldump_params="--skip-lock-tables"
  else
        additional_mysqldump_params=""
  fi
  echo "Creating backup of \"${database}\" database."
  mysqldump ${additional_mysqldump_params} --user=${mysqlUser} --password=${mysqlPassword} ${database} | gzip > "${backupDirectory}/${database}.gz"
  chmod 600 "${backupDirectory}/${database}.gz"
done
