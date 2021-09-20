#!/usr/bin/with-contenv bash
# shellcheck shell=bash

DKIM_ENABLE=${DKIM_ENABLE:-false}
DKIM_PRIVATE_KEY=/data/dkim/${ANONADDY_DOMAIN}.private

if [ "$DKIM_ENABLE" != "true" ]; then
  echo "INFO: OpenDKIM service disabled."
  exit 0
fi
if [ ! -f "$DKIM_PRIVATE_KEY" ]; then
  echo "WRN: $DKIM_PRIVATE_KEY not found. OpenDKIM service disabled."
  exit 0
fi

# Init
mkdir -m o-rwx /var/spool/postfix/opendkim
chown opendkim. /var/spool/postfix/opendkim

# Fix perms
chown -R opendkim. /etc/opendkim /var/db/dkim

# Create service
mkdir -p /etc/services.d/opendkim
cat > /etc/services.d/opendkim/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/usr/sbin/opendkim -f -u opendkim -x /etc/opendkim/opendkim.conf
EOL
chmod +x /etc/services.d/opendkim/run
