#!/bin/bash
##########################################################################
# Vilfredo easy installation script
# Developed by Pietro Speroni di Fenizio
# version 1.3
# 10/05/2016, 11/05/2016, 14/05/2016, 15/05/2016, 16/05/2016, 17/05/2016
# Released under Affero General Public License
##########################################################################

POSSIBLENAMES=`ls /home`

NAME=$(dialog --backtitle 'Vilfredo new instance installation' --inputbox 'Please enter the name of the instance present.'  8 70 $POSSIBLENAMES --output-fd 1)
 case $? in
   1)
     # "Cancel" has been selected
     exit;;
   255)
     # The ESC key has been pressed
     exit;;
 esac


POSSIBLEDOMAINNAMES=`ls /etc/letsencrypt/live`

OLDDOMAIN=$(dialog --backtitle 'Vilfredo new instance installation' --inputbox 'Please enter the name of the OLD domain to be substituted' 8 70 $POSSIBLEDOMAINNAMES --output-fd 1)
  case $? in
    1)
      # "Cancel" has been selected
      exit;;
    255)
      # The ESC key has been pressed
      exit;;
  esac



NEWDOMAIN=$(dialog --backtitle 'Vilfredo new instance installation' --inputbox 'Please enter the name of the NEW DOMAIN to be addes' 8 70  --output-fd 1)
    case $? in
      1)
        # "Cancel" has been selected
        exit;;
      255)
        # The ESC key has been pressed
        exit;;
    esac


sed -i s/$OLDDOMAIN/$NEWDOMAIN/g /etc/$NAME/settings.js 
sed -i s/$OLDDOMAIN/$NEWDOMAIN/g /etc/$NAME/settings.cfg 
sed -i s/'server_name '$OLDDOMAIN/'server_name '$NEWDOMAIN/g /etc/nginx/conf.d/$NAME.conf 

sudo fuser -k 80/tcp
sudo service nginx restart
rm -r /etc/letsencrypt/
sudo /usr/local/letsencrypt/letsencrypt-auto certonly --webroot -w /home/$NAME/vilfredo-client/static -d $NEWDOMAIN
sed -i s/$OLDDOMAIN/$NEWDOMAIN/g /etc/nginx/conf.d/$NAME.conf 
sudo service nginx restart