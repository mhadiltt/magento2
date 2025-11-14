FROM php:8.2-fpm

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

WORKDIR /var/www/html

# ✔ WORKING - Install Composer without using composer:2 image
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

COPY composer.json composer.lock ./

RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader

COPY . .

RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
