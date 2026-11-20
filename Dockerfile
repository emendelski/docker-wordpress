ARG MAILPIT_VERSION=v1.34

FROM axllent/mailpit:${MAILPIT_VERSION} AS mailpit

FROM wordpress:php8.5-apache

ARG XDEBUG_VERSION=3.5.3

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The official image already ships curl, gd, imagick, intl, mbstring, xml and
# zip; only soap is missing.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libxml2-dev \
    && docker-php-ext-install -j"$(nproc)" soap \
    && pecl install "xdebug-${XDEBUG_VERSION}" \
    && docker-php-ext-enable xdebug \
    && rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Mailpit's sendmail mode delivers PHP mail() to the mailpit service. The
# binary comes from the official multi-arch image, so it works on amd64 and
# arm64 alike.
COPY --from=mailpit /mailpit /usr/local/bin/mailpit
RUN echo 'sendmail_path = "/usr/local/bin/mailpit sendmail -S mailpit:1025"' \
    > /usr/local/etc/php/conf.d/mailpit.ini
