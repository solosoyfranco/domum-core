# Coral TPU Troubleshooting (Frigate / Raspberry Pi)
---
# 1. Verify Coral is detected by the OS

Check if the Coral appears on the USB bus.

``` bash
lsusb
```

Expected working output usually shows:

    18d1:9302 Google Inc.

or

    1a6e:089a Global Unichip Corp.

If nothing appears, the Coral is not detected.

Check USB topology:

``` bash
lsusb -t
```

Example:

    Bus 003 Device 002: ID 1a6e:089a Global Unichip Corp.

------------------------------------------------------------------------

# 2. Check kernel logs

This shows USB initialization errors.

``` bash
dmesg -T | grep -i -E "usb|coral|edgetpu|apex|1a6e|18d1"
```

Healthy messages usually look like:

    usb 3-1: New USB device found
    usb 3-1: Product: Google Coral Edge TPU

If you see resets or failures:

- try a different USB port
- try a different cable
- avoid USB hubs

------------------------------------------------------------------------

# 3. Verify Frigate sees the Coral

Check container logs:

``` bash
docker logs frigate | grep -i -E "tpu|edgetpu|coral"
```

Healthy output:

    frigate.detectors.plugins.edgetpu_tfl INFO : Attempting to load TPU as usb

Failure example:

    No EdgeTPU was detected
    Failed to load delegate from libedgetpu.so.1.0

If this happens:

- verify the Coral appears in `lsusb`
- verify Docker USB mapping

------------------------------------------------------------------------

# 4. Confirm Docker has access to USB

Frigate container should include:

``` yaml
devices:
  - /dev/bus/usb:/dev/bus/usb
privileged: true
```

Optional but recommended:

``` yaml
group_add:
  - "plugdev"
```

------------------------------------------------------------------------

# 5. Check device permissions

List device nodes:

``` bash
ls -l /dev/bus/usb/*/*
```

Example:

    crw-rw---- 1 root plugdev 189, 257 /dev/bus/usb/003/002

Ensure the device belongs to **plugdev**.

------------------------------------------------------------------------

# 6. Install Coral UDEV rules

Create rule file:

``` bash
sudo nano /etc/udev/rules.d/99-coral.rules
```

Add:

    SUBSYSTEM=="usb", ATTRS{{idVendor}}=="1a6e", GROUP="plugdev", MODE="0660"
    SUBSYSTEM=="usb", ATTRS{{idVendor}}=="18d1", GROUP="plugdev", MODE="0660"

Reload rules:

``` bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Unplug and replug the Coral.

------------------------------------------------------------------------

# 7. Raspberry Pi 5 compatibility fix

Some Raspberry Pi 5 kernels require enabling DMA compatibility.

Edit config:

``` bash
sudo nano /boot/firmware/config.txt
```

Add:

    dtoverlay=pciex1-compat-pi5,no-mip
    dtoverlay=pcie-32bit-dma-pi5

Reboot:

``` bash
sudo reboot
```

------------------------------------------------------------------------

# 8. Temporary fallback: CPU detector

If the Coral is unavailable, switch Frigate to CPU detection
temporarily.

``` yaml
detectors:
  cpu1:
    type: cpu
    num_threads: 3
```

------------------------------------------------------------------------

# 9. Restart Frigate

``` bash
docker restart frigate
```

or

``` bash
docker compose restart frigate
```

------------------------------------------------------------------------

# 10. Quick health check

``` bash
echo "---- USB ----"; lsusb | grep -E "1a6e|18d1"; echo "---- Docker ----"; docker logs frigate | grep -i edgetpu | tail -5
```

------------------------------------------------------------------------

# Healthy Coral Checklist

- Appears in `lsusb`
- Appears in `lsusb -t`
- No USB errors in `dmesg`
- Frigate logs show `Attempting to load TPU`
- Frigate container remains running

