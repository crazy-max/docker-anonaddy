#!/usr/bin/with-contenv sh
# shellcheck shell=sh

echo "Fixing perms..."
mkdir -p /data \
  /data/dkim \
  /data/dmarc \
  /var/run/nginx \
  /var/run/php-fpm
chown anonaddy. /data
chown -R anonaddy. \
  /data/dkim \
  /tpls \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php8 \
  /var/run/nginx \
  /var/run/php-fpm \
  /var/www/anonaddy/bootstrap/cache \
  /var/www/anonaddy/config \
  /var/www/anonaddy/storage
