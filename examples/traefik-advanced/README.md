This is a strongly opinionated AnonAddy Docker + Traefik config template that provides *some* production quality features.
**Note** that you must further tweak the configuration and then run Docker in Swarm mode to ensure e.g. encrypted network traffic and scaling for *serious* production usage.
You should also use something like Hashicorp Vault to protect any secrets as Docker secret files are still stored in plain text on the filesystem as well as disable root user access in containers.

## Features
 - Automatic creation of ACME SSL Wildcard Certificates using DNS Challenge resolver
 - [Tecnativa's Docker Socket Proxy](https://github.com/Tecnativa/docker-socket-proxy) (reduce risk of Docker socket exposure)
 - Automatic Postfix TLS management using [traefik-certs-dumper](https://github.com/kereis/traefik-certs-dumper)
   - Auto-dumping of Let's Encrypt certificates to Postfix cert directory
   - Watch & restart AnonAddy container on certificate renewal
 - Hardened TLS cipher configuration
 - [Watchtower](https://github.com/containrrr/watchtower) for automatic AnonAddy container updates upon new release
 - CrowdSec with Traefik bouncer for SPAM detection and mitigation. Please refer to the  
   [CrowdSec documentation](https://docs.crowdsec.net/docs/getting_started/install_crowdsec) for initial setup instructions.
 - Enabled Rspamd and exposed Web UI (also covered by CrowdSec bouncer) at [https://**spam**.example.com](https://spam.example.com)

**Note**: This configuration does not ensure true Zero Downtime re-deploys!

## Usage

Make sure you have followed the steps described [here](https://github.com/anonaddy/docker#generate-dkim-privatepublic-keypair) to generate a DKIM keypair.  
Use these files for full SMTP(D) TLS/ DKIM/ DMARC/ PGP signing functionalities.  

```bash
mkdir letsencrypt
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json
docker-compose up -d
docker-compose logs -f
```

You will also need to create secret files containing the DNS Challenge provider credentials. For more information, please refer to the [Traefik Docs](https://doc.traefik.io/traefik/https/acme/#providers).
