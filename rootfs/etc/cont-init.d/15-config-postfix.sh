#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

. $(dirname $0)/00-env

# Restore original config
cp -f /etc/postfix/master.cf.orig /etc/postfix/master.cf
cp -f /etc/postfix/main.cf.orig /etc/postfix/main.cf

echo "Setting Postfix master configuration"
POSTFIX_DEBUG_ARG=""
if [ "$POSTFIX_DEBUG" = "true" ]; then
  POSTFIX_DEBUG_ARG=" -v"
fi
sed -i "s|^smtp.*inet.*|25 inet n - - - - smtpd${POSTFIX_DEBUG_ARG}|g" /etc/postfix/master.cf
cat >>/etc/postfix/master.cf <<EOL
anonaddy unix - n n - - pipe
  flags=F user=anonaddy argv=php /var/www/anonaddy/artisan anonaddy:receive-email --sender=\${sender} --recipient=\${recipient} --local_part=\${user} --extension=\${extension} --domain=\${domain} --size=\${size}

policy  unix  -       n       n       -       0       spawn
  user=anonaddy argv=php /var/www/anonaddy/postfix/AccessPolicy.php
EOL

echo "Setting Postfix main configuration"
VBOX_DOMAINS=""
IFS=","
for domain in $ANONADDY_ALL_DOMAINS; do
  if [ -n "$VBOX_DOMAINS" ]; then VBOX_DOMAINS="${VBOX_DOMAINS},"; fi
  VBOX_DOMAINS="${VBOX_DOMAINS}${domain},unsubscribe.${domain}"
done

sed -i 's/compatibility_level.*/compatibility_level = 3\.6/g' /etc/postfix/main.cf
sed -i 's/inet_interfaces = localhost/inet_interfaces = all/g' /etc/postfix/main.cf
[ "$LISTEN_IPV6" = "true" ] && sed -i 's/inet_protocols.*/inet_protocols = all/g' /etc/postfix/main.cf
sed -i 's/readme_directory.*/readme_directory = no/g' /etc/postfix/main.cf
sed -i 's/queue_directory.*/queue_directory =  \/data\/postfix\/queue/g' /etc/postfix/main.cf

if [ -z "$POSTFIX_SPAMHAUS_DQS_KEY" ]; then
  DBL_DOMAIN="dbl.spamhaus.org"
  ZEN_DOMAIN="zen.spamhaus.org"
else
  DBL_DOMAIN="${POSTFIX_SPAMHAUS_DQS_KEY}.dbl.dq.spamhaus.net"
  ZEN_DOMAIN="${POSTFIX_SPAMHAUS_DQS_KEY}.zen.dq.spamhaus.net"
fi

cat >>/etc/postfix/main.cf <<EOL
myhostname = ${ANONADDY_HOSTNAME}
mydomain = ${ANONADDY_DOMAIN}
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = \$myhostname
mydestination = localhost.\$mydomain, localhost

smtpd_banner = \$myhostname ESMTP
biff = no
readme_directory = no
append_dot_mydomain = no
message_size_limit = ${POSTFIX_MESSAGE_SIZE_LIMIT}

virtual_transport = anonaddy:
virtual_mailbox_domains = ${VBOX_DOMAINS},mysql:/etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf

relayhost = ${POSTFIX_RELAYHOST}
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
mailbox_size_limit = 0
recipient_delimiter = +

local_recipient_maps =

smtpd_relay_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    defer_unauth_destination

smtpd_delay_reject = yes
smtpd_helo_required = yes
smtpd_helo_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_invalid_helo_hostname,
    reject_non_fqdn_helo_hostname,
    reject_unknown_helo_hostname

smtpd_sender_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_non_fqdn_sender,
    reject_unknown_sender_domain,
    reject_unknown_reverse_client_hostname

smtpd_recipient_restrictions =
    permit_mynetworks,
    reject_unauth_destination,
    check_policy_service unix:private/policy,
    reject_rbl_client ${ZEN_DOMAIN}=127.0.0.[2..11],
    reject_rhsbl_sender ${DBL_DOMAIN}=127.0.1.[2..99],
    reject_rhsbl_helo ${DBL_DOMAIN}=127.0.1.[2..99],
    reject_rhsbl_reverse_client ${DBL_DOMAIN}=127.0.1.[2..99],
    warn_if_reject reject_rbl_client ${ZEN_DOMAIN}=127.255.255.[1..255],

# Block clients that speak too early.
smtpd_data_restrictions = reject_unauth_pipelining

disable_vrfy_command = yes
strict_rfc821_envelopes = yes
maillog_file = /dev/stdout
EOL

