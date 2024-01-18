#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Install required dependencies
apt update
apt install -y git-core build-essential libssl-dev libcurl4-openssl-dev zlib1g-dev

# Download cgit source code
git clone https://git.zx2c4.com/cgit

# Change to the cgit directory
cd cgit

# Compile and install cgit
make
make install

# Clean up
cd ..
rm -rf cgit

# Create a basic cgit configuration
cat <<EOF > /etc/cgitrc
css=/cgit.css
logo=/cgit.png
enable-index-links=1
enable-log-filecount=1
EOF

# Restart cgit to apply the changes
systemctl restart cgit

echo "cgit has been installed and configured successfully."