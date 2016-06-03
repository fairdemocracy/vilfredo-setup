.. -*- coding: utf-8 -*-

===========================
Set up a development system
===========================

If everything you want is develop Vilfredo code on your local machine, you can run a simplified installation procedure which will download all code and create a virtual environment for you.

Just download the ``scripts/install.sh`` script, make it executable running ``chmod +x install.sh``, and run it.

The procedure has been written for Debian GNU/Linux, but can be easily adapted for other Linux distributions, replacing the part installing required packages.

===================================
Full install on Digital Ocean
===================================

As Digital Ocean is the kind of system on which Vilfredo is being developed right now, we are going to give the instructions for it separately. As it is much simpler than everything else.

===================================
Starting with a Virgin Server
===================================

Create a new Droplet. Debian 8.3 x64 is the OS on which it has been tested so far. If you find it works with other servers please let us know. For a small server with just one instance usually a 512 MB is enough. Select also IPv6.

Chose as the hostname of the droplet the domain name you will run the server. This is important as Digital ocean uses the hostname to set up the reverse dns. And if you chose a different hostname from the name of the server the mail from the instance might be sent to spam, or worse refused.

Click on Create. Receive the IPv4, and IPv6 and immediately set up the DNS connecting the IPv4 and the IPv6 to that name. It is important that this has spread before running the installation. It use to take a few hours, but now it is pretty much immediate (when the DNS are in Dreamhost at least).

ssh into the server as root, change the password. Then run: 

    apt-get install sudo
    sudo apt-get install wget
    wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/scripts/start
    chmod +x start
    ./start

from this moment everything else is quite automatic. Start will download the other program needed and preare them. The next one to run is 

    ./signmail

This will require you to go back to the DNS to add the TXT information for the DNS. Then install the first instance:

    ./addinstance

And then you will need to add phpmyadmin (see below). Only at that point you can run the system.

===================================
Starting with a Snapshot of an Existing Server, with the same domain name
===================================

This is very simple. A snapshot will generally be set to work with a specific branch and a specific domain name. You only need to create droplet from the snapshot and then define the DNS for the IPv4 and the IPv6. Don't forget to add the TXT info getting it following the instructions under the /etc/dkim/keys/$DOMAINNAME/default.txt

===================================
Starting with a Snapshot of an Existing Server changing the domain name
===================================

If you want to change the domain name from a specific snapshot start creating a droplet from a snapshot. And define the DNS for it as if with the new domain. Then once the info of the DNS has propagated, run

    ./changedomain.sh

everything else is automatic.

===================================
Starting with a Snapshot of an Existing Server changing branch
===================================

If you want to change branch and you do not have a snapshot of that specific branch a possible way is to install a system with a branch, and then run 

    ./delinstance
    
and then run

    ./addinstance
    
At which point you will need to open NGINX configuration file for the new domain.

    /etc/nginx/conf.d/[instance_name].conf

Then paste the following into a ``server`` block (the part surronded by "server {" and "}"):

.. code-block:: nginx

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

    sudo service nginx restart

This is similar to what is needed to install phpmyadmin, but some parts are missing. If you need to install phpmyadmin from zero follow the complete instructions below.

===================================
Full install on a public web server
===================================

A production instance of Vilfredo can be installed on an already existing server or a brand new virtual machine or dedicated box, customizing it with an unique domain name and separate database. Multiple instances can run on the same server without disrupting each other.

We're assuming you're running a ``Debian/GNU Linux`` based distribution (such as Debian stable or Ubuntu). Vilfredo could likely run on other flavours of Linux, but these are not covered by this guide.

WARNING: Do not attempt to run installation if other web servers such as Apache are running on the same server (unless you know how to set up NGINX to run on a different IP address or port). Two web servers on the same IP address and port will likely conflict and prevent installation of each other.

Download the ``scripts/addinstance`` script right to your server, through ``wget``, and run it:

.. code:: sh

    sudo apt-get install wget
    wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/scripts/addinstance
    chmod 700 addinstance

If the ``sudo`` command is not present on the system, log in as root user and install it through:

.. code:: sh

    apt-get install sudo

This requires being able to login to the server as root at least once.

If everything worked, you should be able to access the Vilfredo installation by entering the server IP address into your browser location bar.

Troubleshooting
===============

The "addinstance" procedure, although automated, could rarely generate situations which could need being fixed manually. Most times, these can be solved by rebooting the server. However, do not run the procedure on an existing production server if you're not prepared handling such kind of events.

After running the "addinstance" procedure, you'll find a detailed installation log in ``/home/$INSTANCE/log/install.log`` file, where $INSTANCE is the name chosen for the instance.

In some rare cases, if a previous installation has been interrupted, the final restart of UWSGI-PyPy server could fail. The following message will be displayed:

    uwsgi-pypy: no process found
    Job for uwsgi-pypy.service failed. See 'systemctl status uwsgi-pypy.service' and 'journalctl -xn' for details.

