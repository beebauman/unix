# unixme

**`unixme`** (pronounced "you nix me") is a collection of useful shell scripts for server administrators.

## Features

### 1. Setup script for your server:

* Sets up an `iptables` firewall with an editable ruleset that survives reboots.
* Adds a daily cronjob that emails you the tail of the Apache error logs for all your websites.

### 2. Backup script for your local machine to sync your server's important files:

* Backups are performed using rsync, which is fast and incremental.
* Included and excluded paths are specified using a simple but powerful filter list (template provided).
* Optionally include all MySQL databases, crontabs, and cronjobs in the backup. (A script that restores crontabs from the backups is also included.)

### Compatibility notice

Tested on Debian 7 (wheezy) and Mac OS X 10.9 (Mavericks).

## Getting started

### Server setup

1. Make sure you've got `git` installed and configured on your local machine and on your server.

1. Clone the repository into your server's root directory.
		
		$ cd /
		$ git clone https://github.com/beebauman/unixme.git

1. Add your MYSQL username and password to `/unixme/mysql-backup.sh`.

1. Edit `/unixme/iptables-rules` as desired.

1. Run the setup script

		$ /unixme/server-setup.sh

### Backup script

#### Prepare the server

To back up directories and files that require root access, you need to configure the server to allow `sudo rsync` without asking for a password:

1. Edit `/etc/sudoers`:

		username ALL = NOPASSWD: /usr/bin/rsync

#### Prepare your local machine

1. Clone the unixme repository to a location on your local machine.
		
		$ git clone https://github.com/beebauman/unixme.git

1. Create a folder on local machine to store the backup.

1. Create your own filters that specify the directories and files on the server that will be included/excluded in the backup by copying `unixme/backup-server-default-filter-rules.txt`.

#### Run the backup script

Summary of script options:

|Option        | Short| Meaning                                                                    |
|--------------|------|----------------------------------------------------------------------------|
|`--host`      |`-h`  | Followed by name of `Host` defined in local `~/.ssh/config`. **Required.** |
|`--path`      |`-p`  | Followed by path to a directory to save the backup in. **Required.**       |
|`--filters`   |`-p`  | Followed by path to filter rules file. **Required.**                       |
|`--crontabs`  |`-c`  | Before backup, copy crontabs to /var/backups/crontabs.                     |
|`--databases` |`-d`  | Before backup, copy MySQL databases to /var/backups/mysql/databases.       |

Example:
		
		$ server-backup.sh --host pizza --path /Local/backup/directory --filters /Filter/rules/file --crontabs --databases 

**Note**: The `--host` you supply must be the short name of a `Host` whose `Hostname`, `User`, and authentication parameters are defined in your local machine's `~/.ssh/config`. For example:

		$ cat ~/.ssh/config
		Host pizza
			Hostname pizza.food.com
			User username
			IdentityFile /Path/to/private/key
  			IdentitiesOnly yes

















