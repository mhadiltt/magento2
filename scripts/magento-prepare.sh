#!/bin/bash
set -e

echo "========================================"
echo "🚀 Starting Magento setup preparation..."
echo "========================================"

cd /var/www/html || exit 1

if [ "$SKIP_UPGRADE" != "true" ]; then
  echo "⚙️ Running setup upgrade..."
  php -d memory_limit=2G bin/magento setup:upgrade
else
  echo "⚙️ Skipping setup:upgrade inside image build (no DB/OpenSearch)"
fi

echo "🧱 Deploying static content..."
php -d memory_limit=2G bin/magento setup:static-content:deploy -f

echo "🧰 Compiling DI..."
php -d memory_limit=2G bin/magento setup:di:compile

echo "🧹 Cleaning cache..."
php bin/magento cache:clean || true
php bin/magento cache:flush || true

echo "🔒 Setting proper permissions..."
chmod -R 777 var pub/static pub/media generated

echo "✅ Magento preparation completed successfully!"
