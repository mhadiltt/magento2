FROM hadil01/php-base:8.2

WORKDIR /var/www/html

COPY composer.json composer.lock ./

RUN composer config --global http-basic.repo.magento.com \
    54785d5375de432d919d46b25db931e3 \
    1bea1de9d3a1a9f0ee11fd3d9d508729 && \
    composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

COPY . .

RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 777 var pub generated

RUN chmod +x scripts/magento-prepare.sh && \
    sh scripts/magento-prepare.sh

EXPOSE 9000
CMD ["php-fpm"]
