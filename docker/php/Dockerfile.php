# ---- PHP build stage ----
FROM php:8.2-fpm

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libxml2-dev \
    libxslt-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libonig-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libedit-dev \
    libreadline-dev \
    libsqlite3-dev \
    libxslt1.1 \
    && docker-php-ext-install \
        bcmath \
        gd \
        intl \
        opcache \
        pdo_mysql \
        soap \
        sockets \
        ftp \
        xsl \
        zip \
    && docker-php-ext-enable \
        bcmath gd intl opcache pdo_mysql soap sockets ftp xsl zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY . .

# Allow git access for composer
RUN git config --global --add safe.directory /var/www/html

# Install dependencies (production mode)
RUN composer install --no-dev --optimize-autoloader

# Set permissions
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# ✅ FIX: Create PHP-FPM runtime dir and run in foreground
RUN mkdir -p /run/php && chown -R www-data:www-data /run/php

EXPOSE 9000

# ✅ Permanent fix — PHP-FPM must run in foreground mode
CMD ["php-fpm", "-F"]
