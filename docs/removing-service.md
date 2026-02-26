# Removing a Service


## Step 1 — Disable the Toggle

Edit:

    /opt/domum-core/domum.conf

Set the service to 0:

    ENABLE_FRIGATE=0

---

## Step 2 — Converge State

Run:

    curl -fsSL https://raw.githubusercontent.com/solosoyfranco/domum-core/main/install.sh | sudo bash

Docker Compose will:

- Stop the container
- Remove orphaned containers
- Leave persistent volumes intact

---

## Step 3 — Optional: Remove Data

If you want to delete stored data:

    sudo rm -rf /opt/domum-core/data/frigate

Only do this if you are sure you do not need the data.

---

## Step 4 — Optional: Remove Compose Fragment

Delete the compose fragment from the repo:

    compose/automation/frigate.yml

Remove the toggle logic from bin/domum if permanently removing support.

Commit → Push → Run curl again.

---

# Clean Removal Lifecycle

Disable → Curl → Verify → Remove Data (optional) → Done.

