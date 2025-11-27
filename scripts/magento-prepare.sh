#!/bin/bash
set -e

echo "========================================"
echo "🚀 Starting Magento setup preparation..."
echo "========================================"

# Ensure required directories exist
echo "🔧 Preparing required directories..."
mkdir -p var pub/static pub/media generated
chmod -R 777 var pub/static pub/media generated || true

# Inject dummy OpenSearch config if not available
echo "⚙️ Checking for OpenSearch configuration..."
if ! grep -q "'opensearch'" app/etc/env.php 2>/dev/null; then
  echo "⚙️ Injecting dummy OpenSearch config for CI..."
  php -r '
  $file = "app/etc/env.php";
  if (file_exists($file)) {
      $env = include $file;
      if (!isset($env["system"])) $env["system"] = [];
      $env["system"]["default"]["catalog"]["search"] = [
          "engine" => "opensearch",
          "opensearch_server_hostname" => "localhost",
          "opensearch_server_port" => "9200",
          "opensearch_index_prefix" => "magento2",
          "opensearch_enable_auth" => "0",
          "opensearch_server_timeout" => "15",
      ];
      $export = "<?php\nreturn " . var_export($env, true) . ";";
      file_put_contents($file, $export);
      echo "✅ Dummy OpenSearch configuration added for CI.\n";
  } else {
      echo "⚠️ env.php not found, skipping dummy config.\n";
  }'
fi

# Run setup upgrade
echo "⚙️ Running setup upgrade..."
php -d memory_limit=2G bin/magento setup:upgrade

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

# Final permissions
echo "🔒 Setting proper permissions..."
chmod -R 777 var pub/static pub/media generated

echo "✅ Magento preparation completed successfully!"
