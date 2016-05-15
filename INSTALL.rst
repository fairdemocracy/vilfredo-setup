.. -*- coding: utf-8 -*-

===========================
Set up a development system
===========================

If everything you want is develop Vilfredo code on your local machine, you can run a simplified installation procedure which will download all code and create a virtual environment for you.

Just download the ``scripts/install.sh`` script, make it executable running ``chmod +x install.sh``, and run it.

The procedure has been written for Debian GNU/Linux, but can be easily adapted for other Linux distributions, replacing the part installing required packages.

===================================
Full install on a public web server
===================================

A production instance of Vilfredo can be installed on an already existing server or a brand new virtual machine or dedicated box, customizing it with an unique domain name and separate database. Multiple instances can run on the same server without disrupting each other.

We're assuming you're running a ``Debian/GNU Linux`` based distribution (such as Debian stable or Ubuntu). Vilfredo could likely run on other flavours of Linux, but these are not covered by this guide.

WARNING: Do not attempt to run installation if other web servers such as Apache are running on the same server (unless you know how to set up NGINX to run on a different IP address or port). Two web servers on the same IP address and port will conflict and prevent installation of each other.

Download the ``scripts/addinstance`` script, make it executable with ``chmod +x addinstance`` and run it.

To download the procedure right to your server, first install ``wget`` then use it to get files:

.. code:: sh

    sudo apt-get install wget
    wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/scripts/addinstance
    wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/scripts/delnstance

If the ``sudo`` command is not present on the system, log in as root user and install it through:

.. code:: sh

    apt-get install sudo

This requires being able to login to the server as root at least once.

Disclaimer: The "addinstance" procedure, although automated, could rarely generate situations which need being fixed by a competent system administrator. Do not run it on an existing production server if you're not prepared handling such kind of events.

Note: the ``/home/$INSTANCE/vilfredo-client/static/templates/analytics.template.html`` file could cause JavaScript errors in some Vilfredo versions - in this case, just rename it to ``/home/$INSTANCE/vilfredo-client/static/templates/analytics.template.html.old`` to prevent the webserver from serving it.

Now you should be able to access the Vilfredo installation by entering the server IP address into your browser location bar. There could be other issues to be solved - you might have a look at the ``/var/log/$INSTANCE/vilfredo-vr.log`` for more information.

If you want to delete a Vilfredo instance together with all of its data, download the ``scripts/delinstance`` script, make it executable with ``chmod +x delinstance`` and run it.

This procedure deletes all data associated to the instance. The database will be deleted only if it has the same name of the instance. If your instance connects to an external database, this won't be deleted when removing instance, thus no data will be lost.

==========================================================
Additional instructions for web server administrators only
==========================================================

Some kind of virtual machines or servers could require additional setup. Here follow some guides to solve the most common issues:

- partitioning guide (for LVM setups and virtual machines where partitioning has not been performed before)
- fixing missing locales
- fixing "vi" editor replacing it with more comfortable "vim"
- upgrading existing packages
- logging into MySQL without entering a password
- installing PHPMyAdmin to easily manage the MySQL database through a web-based interface
- installing a working mail server to send messages from Vilfredo and setting SPF and DKIM on DNS
- securing SSH

Partitioning guide
==================

Some servers could not expose all of their disk space without creating additional LVM partitions and mounting them.
The following example assumes an empty partition is available at ``/dev/sda3`` and three volumes have to be created:

.. code:: sh

    sudo vgextend localhost-vg /dev/sda3
    sudo lvcreate -L 30G -n log localhost-vg
    sudo lvcreate -L 12G -n mysql localhost-vg
    # If there's no space available, note down the number of free extents
    # and replace "-L 8G" with "-l number_of_extents"
    sudo lvcreate -L 32G -n home localhost-vg
    sudo mkfs -t ext4 /dev/localhost-vg/home
    sudo mkfs -t ext4 /dev/localhost-vg/mysql
    sudo mkfs -t ext4 /dev/localhost-vg/log
    # Then edit /etc/fstab and move existing folders or remove them
    sudo reboot

