#!/bin/bash
set -e

echo "========================================"
echo "🚀 Starting Magento setup preparation (No OpenSearch Mode)..."
echo "========================================"

# Ensure required directories exist
echo "🔧 Preparing required directories..."
mkdir -p var pub/static pub/media generated
chmod -R 777 var pub/static pub/media generated || true

# Backup and temporarily remove OpenSearch config from env.php
if [ -f app/etc/env.php ]; then
  echo "🧩 Backing up env.php..."
  cp app/etc/env.php app/etc/env.php.bak

  echo "⚙️ Removing OpenSearch config for CI build..."
  php -r '
  $file = "app/etc/env.php";
  $env = include $file;
  if (isset($env["system"]["default"]["catalog"]["search"])) {
      unset($env["system"]["default"]["catalog"]["search"]);
  }
  $export = "<?php\nreturn " . var_export($env, true) . ";";
  file_put_contents($file, $export);
  echo "✅ Removed OpenSearch config temporarily.\n";
  '
else
  echo "⚠️ env.php not found, skipping config modification."
fi

# Run setup upgrade
echo "⚙️ Running setup upgrade..."
php -d memory_limit=2G bin/magento setup:upgrade || true

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

# Restore env.php for production
if [ -f app/etc/env.php.bak ]; then
  echo "♻️ Restoring original env.php..."
  mv app/etc/env.php.bak app/etc/env.php
fi

# Fix permissions
echo "🔒 Setting proper permissions..."
chmod -R 777 var pub/static pub/media generated

echo "✅ Magento preparation completed successfully (No OpenSearch needed)!"
