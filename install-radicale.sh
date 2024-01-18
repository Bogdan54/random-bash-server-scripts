#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Install Radicale and its dependencies
apt update
apt install -y radicale

# Get user credentials
read -p "Enter Radicale username: " radicale_user
read -s -p "Enter Radicale password: " radicale_password
echo

# Create a basic Radicale configuration file
cat <<EOF > /etc/radicale/config
[server]
hosts = 0.0.0.0:5232

[encoding]
request = utf-8
stock = utf-8

[storage]
filesystem_folder = /var/lib/radicale/collections

[auth]
type = htpasswd
htpasswd_filename = /etc/radicale/users
EOF

# Create the user with the provided credentials
htpasswd -b -c /etc/radicale/users "$radicale_user" "$radicale_password"

# Create necessary directories
mkdir -p /var/lib/radicale/collections
chown -R radicale:radicale /var/lib/radicale

# Restart Radicale to apply the changes
systemctl restart radicale

echo "Radicale has been installed and configured successfully."
echo "You can now access Radicale at http://your-server-address:5232"