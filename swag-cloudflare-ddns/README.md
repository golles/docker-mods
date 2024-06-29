# CloudFlare DDNS - Docker mod for SWAG

This mod gives SWAG the ability to update your DNS configuration on CloudFlare making your swag act as a DDNS server.

In SWAG docker arguments, set an environment variable `DOCKER_MODS=golles/docker-mods:swag-cloudflare-ddns`

If adding multiple mods, enter them in an array separated by `|`, such as `DOCKER_MODS=linuxserver/mods:universal-cron|golles/docker-mods:swag-cloudflare-ddns`

## Mod usage instructions

The configuration file gets placed in your persistent data, at `/config/ddns/cloudflare.ini`

Set your zone and record information, all 4 values are required

The mod adds the script to the container cron (`/config/crontabs/root`), configured to run every minute, you can manually adjust this interval if you like.
