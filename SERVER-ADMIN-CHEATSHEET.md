# Server admin cheatsheet

## Initial setup

### Provisioning

1. Choose hostname and domain, e.g. `pizza.food.com`.

1. Provision cloud server (Debian, current stable build, 64-bit).

1. Save the FQDN, IP, and root password.

1. In the domain’s DNS, add an A record for the hostname pointing to cloud server's IP.

### Security

#### Create non-root user

1. Log in as root:

	    # ssh -o PubkeyAuthentication=no root@pizza.food.com
	    [enter password]

1. Change root password:
	
		# passwd

1. Create non-root user:
		
		# useradd --user-group --groups sudo --create-home --shell /bin/bash username

#### Set up keypair authentication

##### Generate keypair on local machine

		$ ssh-keygen
		[enter path to private key file e.g. /Users/local_username/Downloads/username_rsa]
		[Leave passphrase blank]

##### Put public key on server

1. Copy the public key to the server:

		$ scp -o PubkeyAuthentication=no /Users/local_username/Downloads/username_rsa.pub root@food.pizza.com:

1. Move it into the right place:
		
		# mkdir /home/username/.ssh
		# mv /home/username/.ssh/authorized_keys
		# chown -R username:username .ssh
		# chmod 700 .ssh
		# chmod 600 .ssh/authorized_keys

##### Disable server's password authentication and root login

1. Modify the server’s SSH configuration file `/etc/ssh/sshd_config`:

		PasswordAuthentication no
		PermitRootLogin no

1. Restart the SSH service to load the new authorized key and configuration.

		# service ssh restart

##### Set local machine's SSH to use keypair authentication

1. Add this line to your local `~/.profile`:

		ssh-add /Path/to/SSH/private/key &>/dev/null

1. Add these lines to ~/.ssh/config:

		Host pizza
			Hostname pizza.food.com
			User username
			IdentityFile "/Path/to/SSH/private/key"
			IdentitiesOnly yes

1. Restart your local machine's SSH service and reload your `.profile`:

		$ sudo launchctl stop com.openssh.sshd 
		$ sudo launchctl start com.openssh.sshd
		$ source ~/.profile

##### Test keypair authentication

1. Log in using SSH keypair authentication:

		$ ssh pizza
		
	Hopefully that worked :-)


#### Packages

1. Update packages:

		# apt-get update
		# apt-get upgrade

1. Make sure essential packages are installed:
		
		# apt-get install sudo vim git mysql-server mysql-client apache2 php5 php5-mysql
	
	Record the password you set for MYSQL's root user.

#### Time Zone

1. Verify time zone is set to UTC:
		
		# dpkg-reconfigure tzdata

#### Environment Variables

1. Add to `~/.profile`:

		export EDITOR=/usr/bin/vi

### Networking

1. Create a file containing the machine’s name:

		# echo "hammer" > /etc/hostname

1. Set the hostname from that file:

		# hostname -F /etc/hostname

1. Edit `/etc/hosts` to reflect new hostname and public IP address:

		127.0.0.1	localhost.localdomain	localhost
		1.2.3.4		pizza.food.com			pizza

1. Edit `/etc/network/interfaces` (make sure you use the right values for your server and its network):

		# The loopback network interface
		auto lo
		iface lo inet loopback
		
		# The primary network interface
		auto eth0 eth1
		iface eth0 inet static
			address 1.2.3.4
			netmask 255.255.255.0
			gateway 2.3.4.5
		iface eth1 inet static
			address 10.1.1.1
			netmask 255.255.0.0

1. Remove the DHCP client:

		# apt-get remove isc-dhcp-client

1. Check the configured DNS resolvers in `/etc/resolv.conf`. Make sure the IP addresses match the resolvers provided by the hosting company. Optionally add this line for round-robining:
		
		options rotate

1. Reboot the server, and then confirm that the public and private IP addresses are up:

		# ip addr show eth0

### Apache

1. Navigate to the server’s DNS name to test the Apache installation. You should see the default “It works!” page.

1. Edit `/etc/apache2/apache2.conf`:

		### Added by username: ###

		# Disable directory indexes.
		Options -Indexes
		
		# Deny access to all git repositories.
		<Directory ~ "\.git">
			Order allow,deny
			Deny from all
		</Directory>
		
		# Enable central framework access for all virtual sites.
		Alias /fw /var/www/frameworks
		
		# Add MIME types.
		
		# Video
		AddType video/ogg .ogv
		AddType video/mp4 .mp4
		AddType video/webm .webm
		
		# Fonts
		AddType application/vnd.ms-fontobject .eot
		AddType font/ttf .ttf
		AddType font/otf .otf
		AddType application/font-woff .woff

1. Comment out the configuration directives that enable Fancy Indexing in `/etc/apache2/mods-available/alias.conf`.

1. Put config files for all sites into `/etc/apache2/sites-available/`.

1. Copy SSL certificate files to locations specified by site config files.

1. Set correct ownership and permissions for private keys. e.g.:

		# chown root:root /etc/apache2/sites-available/.ssl/food.com/private.pem
		# chmod 0400 /etc/apache2/sites-available/.ssl/food.com/private.pem

1. Put website directories into `/var/www`.

1. Disable default site using `a2dissite`.

1. Enable new site(s) using `a2ensite`.

1. Enable the `ssl` and `rewrite` modules.

1. Restart Apache:

		$ sudo service apache2 restart

### PHP

1. Install PHP:

		# apt-get install php5 php5-curl

