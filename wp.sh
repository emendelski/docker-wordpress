#!/bin/sh
# Runs inside the wpcli container on every `docker compose up`, after
# WordPress core has been copied into ./public. Put WP-CLI commands here that
# keep the project's dependencies in place, for example:
#
#   wp core is-installed || wp core install --url=http://localhost:8080 \
#     --title=WordPress --admin_user=admin --admin_password=admin \
#     --admin_email=admin@example.test --skip-email
#   wp plugin install query-monitor --activate
