#!/bin/sh

BASEDIR=/opt/laravel

echo "Waiting for the database to be ready..."
until pg_isready -h db -p 5432 -U user; do
    echo 'Waiting for database...';
    sleep 2;
done

php artisan migrate --force


php artisan clear-compiled


php artisan key:generate --force


php artisan optimize:clear

rm -rf public/storage

php artisan storage:link

chown -R www-data:www-data /opt/laravel
chmod -R 755 /opt/laravel/storage
chmod -R 777 /opt/laravel/storage/framework/views/


php artisan migrate --force

php artisan test


exec /usr/bin/supervisord -c /etc/supervisord.conf
