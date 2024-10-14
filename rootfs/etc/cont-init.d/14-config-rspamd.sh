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
if [ -z "$ANONADDY_DKIM_SELECTOR" ]; then
  export ANONADDY_DKIM_SELECTOR="default"
  echo "INFO: DKIM selector not set, using default."
fi

echo "Copying DKIM private key for Rspamd"
mkdir -p /var/lib/rspamd/dkim
cp -f "${DKIM_PRIVATE_KEY}" "/var/lib/rspamd/dkim/${ANONADDY_DOMAIN}.${ANONADDY_DKIM_SELECTOR}.key"

echo "Setting Rspamd dkim_signing.conf"
cat >/etc/rspamd/local.d/dkim_signing.conf <<EOL
signing_table = [
"*@${ANONADDY_DOMAIN} ${ANONADDY_DOMAIN}",
"*@*.${ANONADDY_DOMAIN} ${ANONADDY_DOMAIN}",
];

key_table = [
"${ANONADDY_DOMAIN} ${ANONADDY_DOMAIN}:${ANONADDY_DKIM_SELECTOR}:/var/lib/rspamd/dkim/${ANONADDY_DOMAIN}.${ANONADDY_DKIM_SELECTOR}.key",
];

use_domain = "envelope";
allow_hdrfrom_mismatch = true;
allow_hdrfrom_mismatch_sign_networks = true;
allow_username_mismatch = true;
use_esld = true;
sign_authenticated = false;
EOL

echo "Setting Rspamd arc.conf"
cp /etc/rspamd/local.d/dkim_signing.conf /etc/rspamd/local.d/arc.conf

echo "Setting Rspamd classifier-bayes.conf"
cat >/etc/rspamd/local.d/classifier-bayes.conf <<EOL
backend = "redis";
EOL

echo "Setting Rspamd logging.inc"
cat >/etc/rspamd/local.d/logging.inc <<EOL
level = "error";
debug_modules = [];
EOL

if [ -n "$REDIS_HOST" ]; then
  echo "Setting Rspamd redis.conf"
  cat >/etc/rspamd/local.d/redis.conf <<EOL
write_servers = "${REDIS_HOST}";
password = "${REDIS_PASSWORD}";
read_servers = "${REDIS_HOST}";
EOL

  echo "Setting Rspamd greylist.conf"
  cat >/etc/rspamd/local.d/greylist.conf <<EOL
servers = "${REDIS_HOST}:${REDIS_PORT}";
EOL

  echo "Setting Rspamd history_redis.conf"
  cat >/etc/rspamd/local.d/history_redis.conf <<EOL
subject_privacy = true;
EOL
fi

echo "Setting Rspamd groups.conf"
cat >/etc/rspamd/local.d/groups.conf <<EOL
group "headers" {
  symbols {
    "FAKE_REPLY" {
      weight = 0.0;
    }

    "FROM_NEQ_DISPLAY_NAME" {
      weight = 0.0;
    }

    "FORGED_RECIPIENTS" {
      weight = 0.0;
    }
  }
}
EOL

if [ -n "$RSPAMD_WEB_PASSWORD" ]; then
  echo "Setting Rspamd worker-controller.inc"
  cat >/etc/rspamd/local.d/worker-controller.inc <<EOL
bind_socket = "*:11334";
secure_ip = "127.0.0.1/32";
password = "${RSPAMD_WEB_PASSWORD}";
enable_password = "${RSPAMD_WEB_PASSWORD}";
EOL
fi

echo "Setting Rspamd dmarc.conf"
cat >/etc/rspamd/local.d/dmarc.conf <<EOL
actions = {
  quarantine = "add_header";
  reject = "reject";
}
EOL

echo "Setting Rspamd milter_headers.conf"
cat >/etc/rspamd/local.d/milter_headers.conf <<EOL
use = ["authentication-results", "remove-headers", "spam-header", "add_dmarc_allow_header"];

routines {
  remove-headers {
    headers {
      "X-Spam" = 0;
      "X-Spamd-Bar" = 0;
      "X-Spam-Level" = 0;
      "X-Spam-Status" = 0;
      "X-Spam-Flag" = 0;
    }
  }
  authentication-results {
    header = "X-AnonAddy-Authentication-Results";
    remove = 0;
  }
  spam-header {
    header = "X-AnonAddy-Spam";
    value = "Yes";
    remove = 0;
  }
}

custom {
  add_dmarc_allow_header = <<EOD
return function(task, common_meta)
  if task:has_symbol('DMARC_POLICY_ALLOW') then
    return nil,
    {['X-AnonAddy-Dmarc-Allow'] = 'Yes'},
    {['X-AnonAddy-Dmarc-Allow'] = 0},
    {}
  end

  return nil,
  {},
  {['X-AnonAddy-Dmarc-Allow'] = 0},
  {}
end
EOD;
}
EOL

if [ "$RSPAMD_NO_LOCAL_ADDRS" = "true" ]; then
  echo "Disabling Rspamd local networks"
  # Empty the local_addrs array to avoid having Rspamd skip DMARC and SPF checks
  # if the mailserver is running in a local network. Required since it checks
  # the headers injected by Rspamd. See https://github.com/anonaddy/docker/issues/192#issuecomment-1518111988
  sed -i 's/local_addrs.*$/local_addrs=[]/' /etc/rspamd/options.inc
fi

echo "Disabling a variety of Rspamd modules"
echo "enabled = false;" > /etc/rspamd/override.d/fuzzy_check.conf
echo "enabled = false;" > /etc/rspamd/override.d/asn.conf
echo "enabled = false;" > /etc/rspamd/override.d/metadata_exporter.conf
echo "enabled = false;" > /etc/rspamd/override.d/trie.conf
echo "enabled = false;" > /etc/rspamd/override.d/neural.conf
echo "enabled = false;" > /etc/rspamd/override.d/chartable.conf
echo "enabled = false;" > /etc/rspamd/override.d/ratelimit.conf
echo "enabled = false;" > /etc/rspamd/override.d/replies.conf
