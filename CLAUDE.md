# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A production-oriented Laravel Octane + FrankenPHP base Docker image for PHP microservices. There is no application code — the deliverable is a Docker image published to Harbor. Consuming services copy their own code on top of this image.

## Build commands

```bash
# Standard build
docker build -t php-octane-base:local .

# Build with pcov for coverage support
docker build --build-arg INSTALL_PCOV=1 -t php-octane-base:coverage .

# Build with xdebug for local debugging
docker build --build-arg INSTALL_XDEBUG=1 -t php-octane-base:dev .
```

## Smoke checks (run after every build)

```bash
docker run --rm php-octane-base:local php -m
docker run --rm php-octane-base:local php --version
docker run --rm php-octane-base:local php -r "echo PHP_VERSION;"
```

## Architecture

Single-stage `Dockerfile` based on `dunglas/frankenphp:1.12-php8.5-alpine`:

1. Alpine runtime packages + build-only `.build-deps` virtual group (removed after compilation)
2. PHP extensions: `pcntl` + `pdo_pgsql` + `sockets` (compiled), `redis` (PECL), optional `pcov` via `--build-arg INSTALL_PCOV=1`, optional `xdebug` via `--build-arg INSTALL_XDEBUG=1`
3. Composer 2 copied from the official `composer:2` image
4. Config files from `docker/php/` copied into the image
5. Final user: `www-data`; port `8000`; healthcheck via HTTP `GET /up`
6. Default CMD: `php artisan octane:start --server=frankenphp --host=0.0.0.0 --port=8000`

**Key invariants:**
- `opcache.enable_cli=1` — required because Octane is a CLI process; without this OPcache is completely inactive
- `opcache.validate_timestamps=0` — timestamps never checked at runtime; rebuild the container to pick up code changes
- `opcache.jit=0` + `opcache.jit_buffer_size=0` — JIT disabled for the base image; consuming services may enable it by overriding both values (e.g. `jit=tracing`, `jit_buffer_size=128M`); without explicit `jit_buffer_size` PHP emits a warning when JIT is turned on

## Extending in a service

```dockerfile
FROM <github-host>/<github-project>/<image-path>:latest

COPY --chown=www-data:www-data . .

RUN composer install --no-dev --optimize-autoloader

USER www-data
```

Add extra packages or extensions in the consuming service image, not here.

## Constraints

- Extensions added here must be universally needed across microservices
