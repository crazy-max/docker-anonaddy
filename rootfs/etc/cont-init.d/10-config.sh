#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

. $(dirname $0)/00-env

if [[ "$DKIM_ENABLE" = "true" || "$DMARC_ENABLE" = "true" ]]; then
  echo >&2 "ERROR: OpenDKIM/OpenDMARC are not supported anymore. Please use Rspamd instead."
  exit 1
fi

echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} >/etc/timezone

echo "Initializing files and folders"
mkdir -p /data/config
if [ ! -L /var/www/anonaddy/.config ]; then
  ln -sf /data/config /var/www/anonaddy/.config
fi
chown -h anonaddy:anonaddy /var/www/anonaddy/config
chown -R anonaddy:anonaddy /data/config
mkdir -p /data/storage
if [ ! -L /var/www/anonaddy/storage ]; then
  cp -Rf /var/www/anonaddy/storage /data
  rm -rf /var/www/anonaddy/storage
  ln -sf /data/storage /var/www/anonaddy/storage
fi
chown -h anonaddy:anonaddy /var/www/anonaddy/storage
chown -R anonaddy:anonaddy /data/storage
mkdir -p /data/.gnupg
if [ ! -L /var/www/anonaddy/.gnupg ]; then
  ln -sf /data/.gnupg /var/www/anonaddy/.gnupg
fi
chown -h anonaddy:anonaddy /var/www/anonaddy/.gnupg
chown -R anonaddy:anonaddy /data/.gnupg
chmod 700 /data/.gnupg

echo "Checking database connection..."
if [ -z "$DB_HOST" ]; then
  echo >&2 "ERROR: DB_HOST must be defined"
  exit 1
fi
if [ -z "$DB_PASSWORD" ]; then
  echo >&2 "ERROR: Either DB_PASSWORD or DB_PASSWORD_FILE must be defined"
  exit 1
fi
dbcmd="mariadb -h ${DB_HOST} -P ${DB_PORT} -u "${DB_USERNAME}" "-p${DB_PASSWORD}""

echo "Waiting ${DB_TIMEOUT}s for database to be ready..."
counter=1
while ! ${dbcmd} -e "show databases;" >/dev/null 2>&1; do
  sleep 1
  counter=$((counter + 1))
  if [ ${counter} -gt ${DB_TIMEOUT} ]; then
    echo >&2 "ERROR: Failed to connect to database on $DB_HOST"
    exit 1
  fi
done
echo "Database ready!"
