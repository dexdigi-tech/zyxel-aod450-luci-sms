# Zyxel AOD450ZY (Airtel 5G CPE) — Full OpenWrt LuCI + SMS, Cellular & Signal Suite

[![OpenWrt](https://img.shields.io/badge/OpenWrt-21.02.7-blue.svg)](https://openwrt.org)
[![Architecture](https://img.shields.io/badge/Arch-aarch64%20(Cortex--A55%2FA53)-green.svg)](https://openwrt.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Complete offline installation bundle and guide to enable the **full OpenWrt 21.02.7 LuCI Web UI**, interactive **Telephony -> SMS** manager (send, receive, drafts, inbox/outbox), live **Cellular Network, Band, Signal & Modem Details** page with **Antenna Alignment Helper**, and a persistent **2-second DHCP Watchdog** on the **Zyxel AOD450ZY** (Airtel 5G Outdoor Unit / CPE) — without disturbing the stock Airtel/Zyxel Web UI.

---

## Features

### 1. Full OpenWrt 21.02.7 LuCI Web Interface (`uhttpd` on port `4153`)
* Runs alongside the stock Airtel/Zyxel Web UI (`:80` / `:443`) with zero port conflicts.
* **Status**: Overview, Firewall, Routes, System Log, Kernel Log (`dmesg`), Processes, Realtime Graphs.
* **System**: System Properties, Administration/Password, SSH Access & Keys, Startup, Scheduled Tasks, LEDs, Flash/Backup, Software (`opkg`), Reboot.
* **Network**: Interfaces, DHCP & DNS, Hostnames, Static Routes, Diagnostics (`ping`, `traceroute`, `nslookup`).
* **Telephony**: Stock MediaTek/Zyxel Telephony Overview + new **SMS** + new **Cellular & Signal** status pages.

### 2. Cellular & Signal Status (`/cgi-bin/luci/admin/telephony/cellular`)
* **Real-time RF Signal Quality Gauge**:
  * 4-bar visual signal indicator with dynamic color grading (**Excellent**, **Good**, **Fair**, **Poor**).
  * Direct numeric metrics: **RSRP** (dBm), **RSRQ** (dB), **SINR** (dB), **RSSI** (dBm), **Primary Band**, **Bandwidth**, **PCI**, and **eNB ID / Sector**.
* **Serving Cells & Carrier Aggregation (CA) Table**:
  * Displays Primary Serving Cell (**PCell**) and Secondary Cells (**SCells**) for 4G LTE-A and 5G NR.
  * Columns: Cell Type, RAT mode, Band (`B1`, `B3`, `B40`, `n78`), Bandwidth (`10MHz`, `15MHz`, `20MHz`, `100MHz`), EARFCN/ARFCN, PCI, Cell ID (ECI Hex & Decimal), eNB ID, Sector, TAC, RSRP, RSRQ, SINR, and Status.
* **Per-Antenna RF Chains (Directional Antenna Alignment Helper)**:
  * Live telemetry for all 4 internal directional antennas (**RX0 Main**, **RX1 Diversity**, **RX2 MIMO 1**, **RX3 MIMO 2**) via `AT+EDMFAPP=6,9`.
  * Visual progress bars for RSRP (-140 dBm to -60 dBm), RSRQ, RSSI, and SINR.
  * Essential for positioning and aiming the outdoor unit for optimal 4G/5G signal reception!
* **SIM Card & Registration Details**:
  * Status (`Ready / Inserted`), SIM State (`Active`), PIN State (`Unlocked`), PIN1/PIN2 & PUK1/PUK2 remaining attempt counters (`AT+EPINC?`).
  * Operator (`airtel`), PLMN (`404-10`), IMSI (`AT+CIMI`), ICCID (`AT+CCID`), Network Registration State (`Home Network`), and Configured RAT Mode.
* **Modem & Hardware Details**:
  * Manufacturer (`Quectel`), Modem Model (`RG500L-AR`), Firmware Revision (`AT+CGMR`), Platform SoC (`MediaTek T750 / MT6890 5G`), IMEI, IMEI SVN, and Channel Interface (`MIPC / /dev/ttyUSB2`).
  * **21 Thermal Sensors (`AT+QTEMP`)**: Live temperatures for SoC Max, CPU Little cores 0–3, GPUs, DRAM, Modem 5G/4G/3G, RF NTC, NR PA NTC, LTE PA NTC, and PMIC.
  * System info: Device Model (`Zyxel AOD450ZY`), Hostname (`AOD450`), Kernel (`Linux 5.4 aarch64`), OpenWrt release, Uptime, and RAM usage.
* **Active WAN & Data Call Session**:
  * Status (`Connected / Active`), Network Interface (`ccmni1`), APN Profile (`airtelgprs.com`), PDP Type (`IPv4`), IPv4 Address / Subnet Mask, Default Gateway, Primary & Secondary DNS, MTU, and TX/RX byte counters.
* **Diagnostics & Raw AT Response Drawer**:
  * Collapsible drawer displaying raw output of `AT+ECELL`, `AT+EDMFAPP=6,4`, `AT+EDMFAPP=6,9`, `AT+EDMFAPP=6,10`, `AT+CESQ`, `AT+CSQ`, `AT+QTEMP`, and `mipc_wan_cli --data_call_get`.
* **JSON API Endpoint (`/cgi-bin/luci/admin/telephony/cellular_info`)**:
  * Fast (~30ms) REST endpoint returning structured JSON for custom dashboards, Home Assistant, or monitoring scripts.

### 3. Telephony -> SMS Page (`/cgi-bin/luci/admin/telephony/sms`)
* **Send & Save Drafts**: Compose SMS up to 160 characters with live character counter (`smscmd send` / `smscmd save`).
* **Incoming SMS Support**: Decodes both standard `"PduContent"` and incoming `"PduContent000"`+ (multi-part & `\uXXXX` Unicode escapes) from `/xdata/SMS/Inbox/` and auto-converts `/xdata/SMS/sms_new.txt`.
* **Full Management**: Tabbed views (**Inbox**, **Sent**, **Drafts**, **All**), **Unread** counter badge, **Reply**, **Load Draft**, **Mark Read / Unread**, **Delete**, and **Auto-refresh (15s)**.
* **Modem Diagnostics**: Displays SIM SMS storage slots (`AT+CPMS?`) and SMSC center (`AT+CSCA?`).
* **Security**: Enforces LuCI CSRF `token` validation (`test_post_security()`), strict filename allowlisting, input validation, XSS-safe DOM rendering (`textContent`), and shell-free process execution (`luci.sys.process.exec`).

### 4. Persistent 2-Second DHCP Watchdog (`/etc/init.d/dhcp-watchdog`)
* Resolves the 4–5 minute DHCP IP delay when Bridge Mode is disabled (where `/usr/bin/hachi` only polls `udhcpd` every 300s after boot or Ethernet link flaps).
* Automatically checks every 2 seconds and restarts `/usr/sbin/udhcpd` when `bridge_mode_control` is `0` and DHCP Server is enabled, while staying inactive if Bridge Mode is turned back on.

### 5. Persistent ADB & USB Tethering (RNDIS) Service (`/etc/init.d/adbd`)
* **Network ADB (`0.0.0.0:5555`)**:
  * Persistent procd-managed `adbd_usb` service listening on port `5555`.
  * Instant root shell access without password prompts (`adb shell`).
  * High-speed file transfer (`adb push` / `adb pull`) bypassing SFTP limitations.
  * Port forwarding (`adb forward`) to reach LuCI (`:4153`) or Airtel GUI (`:80`) even during network maintenance.
* **USB Tethering (RNDIS / USB Ethernet)**:
  * Automatically configures Linux USB ConfigFS composite gadget (`11201000.usb` MediaTek MTU3 SuperSpeed 5Gbps controller).
  * Creates `rndis0` network interface and bridges it into `br0` (`master br0`).
  * When a PC/laptop is connected via USB Type-C, it automatically enumerates an **RNDIS USB Ethernet adapter**, receives a DHCP IP lease (`192.168.10.x`), and gets full high-speed Airtel 5G internet access directly over the USB cable!

### 6. Fully Offline & Persistent
* Bundles all 9 official OpenWrt `21.02.7` `aarch64_cortex-a53` / `all` `.ipk` packages — no WAN internet needed on the ODU during installation.
* Stores everything persistently in `/overlay` (`~1 MB` / `7%` used) and registers custom files in `/etc/sysupgrade.conf`.
* Automatically detects the target ODU's `admin` password hash from `/etc/passwd` / `/etc/shadow` so LuCI uses that ODU's own credentials.

---

## Repository Structure

```text
zyxel-aod450-luci-sms/
├── luci-sms-aod450.tar.gz             # Self-contained offline tarball for single-file deployment
├── install-from-pc.ps1                # One-command Windows PowerShell deployer (SSH upload + install)
├── install.sh                         # ODU-side installer script (runs offline)
├── ipks/                              # 9 official OpenWrt 21.02.7 IPK packages
│   ├── uhttpd_2021-03-21-15346de8-2_aarch64_cortex-a53.ipk
│   ├── luci-theme-bootstrap_git-22.288.45155-afd0012_all.ipk
│   ├── luci-mod-system_git-23.013.73129-aa7938d_all.ipk
│   ├── luci-mod-network_git-22.244.54918-77c916e_all.ipk
│   ├── luci-mod-status_git-22.089.70019-d4f0b06_aarch64_cortex-a53.ipk
│   ├── luci-mod-admin-full_git-19.253.48496-3f93650_all.ipk
│   ├── luci-app-opkg_git-22.273.29015-e01e38c_all.ipk
│   ├── luci-proto-ipv6_git-21.148.49484-14511e5_all.ipk
│   └── luci-proto-ppp_git-21.163.64918-6c6559a_all.ipk
└── files/
    ├── etc/
    │   ├── opkg/arch.conf             # Allows aarch64_cortex-a53 + aarch64_cortex-a55_neon-vfpv4
    │   ├── config/uhttpd              # Listens on 0.0.0.0:4153 & [::]:4153
    │   ├── config/luci                # Sets ubuspath '/cgi-bin/luci/admin/ubus'
    │   ├── config/rpcd                # Base rpcd config (admin hash injected at install time)
    │   └── init.d/dhcp-watchdog       # procd init service (START=99)
    └── usr/
        ├── sbin/dhcp-watchdog.sh      # 2s udhcpd health check (Router mode safe)
        └── lib/lua/luci/
            ├── controller/admin/telephony.lua  # Telephony, SMS & Cellular routes
            ├── model/cellular.lua              # Cellular & RF metrics decoding model
            └── view/admin_telephony/
                ├── sms.htm                     # Interactive SMS web page
                └── cellular.htm                # Live Cellular & Signal web page
```

---

## Installation Guide

### Method 1: One-Command Install from Windows (Recommended)

Clone this repository, connect to the ODU, and run `install-from-pc.ps1`:

```powershell
git clone https://github.com/dexdigi-tech/zyxel-aod450-luci-sms.git
cd zyxel-aod450-luci-sms
powershell -ExecutionPolicy Bypass -File .\install-from-pc.ps1 -OduIp 192.168.10.1 -Password "<YOUR_ODU_ADMIN_PASSWORD>"
```

*(Supports PuTTY `plink.exe` automatically if installed, or falls back to Windows OpenSSH `scp`/`ssh`.)*

---

### Method 2: Manual Install via SCP & SSH (Windows / Linux / macOS)

1. Download [`luci-sms-aod450.tar.gz`](luci-sms-aod450.tar.gz) (or clone the repo).
2. Upload the archive to `/tmp/` on the ODU:
   ```sh
   scp luci-sms-aod450.tar.gz admin@192.168.10.1:/tmp/
   ```
3. SSH into the ODU, extract, and run `install.sh`:
   ```sh
   ssh admin@192.168.10.1
   cd /tmp
   tar -xzf luci-sms-aod450.tar.gz
   cd luci-sms-aod450
   sh install.sh
   ```

---

## Accessing the Web Interfaces

* **OpenWrt LuCI Web UI**: `http://192.168.10.1:4153/`
  * **Username**: `admin`
  * **Password**: *Your ODU admin password*
  * **Cellular & Signal**: `Telephony -> Cellular & Signal`
  * **SMS Manager**: `Telephony -> SMS`
* **Stock Airtel / Zyxel Web UI**: `http://192.168.10.1/` (port 80 / 443 — untouched)

> **Note on Browser Caching**: Modern browsers cache the LuCI menu structure in `sessionStorage`. If you previously visited LuCI before installing this update, please **Log Out** and **Log In** again (or open an Incognito window) so the new **Cellular & Signal** menu item appears immediately under **Telephony**.

---

## REST API Endpoints

Both features provide fast JSON API endpoints for integration into scripts or home automation:

* **Cellular & Signal Telemetry**:
  ```http
  GET /cgi-bin/luci/admin/telephony/cellular_info
  ```
  Returns full signal metrics (RSRP, RSRQ, SINR, RSSI, Band, Bandwidth, PCI, Cell ID, eNB, TAC), CA cells, per-antenna RX0–RX3 values, SIM card details, modem temperatures, and WAN IP/APN/traffic.

* **SMS List**:
  ```http
  GET /cgi-bin/luci/admin/telephony/sms_list?modem_info=1
  ```

---

## Troubleshooting & Verification

* **Check running services**:
  ```sh
  netstat -lntp | grep 4153          # Verify uhttpd is listening on port 4153
  ps | grep dhcp-watchdog            # Verify 2s watchdog is active
  ```
* **Verify Cellular Model on ODU CLI**:
  ```sh
  lua -e 'local c = require "luci.model.cellular"; print(require("luci.jsonc").stringify(c.get_cellular_info(), true))'
  ```
* **Persistence across firmware upgrades**:
  Verified in `/etc/sysupgrade.conf`:
  ```sh
  cat /etc/sysupgrade.conf
  ```

---

## License

This project is licensed under the [MIT License](LICENSE).
OpenWrt IPK packages are copyright their respective OpenWrt project authors under the GPLv2.
