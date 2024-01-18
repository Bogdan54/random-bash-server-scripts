#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Verify if Nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Please install Nginx before running this script."
    exit 1
fi

# Get the domain name from the user
read -p "Enter your Calibre domain (e.g., calibre.example.org): " calibre_domain

# Install Calibre and its dependencies
apt update
apt install -y calibre

# Create a directory for the Calibre library
calibre_library="/opt/calibre/Library"
mkdir -p "$calibre_library"

# Add an example EPUB book to the Calibre library
calibredb add book.epub --with-library "$calibre_library"

# Start the Calibre server with the specified library path
calibre-server --with-library "$calibre_library" --port 8080 &

# Create a Nginx configuration file
cat <<EOF > /etc/nginx/sites-available/calibre
server {
    listen 80;
    client_max_body_size 64M; # to upload large books
    server_name $calibre_domain;

    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}
EOF

# Create a symbolic link to enable the Nginx configuration
ln -s /etc/nginx/sites-available/calibre /etc/nginx/sites-enabled/

# Test the Nginx configuration
nginx -t

# Restart Nginx to apply the changes
systemctl restart nginx

# Create a Calibre user using calibre-server --manage-users
echo "Creating a Calibre user. Please follow the prompts."
calibre-server --manage-users

# Create a systemd service unit file
cat <<EOF > /etc/systemd/system/calibre-server.service
[Unit]
Description=Calibre library server
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/calibre-server --enable-auth --enable-local-write "$calibre_library" --listen-on 127.0.0.1

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to pick up the new unit file
systemctl daemon-reload

# Enable and start the Calibre server service
systemctl enable calibre-server
systemctl start calibre-server

echo "Calibre server is running. You can access it at http://$calibre_domain."
echo "The library named 'Library' has been created at '$calibre_library'."
echo "An example EPUB book has been added to the library."
echo "A Calibre user has been created."