# Dockerfile chuẩn Laravel PHP-FPM
FROM php:8.2-fpm

# Cài các extension PHP cần thiết
RUN apt-get update && apt-get install -y \
    git unzip curl libzip-dev libonig-dev libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && rm -rf /var/lib/apt/lists/*

# Tạo user www-data với UID 1000 (trùng host user để tránh permission issues)
# Tạo user www-data nếu chưa tồn tại
RUN id -u www-data >/dev/null 2>&1 || useradd -G www-data -u 1000 -m www-data

# Set thư mục làm việc
WORKDIR /var/www
COPY entrypoint.sh /var/www/entrypoint.sh
RUN chmod +x /var/www/entrypoint.sh

# Cài Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set quyền cho Laravel storage và bootstrap/cache (3 dong duoi bo comment khi dung ubuntu)
RUN mkdir -p storage bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache || true \
    && chmod -R 775 storage bootstrap/cache

# Chạy container với user www-data để Laravel không bị lỗi permission
USER www-data

# Laravel container sẽ mount volume từ host, không cần COPY code
# Nếu muốn build sẵn, có thể uncomment:
# COPY ./src /var/www
# RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Mặc định chạy PHP-FPM
CMD ["php-fpm"]
