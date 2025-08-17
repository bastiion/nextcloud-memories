#!/bin/bash

echo "Setting up Memories development environment..."


# Fix permissions
chown -R www-data:www-data /var/www/html/custom_apps

# Configure Memories for system ExifTool
sudo -u www-data php /var/www/html/occ config:system:set memories.exiftool --value="/usr/bin/exiftool"
sudo -u www-data php /var/www/html/occ config:system:set memories.exiftool_no_local --value=false --type=boolean

# Fix temp directory permissions
chmod 777 /tmp

echo 'Memories development environment ready!'
