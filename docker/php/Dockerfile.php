# ========================
# PHP-FPM Stage for Magento
# ========================
FROM php:8.1-fpm

# Install required system dependencies
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

# Copy composer and install dependencies
COPY composer.json composer.lock ./
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Install Magento dependencies
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader

# Copy the rest of the Magento files
COPY . .

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
