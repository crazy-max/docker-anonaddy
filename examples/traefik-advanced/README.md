## Features
 - Automatic creation of ACME SSL Wildcard Certificates using DNS Challenge resolver
 - [Tecnativa's Docker Socket Proxy](https://github.com/Tecnativa/docker-socket-proxy) (minimize risk of Docker socket exposure)
 - Automatic Postfix TLS management using [traefik-certs-dumper](https://github.com/kereis/traefik-certs-dumper)
   - Auto-dumping of Let's Encrypt certificates to Postfix cert directory
   - Watch & restart AnonAddy container on certificate renewal

**Note**: Does not ensure Zero Downtime deployment!

## Usage

Use these files for full SMTP(D) TLS/ DKIM/ DMARC/ PGP signing functionalities. \

```bash
mkdir letsencrypt
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json
docker-compose up -d
docker-compose logs -f
```

You will also need to create secret files containing the DNS Challenge provider credentials. For more information, please refer to the [Traefik Docs](https://doc.traefik.io/traefik/https/acme/#providers).
