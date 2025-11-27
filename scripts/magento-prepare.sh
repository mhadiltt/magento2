#!/bin/bash
set -e

echo "========================================"
echo "🚀 Starting Magento setup preparation..."
echo "========================================"

# Ensure proper working directory
cd "$(pwd)" || exit 1

# Ensure permissions before starting
echo "🔧 Setting permissions before setup..."
chmod -R 777 var pub/static pub/media generated || true

# Run setup upgrade safely
echo "⚙️ Running setup upgrade..."
php -d memory_limit=2G bin/magento setup:upgrade --skip-search-engine-validation

# Deploy static content
echo "🧱 Deploying static content..."
php -d memory_limit=2G bin/magento setup:static-content:deploy -f

# Compile DI
echo "🧰 Compiling DI..."
php -d memory_limit=2G bin/magento setup:di:compile

# Clean cache
echo "🧹 Cleaning cache..."
php bin/magento cache:clean
php bin/magento cache:flush

# Set final permissions
echo "🔒 Setting proper permissions..."
chmod -R 777 var pub/static pub/media generated

echo "✅ Magento preparation completed successfully!"
