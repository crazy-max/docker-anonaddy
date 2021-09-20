#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# From https://github.com/docker-library/mariadb/blob/master/docker-entrypoint.sh#L21-L41
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(<"${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

TZ=${TZ:-UTC}
MEMORY_LIMIT=${MEMORY_LIMIT:-256M}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-16M}
CLEAR_ENV=${CLEAR_ENV:-yes}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-128}
LISTEN_IPV6=${LISTEN_IPV6:-true}
REAL_IP_FROM=${REAL_IP_FROM:-0.0.0.0/32}
REAL_IP_HEADER=${REAL_IP_HEADER:-X-Forwarded-For}
LOG_IP_VAR=${LOG_IP_VAR:-remote_addr}

APP_NAME=${APP_NAME:-AnonAddy}
#APP_KEY=${APP_KEY:-base64:Gh8/RWtNfXTmB09pj6iEflt/L6oqDf9ZxXIh4I9MS7A=}
APP_DEBUG=${APP_DEBUG:-false}
APP_URL=${APP_URL:-http://localhost}

#DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE:-anonaddy}
DB_USERNAME=${DB_USERNAME:-anonaddy}
#DB_PASSWORD=${DB_PASSWORD:-asupersecretpassword}
DB_TIMEOUT=${DB_TIMEOUT:-60}

REDIS_HOST=${REDIS_HOST:-null}
REDIS_PASSWORD=${REDIS_PASSWORD:-null}
REDIS_PORT=${REDIS_PORT:-6379}

#PUSHER_APP_ID=${PUSHER_APP_ID}
#PUSHER_APP_KEY=${PUSHER_APP_KEY}
#PUSHER_APP_SECRET=${PUSHER_APP_SECRET}
PUSHER_APP_CLUSTER=${PUSHER_APP_CLUSTER:-mt1}

ANONADDY_RETURN_PATH=${ANONADDY_RETURN_PATH:-null}
ANONADDY_ADMIN_USERNAME=${ANONADDY_ADMIN_USERNAME:-null}
ANONADDY_ENABLE_REGISTRATION=${ANONADDY_ENABLE_REGISTRATION:-true}
#ANONADDY_DOMAIN=${ANONADDY_DOMAIN:-null}
ANONADDY_HOSTNAME=${ANONADDY_HOSTNAME:-null}
ANONADDY_DNS_RESOLVER=${ANONADDY_DNS_RESOLVER:-127.0.0.1}
ANONADDY_ALL_DOMAINS=${ANONADDY_ALL_DOMAINS:-$ANONADDY_DOMAIN}
#ANONADDY_SECRET=${ANONADDY_SECRET:-long-random-string}
ANONADDY_LIMIT=${ANONADDY_LIMIT:-200}
ANONADDY_BANDWIDTH_LIMIT=${ANONADDY_BANDWIDTH_LIMIT:-104857600}
ANONADDY_NEW_ALIAS_LIMIT=${ANONADDY_NEW_ALIAS_LIMIT:-10}
ANONADDY_ADDITIONAL_USERNAME_LIMIT=${ANONADDY_ADDITIONAL_USERNAME_LIMIT:-10}
#ANONADDY_SIGNING_KEY_FINGERPRINT=${ANONADDY_SIGNING_KEY_FINGERPRINT:-your-signing-key-fingerprint}
#ANONADDY_DKIM_SIGNING_KEY=${ANONADDY_DKIM_SIGNING_KEY:-dkim-signing-key}
#ANONADDY_DKIM_SELECTOR=${ANONADDY_DKIM_SELECTOR:-default}

MAIL_FROM_NAME=${MAIL_FROM_NAME:-AnonAddy}
MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS:-anonaddy@${ANONADDY_DOMAIN}}
MAIL_ENCRYPTION=${MAIL_ENCRYPTION:-null}

