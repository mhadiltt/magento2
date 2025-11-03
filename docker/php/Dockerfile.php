# Dockerfile
FROM php:8.2-fpm

# system deps
RUN apt-get update && apt-get install -y \
    git unzip libonig-dev libxml2-dev libpng-dev libzip-dev libicu-dev libfreetype6-dev libjpeg-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# php extensions
RUN docker-php-ext-install pdo_mysql mbstring intl pdo xml zip bcmath gd opcache

# composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# workdir
WORKDIR /var/www/html

# copy composer files and install dependencies (use cache)
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader

# copy rest of app
COPY . ./

# set permissions for runtime (adjust in k8s to use proper user)
RUN chown -R www-data:www-data /var/www/html \
    && find var pub/static pub/media generated -type d -exec chmod 775 {} \; \
    && find var pub/static pub/media generated -type f -exec chmod 664 {} \;

EXPOSE 9000
CMD ["php-fpm"]
