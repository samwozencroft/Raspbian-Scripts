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

# Cleaning up snmp
apt purge snmpd -y

# Check if SNMP is already installed
if ! dpkg -s snmp &>/dev/null; then
    echo "SNMP is not installed. Installing SNMP..."
    apt update
    apt install snmp -y
    apt install snmpd -y
fi

# Check if curl command is available
if ! command -v curl >/dev/null 2>&1; then
    echo "curl command not found. Installing curl..."
    apt install curl -y
fi

# Install LibreNMS agent components
curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro

# Backup the original SNMP configuration files
cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak
cp /etc/snmp/snmp.conf /etc/snmp/snmp.conf.bak

# Comment out the agentAddress line in snmp.conf
sudo sed -i 's/^agentAddress/# agentAddress/' /etc/snmp/snmp.conf

# Comment out the agentaddress line in snmpd.conf
sudo sed -i 's/^agentaddress/# agentaddress/' /etc/snmp/snmpd.conf

# Prompt for SNMP version
read -p "Enter the SNMP version (2 or 3): " snmp_version

if [ "$snmp_version" = "2" ]; then
    # Prompt for the SNMPv2 string
    read -p "Enter the SNMPv2 string for read-only access: " snmpv2_string

    # Configure SNMPv2 string in the SNMP configuration file
    echo "rocommunity $snmpv2_string" | tee -a /etc/snmp/snmpd.conf >/dev/null
elif [ "$snmp_version" = "3" ]; then
    # Prompt for SNMPv3 credentials
    read -p "Enter the SNMPv3 login: " snmpv3_login
    read -sp "Enter the SNMPv3 password: " snmpv3_password
    echo

    # Configure SNMPv3 user in the SNMP configuration file
    echo "createUser $snmpv3_login SHA \"$snmpv3_password\" AES" >> /etc/snmp/snmpd.conf
    echo "rouser $snmpv3_login priv" >> /etc/snmp/snmpd.conf
else
    echo "Invalid SNMP version. Please choose either 2 or 3."
    exit 1
fi

# Restart SNMP service
systemctl enable snmpd
systemctl restart snmpd

# Wait for SNMP service to start
sleep 2

# Check if agentaddress is properly commented out in snmpd.conf
if grep -qE '^agentaddress\s*#' /etc/snmp/snmpd.conf; then
    echo "agentaddress is commented out in snmpd.conf."
else
    echo "agentaddress is not commented out in snmpd.conf. Commenting it out..."
    sudo sed -i 's/^agentaddress/# agentaddress/' /etc/snmp/snmpd.conf
    systemctl restart snmpd
    sleep 2
    if grep -qE '^agentaddress\s*#' /etc/snmp/snmpd.conf; then
        echo "agentaddress has been successfully commented out in snmpd.conf."
    else
        echo "Failed to comment out agentaddress in snmpd.conf."
    fi
fi

# Test SNMP access
echo "Testing SNMP access..."

if [ "$snmp_version" = "2" ]; then
    snmpwalk -v 2c -c "$snmpv2_string" 127.0.0.1
elif [ "$snmp_version" = "3" ]; then
    snmpwalk -v 3 -u "$snmpv3_login" -l authPriv -a SHA -A "$snmpv3_password" -x AES 127.0.0.1
fi

if [ $? -eq 0 ]; then
    echo "LibreNMS agent setup complete."
else
    echo "LibreNMS agent setup failed. Please check your SNMP configuration."
fi
