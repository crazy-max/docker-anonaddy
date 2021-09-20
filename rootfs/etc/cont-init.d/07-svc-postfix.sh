#!/usr/bin/with-contenv bash
# shellcheck shell=bash

mkdir -p /etc/services.d/postfix
cat > /etc/services.d/postfix/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/usr/sbin/postfix -c /etc/postfix start-fg
EOL
chmod +x /etc/services.d/postfix/run
