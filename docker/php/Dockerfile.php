# =========================================
# PHP-FPM image for Magento 2.4.6 (PHP 8.2)
# =========================================
FROM php:8.2-fpm

# Install required system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libicu-dev \
    libssl-dev \
    libmcrypt-dev \
    libreadline-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        bcmath \
        gd \
        intl \
        pdo_mysql \
        soap \
        sockets \
        xsl \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Copy composer files first (for caching)
COPY composer.json composer.lock ./

# Install Magento dependencies (ignore minor platform warnings)
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader

# Copy the rest of the application code
COPY . .

# Set proper file permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 9000

CMD ["php-fpm"]
