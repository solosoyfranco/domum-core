# domum-core

Home core services using Docker Compose.

- Simple toggles: enable/disable services in one config file.
- Simple scheduling: optional systemd timers for "night-only" profiles (no extra schedulers inside containers).

- A small script that:
  - installs dependencies (Docker + Compose plugin) when needed
  - deploys services based on config toggles
  - updates services when the repo changes
  - optionally sets up night-only schedules

---

## Quick start (new host)

On the Raspberry Pi (or Debian/Ubuntu server):

```bash
curl -fsSL https://raw.githubusercontent.com/solosoyfranco/domum-core/main/install.sh | sudo bash
```

Then:

```bash
sudo domum init
sudo domum apply
```

If you want night-only scheduling:

```bash
sudo domum schedule install
```

---

## How toggles work

All toggles live in:

- `config/domum.conf` (shell variables)

Examples:
- Turn a service on: set `ENABLE_HOME_ASSISTANT=1`
- Turn it off: set `ENABLE_HOME_ASSISTANT=0`

Night-only services:
- Put a service into the `night` profile in its Compose file
- Set `ENABLE_NIGHT_PROFILE=1` and configure times in `config/domum.conf`

---

## TLS and DNS (Cloudflare)

This starter uses Traefik with ACME DNS-01 via Cloudflare so you can get valid certificates without opening ports.

You will need a Cloudflare API token with:
- Zone:DNS:Edit for your zone (example: ladomum.com)

Put the token in:
- `/opt/domum-core/secrets/cloudflare_api_token`

Or export it before apply:
- `export CF_DNS_API_TOKEN="..."`

---

## Internal name resolution (LAN + Tailscale)

Traefik can serve `ha.ladomum.com`, `z2m.ladomum.com`, etc, but your clients must resolve those names to the Traefik IP.

Common options:
- LAN: run a local DNS (Unifi, AdGuard Home or Pi-hole) and create records for `*.ladomum.com` -> Traefik LAN IP
- Tailscale: use Tailscale DNS settings to resolve `*.ladomum.com` to the Traefik Tailscale IP (or use MagicDNS + split DNS)


---

## Project layout

- `install.sh`  
  One-liner bootstrap that installs prerequisites and places `domum` in `/usr/local/bin`.

- `bin/domum`  
  Main CLI.
  - `domum init`
  - `domum apply`
  - `domum status`
  - `domum schedule install|remove`

- `config/domum.conf`  
  Your toggles and host-specific values.

- `compose/`  
  Compose fragments per service.

- `secrets/`  
  Not committed. Put tokens and passwords here on the host.

---

## Workflow

1) Edit config locally in git:
- `config/domum.conf`
- service compose files in `compose/`

2) Commit and push.

3) On the host:
```bash
sudo domum update
sudo domum apply
```

---

## Testing on a spare server

On any Debian/Ubuntu VM:
- run the install command
- enable only a small set of services (Traefik + uptime-kuma)
- confirm you can reach `status.ladomum.com` from a client that resolves it to the host IP

---

## Notes
- Hard-resetting to origin/main is fine as long as you never edit files directly in /opt/domum-core. You should treat /opt/domum-core as deployed code.
- In Tailscale admin console, configure split DNS for ladomum.com to use your LAN DNS (UCG) or another resolver that can answer those names.
	- Then your phone/laptop on Tailscale resolves ha.ladomum.com even when away.
