#!/bin/bash
set -e

echo "========================================"
echo "🚀 Starting Magento setup preparation (No OpenSearch Mode)..."
echo "========================================"

# Ensure we are in Magento root (bin/magento must exist)
if [ ! -f "bin/magento" ]; then
  echo "❌ bin/magento not found in current directory."
  echo "   Please cd to your Magento root before running this script."
  exit 1
fi

# Ensure required directories exist
echo "🔧 Preparing required directories..."
mkdir -p var pub/static pub/media generated
chmod -R 777 var pub/static pub/media generated || true

# Backup and temporarily remove OpenSearch config from env.php
if [ -f app/etc/env.php ]; then
  echo "🧩 Backing up env.php..."
  cp app/etc/env.php app/etc/env.php.bak

  echo "⚙️ Removing OpenSearch config for build/run..."
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
  echo "⚠️ env.php not found, skipping OpenSearch config modification."
fi

echo "----------------------------------------"
echo "ℹ️ Checking DB status (optional)..."
php -d memory_limit=2G bin/magento setup:db:status || true
echo "----------------------------------------"

# Run setup upgrade
echo "⚙️ Running setup:upgrade..."
php -d memory_limit=2G bin/magento setup:upgrade
echo "✅ setup:upgrade completed."

# Deploy static content
echo "🧱 Deploying static content..."
php -d memory_limit=2G bin/magento setup:static-content:deploy -f
echo "✅ Static content deployed."

# Compile DI (this recreates missing Proxy / Interceptor classes)
echo "🧰 Compiling DI (setup:di:compile)..."
php -d memory_limit=2G bin/magento setup:di:compile
echo "✅ Dependency injection compilation completed."

# Clean cache
echo "🧹 Cleaning and flushing cache..."
php bin/magento cache:clean
php bin/magento cache:flush
echo "✅ Cache cleaned & flushed."

# Restore env.php for production (with OpenSearch config)
if [ -f app/etc/env.php.bak ]; then
  echo "♻️ Restoring original env.php..."
  mv app/etc/env.php.bak app/etc/env.php
  echo "✅ env.php restored."
fi

# Fix permissions
echo "🔒 Setting proper permissions..."
chmod -R 777 var pub/static pub/media generated || true
echo "✅ Permissions set."

echo "========================================"
echo "✅ Magento preparation completed successfully (No OpenSearch needed during commands)!"
echo "========================================"
