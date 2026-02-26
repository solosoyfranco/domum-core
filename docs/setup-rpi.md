# domum-core: Raspberry Pi Host (SSD Boot)


# 0) SSD Boot Setup

## 0.1 Enable USB Boot (if starting from SD card)

Boot with SD card once, then:

    sudo raspi-config

Advanced Options → Boot Order → USB Boot

Reboot.

---

## 0.2 Enable Higher USB Current (if SSD boot instability)

Edit:

    sudo nano /boot/firmware/config.txt

Add:

    usb_max_current_enable=1

Reboot.

This prevents SSD power dips during kernel load.

---

## 0.3 Update EEPROM and Set Boot Order

Check:

    sudo rpi-eeprom-update
    sudo rpi-eeprom-config

If update available:

    sudo rpi-eeprom-update -a
    sudo reboot

Set USB first boot order:

    sudo rpi-eeprom-config --edit

Set:

    [all]
    BOOT_ORDER=0xf41

Reboot and verify:

    sudo rpi-eeprom-config | grep BOOT_ORDER

---

## 0.4 Fresh Install to SSD (Recommended)

Using Raspberry Pi Imager:

- OS: Raspberry Pi OS Lite (64-bit)
- Storage: SSD
- Advanced settings:
  - Hostname: domum-core
  - Enable SSH (prefer public key auth)
  - Set username/password
  - Timezone: America/New_York

Boot from SSD and verify:

    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    findmnt /

Root (/) should be on SSD (sda2).

---

# 1) Base OS Setup

Update system:

    sudo apt update
    sudo apt full-upgrade -y
    sudo apt autoremove -y
    sudo reboot

Fix locale if needed:

    sudo apt install -y locales
    sudo locale-gen
    sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    sudo reboot

---

# 2) Security Baseline

## 2.1 SSH Hardening

Edit:

    sudo nano /etc/ssh/sshd_config

Ensure:

    PermitRootLogin no
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PubkeyAuthentication yes

Restart:

    sudo systemctl restart ssh

---

## 2.2 Firewall (UFW)

    sudo apt install -y ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow OpenSSH
    sudo ufw enable
    sudo ufw status verbose

---

## 2.3 Fail2ban

    sudo apt install -y fail2ban
    sudo systemctl enable --now fail2ban

Optional jail override:

    sudo nano /etc/fail2ban/jail.d/sshd.local

    [sshd]
    enabled = true
    bantime = 1h
    findtime = 10m
    maxretry = 5

Restart:

    sudo systemctl restart fail2ban

---

## 2.4 Automatic Updates

    sudo apt install -y unattended-upgrades
    sudo dpkg-reconfigure unattended-upgrades

---

# 3) Docker Installation (Official Repo)

Remove old packages:

    sudo apt remove -y docker docker.io containerd runc || true

Install prerequisites:

    sudo apt update
    sudo apt install -y ca-certificates curl gnupg

Add Docker repo:

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian     $(. /etc/os-release && echo $VERSION_CODENAME) stable" |     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

Install Docker:

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

Add user to docker group:

    sudo usermod -aG docker $USER
    newgrp docker

Test:

    docker version
    docker compose version
    docker run --rm hello-world

---

# 4) Docker Reliability Settings

Create daemon.json:

    sudo nano /etc/docker/daemon.json

Use:

{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

Restart Docker:

    sudo systemctl restart docker

---

# 5) Recommended Directory Structure

Use /srv for persistent data:

    sudo mkdir -p /srv/data
    sudo mkdir -p /srv/backups
    sudo chown -R $USER:$USER /srv/data /srv/backups

Persistent container data:

    /srv/data/<service>

Backups:

    /srv/backups

---

# 6) Git Setup

Set identity:

    git config --global user.name "Franco Lopez"
    git config --global user.email "jfranco8@outlook.com"

Prefer SSH authentication for GitHub.

Test:

    ssh -T git@github.com

Switch remote:

    git remote set-url origin git@github.com:solosoyfranco/domum-core.git

---

# 7) Backup Strategy (restic)

Install:

    sudo apt install -y restic

Initialize:

    mkdir -p /srv/backups/restic
    export RESTIC_REPOSITORY=/srv/backups/restic
    export RESTIC_PASSWORD='CHANGE_THIS'
    restic init

Backup:

    restic backup /srv/data /etc /home/$USER/domum-core

Automate via cron at 2:30am.

---

# 8) Quick Cheat Sheet

Docker:

    docker ps
    docker logs <container>
    docker compose up -d
    docker compose down

System:

    sudo apt update && sudo apt full-upgrade -y
    sudo systemctl status docker
    sudo ufw status

Git:

    git status
    git add -A
    git commit -m "msg"
    git push



