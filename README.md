<p align="center"><a href="https://github.com/anonaddy/docker" target="_blank"><img height="128" src="https://raw.githubusercontent.com/anonaddy/docker/master/.github/docker-anonaddy.jpg"></a></p>

<p align="center">
  <a href="https://hub.docker.com/r/anonaddy/anonaddy/tags?page=1&ordering=last_updated"><img src="https://img.shields.io/github/v/tag/anonaddy/docker?label=version&style=flat-square" alt="Latest Version"></a>
  <a href="https://github.com/anonaddy/docker/actions?workflow=build"><img src="https://img.shields.io/github/workflow/status/anonaddy/docker/build?label=build&logo=github&style=flat-square" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/anonaddy/anonaddy/"><img src="https://img.shields.io/docker/stars/anonaddy/anonaddy.svg?style=flat-square&logo=docker" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/anonaddy/anonaddy/"><img src="https://img.shields.io/docker/pulls/anonaddy/anonaddy.svg?style=flat-square&logo=docker" alt="Docker Pulls"></a>
  <br /><a href="https://github.com/sponsors/crazy-max"><img src="https://img.shields.io/badge/sponsor-crazy--max-181717.svg?logo=github&style=flat-square" alt="Become a sponsor"></a>
  <a href="https://www.paypal.me/crazyws"><img src="https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal&style=flat-square" alt="Donate Paypal"></a>
</p>

## About

