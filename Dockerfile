FROM alpine:latest as builder

RUN apk --no-cache add \
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

WORKDIR /opt/laravel

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY  laravel/ /opt/laravel

RUN  composer install --no-interaction --no-scripts

RUN npm install && npm run build


FROM alpine:latest

RUN apk --no-cache add \
    nginx \
    supervisor \
    postgresql-client \
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

WORKDIR /opt/laravel

COPY conf.d/nginx/default.conf /etc/nginx/nginx.conf
COPY conf.d/php-fpm/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY conf.d/php/php.ini /usr/local/etc/php/conf.d/php.ini
COPY conf.d/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

COPY conf.d/supervisor/supervisord.conf /etc/supervisord.conf

COPY --from=builder /opt/laravel /opt/laravel

RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1
  
RUN chown -R www-data:www-data /opt/laravel \
    && chmod -R 775 /opt/laravel/storage && \
    chown -R www-data:www-data /opt/laravel/storage && \
    chown -R www-data:www-data /var/log && \
    chmod -R 777 /var/log && \
    chmod 777 /var/run && \
    chown www-data:www-data /var/run 

RUN touch /var/log/cron.log

RUN echo "* * * * * /usr/local/bin/php /opt/laravel/artisan schedule:run >> /var/log/cron.log 2>&1" | crontab -

EXPOSE 80

COPY entrypoint.sh /root/entrypoint.sh

RUN chmod +x /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]
