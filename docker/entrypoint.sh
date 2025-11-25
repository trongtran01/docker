#!/bin/sh

set -e

# ---------------------------------------------------------
# 1. Fix quyền cho Laravel (storage + cache) - Bo comment 3 dong duoi khi dung Ubuntu
# ---------------------------------------------------------

echo "Fixing permissions..."
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# ---------------------------------------------------------
# 2. Tạo folder nếu chưa có (tránh crash lần build đầu)
# ---------------------------------------------------------

mkdir -p /var/www/storage/logs
mkdir -p /var/www/storage/framework/cache/data
mkdir -p /var/www/storage/framework/sessions
mkdir -p /var/www/storage/framework/views

# ---------------------------------------------------------
# 3. Copy .env ví dụ nếu file .env chưa tồn tại
# ---------------------------------------------------------
if [ ! -f /var/www/.env ] && [ -f /var/www/.env.example ]; then
    echo "No .env found → copying .env.example"
    cp /var/www/.env.example /var/www/.env
    chown www-data:www-data /var/www/.env
fi

# ---------------------------------------------------------
# 4. Generate key nếu chưa có
# ---------------------------------------------------------
if ! grep -q "APP_KEY=base64" /var/www/.env; then
    echo "Generating APP_KEY..."
    php /var/www/artisan key:generate --force
fi

# ---------------------------------------------------------
# 5. Clear & cache Laravel (tùy chọn)
# ---------------------------------------------------------
echo "Clearing old caches..."
php /var/www/artisan config:clear || true
php /var/www/artisan cache:clear || true
php /var/www/artisan view:clear || true

# ---------------------------------------------------------
# 6. Chạy lệnh được cung cấp ở CMD
# ---------------------------------------------------------
echo "Starting main process..."
exec "$@"
