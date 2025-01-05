#!/bin/bash

set -e

# Disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm /etc/resolv.conf

# Set DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

# Update package list
sudo apt-get update

# Install necessary packages
sudo apt-get install -y \
    docker.io \
    net-tools

# Add vagrant user to docker group and apply immediately
sudo usermod -aG docker vagrant && newgrp docker

# Verify docker is installed
docker --version

# Docker Compose install
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Test docker-compose (Important!)
docker-compose version

# Project Setup
sudo mkdir -p /srv/www

# cp -r /vagrant/* /srv/www  # Alternative:  Use this if you're sure vagrant is in the project directory.  Then you would use "sudo dos2unix *" below the cd /srv/www command
cd /srv/www

# Correct file extensions
find . -name "*.txt" -exec sh -c 'mv "$1" "${1%.txt}"' _ {} \;

# Use dos2unix if possible, fall back to sed
if ! sudo apt-get install -y dos2unix > /dev/null 2>&1; then
    echo "dos2unix installation failed. Falling back to sed..."
    find . -type f \( -name "*.sh" -o -name "*.yml" -o -name "Dockerfile.*" \) -exec sed -i 's/\r$//' {} \;
else
    echo "Converting line endings with dos2unix..."
    sudo find . -type f \( -name "*.sh" -o -name "*.yml" -o -name "Dockerfile.*" \) -exec dos2unix {} \;
fi

# Ensure necessary config files exist
for file in configs/dhcp.conf configs/rndc.key configs/httpd.conf; do
    if [ ! -f $file ]; then
        echo "Error: $file not found!"
        exit 1
    fi
done

docker-compose up -d