Fixing missing locales
======================

.. code:: sh

    sudo dpkg-reconfigure locales
    sudo apt-get install --reinstall locales

and add your locale from the list displayed on the console, then specify it as default.

Fixing "vi" editor
==================

.. code:: sh

    sudo apt-get install vim
    sudo replace "\"syntax on" "syntax on" -- /etc/vim/vimrc
    sudo replace "\"set background" "set background" -- /etc/vim/vimrc

Upgrading packages
==================

Log in as ``root`` user and run the following commands:

.. code:: sh

    sudo apt-get update
    sudo apt-get dist-upgrade
    sudo apt-get autoremove --purge

Logging into MySQL without typing a password
============================================

When logging into the system as "root" user, somebody could prefer accessing MySQL server as "root" user without having to enter their password all the time.

.. code:: sh

    # Creates a file which will be later needed to access MySQL server
    # Replace ROOT_MYSQL_PASSWORD with your MySQL server "root" password
    sudo cat > /root/.my.cnf <<EOF
    [mysql]
    user=root
    password=ROOT_MYSQL_PASSWORD

    [mysqldump]
    user=root
    password=ROOT_MYSQL_PASSWORD
    EOF
    sudo chmod 600 /root/.my.cnf

replacing ROOT_MYSQL_PASSWORD with your MySQL root user password.

Installing PHPMyAdmin for easy database administration
======================================================

Install PHPMyAdmin:

.. code:: sh

    sudo apt-get install phpmyadmin

Open NGINX configuration file for the main domain (or another spare domain) and paste the following into a ``server`` block:

    location /phpmyadmin {
      alias /usr/share/phpmyadmin;
      index index.php;
      try_files $uri $uri/ index.php$is_args$args =404;
      access_log /var/log/nginx/phpmyadmin/access.log;
      error_log /var/log/nginx/phpmyadmin/error.log;
      auth_basic "PHPMyAdmin";
      auth_basic_user_file /etc/nginx/htpasswd;
      # Do not remove this - it is not redundant
      location ~ \.(ico|css|js|gif|jpg|png)$ {
        expires max;
        log_not_found off;
      }
      location ^~ /phpmyadmin/(libraries|setup/lib) { deny all; return 444; }
      # Pass the PHP scripts to FastCGI server
      location ~* ^/phpmyadmin/(.+\.php)$ {
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /usr/share/phpmyadmin/$1;
        include fastcgi_params;
      }
    }

Now enter the following commands:

.. code:: sh

    # Generates additional password to further protect PHPMyAdmin installation
    sudo apt-get install apache2-utils
    sudo htpasswd -c /etc/nginx/htpasswd root
    sudo chown www-data:www-data /etc/nginx/htpasswd
    sudo chmod 600 /etc/nginx/htpasswd
    # Creates log folder for PHPMyAdmin installation
    sudo mkdir /var/log/nginx/phpmyadmin
    # Enables OpCache to accelerate PHP scripts execution
    sudo replace ";opcache.enable=0" "opcache.enable=1" -- /etc/php5/fpm/php.ini
    sudo replace ";opcache.save_comments=1" "opcache.save_comments=0" -- /etc/php5/fpm/php.ini
    sudo replace ";opcache.fast_shutdown=0" "opcache.fast_shutdown=1" -- /etc/php5/fpm/php.ini
    sudo service php5-fpm restart
    sudo service nginx restart

This PHPMyAdmin installation is protected by an additional HTTP password. The reason is preventing direct access to the login page, because in the past this piece of software exhibited serious security issues.
You might as well prefer IP-based authentication.

Installing a working mail server
================================

A working mail server is required to send email messages to Vilfredo users.

