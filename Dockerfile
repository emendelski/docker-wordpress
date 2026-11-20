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

RUN curl --fail --location --output /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 \
    && chmod +x /usr/local/bin/mhsendmail \
    && echo 'sendmail_path="/usr/local/bin/mhsendmail --smtp-addr=mailhog:1025 --from=no-reply@docker.dev"' > /usr/local/etc/php/conf.d/mailhog.ini
