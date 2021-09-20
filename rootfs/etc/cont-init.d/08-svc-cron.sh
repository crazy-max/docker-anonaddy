#!/usr/bin/with-contenv sh
# shellcheck shell=sh

CRONTAB_PATH="/var/spool/cron/crontabs"

# Init
rm -rf ${CRONTAB_PATH}
mkdir -m 0644 -p ${CRONTAB_PATH}
echo "* * * * * php /var/www/anonaddy/artisan schedule:run --no-ansi --no-interaction --quiet" >> ${CRONTAB_PATH}/anonaddy

# Fix perms
echo "Fixing crontabs permissions..."
chmod -R 0644 ${CRONTAB_PATH}

# Create service
mkdir -p /etc/services.d/cron
cat > /etc/services.d/cron/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
exec busybox crond -f -L /dev/stdout
EOL
chmod +x /etc/services.d/cron/run
