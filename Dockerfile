# syntax=docker/dockerfile:1

ARG ANONADDY_VERSION=1.3.0
ARG ALPINE_VERSION=3.21

FROM --platform=$BUILDPLATFORM scratch AS src
ARG ANONADDY_VERSION
ADD "https://github.com/anonaddy/anonaddy.git#v${ANONADDY_VERSION}" .

FROM crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3 AS base
COPY --from=crazymax/yasu:latest / /
RUN apk --no-cache add \
    bash \
    ca-certificates \
    curl \
    gnupg \
    gpgme \
    imagemagick \
    libgd \
    mysql-client \
    nginx \
    openssl \
    php83 \
    php83-cli \
    php83-ctype \
    php83-curl \
    php83-dom \
    php83-fileinfo \
    php83-fpm \
    php83-gd \
    php83-gmp \
    php83-iconv \
    php83-intl \
    php83-json \
    php83-mbstring \
    php83-opcache \
    php83-openssl \
    php83-pdo \
    php83-pdo_mysql \
    php83-pecl-imagick \
    php83-phar \
    php83-redis \
    php83-session \
    php83-simplexml \
    php83-sodium \
    php83-tokenizer \
    php83-xml \
    php83-xmlreader \
    php83-xmlwriter \
    php83-zip \
    php83-zlib \
    postfix \
    postfix-mysql \
    rspamd \
    rspamd-controller \
    rspamd-proxy \
    shadow \
    tar \
    tzdata \
  && cp /etc/postfix/master.cf /etc/postfix/master.cf.orig \
  && cp /etc/postfix/main.cf /etc/postfix/main.cf.orig \
  && apk --no-cache add -t build-dependencies \
    autoconf \
    automake \
    build-base \
    gpgme-dev \
    libtool \
    pcre-dev \
    php83-dev \
    php83-pear \
  && pecl83 install gnupg \
  && echo "extension=gnupg.so" > /etc/php83/conf.d/60_gnupg.ini \
  && pecl83 install mailparse \
  && echo "extension=mailparse.so" > /etc/php83/conf.d/60_mailparse.ini \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && apk del build-dependencies \
  && rm -rf /tmp/* /var/www/*

FROM base AS build
RUN apk --no-cache add nodejs npm
WORKDIR /var/www/anonaddy
COPY --from=src / .
ARG ANONADDY_VERSION
RUN <<EOT
  set -ex
  composer install --optimize-autoloader --no-dev --no-interaction --no-ansi --ignore-platform-req=php-64bit
  npm ci --ignore-scripts --verbose
  APP_URL=https://addy-sh.test npm run production
  npm prune --production
  rm -rf /var/www/anonaddy/node_modules
  chown -R nobody:nogroup /var/www/anonaddy
EOT

FROM base
COPY --from=build /var/www/anonaddy /var/www/anonaddy
ARG ANONADDY_VERSION
ENV ANONADDY_VERSION=$ANONADDY_VERSION \
  S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  SOCKLOG_TIMESTAMP_FORMAT="" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"
RUN addgroup -g ${PGID} anonaddy \
  && adduser -D -h /var/www/anonaddy -u ${PUID} -G anonaddy -s /bin/sh -D anonaddy \
  && addgroup anonaddy mail
COPY rootfs /

EXPOSE 25 8000 11334
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