POSTFIX_DEBUG=${POSTFIX_DEBUG:-false}
POSTFIX_SMTPD_TLS=${POSTFIX_SMTPD_TLS:-false}
POSTFIX_SMTP_TLS=${POSTFIX_SMTP_TLS:-false}
POSTFIX_RELAYHOST_AUTH_ENABLE=${POSTFIX_RELAYHOST_AUTH_ENABLE:-false}
POSTFIX_RELAYHOST_USERNAME=${POSTFIX_RELAYHOST_USERNAME:-null}
POSTFIX_RELAYHOST_PASSWORD=${POSTFIX_RELAYHOST_PASSWORD:-null}

DKIM_ENABLE=${DKIM_ENABLE:-false}
DKIM_PRIVATE_KEY=/data/dkim/${ANONADDY_DOMAIN}.private
DKIM_REPORT_ADDRESS=${DKIM_REPORT_ADDRESS:-postmaster@${ANONADDY_DOMAIN}}

DMARC_ENABLE=${DMARC_ENABLE:-false}
DMARC_FAILURE_REPORTS=${DMARC_FAILURE_REPORTS:-false}
DMARC_MILTER_DEBUG=${DMARC_MILTER_DEBUG:-0}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} >/etc/timezone

# PHP
echo "Init PHP extensions"
cp -Rf /tpls/etc/php8/conf.d /etc/php8

echo "Setting PHP-FPM configuration"
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  -e "s/@CLEAR_ENV@/$CLEAR_ENV/g" \
  /tpls/etc/php8/php-fpm.d/www.conf >/etc/php8/php-fpm.d/www.conf

echo "Setting PHP INI configuration"
sed -i "s|memory_limit.*|memory_limit = ${MEMORY_LIMIT}|g" /etc/php8/php.ini
sed -i "s|;date\.timezone.*|date\.timezone = ${TZ}|g" /etc/php8/php.ini

# OpCache
echo "Setting OpCache configuration"
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php8/conf.d/opcache.ini >/etc/php8/conf.d/opcache.ini

# Nginx
echo "Setting Nginx configuration"
sed -e "s#@UPLOAD_MAX_SIZE@#$UPLOAD_MAX_SIZE#g" \
  -e "s#@REAL_IP_FROM@#$REAL_IP_FROM#g" \
  -e "s#@REAL_IP_HEADER@#$REAL_IP_HEADER#g" \
  -e "s#@LOG_IP_VAR@#$LOG_IP_VAR#g" \
  /tpls/etc/nginx/nginx.conf >/etc/nginx/nginx.conf

if [ "$LISTEN_IPV6" != "true" ]; then
  sed -e '/listen \[::\]:/d' -i /etc/nginx/nginx.conf
fi

echo "Initializing files and folders"
cp -Rf /var/www/anonaddy/storage /data
rm -rf /var/www/anonaddy/storage
ln -sf /data/storage /var/www/anonaddy/storage
chown -h anonaddy. /var/www/anonaddy/storage
chown -R anonaddy. /data/storage
mkdir -p /data/.gnupg
ln -sf /data/.gnupg /var/www/anonaddy/.gnupg
chown -h anonaddy. /var/www/anonaddy/.gnupg
chown -R anonaddy. /data/.gnupg
chmod 700 /data/.gnupg

echo "Checking database connection..."
if [ -z "$DB_HOST" ]; then
  echo >&2 "ERROR: DB_HOST must be defined"
  exit 1
fi
file_env 'DB_USERNAME'
file_env 'DB_PASSWORD'
if [ -z "$DB_PASSWORD" ]; then
  echo >&2 "ERROR: Either DB_PASSWORD or DB_PASSWORD_FILE must be defined"
  exit 1
fi
dbcmd="mysql -h ${DB_HOST} -P ${DB_PORT} -u "${DB_USERNAME}" "-p${DB_PASSWORD}""

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

file_env 'APP_KEY'
if [ -z "$APP_KEY" ]; then
  echo >&2 "ERROR: Either APP_KEY or APP_KEY_FILE must be defined"
  exit 1