You will find the following in ``/home/$INSTANCE/log/install.log`` file:

    uwsgi socket 0 bound to UNIX address /run/uwsgi-pypy/app/$INSTANCE/socket fd 3
    error removing unix socket, unlink(): Operation not permitted [core/socket.c line 200]

This can be easily solved by rebooting the server.

A detailed log file of each running instance is accessible at ``/home/$INSTANCE/log/uwsgi-pypy.log`` where $INSTANCE is the name chosen for the instance. This is a symbolic link automatically created by the installation procedure to the corresponding UWSGI-PyPy subfolder, for convenience. Open a separate terminal and enter:

.. code:: sh

    tail -f /home/$INSTANCE/log/uwsgi-pypy.log

to follow the file in real time (being able to scroll it back to view previous contents). Or enter

.. code:: sh

    tail -n 200 /home/$INSTANCE/log/uwsgi-pypy.log

to display the latest 200 rows of the file (the value "200" can be edited at your convenience).

Installing more than one instance on a single server could require a great deal of memory, due to the use of PyPy in place of CPython. Problems could arise, and be rather difficult to debug (manifesting themselves as missing packages, where the package is perfectly installed, for instance). In this case, we suggest configuring one instance for server, and only attempt multiple installations on servers with at least 2Gb of physical RAM.

When Vilfredo code is modified, new packages could be required to run the application. We cannot unfortunately execute the ``python setup.py develop`` command inside the virtual environment, due to the use of PyPy, so extra packages will have to be installed manually, as follows:

.. code:: sh

    cd /home/$NAME
    . vilfredo-ve/bin/activate
    pip install [package_name]
    deactivate

If package seems to be already installed, but cannot be imported nevertheless, this could mask an Out of Memory error. Before attempting to debug code or import the package, check this does not occur on other instances, with enough memory.

The ``/home/$INSTANCE/vilfredo-client/static/templates/analytics.template.html`` file could cause JavaScript errors in some Vilfredo versions - in this case, just rename it to ``/home/$INSTANCE/vilfredo-client/static/templates/analytics.template.html.old`` to prevent the webserver from serving it.

=============================
Deleting an existing instance
=============================

If you want to delete a Vilfredo instance together with all of its data, you may download the ``scripts/delinstance`` script right to your server, through ``wget``, and run it:

.. code:: sh

    sudo apt-get install wget
    wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/scripts/delinstance
    chmod 700 delinstance
    ./delinstance

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

(note: this will attempt to install Apache Web Server too, but it will later have to be removed to prevent conflicts with NGINX!).

Open NGINX configuration file for the main domain or another spare domain. You'll find it in

    /etc/nginx/conf.d/[instance_name].conf

or

    /etc/nginx/sites-available/[instance_name]

Then paste the following into a ``server`` block (the part surronded by "server {" and "}"):

.. code-block:: nginx

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
    sudo apt-get install apache2-utils php5-fpm
    sudo htpasswd -c /etc/nginx/htpasswd root
    sudo chown www-data:www-data /etc/nginx/htpasswd
    sudo sed -i 's/user  nginx/user  www-data/g' /etc/nginx/nginx.conf
    sudo chmod 600 /etc/nginx/htpasswd
    # Creates log folder for PHPMyAdmin installation
    sudo mkdir /var/log/nginx/phpmyadmin
    # Enables OpCache to accelerate PHP scripts execution
    sudo sed -i 's/;opcache.enable=0/opcache.enable=1/g' /etc/php5/fpm/php.ini
    sudo sed -i 's/;opcache.save_comments=1/opcache.save_comments=0/g' /etc/php5/fpm/php.ini
    sudo sed -i 's/;opcache.fast_shutdown=0/opcache.fast_shutdown=1/g' /etc/php5/fpm/php.ini
    sudo service php5-fpm restart
    sudo service nginx restart

This PHPMyAdmin installation is protected by an additional HTTP password. The reason is preventing direct access to the login page, because in the past this piece of software exhibited serious security issues.
You might as well prefer IP-based authentication.

Installing a working mail server
================================

A working mail server is required to send email messages to Vilfredo users.

If you already have an account on an existing mail server, you can just specify its credentials during Vilfredo instance creation, when prompted. Or you might create a GMail account, add an alias for the mail sender (provided you actually own that address, hosted somewhere else) and then use that to send mail from Vilfredo instance.

Alternatively, if an external SMTP server with authentication is not available, a local server could be configured instead. Please note that, to avoid messages being marked as spam by recipients, it should support DKIM and SPF, and proper DNS configuration will be additionally needed.

