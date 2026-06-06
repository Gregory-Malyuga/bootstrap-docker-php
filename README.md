# php-octane-base-image

Production-oriented Laravel Octane + Swoole base image for PHP microservices.

The image ships PHP CLI with Swoole and a curated set of runtime extensions. It contains no application code — the consuming service copies its own code on top and runs Laravel Octane.

## Runtime contract

- PHP `8.5-cli-alpine`
- `APP_ENV=prod` by default (override at runtime with `-e APP_ENV=...`)
- Composer 2
- Octane (Swoole) on port `8000`
- Healthcheck via HTTP `GET /up`
- Production PHP and OPcache settings in `docker/php/`

## Extensions

Installed explicitly:

- `swoole` — application server for Laravel Octane
- `pcntl` — signal handling for graceful shutdown
- `sockets` — required by Swoole internals
- `pdo_pgsql`
- `rdkafka`
- `redis`

Optional for local test coverage builds:

- `pcov` when built with `--build-arg INSTALL_PCOV=1`

Provided by the upstream PHP image:

- `ctype`, `curl`, `dom`, `fileinfo`, `filter`, `iconv`, `json`, `mbstring`, `openssl`, `phar`, `simplexml`, `tokenizer`, `xml`, `Zend OPcache`

## Configuration files

- `docker/php/conf.d/10-php.ini`: base production PHP settings
- `docker/php/conf.d/20-opcache.ini`: production OPcache settings (`enable_cli=1` required for Octane)
- `docker/php/conf.d/30-swoole.ini`: `swoole.use_shortname=Off`

## Build

```bash
docker build -t php-octane-base:local .
```

Build with pcov for local coverage runs:

```bash
docker build --build-arg INSTALL_PCOV=1 -t php-octane-base:coverage .
```

In a consuming service's `docker-compose.yml`:

```yaml
services:
  php:
    build:
      args:
        INSTALL_PCOV: "1"
```

## Smoke checks

```bash
docker run --rm php-octane-base:local php -m
docker run --rm php-octane-base:local php --version
docker run --rm php-octane-base:local php -r "echo swoole_version();"
```

## GitLab CI

The pipeline performs:

- Dockerfile lint with Hadolint
- Docker image build
- PHP extension smoke checks for `pdo_pgsql`, `rdkafka`, `redis`, `swoole`, `pcntl`, `sockets`
- Trivy HIGH/CRITICAL image vulnerability scan
- Registry push from the default branch

## Use in a service image

```dockerfile
FROM <github-host>/<github-project>/<image-path>:latest

COPY --chown=www-data:www-data . .

RUN composer install --no-dev --optimize-autoloader --no-interaction

USER www-data
```

Laravel Octane starts automatically via the inherited `CMD`. To override the port or worker count:

```dockerfile
CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000", "--workers=4"]
```

Add extra Alpine packages or PHP extensions in the consuming service image rather than expanding this shared base.
