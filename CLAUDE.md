# docker-wordpress

Local WordPress development environment on Docker Compose. There is no application code here:
the repo is the environment (`compose.yaml`, `Dockerfile`, PHP config) plus mount points for a
project's plugins and themes.

## Stack

| Service      | Image / build                     | Host address (default)         |
| ------------ | --------------------------------- | ------------------------------ |
| `wordpress`  | `Dockerfile` target `wordpress`   | http://localhost:8080          |
| `wpcli`      | `Dockerfile` target `cli`         | runs `wp.sh` on `up`, exits    |
| `db`         | `mariadb:lts`                     | `127.0.0.1:3308`               |
| `mailpit`    | `axllent/mailpit`                 | http://localhost:8025, SMTP 1025 |
| `phpmyadmin` | `phpmyadmin:5`                    | http://localhost:8181          |

- `wordpress` target: `wordpress:php8.5-apache` + soap, Xdebug 3 and Mailpit's sendmail.
- `cli` target: `wordpress:cli-php8.5` + the same Mailpit sendmail.
- All ports bind to `BIND_ADDRESS` (default `127.0.0.1`).
- Ports, DB credentials, `WORDPRESS_DEBUG`, `WP_ENVIRONMENT_TYPE` and `XDEBUG_MODE` come from
  `.env`; every value has a default in `compose.yaml`, so `.env` is optional (see
  `.env.example`).

## Layout

- `public/` – WordPress core, bind-mounted to `/var/www/html`; generated, git-ignored.
- `plugins/`, `themes/`, `uploads/`, `mu-plugins/` – bind-mounted over the matching
  `wp-content/` directories. Their contents are git-ignored except `.gitkeep` and
  `mu-plugins/docker-mail.php`.
- `wp.sh` – mounted read-only at `/usr/local/bin/wp.sh` in `wpcli` and run with `sh` on every
  `docker compose up`.
- `phpconf.ini`, `xdebug.ini` – PHP and Xdebug settings.

## Commands

```bash
docker compose up -d                      # start (builds images on first run)
docker compose up -d --build              # after changing Dockerfile / xdebug.ini
docker compose down                       # stop, keep the database
docker compose down --volumes             # stop and delete the database
docker compose logs -f wordpress

docker compose run --rm wpcli wp <command>
docker compose exec wordpress php -m
```

Install WordPress on a fresh stack:

```bash
docker compose run --rm wpcli wp core install --url=http://localhost:8080 \
  --title=WordPress --admin_user=admin --admin_password=admin \
  --admin_email=admin@example.test --skip-email
```

Read captured mail without a browser: `curl -s localhost:8025/api/v1/messages`.

## Gotchas

- **`WORDPRESS_DEBUG`**: the image does `!!getenv_docker('WORDPRESS_DEBUG', '')`, so any
  non-empty value, including `false`, enables `WP_DEBUG`. Leave it empty to disable.
- **wp_mail() sender**: WordPress's default From is `wordpress@localhost`, which PHPMailer
  rejects ("Invalid address: (From)"). `mu-plugins/docker-mail.php` replaces an invalid sender
  with `wordpress@localhost.test`. Do not remove it or the `mu-plugins` mounts.
- **WP-CLI user**: the `cli` image runs as uid/gid 33 (Apache's `www-data` in the Debian image). The CLI
  image is Alpine, where `www-data` is 82 and could not write core files. No `--allow-root` or
  `--user root` is needed.
- **No single-file bind mounts inside `./public`**: Docker Desktop (virtiofs) refuses to create
  the mount point inside another bind mount. Mount directories, or files outside the document
  root.
- **Core updates**: rebuilding the image does not update WordPress core; the image only seeds
  `public/` when it is empty. Use `wp core update` and `wp core update-db`.
- **WP_HOME / WP_SITEURL** come from `WP_PORT` via `WORDPRESS_CONFIG_EXTRA`. After changing
  `WP_PORT`, run `docker compose up -d` so the containers pick it up.
- **Xdebug** connects to `host.docker.internal:9003` (IDE key `docker`) only with a trigger
  (`XDEBUG_TRIGGER` cookie/GET/POST or a browser extension). `XDEBUG_MODE=off` disables it.
- **Pretty permalinks** work out of the box: the PHP Apache image already sets
  `AllowOverride All` (`docker-php.conf`) and core ships an `.htaccess`.
- WP-CLI 2.12 prints a PHP 8.5 `Deprecated` notice from its own vendor code; it is harmless.

## Verifying changes

CI (`.github/workflows/ci.yml`) runs hadolint, `docker compose config`, then starts the stack,
installs WordPress, checks the site responds, soap and Xdebug are loaded, and that `mail()` and
`wp_mail()` reach Mailpit. Reproduce locally with the same commands, then clean up with
`docker compose down --volumes` and `git clean -fdX -- public plugins themes uploads mu-plugins`.
