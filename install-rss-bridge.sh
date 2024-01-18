#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Install required dependencies
apt update
apt install -y curl unzip nginx certbot php-fpm php-mysql php-cli php7.4-mbstring php7.4-curl php7.4-xml php7.4-sqlite3 php7.4-json

# Clone RSS-Bridge repository
mkdir -p /var/www/rss-bridge
cd /var/www/rss-bridge
wget https://github.com/RSS-Bridge/rss-bridge/archive/refs/tags/2021-04-25.zip
unzip 2021-04-25.zip
mv rss-bridge-2021-04-25/* .
rm -rf rss-bridge-2021-04-25 2021-04-25.zip

# Set correct permissions
chown -R www-data:www-data /var/www/rss-bridge

# Add nginx config file
cat <<EOF > /etc/nginx/sites-available/rss-bridge
server {
    root /var/www/rss-bridge;
    index index.php index.html index.htm index.nginx-debian.html;
    server_name rss-bridge.example.org;

    location / {
            try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }

    location ~ /\.ht {
            deny all;
    }
}
EOF

# Create a symbolic link to enable the Nginx configuration
ln -s /etc/nginx/sites-available/rss-bridge /etc/nginx/sites-enabled/rss-bridge


echo "RSS-Bridge has been installed successfully."
echo "You can use the 'rss-bridge' command to start the service."