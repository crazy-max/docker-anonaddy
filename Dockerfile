# syntax=docker/dockerfile:1

ARG ANONADDY_VERSION=1.3.0
ARG ALPINE_VERSION=3.18

FROM crazymax/yasu:latest AS yasu
FROM crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3

COPY --from=yasu / /
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
    php82 \
    php82-cli \
    php82-ctype \
    php82-curl \
    php82-dom \
    php82-fileinfo \
    php82-fpm \
    php82-gd \
    php82-gmp \
    php82-iconv \
    php82-intl \
    php82-json \
    php82-mbstring \
    php82-opcache \
    php82-openssl \
    php82-pdo \
    php82-pdo_mysql \
    php82-pecl-imagick \
    php82-phar \
    php82-redis \
    php82-session \
    php82-simplexml \
    php82-sodium \
    php82-tokenizer \
    php82-xml \
    php82-xmlreader \
    php82-xmlwriter \
    php82-zip \
    php82-zlib \
    postfix \
    postfix-mysql \
    rspamd \
    rspamd-controller \
    rspamd-proxy \
    shadow \
    tar \
    tzdata \
    cyrus-sasl \
    cyrus-sasl-login \
  && ln -s /usr/bin/php82 /usr/bin/php \
  && cp /etc/postfix/master.cf /etc/postfix/master.cf.orig \
  && cp /etc/postfix/main.cf /etc/postfix/main.cf.orig \
  && apk --no-cache add -t build-dependencies \
    autoconf \
    automake \
    build-base \
    gpgme-dev \
    libtool \
    pcre-dev \
    php82-dev \
    php82-pear \
  && pecl82 install gnupg \
  && echo "extension=gnupg.so" > /etc/php82/conf.d/60_gnupg.ini \
  && pecl82 install mailparse \
  && echo "extension=mailparse.so" > /etc/php82/conf.d/60_mailparse.ini \
  && apk del build-dependencies \
  && rm -rf /tmp/* /var/www/*

ARG ANONADDY_VERSION
ENV ANONADDY_VERSION=$ANONADDY_VERSION \
  S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  SOCKLOG_TIMESTAMP_FORMAT="" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

WORKDIR /var/www/anonaddy
RUN apk --no-cache add -t build-dependencies \
    git \
    nodejs \
    npm \
  && node --version \
  && npm --version \
  && addgroup -g ${PGID} anonaddy \
  && adduser -D -h /var/www/anonaddy -u ${PUID} -G anonaddy -s /bin/sh -D anonaddy \
  && addgroup anonaddy mail \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && git config --global --add safe.directory /var/www/anonaddy \
  && git init . && git remote add origin "https://github.com/anonaddy/anonaddy.git" \
  && git fetch --depth 1 origin "v${ANONADDY_VERSION}" && git checkout -q FETCH_HEAD \
  && composer install --optimize-autoloader --no-dev --no-interaction --no-ansi --ignore-platform-req=php-64bit \
  && chown -R anonaddy. /var/www/anonaddy \
  && npm ci --ignore-scripts \
  && APP_URL=https://addy-sh.test npm run production \
  && npm prune --production \
  && chown -R nobody.nogroup /var/www/anonaddy \
  && apk del build-dependencies \
  && rm -rf /root/.composer \
    /root/.config \
    /root/.npm \
    /var/www/anonaddy/.git \
    /var/www/anonaddy/node_modules \
    /tmp/*

COPY rootfs /

EXPOSE 25 8000 11334
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
