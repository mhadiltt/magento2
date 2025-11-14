# ==============================================
# PHP-FPM 8.2 for Magento 2.4.6 (Stable Build)
# ==============================================
FROM php:8.2-fpm

# Install OS dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libonig-dev \
    libssl-dev \
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

# ----------------------------------------------
# Install Composer (Safe & Permanent Method)
# ----------------------------------------------
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files first (cache layer)
COPY composer.json composer.lock ./

# Magento repo auth (you can replace your keys)
RUN composer config --global http-basic.repo.magento.com \
    YOUR_PUBLIC_KEY_HERE \
    YOUR_PRIVATE_KEY_HERE

# Install Magento dependencies
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Copy full source code
COPY . .

# Fix permissions (very important for var/pub/generated)
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 777 var pub generated

EXPOSE 9000

CMD ["php-fpm"]
