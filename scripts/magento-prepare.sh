#!/bin/sh
set -e

echo "========================================"
echo "🚀 Starting Magento setup preparation..."
echo "========================================"

# Go to Magento project root (one level up from /scripts)
cd "$(dirname "$0")/.." || exit 1

echo "⚙️ Running setup upgrade..."
php bin/magento setup:upgrade

echo "🧱 Deploying static content..."
php bin/magento setup:static-content:deploy -f

echo "🧰 Compiling DI..."
php bin/magento setup:di:compile

echo "🧹 Cleaning cache..."
php bin/magento cache:clean
php bin/magento cache:flush

echo "🔒 Setting proper permissions..."
chmod -R 777 var pub/static pub/media generated

echo "✅ Magento preparation completed successfully!"
