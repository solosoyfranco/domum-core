# IoT VLAN Tagging and go2rtc

# 1. Network Architecture Overview

Example network layout:

  Network   Purpose                      Subnet
  --------- ---------------------------- --------------
  VLAN 10   Services / Servers           10.0.10.0/24
  VLAN 50   IoT Devices (cameras etc.)   10.0.50.0/24

Host machine (Raspberry Pi):

- Native network: **VLAN10**
- Tagged network: **VLAN50**

Example IP assignments:

  Interface   VLAN     IP
  ----------- -------- -----------
  end0        VLAN10   10.0.10.2
  end0.50     VLAN50   10.0.50.2

This makes the host appear **directly on the IoT VLAN at Layer‑2**,
allowing containers to communicate with IoT devices without routing
tricks.

------------------------------------------------------------------------

# 2. Creating the VLAN Interface on Linux

Use **NetworkManager (nmcli)** or your system network UI.

Example CLI configuration:

``` bash
sudo nmcli connection add type vlan   con-name vlan50   ifname end0.50   dev end0   id 50   ip4 10.0.50.2/24   gw4 10.0.50.1

sudo nmcli connection up vlan50
```

Verify:

``` bash
ip addr show end0.50
```

You should see:

    end0.50: 10.0.50.2/24

------------------------------------------------------------------------

# 3. Docker Network for VLAN50

To allow containers to appear on the IoT VLAN, create a **macvlan or
ipvlan** network.

Example macvlan network:

``` bash
docker network create -d macvlan   --subnet=10.0.50.0/24   --gateway=10.0.50.1   -o parent=end0.50   iot_vlan50
```

Containers attached to this network will receive **real IP addresses on
VLAN50**.

------------------------------------------------------------------------

# 4. go2rtc Configuration File

Create:

/etc/domum-core/secrets/go2rtc/go2rtc.yaml

Example configuration:

``` yaml
api:
  listen: ":1984"

rtsp:
  listen: ":8554"

streams:

  front_porch:
    - rtsp://USER:PASSWORD@10.0.50.121/live?tcp

  driveway:
    - rtsp://USER:PASSWORD@10.0.50.137/live?tcp

webrtc:
  listen: ":8555"
  candidates:
    - 10.0.50.3
```

------------------------------------------------------------------------

# 7. Starting go2rtc

Start container:

``` bash
docker compose up -d go2rtc
```

Web interface:

http://10.0.50.3:1984

RTSP restream:

rtsp://10.0.50.3:8554/front_porch

------------------------------------------------------------------------

# 8. Home Assistant Example

Example HA camera entry:

rtsp://10.0.50.3:8554/front_porch

This avoids opening multiple RTSP sessions to the camera.

------------------------------------------------------------------------

# 9. Troubleshooting

Camera unreachable:

    ping 10.0.50.X

Verify VLAN interface:

    ip addr show end0.50

Check Docker network:

    docker network inspect iot_vlan50

View go2rtc logs:

    docker logs -f go2rtc