fi
if [ -z "$ANONADDY_DOMAIN" ]; then
  echo >&2 "ERROR: ANONADDY_DOMAIN must be defined"
  exit 1
fi
file_env 'ANONADDY_SECRET'
if [ -z "$ANONADDY_SECRET" ]; then
  echo >&2 "ERROR: Either ANONADDY_SECRET or ANONADDY_SECRET_FILE must be defined"
  exit 1
fi
file_env 'PUSHER_APP_SECRET'

echo "Creating AnonAddy env file"
cat >/var/www/anonaddy/.env <<EOL
APP_NAME=${APP_NAME}
APP_ENV=production
APP_KEY=${APP_KEY}
APP_DEBUG=${APP_DEBUG}
APP_URL=${APP_URL}

LOG_CHANNEL=stack

DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

REDIS_CLIENT=phpredis
REDIS_HOST=${REDIS_HOST}
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_PORT=${REDIS_PORT}

MAIL_FROM_NAME=${MAIL_FROM_NAME}
MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS}
MAIL_DRIVER=smtp
MAIL_HOST=127.0.0.1
MAIL_PORT=25
MAIL_ENCRYPTION=${MAIL_ENCRYPTION}

PUSHER_APP_ID=${PUSHER_APP_ID}
PUSHER_APP_KEY=${PUSHER_APP_KEY}
PUSHER_APP_SECRET=${PUSHER_APP_SECRET}
PUSHER_APP_CLUSTER=${PUSHER_APP_CLUSTER}

MIX_PUSHER_APP_KEY="\${PUSHER_APP_KEY}"
MIX_PUSHER_APP_CLUSTER="\${PUSHER_APP_CLUSTER}"

ANONADDY_RETURN_PATH=${ANONADDY_RETURN_PATH}
ANONADDY_ADMIN_USERNAME=${ANONADDY_ADMIN_USERNAME}
ANONADDY_ENABLE_REGISTRATION=${ANONADDY_ENABLE_REGISTRATION}
ANONADDY_DOMAIN=${ANONADDY_DOMAIN}
ANONADDY_HOSTNAME=${ANONADDY_HOSTNAME}
ANONADDY_DNS_RESOLVER=${ANONADDY_DNS_RESOLVER}
ANONADDY_ALL_DOMAINS=${ANONADDY_ALL_DOMAINS}
ANONADDY_SECRET=${ANONADDY_SECRET}
ANONADDY_LIMIT=${ANONADDY_LIMIT}
ANONADDY_BANDWIDTH_LIMIT=${ANONADDY_BANDWIDTH_LIMIT}
ANONADDY_NEW_ALIAS_LIMIT=${ANONADDY_NEW_ALIAS_LIMIT}
ANONADDY_ADDITIONAL_USERNAME_LIMIT=${ANONADDY_ADDITIONAL_USERNAME_LIMIT}
ANONADDY_SIGNING_KEY_FINGERPRINT=${ANONADDY_SIGNING_KEY_FINGERPRINT}
ANONADDY_DKIM_SIGNING_KEY=${ANONADDY_DKIM_SIGNING_KEY}
ANONADDY_DKIM_SELECTOR=${ANONADDY_DKIM_SELECTOR}
EOL
chown anonaddy. /var/www/anonaddy/.env

echo "Trust all proxies"
anonaddy vendor:publish --no-interaction --provider="Fideloper\Proxy\TrustedProxyServiceProvider"
sed -i "s|^    'proxies'.*|    'proxies' => '\*',|g" /var/www/anonaddy/config/trustedproxy.php

if [ "$DKIM_ENABLE" = "true" ] && [ -f "$DKIM_PRIVATE_KEY" ]; then
  echo "Copying OpenDKIM private key"
  mkdir -p /var/db/dkim
  cp -f "${DKIM_PRIVATE_KEY}" "/var/db/dkim/${ANONADDY_DOMAIN}.private"

  echo "Setting OpenDKIM configuration"
  cat >/etc/opendkim/opendkim.conf <<EOL
