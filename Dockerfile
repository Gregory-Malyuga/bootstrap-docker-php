FROM serversideup/php:8.5-frankenphp-alpine

# Переключаемся на root только для установки системных утилит и настройки прав
USER root

# Включаем встроенную поддержку Laravel Octane + FrankenPHP
ENV APP_ENV=prod \
    AUTORUN_ENABLED=true \
    AUTORUN_LARAVEL_OCTANE=true \
    OCTANE_SERVER=frankenphp \
    FRANKENPHP_CONFIG="worker ./public/index.php" \
    PHP_OPCACHE_ENABLE=1 \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer \
    COMPOSER_NO_INTERACTION=1 \
    COMPOSER_PROCESS_TIMEOUT=600

WORKDIR /var/www/html

# Устанавливаем недостающие системные пакеты (git, unzip, tzdata и др.)
RUN apk upgrade --no-cache \
    && apk add --no-cache \
        git \
        tzdata \
        unzip \
    && chown -R www-data:www-data /var/www/html

# Копируем ваши кастомные настройки PHP
COPY docker/php/conf.d/*.ini /usr/local/etc/php/conf.d/

# Возвращаемся к непривилегированному пользователю
USER www-data

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD wget -qO- http://127.0.0 || exit 1
