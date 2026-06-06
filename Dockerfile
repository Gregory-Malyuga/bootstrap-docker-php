FROM php:8.5-cli-alpine

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG INSTALL_PCOV=0

ENV APP_ENV=prod \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer

WORKDIR /var/www/app

RUN apk upgrade --no-cache \
    && apk add --no-cache \
        ca-certificates \
        git \
        libpq \
        librdkafka \
        openssl \
        tzdata \
        unzip \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        librdkafka-dev \
        linux-headers \
        openssl-dev \
        postgresql-dev \
    && docker-php-ext-install -j"$(nproc)" \
        pcntl \
        pdo_pgsql \
        sockets \
    && pecl install \
        rdkafka \
        redis \
        swoole \
    && docker-php-ext-enable \
        rdkafka \
        redis \
        swoole \
    && if [ "$INSTALL_PCOV" = "1" ]; then \
        pecl install pcov; \
        docker-php-ext-enable pcov; \
    fi \
    && apk del .build-deps \
    && rm -rf /tmp/pear ~/.pearrc \
    && chown www-data:www-data /var/www/app

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

COPY docker/php/conf.d/*.ini /usr/local/etc/php/conf.d/

USER www-data

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8000/up || exit 1

CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000"]
