FROM php:8.4-fpm

# Установить необходимые зависимости
RUN apt-get update && apt-get install -y \
    curl \
    libpq-dev \
    libzip-dev \
    unzip \
    git \
    nginx \
    postgresql-client \
    supervisor \
    && docker-php-ext-install pdo_pgsql zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Установить зависимости Laravel
WORKDIR /var/www/html
COPY ./laravel /var/www/html

# Установить права доступа
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache && \
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Копировать конфигурацию Nginx
COPY ./nginx.conf /etc/nginx/sites-available/default

# Запуск служб
CMD service nginx start && php-fpm
