FROM nginx:alpine

# Copy Nginx config file
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy all Magento files from project root to the container
COPY . /var/www/html/
