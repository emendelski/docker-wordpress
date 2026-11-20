# docker-wordpress

Local WordPress development environment with Docker Compose: PHP 8.5 with Xdebug 3, MariaDB,
Mailpit, phpMyAdmin and WP-CLI.

[![CI](https://github.com/emendelski/docker-wordpress/actions/workflows/ci.yml/badge.svg)](https://github.com/emendelski/docker-wordpress/actions/workflows/ci.yml)

## Requirements

[Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine with the
Compose plugin. Works on amd64 and arm64 (Apple Silicon).

## Getting started

```bash
# optional: adjust ports, credentials and debug settings
cp .env.example .env

# build and start everything in the background
docker compose up -d

# stop the containers (data is kept)
docker compose down
```

On the first start WordPress core is copied into `public/`. Finish the installation in the
browser or with WP-CLI:

```bash
docker compose run --rm wpcli wp core install --url=http://localhost:8080 \
  --title=WordPress --admin_user=admin --admin_password=admin \
  --admin_email=admin@example.test --skip-email
```

| Service    | Address                                        |
| ---------- | ---------------------------------------------- |
| WordPress  | http://localhost:8080                          |
| Mailpit    | http://localhost:8025 (SMTP on port 1025)      |
| phpMyAdmin | http://localhost:8181                          |
| MariaDB    | `localhost:3308`, user/password `wordpress`    |

All ports and credentials can be changed in `.env` (see `.env.example`). Database credentials
apply when the `db_data` volume is first created; `docker compose down --volumes` removes the
database.

## WP-CLI

```bash
docker compose run --rm wpcli wp plugin list
docker compose run --rm wpcli wp plugin install query-monitor --activate
```

The `wpcli` service runs as the same user as Apache (`www-data`, uid 33), so it can write core,
plugin and theme files. `wp.sh` runs in that container on every `docker compose up`: put
commands that keep the project's dependencies in place there.

Mail sent from WP-CLI itself is not captured; mail sent by WordPress in the browser is.

## Mail

PHP `mail()` and `wp_mail()` are delivered to [Mailpit](https://mailpit.axllent.org/) instead of
real recipients. Open http://localhost:8025 to read them.

## Xdebug

Xdebug 3 connects to your IDE on port **9003** (`host.docker.internal`) with the IDE key
`docker`, only when a request carries the trigger: use a
[browser extension](https://xdebug.org/docs/step_debug#browser-extensions), or add an
`XDEBUG_TRIGGER` cookie, GET or POST parameter.

Map `public/` to `/var/www/html` and `plugins/`, `themes/`, `uploads/` to the matching
`/var/www/html/wp-content/*` paths in your IDE.

Set `XDEBUG_MODE` in `.env` (`off`, `develop`, `profile`, `coverage`, `trace`) and run
`docker compose up -d` to switch modes, e.g. `off` for full speed.

## Debugging

`WORDPRESS_DEBUG` is on by default and errors are logged to `public/wp-content/debug.log`.
Leave it empty in `.env` to turn debugging off: the WordPress image treats any non-empty value,
including `false`, as enabled.

## Updating

Rebuilding the image (`docker compose build --pull`) updates PHP, Xdebug and the other tools,
but **not WordPress core**: the image only copies core into `public/` when it is empty. Update
core with WP-CLI:

```bash
docker compose run --rm wpcli wp core update
docker compose run --rm wpcli wp core update-db
```

## Repository structure

- `public/` – WordPress core (generated, ignored by git)
- `plugins/` – project plugins, mounted as `wp-content/plugins/`
- `themes/` – project themes, mounted as `wp-content/themes/`
- `uploads/` – media, mounted as `wp-content/uploads/`
- `compose.yaml` – services and configuration
- `Dockerfile` – WordPress image with soap, Xdebug and Mailpit's sendmail
- `phpconf.ini`, `xdebug.ini` – PHP and Xdebug settings
- `wp.sh` – WP-CLI commands run on every `docker compose up`
