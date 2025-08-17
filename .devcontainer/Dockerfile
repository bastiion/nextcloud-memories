# Use the official Nextcloud image as the base image
FROM nextcloud:31

# Get the host user ID and group ID to avoid permission issues
ARG USER_ID=1000
ARG GROUP_ID=1000

# Install Node.js 20 and npm
# Also install common development tools
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get install -y sudo git wget make unzip vim ffmpeg && \
    apt-get install -y libimage-exiftool-perl && \
    rm -rf /var/lib/apt/lists/*

# Install PHP Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer  && \
    php -r "unlink('composer-setup.php');"

# Fix user ID mapping for proper permissions
# Handle group conflicts by checking if group ID already exists
RUN set -ex && \
    # Check if group ID already exists and handle it
    EXISTING_GROUP=$(getent group $GROUP_ID | cut -d: -f1 || true) && \
    if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "www-data" ]; then \
    echo "Group ID $GROUP_ID exists as '$EXISTING_GROUP', adding www-data to it"; \
    usermod -a -G $EXISTING_GROUP www-data; \
    usermod -u $USER_ID www-data; \
    else \
    echo "Setting www-data to UID $USER_ID and GID $GROUP_ID"; \
    usermod -u $USER_ID www-data; \
    groupmod -g $GROUP_ID www-data; \
    fi && \
    # Ensure proper ownership
    chown -R www-data:www-data /var/www/html