if [ -n "$SMTPD_MILTERS" ]; then
  echo "Setting Postfix milter configuration"
  cat >>/etc/postfix/main.cf <<EOL

# Milter configuration
milter_default_action = accept
milter_protocol = 6
smtpd_milters = ${SMTPD_MILTERS}
non_smtpd_milters = \$smtpd_milters
milter_mail_macros =  i {mail_addr} {client_addr} {client_name} {auth_authen}
EOL
fi

if [ "$POSTFIX_SMTPD_TLS" = "true" ]; then
  echo "Setting Postfix smtpd TLS configuration"
  cat >>/etc/postfix/main.cf <<EOL

# SMTPD
smtpd_use_tls=yes
smtpd_tls_session_cache_database = lmdb:\${data_directory}/smtpd_scache
smtpd_tls_CApath = /etc/ssl/certs
smtpd_tls_security_level = may
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1
smtpd_tls_loglevel = 1
smtpd_tls_session_cache_database = lmdb:\${data_directory}/smtpd_scache
smtpd_tls_mandatory_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtpd_tls_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1
smtpd_tls_mandatory_ciphers = high
smtpd_tls_ciphers = high
smtpd_tls_eecdh_grade = ultra
tls_high_cipherlist=EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH+aRSA+RC4:EECDH:EDH+aRSA:RC4:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS
tls_preempt_cipherlist = yes
tls_ssl_options = NO_COMPRESSION
EOL
  if [ -n "$POSTFIX_SMTPD_TLS_CERT_FILE" ]; then
    echo "smtpd_tls_cert_file=${POSTFIX_SMTPD_TLS_CERT_FILE}" >>/etc/postfix/main.cf
  fi
  if [ -n "$POSTFIX_SMTPD_TLS_KEY_FILE" ]; then
    echo "smtpd_tls_key_file=${POSTFIX_SMTPD_TLS_KEY_FILE}" >>/etc/postfix/main.cf
  fi
fi

if [ "$POSTFIX_SMTP_TLS" = "true" ]; then
  echo "Setting Postfix smtp TLS configuration"
  cat >>/etc/postfix/main.cf <<EOL

# SMTP
smtp_tls_CApath = /etc/ssl/certs
smtp_use_tls=yes
smtp_tls_loglevel = 1
smtp_tls_session_cache_database = lmdb:\${data_directory}/smtp_scache
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1
smtp_tls_mandatory_ciphers = high
smtp_tls_ciphers = high
smtp_tls_mandatory_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtp_tls_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtp_tls_security_level = may
EOL
fi

if [ "$POSTFIX_RELAYHOST_AUTH_ENABLE" = "true" ]; then
  echo "Setting Postfix SASL configuration"
  cat >>/etc/postfix/main.cf <<EOL

smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = texthash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
header_size_limit = 4096000
EOL

  cat >/etc/postfix/sasl_passwd <<EOL

${POSTFIX_RELAYHOST} ${POSTFIX_RELAYHOST_USERNAME}:${POSTFIX_RELAYHOST_PASSWORD}
EOL

  chmod 600 /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
fi

# usernames query
QUERY_USERNAMES=""
QUERY_DOMAINS=""
IFS=","
for domain in $ANONADDY_ALL_DOMAINS; do
  if [ -n "$QUERY_USERNAMES" ]; then QUERY_USERNAMES="${QUERY_USERNAMES} OR "; fi
  if [ -n "$QUERY_DOMAINS" ]; then QUERY_DOMAINS="${QUERY_DOMAINS}, "; fi
  QUERY_USERNAMES="${QUERY_USERNAMES}CONCAT(username, '.${domain}') = '%s'"
  QUERY_DOMAINS="${QUERY_DOMAINS}CONCAT(username, '.${domain}')"
done

echo "Creating Postfix virtual alias domains and subdomains configuration"
cat >/etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf <<EOL
user = ${DB_USERNAME}
password = ${DB_PASSWORD}
hosts = ${DB_HOST}:${DB_PORT}
dbname = ${DB_DATABASE}
query = SELECT (SELECT 1 FROM usernames WHERE ${QUERY_USERNAMES}) AS usernames, (SELECT 1 FROM domains WHERE domain = '%s' AND domain_verified_at IS NOT NULL) AS domains LIMIT 1;
EOL
chmod o= /etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf
chgrp postfix /etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf

if [ -f "/data/postfix-main.alt.cf" ]; then
  cat "/data/postfix-main.alt.cf" > /etc/postfix/main.cf
fi

echo "Display Postfix config"
postconf | sed -e 's/^/[postfix-config] /'
