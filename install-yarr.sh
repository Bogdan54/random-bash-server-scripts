#!/bin/bash

# Yarr installation script for Debian

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or using sudo."
    exit 1
fi

# Prompt for domain name, username, and password
read -p "Enter the domain name for nginx configuration (e.g., rss.example.org): " DOMAIN_NAME
read -p "Enter the username for Yarr authentication: " USERNAME
read -p "Enter the password for Yarr authentication: " PASSWORD

# Update package list
apt update

# Install dependencies
apt install -y git npm unzip

# Get yarr
wget https://github.com/nkanaev/yarr/releases/download/v2.3/yarr-v2.3-linux64.zip

# Unzip the archive and move the folder
unzip -x yarr-v2.3-linux64.zip
mv yarr /usr/local/bin/yarr

# Make the user
mkdir ~/.config/yarr
echo "$USERNAME:$PASSWORD" > ~/.config/yarr/auth.conf

# Set up a systemd service
cat <<EOF > /etc/systemd/system/yarr.service
[Unit]
Description=Yarr

[Service]
Environment=HOME=/home/$USERNAME
ExecStart=/usr/bin/env yarr -addr 0.0.0.0:7070 -auth-file=/home/$USERNAME/.config/yarr/auth.conf -db=/home/$USERNAME/.config/yarr/feed.sql -log-file=/home/$USERNAME/.config/yarr/access.log
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the Yarr service
systemctl daemon-reload
systemctl enable --now yarr

# Add nginx config file
cat <<EOF > /etc/nginx/sites-available/yarr
server {
	listen 80 ;
	listen [::]:80 ;

	server_name rss.$DOMAIN_NAME ;

	location / {
		proxy_pass http://localhost:7070/;
	}
}
EOF

# Create a symbolic link to enable the site
ln -s /etc/nginx/sites-available/yarr /etc/nginx/sites-enabled/

# Reload Nginx to apply changes
systemctl reload nginx

echo "Yarr has been installed and started. You can access it at http://your-server-ip."