DKIM is a sort of "digital signature" which is added to all email messages to ensure they had been originated by a server in the domain of the sender. A public-private key has to be generated on the server, then a dedicated daemon (for instance OpenDKIM) will take care of generating a digital signature using those keys, adding it to the message headers. The public key must also be added to a TXT record in the domain zone on DNS.

SPF is used to specify the list of IP addresses and servers which are allowed sending messages from a given domain. It does not require generating public-private key pairs. Just add a TXT record in the domain zone on DNS specifying the list of servers and IP addresses.

This part has not been included in the automated installation procedure because a manual part is involved (adding records into the DNS). If you do not feel comfortable setting up a mail server, just create an account on an external mail server and configure Vilfredo to use it to send mail instead.

As always, feel free to replace ``vilfredo.org`` with your mail server domain name.

First of all, install Postfix and OpenDKIM on your server:

.. code:: sh

    sudo apt-get install postfix opendkim opendkim-tools
    sudo wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/scripts/addinstance -O /etc/opendkim.conf
    sudo mkdir /etc/dkim
    # The following line allows the server itself sending digitally signed messages
    sudo echo "localhost [::1]" > /etc/dkim/domains

    # Repeat the following 8 lines for all extra domains you want to configure on the mail server
    # replacing "vilfredo.org" with the name of the mail domain to be added
    sudo echo "vilfredo.org" >> /etc/dkim/domains
    sudo echo "default._domainkey.vilfredo.org  vilfredo.org:default:/etc/dkim/keys/vilfredo.org/default" > /etc/dkim/keytable
    sudo echo "vilfredo.org  default._domainkey.vilfredo.org" > /etc/dkim/signingtable
    sudo mkdir -p /etc/dkim/keys/vilfredo.org
    cd /etc/dkim/keys/vilfredo.org
    sudo opendkim-genkey -r -d vilfredo.org
    sudo mv /etc/dkim/keys/vilfredo.org/default.private /etc/dkim/keys/vilfredo.org/default
    sudo chmod 600 /etc/dkim/keys/vilfredo.org/default

    sudo chown -R opendkim:opendkim /etc/dkim
    sudo chmod -R o-r,o-w,o-x /etc/dkim
    # WARNING: Do not mistype this - do not enter ">" instead of ">>" or you'll erase Postfix configuration!
    sudo wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/postfix-dkim.conf -O /etc/postfix/postfix-dkim.conf
    sudo cat /etc/postfix/postfix-dkim.conf >> /etc/postfix/main.cf
    sudo rm /etc/postfix/postfix-dkim.conf
    sudo sed -i s/#myorigin/myorigin/g /etc/postfix/main.cf
    sudo service opendkim restart
    sudo service postfix restart

Now get the contents of the ``/etc/dkim/keys/vilfredo.org/default.txt`` file (or whatever, depending from the domain name chosen) and copy its contents to the domain zone file in the DNS. To download it, you might enter:

.. code:: sh

    scp root@server:/etc/dkim/keys/vilfredo.org/default.txt .

or use your favourite SFTP client, connecting to root@server, always replacing ``vilfredo.org`` with the domain name and ``server`` with the host name. Then pick up the part between parentheses, strip quotes, spaces and new lines and copy and paste it into the DNS zone for the domain name. For instance:

    ( "v=DKIM1; k=rsa; s=email; "
    "p=MIGfMA0GCSqGSIb3DQE4pk3ITfqcFifEodZJBBgQCw4vP/IB+2e2xM4LsOvM6tye2AQUBB8GNADCBiQKHNCG4E9xyY9OZyd4Orwo5yjyY3f/XPCqHkyxJuW5vAje9kug/DE2OfGrCmZG2evz+2Y66sXK9SVhQijYSAk2+/Z9ysthk7/Un6mGz7gCq3bs2WesKxPEQ/AQva2fAypBvwIDAQAB" )

becomes (this is only an example and does not correspond to any actual valid key):

    v=DKIM1;k=rsa;s=email;p=MIGfMA0GCSqGSIb3DQE4pk3ITfqcFifEodZJBBgQCw4vP/IB+2e6xM4LsOvM8tye2AQUBB8GNADCViQKHNCG4E9xyY9OZyd4Orwo5yjyY2f/XPCqHnyxJuW5vAje9kug/DE2OfGrCmZG2evz+4Y66sXK9SVhQijYSAk1+/Z9ysthk7/Un6mGz7gCq3bs2WesKxPEQ/AQva2fAypBvwIDAQAB

To complete configuration, create a new TXT record for the domain, named ``default._domainkey``, containing this string. If you DNS is externally managed (you do not have access to the configuration files but only to a web-based interface):

- add a new TXT type record
- specify as name ``default._domainkey``
- enter the text above

If you want to send mail from a subdomain (for instance demo.vilfredo.org) do not forget to add the TXT record containing the DKIM key to the subdomain instead of the main domain! So in the example given, the name would become ``default._domainkey.demo.vilfredo.org``.

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
