# php-octane-base-image

Production-oriented Laravel Octane + FrankenPHP base image for PHP microservices.

The image ships PHP with FrankenPHP and a curated set of runtime extensions. It contains no application code — the consuming service copies its own code on top and runs Laravel Octane.

## Runtime contract

- `dunglas/frankenphp:1.12-php8.5-alpine` base
- `APP_ENV=prod` by default (override at runtime with `-e APP_ENV=...`)
- Composer 2
- Octane (FrankenPHP) on port `8000`
- Healthcheck via HTTP `GET /up`
- Production PHP and OPcache settings in `docker/php/`

## Extensions

Installed explicitly:

- `pcntl` — signal handling for graceful shutdown / Octane reload
- `sockets` — required by PHP networking internals
- `pdo_pgsql`
- `redis`

FrankenPHP itself is part of the base image (`dunglas/frankenphp`) — no separate extension needed.

Provided by the upstream PHP image:

- `ctype`, `curl`, `dom`, `fileinfo`, `filter`, `iconv`, `json`, `mbstring`, `openssl`, `phar`, `simplexml`, `tokenizer`, `xml`, `Zend OPcache`

## Configuration files

- `docker/php/conf.d/10-php.ini`: base production PHP settings (`max_execution_time=0` — Octane is a long-lived process)
- `docker/php/conf.d/20-opcache.ini`: production OPcache settings (`enable_cli=1` required for Octane; `jit=0` + `jit_buffer_size=0` — JIT off by default, override both in the consuming service)

## Build

```bash
docker build -t php-octane-base:local .
```

## Smoke checks

```bash
docker run --rm php-octane-base:local php -m
docker run --rm php-octane-base:local php --version
docker run --rm php-octane-base:local php -r "echo swoole_version();"
```

## GitHub CI

The pipeline performs:

- Dockerfile lint with Hadolint
- Docker image build
- PHP extension smoke checks for `pdo_pgsql`, `redis`, `pcntl`, `sockets`
- Trivy HIGH/CRITICAL image vulnerability scan
- Registry push from the default branch

## Use in a service image

```dockerfile
FROM ghcr.io/gregory-malyuga/bootstrap-docker-php:latest

COPY --chown=www-data:www-data . .

RUN composer install --no-dev --optimize-autoloader

USER www-data
```

Laravel Octane starts automatically via the inherited `CMD`. To override the port or worker count:

```dockerfile
CMD ["php", "artisan", "octane:start", "--server=frankenphp", "--host=0.0.0.0", "--port=8000", "--workers=4"]
```

Add extra Alpine packages or PHP extensions in the consuming service image rather than expanding this shared base.