BaseDirectory         /var/spool/postfix/opendkim

LogWhy                yes
Syslog                yes
SyslogSuccess         yes

Canonicalization      simple
Mode                  sv
SubDomains            yes

KeyTable              refile:/etc/opendkim/key.table
SigningTable          refile:/etc/opendkim/signing.table
RequireSafeKeys       false

ExternalIgnoreList    /etc/opendkim/trusted.hosts
InternalHosts         /etc/opendkim/trusted.hosts

Socket                local:/var/spool/postfix/opendkim/opendkim.sock
UMask                 007
PidFile               /var/spool/postfix/opendkim/opendkim.pid
UserID                opendkim

ReportAddress         ${DKIM_REPORT_ADDRESS}
SendReports           yes
EOL

  echo "Setting OpenDKIM trusted hosts"
  cat >/etc/opendkim/trusted.hosts <<EOL
127.0.0.1
localhost
*.${ANONADDY_DOMAIN}
EOL

  echo "Setting OpenDKIM signing table"
  cat >/etc/opendkim/signing.table <<EOL
*@${ANONADDY_DOMAIN}    default._domainkey.${ANONADDY_DOMAIN}
*@*.${ANONADDY_DOMAIN}    default._domainkey.${ANONADDY_DOMAIN}
EOL

  echo "Setting OpenDKIM key table"
  cat >/etc/opendkim/key.table <<EOL
default._domainkey.${ANONADDY_DOMAIN}    ${ANONADDY_DOMAIN}:default:/var/db/dkim/${ANONADDY_DOMAIN}.private
EOL
fi

if [ "$DMARC_ENABLE" = "true" ]; then
  echo "Setting OpenDMARC configuration"
  cat >/etc/opendmarc/opendmarc.conf <<EOL
BaseDirectory               /var/spool/postfix/opendmarc

AuthservID                  OpenDMARC
TrustedAuthservIDs          mail.${ANONADDY_DOMAIN}

Syslog                      yes
DNSTimeout                  10

FailureReports              ${DMARC_FAILURE_REPORTS}
FailureReportsOnNone        false
FailureReportsSentBy        postmaster@${ANONADDY_DOMAIN}

HistoryFile                 /data/dmarc/opendmarc.dat
RecordAllMessages           false

IgnoreAuthenticatedClients  true

MilterDebug                 ${DMARC_MILTER_DEBUG}

RejectFailures              true
RequiredHeaders             true

Socket                      local:/var/spool/postfix/opendmarc/opendmarc.sock
UMask                       007
PidFile                     /var/spool/postfix/opendmarc/opendmarc.pid
UserID                      opendmarc

SoftwareHeader              true
SPFIgnoreResults            true
SPFSelfValidate             true
EOL
fi

echo "Setting Postfix master configuration"
POSTFIX_DEBUG_ARG=""
if [ "$POSTFIX_DEBUG" = "true" ]; then
  POSTFIX_DEBUG_ARG=" -v"
fi
sed -i "s|^smtp.*inet.*|25 inet n - - - - smtpd${POSTFIX_DEBUG_ARG}|g" /etc/postfix/master.cf
cat >>/etc/postfix/master.cf <<EOL
anonaddy unix - n n - - pipe
  flags=F user=anonaddy argv=php /var/www/anonaddy/artisan anonaddy:receive-email --sender=\${sender} --recipient=\${recipient} --local_part=\${user} --extension=\${extension} --domain=\${domain} --size=\${size}
EOL

echo "Setting Postfix main configuration"
VBOX_DOMAINS=""
IFS=","
for domain in $ANONADDY_ALL_DOMAINS; do
  if [ -n "$VBOX_DOMAINS" ]; then VBOX_DOMAINS="${VBOX_DOMAINS},"; fi
  VBOX_DOMAINS="${VBOX_DOMAINS}${domain},unsubscribe.${domain}"