1. Test installation with:

		# vi /var/www/example.com/public/phpinfo.php
		<?php
		phpinfo();
		
### MYSQL

1. Edit MYSQL's configuration file `/etc/mysql/my.cnf`:

		bind-address = 0.0.0.0
		
	Make sure `skip-networking` is either not there, or commented out.

1. Restart the MYSQL service:

		$ sudo service mysql restart

1. Log in to MYSQL:

		$ mysql -u root -p

	Enter your password...

1. Grant the root user privileges for networking connections and create a new user for web stuff:

		mysql> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root-password' WITH GRANT OPTION;
		CREATE USER 'www-data'@'%' IDENTIFIED BY 'www-password';
		GRANT ALL PRIVILEGES ON *.* TO 'www-data'@'%' WITH GRANT OPTION;
		CREATE USER 'www-data'@'localhost' IDENTIFIED BY 'www-password';
		GRANT ALL PRIVILEGES ON *.* TO 'www-data'@'localhost' WITH GRANT OPTION;
		FLUSH PRIVILEGES;

1. If necessary, import databases from backups using Sequel Pro.app.

### Postfix

1. Install postfix.

		# apt-get install postfix

	Choose “Internet site” option when asked during installation.

2. To configure for sending mail only (copied from http://www.postfix.org/STANDARD_CONFIGURATION_README.html#null_client):

		# vi /etc/postfix/main.cf
		myhostname = hostname.example.com
		myorigin = $mydomain
		relayhost =
		inet_interfaces = loopback-only
		mydestination =

	Then run:

		# postfix upgrade-configuration
		# postfix stop
		# postfix start
		# echo 'this is a test'| mail -s Test me@food.com

**Note:** Unlike the instructions in the postfix docs, I left the `relayhost` parameter blank, so that outgoing emails are delivered directly to the MX of the recipient’s domain name. Using the suggested value of `$mydomain` would route all outgoing mail though my domain’s MX (which is Google Apps). I originally had it set that way, until Google started sending “account doesn’t exist” bounce-backs for emails to non-Google addresses.

### Git

1. Copy private keys for Github and Bitbucket to `/home/username/.ssh`.

1. Add to server's `~/.profile`:

		# Start the SSH agent.
		killall -u $USER ssh-agent &>/dev/null
		eval `ssh-agent -s` &>/dev/null
		
		# Add SSH identities.
		ssh-add ${HOME}/.ssh/bitbucket_rsa &>/dev/null
		ssh-add ${HOME}/.ssh/github_rsa &>/dev/null

1. Reload the server's `~/.profile`:

		$ source ~/.profile

1. Configure git:

		$ git config --global user.name "Testy Tester"
		$ git config --global user.email webmaster@food.com

### Web development frameworks

1. Create a folder for web frameworks:
	
		$ mkdir /var/www/frameworks

1. Clone public repositories:

		$ cd /var/www/frameworks
		$ git clone https://github.com/beebauman/ie-vay.git
		$ git clone https://github.com/beebauman/mediaelement-timecode.git
		$ git clone https://github.com/beebauman/formative.git
		$ git clone https://github.com/twbs/bootstrap.git
		$ git clone https://github.com/ftlabs/fastclick.git
		$ git clone https://github.com/gfranko/jquery.selectBoxIt.js.git select-box-it
		$ git clone https://github.com/FortAwesome/Font-Awesome.git font-awesome
		$ git clone https://github.com/jasny/bootstrap.git bootstrap-jasny
		$ git clone https://github.com/johndyer/mediaelement.git
		$ git clone https://github.com/carhartl/jquery-cookie.git

1. Manually copy `jquery`, `jquery-mobile`, and `jquery-ui` into the frameworks folder.
		
### Cron

1. Set up your email address to recieve cronjob output from the root, username, and system crontabs.

		$ sudo crontab -u root -e
		MAILTO="webmaster@food.com"
		
		$ crontab -u username -e
		MAILTO="webmaster@food.com"

		$ sudo vi /etc/crontab
		MAILTO="webmaster@food.com"

2. Uninstall `anacron` so that it doesn't conflict with `cron`:
		
		$ sudo apt-get remove --purge anacron

## Misc.

#### Install an FTP client

	# apt-get install proftpd

Choose standalone mode when asked during installation.

#### Install and use screen for a shared console session

Install screen:

	# apt-get install screen

To enable multi-user sessions, the setuid flag must be on:

	# chmod u+s /usr/bin/screen

Start the screen session:

	# screen -s collaborate

Enter command mode by hitting control-A, and then turn multi-user mode on:

	:multiuser on

Enter another command to give permission to the second user to share the session:

	:acladd username2

The second user can then join the session:

	# screen -x username1/collaborate

#### Install a browsing proxy

In case I need to masquerade as a different IP address.

	# apt-get install tinyproxy

Edit `/etc/tinyproxy.conf`:

	LogLevel Error
	Allow my.ip.add.ress

Then restart TinyProxy:

	# /etc/init.d/tinyproxy restart

Note: the TinyProxy default port is 8888. Don’t forget to open the firewall!

#### Delete all files except certain ones

	$ find . ! -name "do-not-delete-me*" -type f -exec rm -rf {} \;

#### Completely remove a package and all its files

	# apt-get --purge remove packagename

#### Find and replace

	# apt-get install rpl

#### Find and replace text throughout all SMF posts

	> UPDATE `smf_messages`
	> SET `body` = REPLACE(`body`, 'search string', 'replacement string');










