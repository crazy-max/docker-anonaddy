#!/usr/bin/with-contenv sh
# shellcheck shell=sh

# Unset sensitive vars
unset APP_KEY \
  DB_USERNAME \
  DB_PASSWORD \
  REDIS_PASSWORD \
  PUSHER_APP_SECRET \
  ANONADDY_SECRET \
  ANONADDY_SIGNING_KEY_FINGERPRINT