done
sed -i 's/compatibility_level.*/compatibility_level = 2/g' /etc/postfix/main.cf
sed -i 's/inet_interfaces = localhost/inet_interfaces = all/g' /etc/postfix/main.cf
sed -i 's/readme_directory.*/readme_directory = no/g' /etc/postfix/main.cf
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
    check_recipient_access mysql:/etc/postfix/mysql-recipient-access.cf,
    #check_policy_service unix:private/policyd-spf
    reject_rhsbl_helo dbl.spamhaus.org,
    reject_rhsbl_reverse_client dbl.spamhaus.org,
    reject_rhsbl_sender dbl.spamhaus.org,
    reject_rbl_client zen.spamhaus.org
    reject_rbl_client dul.dnsbl.sorbs.net

# Block clients that speak too early.
smtpd_data_restrictions = reject_unauth_pipelining

disable_vrfy_command = yes
strict_rfc821_envelopes = yes
maillog_file = /dev/stdout
EOL

SMTPD_MILTERS=""
if [ "$DKIM_ENABLE" = "true" ] && [ -f "$DKIM_PRIVATE_KEY" ]; then
  if [ -n "$SMTPD_MILTERS" ]; then SMTPD_MILTERS="${SMTPD_MILTERS},"; fi
  SMTPD_MILTERS="${SMTPD_MILTERS}unix:opendkim/opendkim.sock"
fi
if [ "$DMARC_ENABLE" = "true" ]; then
  if [ -n "$SMTPD_MILTERS" ]; then SMTPD_MILTERS="${SMTPD_MILTERS},"; fi
  SMTPD_MILTERS="${SMTPD_MILTERS}unix:opendmarc/opendmarc.sock"
fi
if [ -n "$SMTPD_MILTERS" ]; then
  echo "Setting Postfix milter configuration"
  cat >>/etc/postfix/main.cf <<EOL

# Milter configuration
milter_default_action = accept
milter_protocol = 6
smtpd_milters = ${SMTPD_MILTERS}
non_smtpd_milters = \$smtpd_milters
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

  cat >>/etc/postfix/sasl_passwd <<EOL

${POSTFIX_RELAYHOST} ${POSTFIX_RELAYHOST_USERNAME}:${POSTFIX_RELAYHOST_PASSWORD}
EOL

  chmod 600 /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd

fi

echo "Creating Postfix virtual alias domains and subdomains configuration"
QUERY_USERS=""
QUERY_USERNAMES=""
IFS=","
for domain in $ANONADDY_ALL_DOMAINS; do
  if [ -n "$QUERY_USERS" ]; then QUERY_USERS="${QUERY_USERS} OR "; fi
  if [ -n "$QUERY_USERNAMES" ]; then QUERY_USERNAMES="${QUERY_USERNAMES} OR "; fi
  QUERY_USERS="${QUERY_USERS}CONCAT(username, '.${domain}') = '%s'"
  QUERY_USERNAMES="${QUERY_USERNAMES}CONCAT(additional_usernames.username, '.${domain}') = '%s'"
done
cat >/etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf <<EOL
user = ${DB_USERNAME}
password = ${DB_PASSWORD}
hosts = ${DB_HOST}:${DB_PORT}
dbname = ${DB_DATABASE}
query = SELECT (SELECT 1 FROM users WHERE ${QUERY_USERS}) AS users, (SELECT 1 FROM additional_usernames WHERE ${QUERY_USERNAMES}) AS usernames, (SELECT 1 FROM domains WHERE domains.domain = '%s' AND domains.domain_verified_at IS NOT NULL) AS domains LIMIT 1;
EOL
chmod o= /etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf
chgrp postfix /etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf

echo "Creating Postfix recipient access configuration"
cat >/etc/postfix/mysql-recipient-access.cf <<EOL
user = ${DB_USERNAME}
password = ${DB_PASSWORD}
hosts = ${DB_HOST}:${DB_PORT}
dbname = ${DB_DATABASE}
query = CALL check_access('%s')
EOL
chmod o= /etc/postfix/mysql-recipient-access.cf
chgrp postfix /etc/postfix/mysql-recipient-access.cf

