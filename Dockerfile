FROM alpine:latest

# Установим необходимые зависимости и PHP
RUN apk --no-cache add \
    bash \
    nginx \
    supervisor \
    postgresql-client \
    postgresql-dev \
    nodejs \
    npm \
    php \
    php-fpm \
    php-pdo \
    php-pdo_pgsql \
    php-opcache \
    php-phar \
    php-mbstring \
    php-json \
    php-curl \
    php-dom \
    php-tokenizer \
    php-fileinfo \
    php-openssl \
    php-xml \
    php-session \
    php-simplexml \
    php-xmlwriter \
    curl 

RUN if [ ! -e /usr/bin/php ]; then ln -s /usr/bin/php83 /usr/bin/php; fi
# Set working directory
WORKDIR /opt/laravel


# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy Nginx configuration
COPY conf.d/nginx/default.conf /etc/nginx/nginx.conf

# Copy PHP configuration
COPY conf.d/php-fpm/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

COPY conf.d/php/php.ini /usr/local/etc/php/conf.d/php.ini

COPY conf.d/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Copy Supervisor configuration
COPY conf.d/supervisor/supervisord.conf /etc/supervisord.conf

# Copy Laravel application files
COPY  laravel/ /opt/laravel

RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1
# Set up permissions
RUN chown -R www-data:www-data /opt/laravel \
    && chmod -R 775 /opt/laravel/storage && \
    chown -R www-data:www-data /opt/laravel/storage 


# Scheduler setup

# Create a log file
RUN touch /var/log/cron.log

# Add cron job directly to crontab
RUN echo "* * * * * /usr/local/bin/php /opt/laravel/artisan schedule:run >> /var/log/cron.log 2>&1" | crontab -

# Expose ports
EXPOSE 80

ADD entrypoint.sh /root/entrypoint.sh

RUN chmod +x /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]