[AnonAddy](https://anonaddy.com/) Docker image based on Alpine Linux.<br />
If you are interested, [check out](https://hub.docker.com/r/crazymax/) my other Docker images!

💡 Want to be notified of new releases? Check out 🔔 [Diun (Docker Image Update Notifier)](https://github.com/crazy-max/diun) project!

___

* [Features](#features)
* [Build locally](#build-locally)
* [Image](#Image)
* [Environment variables](#environment-variables)
  * [General](#general)
  * [App](#app)
  * [AnonAddy](#anonaddy)
  * [Database](#database)
  * [Redis](#redis)
  * [Mail](#mail)
  * [Postfix](#postfix)
  * [DKIM](#dkim)
  * [DMARC](#dmarc)
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
* [Contributing](#contributing)
* [License](#license)

## Features

* Run as non-root user
* Multi-platform image
* [s6-overlay](https://github.com/just-containers/s6-overlay/) as process supervisor
* [Traefik](https://github.com/containous/traefik-library-image) as reverse proxy and creation/renewal of Let's Encrypt certificates (see [this template](examples/traefik))

## Build locally

```shell
git clone https://github.com/anonaddy/docker.git docker-anonaddy
cd docker-anonaddy

# Build image and output to docker (default)
docker buildx bake

# Build multi-platform image
docker buildx bake image-all
```

## Image

Following platforms for this image are available:

```
$ docker run --rm mplatform/mquery anonaddy/anonaddy:latest
Image: anonaddy/anonaddy:latest
 * Manifest List: Yes
 * Supported platforms:
   - linux/amd64
   - linux/arm/v6
   - linux/arm/v7
   - linux/arm64
```

## Environment variables

### General

* `TZ`: The timezone assigned to the container (default `UTC`)
* `PUID`: AnonAddy user id (default `1000`)
* `PGID`: AnonAddy group id (default `1000`)
* `MEMORY_LIMIT`: PHP memory limit (default `256M`)
* `UPLOAD_MAX_SIZE`: Upload max size (default `16M`)
* `CLEAR_ENV`: Clear environment in FPM workers (default `yes`)
* `OPCACHE_MEM_SIZE`: PHP OpCache memory consumption (default `128`)
* `LISTEN_IPV6`: Enable IPv6 for Nginx (default `true`)
* `REAL_IP_FROM`: Trusted addresses that are known to send correct replacement addresses (default `0.0.0.0/32`)
* `REAL_IP_HEADER`: Request header field whose value will be used to replace the client address (default `X-Forwarded-For`)
* `LOG_IP_VAR`: Use another variable to retrieve the remote IP address for access [log_format](http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format) on Nginx. (default `remote_addr`)

### App

* `APP_NAME`: Name of the application (default `AnonAddy`)
* `APP_KEY`: Application key for encrypter service. You can generate one through `anonaddy key:generate --show` or `echo "base64:$(openssl rand -base64 32)"`. **required**
* `APP_DEBUG`: Enables or disables debug mode, used to troubleshoot issues (default `false`)
* `APP_URL`: The URL of your AnonAddy installation

> 💡 `APP_KEY_FILE` can be used to fill in the value from a file, especially for Docker's secrets feature.

### AnonAddy

* `ANONADDY_RETURN_PATH`: Return-path header for outbound emails
* `ANONADDY_ADMIN_USERNAME`: If set this value will be used and allow you to receive forwarded emails at the root domain
* `ANONADDY_ENABLE_REGISTRATION`: If set to false this will prevent new users from registering on the site (default `true`)
* `ANONADDY_DOMAIN`: Root domain to receive email from **required**
* `ANONADDY_HOSTNAME`: FQDN hostname for your server used to validate records on custom domains that are added by users
* `ANONADDY_DNS_RESOLVER`: Custom domains that are added by users to validate records (default `127.0.0.1`)
* `ANONADDY_ALL_DOMAINS`: Other domains to use
* `ANONADDY_SECRET`: Long random string used when hashing data for the anonymous replies **required**
* `ANONADDY_LIMIT`: Number of emails a user can forward and reply per hour (default `200`)
* `ANONADDY_BANDWIDTH_LIMIT`: Monthly bandwidth limit for users in bytes domains to use (default `104857600`)
* `ANONADDY_NEW_ALIAS_LIMIT`: Number of new aliases a user can create each hour (default `10`)
* `ANONADDY_ADDITIONAL_USERNAME_LIMIT`: Number of additional usernames a user can add to their account (default `10`)
* `ANONADDY_DKIM_SIGNING_KEY`: Path to the private DKIM signing key to be used to sign emails for custom domains.
* `ANONADDY_DKIM_SELECTOR`: Selector for the current DKIM signing key (default `default`)

> 💡 `ANONADDY_SECRET_FILE` can be used to fill in the value from a file, especially for Docker's secrets feature.

### Database

* `DB_HOST`: MySQL database hostname / IP address **required**
* `DB_PORT`: MySQL database port (default `3306`)
* `DB_DATABASE`: MySQL database name (default `anonaddy`)
* `DB_USERNAME`: MySQL user (default `anonaddy`)
* `DB_PASSWORD`: MySQL password
* `DB_TIMEOUT`: Time in seconds after which we stop trying to reach the MySQL server (useful for clusters, default `60`)

> 💡 `DB_USERNAME_FILE` and `DB_PASSWORD_FILE` can be used to fill in the value from a file, especially for Docker's
> secrets feature.

### Redis

* `REDIS_HOST`: Redis hostname / IP address
* `REDIS_PORT`: Redis port (default `6379`)
* `REDIS_PASSWORD`: Redis password

### Mail

* `MAIL_FROM_NAME`: From name (default `AnonAddy`)
* `MAIL_FROM_ADDRESS`: From email address (default `anonaddy@${ANONADDY_DOMAIN}`)
* `MAIL_ENCRYPTION`: Encryption protocol to send e-mail messages (default `null`)

### Postfix

* `POSTFIX_DEBUG`: Enable debug (default `false`)
* `POSTFIX_SMTPD_TLS`: Enabling TLS in the Postfix SMTP server (default `false`)
* `POSTFIX_SMTPD_TLS_CERT_FILE`: File with the Postfix SMTP server RSA certificate in PEM format
* `POSTFIX_SMTPD_TLS_KEY_FILE`: File with the Postfix SMTP server RSA private key in PEM format
* `POSTFIX_SMTP_TLS`: Enabling TLS in the Postfix SMTP client (default `false`)
* `POSTFIX_RELAYHOST`: Default host to send mail to
* `POSTFIX_RELAYHOST_AUTH_ENABLE`: Enable client-side authentication for relayhost (default `false`)
* `POSTFIX_RELAYHOST_USERNAME`: Postfix SMTP Client username for relayhost authentication
* `POSTFIX_RELAYHOST_PASSWORD`: Postfix SMTP Client password for relayhost authentication

### DKIM

* `DKIM_ENABLE`: Enable OpenDKIM service. (default `false`)
* `DKIM_REPORT_ADDRESS`: Specifies the string to use in the `From:` header field for outgoing reports (default `postmaster@${ANONADDY_DOMAIN}`)

> :warning: DKIM private key must be located in `/data/dkim/${ANONADDY_DOMAIN}.private`. You can generate a DKIM
> private/public keypair by following [this note](#generate-dkim-privatepublic-keypair).

> :warning: OpenDKIM service is disabled if DKIM private key is not found

### DMARC

* `DMARC_ENABLE`: Enable OpenDMARC service. (default `false`)
* `DMARC_FAILURE_REPORTS`: Enables generation of failure reports when the DMARC test fails (default `false`)
* `DMARC_MILTER_DEBUG`: Sets the debug level to be requested from the milter library (default `0`)

## Volumes

* `/data`: Contains storage

> :warning: Note that the volume should be owned by the user/group with the specified `PUID` and `PGID`. If you don't
> give the volume correct permissions, the container may not start.

## Ports

* `8000`: HTTP port
* `25`: SMTP port (postfix)

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. You can use the following
[docker compose template](examples/compose/docker-compose.yml), then run the container:

```bash
docker-compose up -d
docker-compose logs -f
```

## Upgrade

You can upgrade AnonAddy automatically through the UI, it works well. But I recommend to recreate the container
whenever I push an update:

```bash
docker-compose pull
docker-compose up -d
```

## Notes

### `anonaddy` command

If you want to use the artisan command to perform common server operations like manage users, passwords and more, type:

```bash
docker-compose exec anonaddy anonaddy <command>
```

For example to list all available commands:

```bash
docker-compose exec anonaddy anonaddy list
```

### Create user

```shell
docker-compose exec anonaddy anonaddy anonaddy:create-user "username" "webmaster@example.com"
```

### Generate DKIM private/public keypair

```shell
docker-compose run --entrypoint '' anonaddy gen-dkim
```
```text
opendkim-genkey: generating private key
opendkim-genkey: private key written to example.com.private
opendkim-genkey: extracting public key
opendkim-genkey: DNS TXT record written to example.com.txt
```

The keypair will be available in `/data/dkim`.

### Generate GPG key

If you don't have an existing GPG key, you can generate a new GPG key with the following command:

```shell
docker-compose exec --user anonaddy anonaddy gpg --full-gen-key
```

Keys will be stored in `/data/.gnupg` folder.

## Contributing

Want to contribute? Awesome! The most basic way to show your support is to star the project, or to raise issues. You
can also support this project by [**becoming a sponsor on GitHub**](https://github.com/sponsors/crazy-max) or by making
a [Paypal donation](https://www.paypal.me/crazyws) to ensure this journey continues indefinitely!

Thanks again for your support, it is much appreciated! :pray:

## License

MIT. See `LICENSE` for more details.
