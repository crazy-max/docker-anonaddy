<p align="center"><a href="https://github.com/anonaddy/docker" target="_blank"><img height="128" src="https://raw.githubusercontent.com/anonaddy/docker/master/.github/docker-anonaddy.jpg"></a></p>

<p align="center">
  <a href="https://hub.docker.com/r/anonaddy/anonaddy/tags?page=1&ordering=last_updated"><img src="https://img.shields.io/github/v/tag/anonaddy/docker?label=version&style=flat-square" alt="Latest Version"></a>
  <a href="https://github.com/anonaddy/docker/actions?workflow=build"><img src="https://img.shields.io/github/actions/workflow/status/anonaddy/docker/build.yml?branch=master&label=build&logo=github&style=flat-square" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/anonaddy/anonaddy/"><img src="https://img.shields.io/docker/stars/anonaddy/anonaddy.svg?style=flat-square&logo=docker" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/anonaddy/anonaddy/"><img src="https://img.shields.io/docker/pulls/anonaddy/anonaddy.svg?style=flat-square&logo=docker" alt="Docker Pulls"></a>
  <br /><a href="https://github.com/sponsors/crazy-max"><img src="https://img.shields.io/badge/sponsor-crazy--max-181717.svg?logo=github&style=flat-square" alt="Become a sponsor"></a>
  <a href="https://www.paypal.me/crazyws"><img src="https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal&style=flat-square" alt="Donate Paypal"></a>
</p>

## About

