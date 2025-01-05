#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

. $(dirname $0)/00-env

if [ "$RSPAMD_ENABLE" != "true" ]; then
  echo "INFO: Rspamd service disabled."
  exit 0
fi
if [ ! -f "$DKIM_PRIVATE_KEY" ]; then
  echo "WRN: $DKIM_PRIVATE_KEY not found. Rspamd service disabled."
  exit 0
fi

# Init
mkdir -p -m o-rwx /var/run/rspamd
chown rspamd:rspamd /var/run/rspamd

# Fix perms
chown -R rspamd:rspamd /etc/rspamd /var/lib/rspamd

# Create service
mkdir -p /etc/services.d/rspamd
cat >/etc/services.d/rspamd/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/usr/bin/rspamd -i -f -u rspamd -g rspamd
EOL
chmod +x /etc/services.d/rspamd/run
