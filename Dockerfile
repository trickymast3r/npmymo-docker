FROM trickymast3r/ubuntu:14.04.4
MAINTAINER Tricky <tricky@gvr.vn>

# Enable PHP 5.6 repo and update apt-get
RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php
RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:nginx/stable
RUN apt-get update

# Update dependencies ready
RUN apt-get upgrade -y

# Install NGINX and PHP5.6-FPM
RUN apt-get install -y nginx
RUN apt-get install -yq --no-install-suggests --no-install-recommends --force-yes php5.6-fpm \
    php5.6-cli \
    php5.6-common \
    php5.6-curl \
    php5.6-gd \
    php5.6-gettext \
    php5.6-imagick \
    php5.6-imap \
    php5.6-intl \
    php5.6-json \
    php5.6-mbstring \
    php5.6-memcached \
    php5.6-memcache \
    php5.6-mcrypt \
    php5.6-mongo \
    php5.6-mongodb \
    php5.6-mysql \
    php-pear \
    php5.6-redis \
    php5.6-xmlrpc \
    php5.6-xsl \
    php5.6-zip \
    libcurl4-openssl-dev \
    libevent-dev \
    libxml2-dev \
    libssh2-1-dev \
    libxml2 \
    libc-dev \
    libjpeg-dev \
    libpng12-dev \
    libfreetype6-dev \
    libmcrypt-dev \
    libtidy-dev \
    libxslt1-dev \
    libyaml-dev \
    libfreetype6-dev \
    libxpm-dev \
    libvpx-dev
# Update Channel PECL
RUN pecl channel-update pecl.php.net

# Add installers
ADD scripts/*.sh /scripts/

# Install ext-ssh2
RUN printf "\n" | pecl install -a ssh2-0.12 && \
    echo 'extension=ssh2.so' | tee /etc/php/5.6/mods-available/ssh2.ini && \
    ln -s /etc/php/5.6/mods-available/ssh2.ini /etc/php/5.6/cli/conf.d/20-ssh2.ini

# Install ext-yaml
RUN printf "\n" | pecl install yaml && \
    echo 'extension=yaml.so' | tee /etc/php/5.6/mods-available/yaml.ini && \
    ln -s /etc/php/5.6/mods-available/yaml.ini /etc/php/5.6/cli/conf.d/20-yaml.ini

# Install ext-libsodium
RUN printf "\n" | pecl install -a libsodium && \
    echo 'extension=libsodium.so' | tee /etc/php/5.6/mods-available/libsodium.ini && \
    ln -s /etc/php/5.6/mods-available/libsodium.ini /etc/php/5.6/cli/conf.d/20-libsodium.ini

# Install ext-msgpack
RUN printf "\n" | pecl install -a msgpack-0.5.7 && \
    echo 'extension=msgpack.so' | tee /etc/php/5.6/mods-available/msgpack.ini && \
    ln -sf /etc/php/5.6/mods-available/msgpack.ini /etc/php/5.6/cli/conf.d/20-msgpack.ini

# Install ext-xdebug
RUN pecl install xdebug && \
    echo '[Xdebug]' >  /etc/php/5.6/mods-available/xdebug.ini && \
    echo 'zend_extension = /usr/lib/php/20131226/xdebug.so' >> /etc/php/5.6/mods-available/xdebug.ini && \
    echo "xdebug.remote_enable = 1" >> /etc/php/5.6/mods-available/xdebug.ini && \
    echo "xdebug.remote_host = 0.0.0.0" >> /etc/php/5.6/mods-available/xdebug.ini && \
    echo "xdebug.remote_port = 9001" >> /etc/php/5.6/mods-available/xdebug.ini && \
    echo 'xdebug.remote_handler = "dbgp"' >> /etc/php/5.6/mods-available/xdebug.ini && \
    echo "xdebug.remote_connect_back = 1" >> /etc/php/5.6/mods-available/xdebug.ini && \
    echo "xdebug.cli_color = 1" >> /etc/php/5.6/mods-available/xdebug.ini && \
    echo 'xdebug.idekey = "PHPSTORM"' >> /etc/php/5.6/mods-available/xdebug.ini && \
    ln -sf /etc/php/5.6/mods-available/xdebug.ini /etc/php/5.6/cli/conf.d/20-xdebug.ini

# Fix PHP warnings
RUN find /etc/php/5.6/mods-available/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Tune up PHP FPM
RUN sed -i -e "s|;catch_workers_output\s*=.*|catch_workers_output = yes|g" /etc/php/5.6/fpm/pool.d/www.conf && \
    sed -i -e "s|^pm.max_children =.*|pm.max_children = 9|g" /etc/php/5.6/fpm/pool.d/www.conf && \
    sed -i -e "s|^pm.start_servers =.*|pm.start_servers = 3|g" /etc/php/5.6/fpm/pool.d/www.conf && \
    sed -i -e "s|^pm.min_spare_servers =.*|pm.min_spare_servers = 2|g" /etc/php/5.6/fpm/pool.d/www.conf && \
    sed -i -e "s|^pm.max_spare_servers =.*|pm.max_spare_servers = 4|g" /etc/php/5.6/fpm/pool.d/www.conf && \
    sed -i -e "s|;pm.max_requests =.*|pm.max_requests = 200|g" /etc/php/5.6/fpm/pool.d/www.conf && \
    sed -i -e "s|;security.limit_extensions =.*|security.limit_extensions = .php|g" /etc/php/5.6/fpm/pool.d/www.conf

# Tune up PHP
RUN TIMEZONE=`cat /etc/timezone`; sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/5.6/fpm/php.ini && \
    sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/5.6/fpm/php.ini && \
    sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/5.6/fpm/php.ini && \
    sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/5.6/fpm/php.ini && \
    sed -i "s|post_max_size =.*|max_file_uploads = ${PHP_MAX_POST}|" /etc/php/5.6/fpm/php.ini && \
    sed -i 's|short_open_tag =.*|short_open_tag = On|' /etc/php/5.6/fpm/php.ini && \
    sed -i 's|error_reporting =.*|error_reporting = -1|' /etc/php/5.6/fpm/php.ini && \
    sed -i 's|display_errors =.*|display_errors = On|' /etc/php/5.6/fpm/php.ini && \
    sed -i 's|display_startup_errors =.*|display_startup_errors = On|' /etc/php/5.6/fpm/php.ini && \
    sed -i -re 's|^(;?)(session.save_path) =.*|\2 = "/tmp"|g' /etc/php/5.6/fpm/php.ini

RUN sed -i -e "s|;listen.mode =.*|listen.mode = 0750|g" /etc/php/5.6/fpm/pool.d/www.conf && \
    sed -i -e 's|^listen =.*|listen = 0.0.0.0:9000|g' /etc/php/5.6/fpm/pool.d/www.conf && \
    sed -i -e 's|^listen.allowed_clients|;listen.allowed_clients|g' /etc/php/5.6/fpm/pool.d/www.conf

RUN phpenmod -s fpm phalcon xdebug

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stderr /var/log/php5.6-fpm.log

# Cleanup package manager
RUN apt-get autoremove && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/php5 /etc/php/5.5 /etc/php/7.0 /usr/lib/php/7.0 /usr/lib/php/20121212 /usr/lib/php/20151012

# Expose the container port 80 & 443
EXPOSE 80
EXPOSE 443

# Run the services
CMD service php5.6-fpm start && nginx


# Expose volumes
VOLUME ["/var/www/html/"]
