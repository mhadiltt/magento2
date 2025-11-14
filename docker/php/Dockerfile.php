FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git unzip curl \
    libxml2-dev libxslt1-dev libzip-dev \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev libicu-dev libssl-dev libreadline-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
         bcmath gd intl pdo_mysql soap sockets xsl zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Copy composer manifests
COPY composer.json composer.lock ./

# Magento repo keys
RUN composer config --global http-basic.repo.magento.com \
    54785d5375de432d919d46b25db931e3 \
    1bea1de9d3a1a9f0ee11fd3d9d508729

RUN composer install \
    --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader

COPY . .

RUN chown -R www-data:www-data /var/www/html && \
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod 644 {} \; && \
    find var generated vendor pub/static pub/media app/etc -type d -exec chmod 755 {} \;

EXPOSE 9000
CMD ["php-fpm"]
