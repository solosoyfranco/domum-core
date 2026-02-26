# Adding a New Service


## Step 1 — Create a Compose Fragment

Create a new compose file inside the appropriate category:

    compose/<category>/<service-name>.yml

Example:

    compose/automation/frigate.yml

Keep it focused. Do not redefine global networks or shared configuration already defined in compose/base.yml.

Example skeleton:

```yaml
services:
  frigate:
    image: ghcr.io/blakeblackshear/frigate:stable
    container_name: frigate
    restart: unless-stopped
    networks:
      - domum-proxy
      - domum-internal
    volumes:
      - ${DOMUM_DIR}/data/frigate:/config
```


---

## Step 2 — Add a Toggle

Edit your host config:

    /etc/domum/domum.conf

Add:

    ENABLE_FRIGATE=1

If optional by default, keep it disabled in repo config:

    ENABLE_FRIGATE=0

---

## Step 3 — Register the Service in bin/domum

Inside compose_files_for_enabled_services(), add:

```bash
if [[ "${ENABLE_FRIGATE:-0}" == "1" ]]; then
  files+=("$DOMUM_DIR/compose/automation/frigate.yml")
fi
```

Ensure the path matches exactly.

---

## Step 4 — Optional: Add Profiles

If the service should only run at night or under a specific profile:

```yaml
profiles:
  - night
```

Enable the profile in domum.conf:

    ENABLE_NIGHT_PROFILE=1

---

## Step 5 — Apply Changes

Run:

    curl -fsSL https://raw.githubusercontent.com/solosoyfranco/domum-core/main/install.sh | sudo bash

The system will:

- Pull latest repo
- Detect toggle
- Start container
- Remove orphaned containers if necessary

---

## Step 6 — Expose via Traefik (Optional)

If the service needs a public hostname:

1. Add Traefik labels in the compose file
2. Create LAN DNS record in UniFi
3. Configure Tailscale split DNS if remote access is required

---

# Best Practices

- One service per compose fragment
- No hardcoded IPs
- Use ${DOMUM_DIR}/data/<service> for storage
- Use existing Docker networks
- Keep secrets in /etc/domum-core/secrets
- Never edit files directly in /opt/domum-core

---

# Service Lifecycle

Add service → Add toggle → Commit → Push → Run curl → Done.

