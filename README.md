**`unixme`** (pronounced "you nix me") is a collection of useful shell scripts for server administrators.

## Features

* Sets up an `iptables` firewall with an editable ruleset that survives reboots.
* Adds a daily cronjob that emails you the tail of the Apache and PHP error logs for all your websites.
* Enables a backup script you can run from your local machine to sync your server's important files:
	* Backups are performed using rsync, which is fast and incremental.
	* Included and excluded paths are specified using a simple but powerful filter list (template provided).
	* Optionally include all MySQL databases, crontabs, and cronjobs in the backup. (A script that restores crontabs from the backups is also included.)

**Compatibility notice:** Tested on Debian 7 (wheezy) and Mac OS X 10.9 (Mavericks).

## Getting started

### Server setup

1. Make sure you've got `git` installed and configured on your local machine and on your server.

1. Clone the repository into your server's root directory.
		
		$ cd /
		$ sudo mkdir unixme
		$ sudo chown -R username:username unixme
		$ git clone https://github.com/beebauman/unixme.git unixme

1. Edit `/unixme/iptables-rules` as desired.

1. Run the setup script

		$ /unixme/server-setup.sh

### Backing up to your local machine

#### Prepare the server

The backup script requires you to allow execution on the server of `sudo rsync` without re-authentication. To do so, edit `/etc/sudoers` using the `$ sudo visudo` command. Add this line to that file:

		username ALL = NOPASSWD: /usr/bin/rsync

#### Prepare your local machine

1. Clone the repository to your local machine.
		
		$ git clone https://github.com/beebauman/unixme.git

1. Create your own filter rules file that identifies the paths on the server to be included/excluded in the backup. Use `unixme/backup-server-default-filter-rules.txt` as a template.

#### Run the backup script

**Script options:**

|Option         | Short| Meaning                                                                    |
|---------------|------|----------------------------------------------------------------------------|
|`--host`       |`-h`  | Followed by name of `Host` defined in local `~/.ssh/config`. **Required.** |
|`--path`       |`-p`  | Followed by path to a directory to save the backup in. **Required.**       |
|`--filters`    |`-p`  | Followed by path to filter rules file. **Required.**                       |
|`--crontabs`   |`-c`  | Before backup, copy crontabs to /var/backups/crontabs.                     |
|`--databases`  |`-d`  | Before backup, copy MySQL databases to /var/backups/mysql/databases.       |

**Example:** `$ server-backup.sh --host pizza --path /Local/backup/directory --filters /Filter/rules/file --crontabs --databases`

**Note**: The supplied `--host`'s authentication parameters must be defined in `~/.ssh/config`, for example:

		$ cat ~/.ssh/config
		Host pizza
			Hostname pizza.food.com
			User username
			IdentityFile /Path/to/private/key
  			IdentitiesOnly yes

















