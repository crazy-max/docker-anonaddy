#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

. $(dirname $0)/00-env

echo "Init PHP extensions"
cp -Rf /tpls/etc/php83/conf.d /etc/php83

echo "Setting PHP-FPM configuration"
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  -e "s/@CLEAR_ENV@/$CLEAR_ENV/g" \
  /tpls/etc/php83/php-fpm.d/www.conf >/etc/php83/php-fpm.d/www.conf

echo "Setting PHP INI configuration"
sed -i "s|memory_limit.*|memory_limit = ${MEMORY_LIMIT}|g" /etc/php83/php.ini
sed -i "s|;date\.timezone.*|date\.timezone = ${TZ}|g" /etc/php83/php.ini

echo "Setting OpCache configuration"
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php83/conf.d/opcache.ini >/etc/php83/conf.d/opcache.ini
