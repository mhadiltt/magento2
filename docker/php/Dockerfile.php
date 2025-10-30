# Use PHP 8.2 (Magento 2.4.7+ requires >=8.2)
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev libzip-dev libicu-dev libxml2-dev libonig-dev unzip git zip vim curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install bcmath gd intl pdo_mysql soap xml zip opcache

# Install Composer globally
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy Magento source code
COPY . .

# Install Magento dependencies
RUN composer install --no-dev --optimize-autoloader

# Set permissions for Magento directories
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

CMD ["php-fpm"]
