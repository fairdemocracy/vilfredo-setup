#!/bin/bash
cat <<EOF
Installs a local environment for development only.
Will create a folder in current directory named "vilfredo-dev".
A previous folder having the same name, if existing, will be deleted.
This MUST not be used in production (passwords are identical for all installations!)
Successfully tested on Ubuntu Desktop 14.04.
Requires root privileges to install packages.
Developed by massimiliano.alessandri@gmail.com
Press ENTER to continue or CTRL+C to stop
EOF
read
#################################################################################
# Install required packages (some of them could be already present on the system)
#################################################################################
sudo apt-get update
sudo apt-get install python-virtualenv python-dev python-pkginfo-doc python-nose libmysqlclient-dev graphviz git gcc sudo mysql-server libjansson4 libmatheval1 libyaml-0-2 libzmq3 uuid-dev libcap-dev libssl-dev libssl-doc libpcre3-dev libpcrecpp0
######################
# Install the database
######################
wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/database.sql
sudo service mysql start
echo "Please enter your local MySQL server root password"
mysql -u root -p -e "DROP DATABASE IF EXISTS vilfredo;CREATE DATABASE vilfredo;USE vilfredo;SET NAMES UTF8;SOURCE database.sql;GRANT USAGE ON *.* TO vilfredo@localhost IDENTIFIED BY 'vilfredo_dev_password';GRANT SELECT, INSERT, UPDATE, DELETE ON vilfredo.* TO vilfredo@localhost"
rm database.sql
####################################
# Download and configure application
####################################
rm -rf vilfredo-dev
mkdir vilfredo-dev
cd vilfredo-dev
git clone -b develop https://github.com/fairdemocracy/vilfredo-core.git
git clone -b develop https://github.com/fairdemocracy/vilfredo-client.git
replace Flask-CDN==1.2.0 Flask-CDN==1.2.1 -- vilfredo-core/requirements/base.txt
virtualenv vilfredo-ve
. vilfredo-ve/bin/activate
cd vilfredo-core
pip install -U setuptools
pip install itsdangerous==0.23
pip install argparse==1.2.1
pip install alembic==0.7.4
pip install Flask-Script==0.6.7
pip install Flask-Migrate==1.3.0
pip install Pillow==2.8.1
pip install requests==2.7.0
pip install ipython==4.0.0
pip install Flask==0.10
pip install Flask-Mail==0.8.2
pip install Flask-Babel==0.8
pip install Flask-Login==0.2.6
pip install SQLAlchemy==0.8.2
pip install Flask-SQLAlchemy==1.0
pip install Flask-CDN==1.2.1
pip install flask-util-js==0.2.19
pip install MySQL-python==1.2.5
pip install pyparsing==1.5.7
pip install pydot==1.0.2
python setup.py develop
cd ..
. vilfredo-ve/bin/deactivate
cd vilfredo-core/VilfredoReloadedCore
wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/settings.cfg
ln -sf ../../vilfredo-client/static .
ln -sf ../../vilfredo-client/templates .
replace /home/vilfredo . -- settings.cfg
replace www.vilfredo.org localhost:8000 -- settings.cfg
replace https https -- settings.cfg
replace vilfredo_mysql_password vilfredo_dev_password -- settings.cfg
replace secret_key vilfredo_dev_secret -- settings.cfg
replace vilfredo_salt vilfredo_dev_salt -- settings.cfg
replace www.vilfredo.org localhost:8000 -- ../../vilfredo-client/static/js/settings.js
replace 127.0.0.1:8080 localhost:8000 -- ../../vilfredo-client/static/js/settings.js
replace https http -- ../../vilfredo-client/static/js/settings.js
replace /var/log/vilfredo/vilfredo-vr.log vilfredo.log -- logging_debug.conf
cat > start.py <<EOF
from VilfredoReloadedCore import app
if __name__ == "__main__":
    app.run(host='127.0.0.1', port=8000)
EOF
cd ../../..

cat <<EOF
Vilfredo download and configuration completed.
To run development environment, enter:
cd vilfredo-dev
. vilfredo-ve/bin/activate
python vilfredo-core/VilfredoReloadedCore/start.py
To test Vilfredo, go to http://127.0.0.1:8000
If you did not configure an external mail server,
to activate user after registering, check contents
of the "verify_email" table, get the token and go to
http://localhost:8000/activate?u=[ID]&t=[TOKEN]
replacing ID with user id and TOKEN with token field.
EOF