If an external SMTP with authentication is not available, a local server should be configured instead.
To avoid messages being marked as spam by recipients, the server should support DKIM and SPF.
DKIM is a sort of "digital signature" which is added to all email messages to ensure they had been originated by a server in the domain of the sender. A public-private key has to be generated on the server, then a dedicated daemon (for instance OpenDKIM) will take care of generating a digital signature using those keys, adding it to the message headers. The public key must also be added to a TXT record in the domain zone on DNS.
SPF is used to specify the list of IP addresses and servers which are allowed sending messages from a given domain. It does not require generating public-private key pairs. Just add a TXT record in the domain zone on DNS specifying the list of servers and IP addresses.
As always, feel free to replace ``vilfredo.org`` with your mail server domain name.

This part has not been included in the automated installation procedure because a manual part is involved (adding records into the DNS). If you do not feel comfortable setting up a mail server, just create an account on an external mail server and configure Vilfredo to use it to send mail instead.

First of all, install Postfix and OpenDKIM on your server:

.. code:: sh

    apt-get install postfix opendkim opendkim-tools
    cp /home/vilfredo/vilfredo-setup/opendkim.conf /etc
    mkdir /etc/dkim
    # The /etc/dkim/domains file contains the list of domains authorized to send mail messages
    # The following line allows the server itself sending digitally signed messages
    echo "localhost [::1]" > /etc/dkim/domains
    # Note: From now on, replace "vilfredo.org" with the site domain if different
    echo "vilfredo.org" >> /etc/dkim/domains
    echo "default._domainkey.vilfredo.org  vilfredo.org:default:/etc/dkim/keys/vilfredo.org/default" > /etc/dkim/keytable
    echo "vilfredo.org  default._domainkey.vilfredo.org" > /etc/dkim/signingtable
    mkdir -p /etc/dkim/keys/vilfredo.org
    cd /etc/dkim/keys/vilfredo.org
    opendkim-genkey -r -d vilfredo.org
    mv /etc/dkim/keys/vilfredo.org/default.private /etc/dkim/keys/vilfredo.org/default
    chmod 600 /etc/dkim/keys/vilfredo.org/default
    chown -R opendkim:opendkim /etc/dkim
    chmod -R o-r,o-w,o-x /etc/dkim
    # WARNING: Do not mistype this - do not enter ">" instead of ">>" or you'll erase Postfix configuration!
    cat /home/vilfredo/vilfredo-setup/postfix-dkim.conf >> /etc/postfix/main.cf
    replace "#myorigin" "myorigin" -- /etc/postfix/main.cf
    service opendkim restart
    service postfix restart

Now get the contents of the ``/etc/dkim/keys/vilfredo.org/default.txt`` file (or whatever, depending from the domain name chosen) and copy its contents to the domain zone file in the DNS.
If you DNS is externally managed (you do not have access to the configuration files but only to a web-based interface):

- add a new TXT type record
- specify as name ``default._domainkey``
- enter the text between quotes as value (without any additional quotes!)

If you want to send mail from a subdomain (for instance demo.vilfredo.org) do not forget to add the TXT record containing the DKIM key to the subdomain instead of the main domain!

Moreover, ensure the ``/etc/hostname`` and ``/etc/mailname`` files contains the server domain name (for instance vilfredo.org).

To avoid triggering SpamAssassin filter (rule ``TVD_PH_SUBJ_ACCOUNTS_POST``), also ensure the subject of messages sent by Vilfredo does not match the following regular expression:

    /\b(?:(?:re-?)?activat[a-z]*| secure| verify| restore| flagged| limited| unusual| report| notif(?:y| ication)| suspen(?:d| ded| sion)| confirm[a-z]*) (?:[a-z_,-]+ )*?accounts?\b/i

So it should be different from "Vilfredo - Activate Your Account".
Additionally, please note other steps could be needed in order to circumvent spam filters.

Securing SSH
============

To improve security of the server, you might limit users allowed to log in through SSH, by editing the /etc/ssh/sshd_config file and adding

    AllowUsers root user1 user2

replacing ``user1`` and ``user2`` with other users allowed to log in.
Then enter

.. code:: sh

    service ssh restart

This way, there will be no risks in case a weak password has been chosen for system users or users running Vilfredo instances.
