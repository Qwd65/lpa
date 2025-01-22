#!/bin/sh

# Set the base directory for the app
BASEDIR=/opt/laravel

# Flag to check if it's a fresh install
FIRST_INSTALL=false

# Check if the .env file exists
if [ ! -f "$BASEDIR/.env" ]; then
   FIRST_INSTALL=true
fi

# Use FIRST_INSTALL variable as needed in the rest of your script
if [ "$FIRST_INSTALL" = true ]; then
    echo "This is a FRESH INSTALL."

    # Determine the appropriate environment file based on the PRODUCTION variable
    if [ "$PRODUCTION" = "1" ]; then
        ENV_FILE=".env.production"
    else
        ENV_FILE=".env.example"
    fi

    # Copy the chosen environment file to create the .env file
    echo "Generating .env from a copy $ENV_FILE ..."
    cp $ENV_FILE .env
    echo "File .env generated."
fi

# Clear the old boostrap/cache
php artisan clear-compiled

# Install composer dependencies
if [ "$PRODUCTION" = "1" ]; then
    composer install --no-dev --no-interaction --no-scripts
else
    composer install --no-interaction --no-scripts
fi


echo "Installing npm dependencies..."
npm install

# Build frontend assets
echo "Building frontend assets..."
npm run build

echo "Generating app key..."
# Generate an application key
php artisan key:generate --force
echo "App key generated."

# Clear the optimization cache
php artisan optimize:clear

# Remove prior storage links that exist
rm -rf public/storage

# Build up a new storage link
php artisan storage:link

# Set permissions
echo "Setting file permissions..."
chown -R www-data:www-data /opt/laravel
chmod -R 755 /opt/laravel/storage


# Wait for the database to be ready (PostgreSQL in this case)
echo "Waiting for the database to be ready..."
until pg_isready -h db -p 5432 -U user; do
    echo 'Waiting for database...';
    sleep 2;
done

# Run database migrations
echo "Running migrations..."
php artisan migrate --force

# Run tests
echo "Running tests..."
php artisan test



# Check if running in production or development mode
if [ "$PRODUCTION" = "1" ]; then
    echo "Running in production mode"
else
    echo "Running in development mode"
fi

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisord.conf
