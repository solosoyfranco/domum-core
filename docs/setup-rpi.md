# domum-core: Raspberry Pi Host (SSD Boot)

This document defines the canonical Raspberry Pi SSD-based Docker host setup for domum-core.

# 0) SSD Boot Setup

## 0.1 Enable USB Boot
```
    sudo raspi-config
```
Advanced Options → Boot Order → USB Boot

---

## 0.2 Enable Higher USB Current

Edit:
```
    sudo nano /boot/firmware/config.txt
```

Add:
```
    usb_max_current_enable=1
```

Reboot.

---
## 0.3 Update EEPROM and Boot Order
```
    sudo rpi-eeprom-update
    sudo rpi-eeprom-config
```
Set:
```
    [all]
    BOOT_ORDER=0xf41
```
---
# 1) Base OS Setup
```
    sudo apt update
    sudo apt full-upgrade -y
    sudo apt autoremove -y
    sudo reboot
```
---
# 2) Security Baseline

## SSH
```
    sudo nano /etc/ssh/sshd_config
```
Ensure:
```
    PermitRootLogin no
    PasswordAuthentication no
    PubkeyAuthentication yes
```
Restart:
```
    sudo systemctl restart ssh
```
---
## Firewall

```
    sudo apt install -y ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow OpenSSH
    sudo ufw allow 9090/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw enable
```

---

## Fail2ban
```
    sudo apt install -y fail2ban
    sudo systemctl enable --now fail2ban
```

---
# 3) Docker Install (Official Repo)

Remove old packages:
```

    sudo apt remove -y docker docker.io containerd runc || true
```

Install Docker from official repository.

Add user to docker group:
```

    sudo usermod -aG docker $USER
    newgrp docker
```

Test:
```

    docker version
    docker compose version
```

---
# 4) Docker Log Limits

Create:
```

    sudo nano /etc/docker/daemon.json
```

Use:
```

{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Restart:
```

    sudo systemctl restart docker
```

---
# 5) Recommended Directory Structure

Persistent container data:
```

    /opt/domum-core/data
```

Local backup mirror:
```

    /home/jfranco/backups/domum-core/data
```

---
# 6) Backup Strategy (rsync Mirror + Cron)

We use a simple local mirror backup with rsync.

Create backup directory:
```

    mkdir -p ~/backups/domum-core/data
```

Manual backup:
```

    rsync -aHAX --delete       /opt/domum-core/data/       /home/jfranco/backups/domum-core/data/
```

Explanation:
- -a = archive
- -HAX = preserve hardlinks, ACLs, xattrs
- --delete = mirror exactly

---
## Automate with Cron

Edit crontab:
```

    crontab -e
```

Add daily backup at 2:00 AM:
```

    0 2 * * * rsync -aHAX --delete /opt/domum-core/data/ /home/jfranco/backups/domum-core/data/ >> /home/jfranco/backups/backup.log 2>&1
```

---
# 7) Future NAS Sync

Later you can sync to NAS:
```

    rsync -aHAX --delete       /home/jfranco/backups/domum-core/data/       user@nas:/mnt/backups/rpi/domum-core/data/
```

This creates:

Layer 1: Live data
Layer 2: Local mirror
Layer 3: NAS mirror

---
# 8) Quick Commands

Docker:
```

    docker ps
    docker logs <container>
```

System:
```

    sudo apt update && sudo apt full-upgrade -y
    sudo systemctl status docker
    sudo ufw status
```

Git:
```

    git status
    git add -A
    git commit -m "msg"
    git push
```
---
# Make Your User a sudo User

If your user is not already in the sudo group, run:
```bash
sudo usermod -aG docker jfranco
newgrp docker


```


Then log out completely and log back in.

Verify:
```

    groups
```

You should see `sudo` listed.

If sudo still does not work:
```

    sudo visudo
```

Ensure this line exists and is NOT commented:
```

    %sudo   ALL=(ALL:ALL) ALL
```

---
# Fix Ownership of backups Directory

If backups was created by root:
```

    sudo chown -R jfranco:jfranco /home/jfranco/backups
```

Verify:
```

    ls -ld ~/backups
```

Owner should now be jfranco.

---

