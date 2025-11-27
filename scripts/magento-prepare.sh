#!/bin/bash
set -e

echo "========================================"
echo "🚀 Starting Magento setup preparation..."
echo "========================================"

echo "🔧 Preparing required directories..."
mkdir -p var pub/static pub/media generated
chmod -R 777 var pub/static pub/media generated || true

echo "⚙️ Setting search engine to MySQL for CI..."
php -r '
$envFile = "app/etc/env.php";
if (file_exists($envFile)) {
    $data = include $envFile;
    if (!isset($data["system"])) { $data["system"] = []; }
    if (!isset($data["system"]["default"])) { $data["system"]["default"] = []; }
    if (!isset($data["system"]["default"]["catalog"])) { $data["system"]["default"]["catalog"] = []; }
    if (!isset($data["system"]["default"]["catalog"]["search"])) { $data["system"]["default"]["catalog"]["search"] = []; }
    $data["system"]["default"]["catalog"]["search"]["engine"] = "mysql";
    $export = "<?php\nreturn " . var_export($data, true) . ";";
    file_put_contents($envFile, $export);
    echo "✅ Search engine temporarily set to MySQL\n";
} else {
    echo "⚠️ env.php not found; skipping search engine switch\n";
}'

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
