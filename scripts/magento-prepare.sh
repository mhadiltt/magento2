#!/bin/bash
set -e

echo "========================================"
echo "🚀 Starting Magento setup preparation..."
echo "========================================"

cd /var/www/html || exit 1

echo "⚙️ Running setup upgrade..."
php -d memory_limit=2G bin/magento setup:upgrade

echo "🧱 Deploying static content..."
php -d memory_limit=2G bin/magento setup:static-content:deploy -f

echo "🧰 Compiling DI..."
php -d memory_limit=2G bin/magento setup:di:compile

echo "🧹 Cleaning cache..."
php bin/magento cache:clean
php bin/magento cache:flush

echo "🔒 Setting proper permissions..."
chmod -R 777 var pub/static pub/media generated

echo "✅ Magento preparation completed successfully!"
