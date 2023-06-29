#!/bin/bash

cat << "EOF"
 _____ _            _____            _       _  ______          _           _
|_   _| |          /  ___|          (_)     | | | ___ \        (_)         | |
  | | | |__   ___  \ `--.  ___   ___ _  __ _| | | |_/ / __ ___  _  ___  ___| |_
  | | | '_ \ / _ \  `--. \/ _ \ / __| |/ _` | | |  __/ '__/ _ \| |/ _ \/ __| __|
  | | | | | |  __/ /\__/ / (_) | (__| | (_| | | | |  | | | (_) | |  __/ (__| |_
  \_/ |_| |_|\___| \____/ \___/ \___|_|\__,_|_| \_|  |_|  \___/| |\___|\___|\__|
                                                              _/ |
                                                             |__/
EOF

##### Check if sudo
if [[ "$EUID" -ne 0 ]]
  then echo "Please run as root"
  exit
fi

##### Start script
echo "###########################################################"
echo "This script will install LibreNMS using NGINX webserver, developed for Ubuntu 20.04 LTS"
echo "The script will perform apt install and update commands."
echo "Use at your own risk"
echo "###########################################################"
read -p "Please [Enter] to continue..." ignore

##### Installing Required Packages
apt install -y software-properties-common
add-apt-repository universe
apt update
echo "Upgrading installed packages"
echo "###########################################################"
apt upgrade -y
echo "Installing LibreNMS required packages"
echo "###########################################################"
apt install -y acl curl composer fping git graphviz imagemagick mariadb-client \
mariadb-server mtr-tiny nginx-full nmap php7.4-cli php7.4-curl php7.4-fpm \
php7.4-gd php7.4-json php7.4-mbstring php7.4-mysql php7.4-snmp php7.4-xml \
php7.4-zip rrdtool snmp snmpd whois unzip python3-pymysql python3-dotenv \
python3-redis python3-setuptools

##### Add librenms user
echo "Add librenms user"
echo "###########################################################"
# add user link home directory, do not create home directory
useradd librenms -d /opt/librenms -M -r -s "$(which bash)"

##### Download LibreNMS itself
echo "Downloading libreNMS to /opt/librenms"
echo "###########################################################"
# check if /opt directory exists, if not create it
mkdir -p /opt
cd /opt
git clone https://github.com/librenms/librenms.git
# Set permissions
echo "Setting permissions and file access controls"
echo "###########################################################"
# set owner:group recursively on directory
chown -R librenms:librenms /opt/librenms
# mod permission on directory O=All,G=All, Oth=view
chmod 771 /opt/librenms
# mod default ACL
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
# mod ACL recursively
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/

##### Install PHP dependencies
echo "Install PHP dependencies"
echo "###########################################################"
# run php dependencies installer
su librenms bash -c '/opt/librenms/scripts/composer_wrapper.php install --no-dev'

##### Set system timezone
echo "Setup of system and PHP timezone"
echo "###########################################################"
# Asking for timezome of choice
echo "We have to set the system time zone."
echo "You will get a list of all available time zones"
echo "Use q to quit the list and enter your choice"
read -p "Please [Enter] to continue..." ignore
echo "-----------------------------"
echo " "
timedatectl list-timezones
echo " "
echo "Enter system time zone of choice:"
read TZ
timedatectl set-timezone $TZ
# Set timezone
echo "Setting PHP time zone"
echo "Changing to $TZ"
echo "################################################################################"
# Remove semicolon before date.timezone and set the timezone
sed -i "s/;date.timezone =/date.timezone = $TZ/g" /etc/php/7.4/fpm/php.ini
sed -i "s/;date.timezone =/date.timezone = $TZ/g" /etc/php/7.4/cli/php.ini

##### Configure PHP-FPM
echo "Configure PHP-FPM (FastCGI Process Manager)"
echo "###########################################################"
cp /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/librenms.conf
sed -i 's/^\[www\]/\[librenms\]/' /etc/php/7.4/fpm/pool.d/librenms.conf
sed -i 's/^user = www-data/user = librenms/' /etc/php/7.4/fpm/pool.d/librenms.conf
sed -i 's/^group = www-data/group = librenms/' /etc/php/7.4/fpm/pool.d/librenms.conf
sed -i 's/^listen =.*/listen = \/run\/php-fpm-librenms.sock/' /etc/php/7.4/fpm/pool.d/librenms.conf

##### Configure web server (NGINX)
echo "Configure web server (NGINX)"
echo "###########################################################"
# Create NGINX .conf file
echo "We need to change the sever name to the current IP unless the name is resolvable /etc/nginx/conf.d/librenms.conf"
echo "################################################################################"
echo "Enter nginx server_name [x.x.x.x or serv.examp.com]: "
read HOSTNAME
# Write nginx configuration to file using here document
cat > /etc/nginx/conf.d/librenms.conf << EOF
server {
    listen      80;
    server_name $HOSTNAME;
    root        /opt/librenms/html;
    index       index.php;

    charset utf-8;
    gzip on;
    gzip_types text/css application/javascript text/javascript application/x-javascript image/svg+xml \
    text/plain text/xsd text/xsl text/xml image/x-icon;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ [^/]\.php(/|\$) {
        fastcgi_pass unix:/run/php-fpm-librenms.sock;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        include fastcgi.conf;
    }
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
# remove the default site link
rm /etc/nginx/sites-enabled/default
systemctl restart nginx
systemctl restart php7.4-fpm

##### Enable lnms command completion
echo "Enable lnms command completion"
echo "###########################################################"
ln -s /opt/librenms/lnms /usr/local/bin/lnms
cp /opt/librenms/misc/lnms-completion.bash /etc/bash_completion.d/

##### Configure snmpd
echo "Configure snmpd"
cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf
# Edit the text which says RANDOMSTRINGGOESHERE and set your own community string.
echo "We need to set your default SNMP community string"
echo "Enter community string [e.g.: public ]: "
read ANS
sed -i "s/RANDOMSTRINGGOESHERE/$ANS/g" /etc/snmp/snmpd.conf

# get standard MIBs
curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro
systemctl enable --now snmpd

##### Setup Cron job
echo "Setup LibreNMS Cron job"
echo "###########################################################"
cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms

##### Setup logrotate config
echo "Setup logrotate config"
echo "###########################################################"
cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

#### Common fixes
echo "Perform common fixes in order to help pass LibreNMS validation"
echo "###########################################################"
# create default custom config.php in case the user needs it
cp /opt/librenms/config.php.default /opt/librenms/config.php
# set default LibreNMS permissions which cause most errors
sudo chown -R librenms:librenms /opt/librenms
sudo setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
sudo chmod -R ug=rwX /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
echo "Select yes to the following or you might get a warning during validation"
echo "------------------------------------------------------------------------"
# Remove github leftovers
sudo su librenms bash -c '/opt/librenms/scripts/github-remove -d'

##### End of installation, continue in web browser
echo "###############################################################################################"
echo "Navigate to http://$HOSTNAME/install.php in your web browser to finish the installation."
echo "###############################################################################################"
