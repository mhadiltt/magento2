# Use official Nginx base image

FROM nginx:1.24-alpine

# Set working directory

WORKDIR /var/www/html

# Copy Nginx configuration

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy Magento source code into container

COPY . /var/www/html/

# Expose port 80

EXPOSE 80

# Start Nginx in foreground

CMD ["nginx", "-g", "daemon off;"]
