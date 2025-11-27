#!/bin/bash
set -e

echo "========================================"
echo "🚀 Starting Magento setup preparation (No OpenSearch Mode)..."
echo "========================================"

# Ensure required directories exist
echo "🔧 Preparing required directories..."
mkdir -p var pub/static pub/media generated
chmod -R 777 var pub/static pub/media generated || true

echo "----------------------------------------"
echo "ℹ️ Checking DB status (optional)..."
if php bin/magento setup:db:status >/dev/null 2>&1; then
  echo "✅ DB status is OK."
else
  echo "⚠️ Declarative Schema is not up to date or status check failed."
  echo "   Will continue and run setup:upgrade."
fi
echo "----------------------------------------"

# ---------- DO NOT CHANGE: OpenSearch handling block ----------
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
# ---------- END OpenSearch handling block ----------

# Run setup upgrade (but DO NOT fail the pipeline if OpenSearch breaks it)
echo "⚙️ Running setup:upgrade..."
if ! php -d memory_limit=2G bin/magento setup:upgrade; then
  echo "⚠️ setup:upgrade failed (likely OpenSearch connection issue)."
  echo "   Continuing build anyway..."
fi

# Deploy static content
echo "🧱 Deploying static content..."
php -d memory_limit=2G bin/magento setup:static-content:deploy -f

# Compile DI (regenerates proxies, interceptors, etc.)
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

# Optional: generate custom feed if command is available
echo "📦 Checking for custom feed command..."
if php bin/magento list | grep -q 'customfeed:generate'; then
  echo "➡️ Running customfeed:generate..."
  if php bin/magento customfeed:generate; then
    echo "✅ Custom feed generated successfully."
  else
    echo "⚠️ customfeed:generate failed, but continuing..."
  fi
else
  echo "ℹ️ customfeed:generate command not found, skipping feed generation."
fi

echo "✅ Magento preparation completed successfully (No OpenSearch needed)!"