echo "Checking Postfix hostname"
postconf myhostname

echo "Creating check_access stored procedure"
QUERY_USERNAMES=""
IFS=","
for domain in $ANONADDY_ALL_DOMAINS; do
  if [ -n "$QUERY_USERNAMES" ]; then QUERY_USERNAMES="${QUERY_USERNAMES},"; fi
  QUERY_USERNAMES="${QUERY_USERNAMES}CONCAT(username, '.${domain}')"
done
mysql -h ${DB_HOST} -P ${DB_PORT} -u "${DB_USERNAME}" "-p${DB_PASSWORD}" ${DB_DATABASE} <<EOL
DELIMITER //

DROP PROCEDURE IF EXISTS \`block_alias\`//
DROP PROCEDURE IF EXISTS \`check_access\`//

CREATE PROCEDURE \`check_access\`(alias_email VARCHAR(254) charset utf8)
BEGIN
    DECLARE no_alias_exists int(1);
    DECLARE alias_action varchar(7) charset utf8;
    DECLARE username_action varchar(7) charset utf8;
    DECLARE additional_username_action varchar(7) charset utf8;
    DECLARE domain_action varchar(7) charset utf8;
    DECLARE alias_domain varchar(254) charset utf8;

    SET alias_domain = SUBSTRING_INDEX(alias_email, '@', -1);

    # We only want to carry out the checks if it is a full RCPT TO address without any + extension
    IF LOCATE('+',alias_email) = 0 THEN

        SET no_alias_exists = CASE WHEN NOT EXISTS(SELECT NULL FROM aliases WHERE email = alias_email) THEN 1 ELSE 0 END;

        # If there is an alias, check if it is deactivated or deleted
        IF NOT no_alias_exists THEN
            SET alias_action = (SELECT
                IF(deleted_at IS NULL,
                'DISCARD',
                'REJECT')
            FROM
                aliases
            WHERE
                email = alias_email
                AND (active = 0
                OR deleted_at IS NOT NULL));
        END IF;

        # If the alias is deactivated or deleted then increment its blocked count and return the alias_action
        IF alias_action IN('DISCARD','REJECT') THEN
            UPDATE
                aliases
            SET
                emails_blocked = emails_blocked + 1
            WHERE
                email = alias_email;

            SELECT alias_action;
        ELSE
            SELECT
            (
            SELECT
                CASE
                    WHEN no_alias_exists
                    AND catch_all = 0 THEN "REJECT"
                    ELSE NULL
                END
            FROM
                users
            WHERE
                alias_domain IN (${QUERY_USERNAMES}) ) AS users,
            (
            SELECT
                CASE
                    WHEN no_alias_exists
                    AND catch_all = 0 THEN "REJECT"
                    WHEN active = 0 THEN "DISCARD"
                    ELSE NULL
                END
            FROM
                additional_usernames
            WHERE
                alias_domain IN (${QUERY_USERNAMES}) ) AS usernames,
            (
            SELECT
                CASE
                    WHEN no_alias_exists
                    AND catch_all = 0 THEN "REJECT"
                    WHEN active = 0 THEN "DISCARD"
                    ELSE NULL
                END
            FROM
                domains
            WHERE
                domain = alias_domain) INTO username_action, additional_username_action, domain_action;

            # If all actions are NULL then we can return 'DUNNO' which will prevent Postfix from trying substrings of the alias
            IF username_action IS NULL AND additional_username_action IS NULL AND domain_action IS NULL THEN
                SELECT 'DUNNO';
            ELSEIF username_action IN('DISCARD','REJECT') THEN
                SELECT username_action;
            ELSEIF additional_username_action IN('DISCARD','REJECT') THEN
                SELECT additional_username_action;
            ELSE
                SELECT domain_action;
            END IF;
        END IF;
    ELSE
        # This means the alias must have a + extension so we will ignore it
        SELECT NULL;
    END IF;
 END//

DELIMITER ;
EOL