Docker image for [addy.io](https://addy.io/), an anonymous email forwarding service. 

> [!TIP]
> Want to be notified of new releases? Check out 🔔 [Diun (Docker Image Update Notifier)](https://github.com/crazy-max/diun)
> project!

___

* [Features](#features)
* [Build locally](#build-locally)
* [Image](#Image)
* [Environment variables](#environment-variables)
  * [General](#general)
  * [App](#app)
  * [Database](#database)
  * [Redis](#redis)
  * [Mail](#mail)
  * [Postfix](#postfix)
  * [RSPAMD](#rspamd)
* [Volumes](#volumes)
* [Ports](#ports)
* [Usage](#usage)
  * [Docker Compose](#docker-compose)
* [Upgrade](#upgrade)
* [Notes](#notes)
  * [`anonaddy` command](#anonaddy-command)
  * [Create user](#create-user)
  * [Generate DKIM private/public keypair](#generate-dkim-privatepublic-keypair)
  * [Generate GPG key](#generate-gpg-key)
  * [Define additional env vars](#define-additional-env-vars)
  * [Override Postfix main configuration](#override-postfix-main-configuration)
  * [Spamhaus DQS configuration](#spamhaus-dqs-configuration)
* [Contributing](#contributing)
* [License](#license)

## Features

* Run as non-root user
* Multi-platform image
* [s6-overlay](https://github.com/just-containers/s6-overlay/) as process supervisor
* [Traefik](https://github.com/containous/traefik-library-image) as reverse proxy and creation/renewal of Let's Encrypt certificates (see [this template](examples/traefik))

## Build locally

```console
git clone https://github.com/anonaddy/docker.git docker-addy
cd docker-addy

# Build image and output to docker (default)
docker buildx bake

# Build multi-platform image
docker buildx bake image-all
```

## Image

Following platforms for this image are available:

```
$ docker buildx imagetools inspect anonaddy/anonaddy --format "{{json .Manifest}}" | \
  jq -r '.manifests[] | select(.platform.os != null and .platform.os != "unknown") | .platform | "\(.os)/\(.architecture)\(if .variant then "/" + .variant else "" end)"'

linux/amd64
linux/arm/v6
linux/arm/v7
linux/arm64
```

## Environment variables

### General

* `TZ`: The timezone assigned to the container (default `UTC`)
* `PUID`: user id (default `1000`)
* `PGID`: group id (default `1000`)
* `MEMORY_LIMIT`: PHP memory limit (default `256M`)
* `UPLOAD_MAX_SIZE`: Upload max size (default `16M`)
* `CLEAR_ENV`: Clear environment in FPM workers (default `yes`)
* `OPCACHE_MEM_SIZE`: PHP OpCache memory consumption (default `128`)
* `LISTEN_IPV6`: Enable IPv6 for Nginx and Postfix (default `true`)
* `REAL_IP_FROM`: Trusted addresses that are known to send correct replacement addresses (default `0.0.0.0/32`)
* `REAL_IP_HEADER`: Request header field whose value will be used to replace the client address (default `X-Forwarded-For`)
* `LOG_IP_VAR`: Use another variable to retrieve the remote IP address for access [log_format](http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format) on Nginx. (default `remote_addr`)
* `LOG_CROND`: Enable crond logging. (default `true`)

### App

* `APP_NAME`: Name of the application (default `addy.io`)
* `APP_KEY`: Application key for encrypter service. You can generate one through `anonaddy key:generate --show` or `echo "base64:$(openssl rand -base64 32)"`. **required**
* `APP_DEBUG`: Enables or disables debug mode, used to troubleshoot issues (default `false`)
* `APP_URL`: The URL of your installation
* `ANONADDY_RETURN_PATH`: Return-path header for outbound emails
* `ANONADDY_ADMIN_USERNAME`: If set this value will be used and allow you to receive forwarded emails at the root domain
* `ANONADDY_NON_ADMIN_SHARED_DOMAINS`: If set to false this will prevent any non-admin users from being able to create shared domain aliases at any domains that have been set for `$ANONADDY_ALL_DOMAINS` (default `true`)
* `ANONADDY_ENABLE_REGISTRATION`: If set to false this will prevent new users from registering on the site (default `true`)
* `ANONADDY_DOMAIN`: Root domain to receive email from **required**
* `ANONADDY_HOSTNAME`: FQDN hostname for your server used to validate records on custom domains that are added by users
* `ANONADDY_DNS_RESOLVER`: Custom domains that are added by users to validate records (default `127.0.0.1`)
* `ANONADDY_ALL_DOMAINS`: If you would like to have other domains to use (e.g. `@username.example2.com`), set a comma separated list like so, `example.com,example2.com` (default `$ANONADDY_DOMAIN`)
* `ANONADDY_SECRET`: Long random string used when hashing data for the anonymous replies **required**
* `ANONADDY_LIMIT`: Number of emails a user can forward and reply per hour (default `200`)
* `ANONADDY_BANDWIDTH_LIMIT`: Monthly bandwidth limit for users in bytes domains to use (default `104857600`)
* `ANONADDY_NEW_ALIAS_LIMIT`: Number of new aliases a user can create each hour (default `10`)
* `ANONADDY_ADDITIONAL_USERNAME_LIMIT`: Number of additional usernames a user can add to their account (default `10`)
* `ANONADDY_SIGNING_KEY_FINGERPRINT`: GPG key used to sign forwarded emails. Should be the same as your mail from email address
* `ANONADDY_DKIM_SIGNING_KEY`: Path to the private DKIM signing key to be used to sign emails for custom domains.
* `ANONADDY_DKIM_SELECTOR`: Selector for the current DKIM signing key (default `default`)

> [!NOTE]
> `APP_KEY_FILE`, `ANONADDY_SECRET_FILE` and `ANONADDY_SIGNING_KEY_FINGERPRINT_FILE`
> can be used to fill in the value from a file, especially for Docker's secrets
> feature.

### Database

* `DB_HOST`: MySQL database hostname / IP address **required**
* `DB_PORT`: MySQL database port (default `3306`)
* `DB_DATABASE`: MySQL database name (default `anonaddy`)
* `DB_USERNAME`: MySQL user (default `anonaddy`)
* `DB_PASSWORD`: MySQL password
* `DB_TIMEOUT`: Time in seconds after which we stop trying to reach the MySQL server (useful for clusters, default `60`)

> [!NOTE]
> `DB_USERNAME_FILE` and `DB_PASSWORD_FILE` can be used to fill in the value
> from a file, especially for Docker's secrets feature.

### Redis

* `REDIS_HOST`: Redis hostname / IP address
* `REDIS_PORT`: Redis port (default `6379`)
* `REDIS_PASSWORD`: Redis password

> [!NOTE]
> `REDIS_PASSWORD_FILE` can be used to fill in the value from a file, especially
> for Docker's secrets feature.

### Mail

* `MAIL_FROM_NAME`: From name (default `addy.io`)
* `MAIL_FROM_ADDRESS`: From email address (default `addy@${ANONADDY_DOMAIN}`)
* `MAIL_ENCRYPTION`: Encryption protocol to send e-mail messages (default `null`)

### Postfix

* `POSTFIX_DEBUG`: Enable debug (default `false`)
* `POSTFIX_MESSAGE_SIZE_LIMIT`: The maximal size in bytes of a message, including envelope information (default `26214400`)
* `POSTFIX_SMTPD_TLS`: Enabling TLS in the Postfix SMTP server (default `false`)
* `POSTFIX_SMTPD_TLS_CERT_FILE`: File with the Postfix SMTP server RSA certificate in PEM format
* `POSTFIX_SMTPD_TLS_KEY_FILE`: File with the Postfix SMTP server RSA private key in PEM format
* `POSTFIX_SMTP_TLS`: Enabling TLS in the Postfix SMTP client (default `false`)
* `POSTFIX_RELAYHOST`: Default host to send mail to
* `POSTFIX_RELAYHOST_AUTH_ENABLE`: Enable client-side authentication for relayhost (default `false`)
* `POSTFIX_RELAYHOST_USERNAME`: Postfix SMTP Client username for relayhost authentication
* `POSTFIX_RELAYHOST_PASSWORD`: Postfix SMTP Client password for relayhost authentication
* `POSTFIX_SPAMHAUS_DQS_KEY`: Personal key for [Spamhaus DQS](#spamhaus-dqs-configuration)

> [!NOTE]
> `POSTFIX_RELAYHOST_USERNAME_FILE` and `POSTFIX_RELAYHOST_PASSWORD_FILE` can be
> used to fill in the value from a file, especially for Docker's secrets feature.

### RSPAMD

* `RSPAMD_ENABLE`: Enable Rspamd service. (default `false`)
* `RSPAMD_WEB_PASSWORD`: Rspamd web password (default `null`)
* `RSPAMD_NO_LOCAL_ADDRS`: Disable Rspamd local networks (default `false`)

> [!NOTE]
> `RSPAMD_WEB_PASSWORD_FILE` can be used to fill in the value from a file,
> especially for Docker's secrets feature.

> [!WARNING]
> DKIM private key must be located in `/data/dkim/${ANONADDY_DOMAIN}.private`.
> You can generate a DKIM private/public keypair by following [this note](#generate-dkim-privatepublic-keypair).

> [!WARNING]
> Rspamd service is disabled if DKIM private key is not found

> [!WARNING]
> Rspamd service needs to be enabled for the reply anonymously feature to work.  
> See [#169](https://github.com/anonaddy/docker/issues/169#issuecomment-1232577449) for more details.


## Volumes

* `/data`: Contains storage

> [!WARNING]
> Note that the volume should be owned by the user/group with the specified
> `PUID` and `PGID`. If you don't give the volume correct permissions, the
> container may not start.

## Ports

* `8000`: HTTP port (addy.io)
* `11334`: HTTP port (rspamd web dashboard)
* `25`: SMTP port (postfix)

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. You can use the following
[docker compose template](examples/compose/compose.yml), then run the container:

```console
docker compose up -d
docker compose logs -f
```

## Upgrade

```console
docker compose pull
docker compose up -d
```

## Notes

### `anonaddy` command

If you want to use the artisan command to perform common server operations like
manage users, passwords and more, type:

```console
docker compose exec addy anonaddy <command>
```

For example to list all available commands:

```console
docker compose exec addy anonaddy list
```

### Create user

```console
docker compose exec addy anonaddy anonaddy:create-user "username" "webmaster@example.com"
```

### Generate DKIM private/public keypair

```console
docker compose run --entrypoint '' addy gen-dkim
```

```text
generating private and storing in data/dkim/example.com.private
generating DNS TXT record with public key and storing it in data/dkim/example.com.txt

default._domainkey IN TXT ( "v=DKIM1; k=rsa; "
        "p=***"
        "***"
) ;
```

The keypair will be available in `/data/dkim`.

### Generate GPG key

If you don't have an existing GPG key, you can generate a new GPG key with the
following command:

```console
docker compose exec --user anonaddy addy gpg --full-gen-key
```

Keys will be stored in `/data/.gnupg` folder.

### Define additional env vars

You can define additional environment variables that will be used by the app
by creating a file named `.env` in `/data`.

### Override Postfix main configuration

In some cases you may want to override the default Postfix main configuration
to fit your infrastructure. To do so, you can create a file named
`postfix-main.alt.cf` in `/data` and it will be used instead of the generated
configuration. **Use at your own risk**.

> [!WARNING]
> Container has to be restarted to propagate changes

### Spamhaus DQS configuration

If a public DNS resolver is used, it may be blocked by Spamhaus and return a
'non-existent domain' (NXDOMAIN), and soon will start to return an error code:

```text
Aug  3 10:15:40 mail01 postfix/smtpd[23645]: NOQUEUE: reject: RCPT from sender.example.com[xx.xx.xx.xx]: 554 5.7.1 Service unavailable;
Client host [xx.xx.xx.xx] blocked using zen.spamhaus.org; Error: open resolver; https://www.spamhaus.org/returnc/pub/162.158.148.77;
from=<sender@example.com> to=<recipient@example.com> proto=ESMTP helo=<icinga2.infiniroot.net>
```

To fix this issue, you can register a DQS key [here](https://www.spamhaustech.com/dqs/)
and complete the registration procedure. After you register an account, you can find the DQS key in the "Access" section of
[this page](https://portal.spamhaustech.com/dqs/).

## Contributing

Want to contribute? Awesome! The most basic way to show your support is to star
the project, or to raise issues. You can also support this project by [**becoming a sponsor on GitHub**](https://github.com/sponsors/crazy-max)
or by making a [PayPal donation](https://www.paypal.me/crazyws) to ensure this
journey continues indefinitely!

Thanks again for your support, it is much appreciated! :pray:

## License

MIT. See `LICENSE` for more details.
