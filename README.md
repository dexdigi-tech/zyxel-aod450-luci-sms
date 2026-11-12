# Zyxel AOD450ZY (Airtel 5G CPE) — Full OpenWrt LuCI + SMS, Cellular & Signal Suite

[![OpenWrt](https://img.shields.io/badge/OpenWrt-21.02.7-blue.svg)](https://openwrt.org)
[![Architecture](https://img.shields.io/badge/Arch-aarch64%20(MediaTek%20T750%2FMT6890)-green.svg)](https://openwrt.org)
[![Modem](https://img.shields.io/badge/Modem-Quectel%20RG500L--AR%205G-orange.svg)](https://www.quectel.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Complete, self-contained offline installation bundle and comprehensive guide to unlock the **full OpenWrt 21.02.7 LuCI Web UI**, interactive **Telephony -> SMS** messaging manager, real-time **Cellular Network, Band, Signal & Modem Details** page with **Directional Antenna Alignment Helper**, persistent **2-Second DHCP Watchdog**, and persistent **ADB Root Daemon + USB-C RNDIS Tethering** on the **Zyxel AOD450ZY** (Airtel 5G Outdoor Unit / CPE) — all without disturbing the stock Airtel/Zyxel Web UI.

---

## Table of Contents

- [Overview & Architecture](#overview--architecture)
- [Features](#features)
  - [1. Full OpenWrt LuCI Web Interface (`:4153`)](#1-full-openwrt-luci-web-interface-uhttpd-on-port-4153)
  - [2. Cellular & Signal Diagnostics (`Telephony -> Cellular & Signal`)](#2-cellular--signal-diagnostics-telephony---cellular--signal)
  - [3. Directional Antenna Alignment Helper](#3-directional-antenna-alignment-helper)
  - [4. Telephony SMS Manager (`Telephony -> SMS`)](#4-telephony-sms-manager-telephony---sms)
  - [5. Persistent 2-Second DHCP Watchdog](#5-persistent-2-second-dhcp-watchdog)
  - [6. Persistent ADB Root Daemon & USB Tethering (RNDIS)](#6-persistent-adb-root-daemon--usb-tethering-rndis)
  - [7. 100% Offline & Upgrade-Persistent](#7-100-offline--upgrade-persistent)
- [Visual Interface Tour](#visual-interface-tour)
- [Repository Structure](#repository-structure)
- [Installation Guide](#installation-guide)
  - [Method 1: One-Command Windows PowerShell Deployer (Recommended)](#method-1-one-command-windows-powershell-deployer-recommended)
  - [Method 2: Manual Upload & Install via SCP / SSH](#method-2-manual-upload--install-via-scp--ssh)
  - [Method 3: Install via ADB (Network or USB)](#method-3-install-via-adb-network-or-usb)
- [Accessing the Web Interfaces](#accessing-the-web-interfaces)
  - [Important Browser Caching Notice](#important-browser-caching-notice)
- [ADB & USB Tethering Guide](#adb--usb-tethering-guide)
  - [Network ADB Connection](#network-adb-connection)
  - [USB Tethering (RNDIS over USB Type-C)](#usb-tethering-rndis-over-usb-type-c)
- [REST JSON API Endpoints](#rest-json-api-endpoints)
  - [Cellular & Signal Telemetry API](#cellular--signal-telemetry-api)
  - [SMS Management API](#sms-management-api)
- [Troubleshooting & Verification](#troubleshooting--verification)
- [License](#license)

---

## Overview & Architecture

The **Zyxel AOD450ZY** is an enterprise-grade 5G Outdoor Unit (ODU) deployed by Airtel India. Powered by a **MediaTek MT6890 / T750 SoC** (quad-core ARM Cortex-A55 @ 2.0 GHz) and an integrated **Quectel RG500L-AR 5G Sub-6GHz modem**, it runs an underlying OpenWrt 21.02.7 Linux system.

However, the stock Airtel firmware restricts web management to a stripped-down portal on ports 80/443, hides SMS functionality, conceals detailed RF metrics, disables standard ADB root access, and suffers from a known 5-minute DHCP assignment delay when switching out of bridge mode.

This suite resolves all of these limitations cleanly:

```
+-----------------------------------------------------------------------------------+
|                        Zyxel AOD450ZY (Airtel 5G ODU)                             |
|                                                                                   |
|  +-------------------------------------+   +-----------------------------------+  |
|  |       Stock Airtel / Zyxel UI       |   |       Full OpenWrt LuCI UI        |  |
|  |     Ports: 80 (HTTP) / 443 (HTTPS)  |   |          Port: 4153 (HTTP)        |  |
|  |    (Untouched & Fully Operational)  |   |    (Full Network, System & SMS)   |  |
|  +-------------------------------------+   +-----------------------------------+  |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  |                            Telephony Menus                                  |  |
|  |  * Telephony -> Overview         (Stock MediaTek Telephony Status)          |  |
|  |  * Telephony -> SMS              (Send, Receive, Drafts, Unicode Decoder)   |  |
|  |  * Telephony -> Cellular & Signal (Live 4G/5G RF, CA, 4x Antennas, Thermals)|  |
|  +-----------------------------------------------------------------------------+  |
|                                                                                   |
|  +-------------------------------------+   +-----------------------------------+  |
|  |      Persistent DHCP Watchdog       |   |       Persistent ADB & RNDIS      |  |
|  |   Checks every 2s for udhcpd        |   |   Network ADB on 0.0.0.0:5555     |  |
|  |   Eliminates 5-minute boot delay    |   |   USB-C Tethering (rndis0 in br0) |  |
|  +-------------------------------------+   +-----------------------------------+  |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  |              Persistent Overlay & sysupgrade.conf Protection                |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## Features

### 1. Full OpenWrt LuCI Web Interface (`uhttpd` on port `4153`)
* **Zero Port Conflicts**: Runs on port `4153`, leaving the Airtel stock web portal on ports `80` and `443` completely functional.
* **Status**: Overview, Firewall rules, Kernel routing tables, System Log, Kernel Ring Buffer (`dmesg`), Active Processes, and Real-Time CPU/Load/Traffic Graphs.
* **System**: Hostname, Time Synchronization (NTP), Administration & Password, SSH Access Keys, Startup (`init.d`), Scheduled Tasks (`cron`), LED configurations, Flash/Backup, and Package Manager (`opkg`).
* **Network**: Physical and Logical Interfaces (`br0`, `eth0`, `ccmni1`), DHCP & DNS Server (`dnsmasq` / `udhcpd`), Static Leases, Hostnames, Routing, and Diagnostic Tools (`ping`, `traceroute`, `nslookup`).
* **Telephony**: Stock MediaTek overview + custom **SMS** + custom **Cellular & Signal** status pages.

---

### 2. Cellular & Signal Diagnostics (`Telephony -> Cellular & Signal`)

Navigate to **Telephony ➔ Cellular & Signal** (`/cgi-bin/luci/admin/telephony/cellular`) for comprehensive, real-time RF and hardware telemetry:

* **Real-Time RF Signal Quality Gauge**:
  * 4-bar visual indicator with dynamic color grading:
    * **Excellent** (Green, RSRP ≥ -85 dBm, SINR ≥ 20 dB)
    * **Good** (Blue, RSRP ≥ -95 dBm, SINR ≥ 13 dB)
    * **Fair** (Orange, RSRP ≥ -105 dBm, SINR ≥ 0 dB)
    * **Poor** (Red, RSRP < -105 dBm)
  * Instant metrics cards: **RSRP** (dBm), **RSRQ** (dB), **SINR** (dB), **RSSI** (dBm), **Active Band** (`B1`, `B3`, `B40`, `n78`), **Bandwidth** (`10MHz`, `15MHz`, `20MHz`, `100MHz`), **PCI** (Physical Cell ID), **eNB ID**, and **Sector Number**.
* **Serving Cells & Carrier Aggregation (CA) Table**:
  * Decodes Primary Serving Cell (**PCell**) and all active Secondary Cells (**SCells**) for 4G LTE-A and 5G NR NSA / SA.
  * Columns: Cell Type (`PCC` / `SCC`), RAT Mode (`LTE` / `NR5G`), Band, Bandwidth, EARFCN / ARFCN, PCI, Cell ID (Hex & Decimal), eNodeB / gNodeB ID, Sector, TAC (Tracking Area Code), RSRP, RSRQ, SINR, and State (`Serving` / `Active`).
* **SIM Card & Security Information**:
  * Insertion status (`Ready / Inserted`), Card State (`Active`), PIN State (`Unlocked`).
  * **Remaining Attempt Counters**: Live counters for PIN1, PIN2, PUK1, and PUK2 attempts remaining via `AT+EPINC?`.
  * Operator Name (`airtel`), PLMN (`404-10`), IMSI (`AT+CIMI`), ICCID (`AT+CCID`), Registration Status (`Home Network`), and Configured RAT Mode.
* **Quectel RG500L-AR Modem & Hardware Details**:
  * Manufacturer (`Quectel`), Model (`RG500L-AR`), Firmware Revision (`AT+CGMR`), Platform SoC (`MediaTek MT6890 / T750`), IMEI, IMEI SVN, and Control Channels (`MIPC / /dev/ttyUSB2`).
  * Device Model (`Zyxel AOD450ZY`), Hostname (`AOD450`), Linux Kernel (`5.4 aarch64`), OpenWrt Release, System Uptime, and RAM utilization.
* **21 Thermal Sensors (`AT+QTEMP`)**:
  * Full real-time thermal matrix monitoring temperatures across the device:
    * **SoC Core**: SoC Max, CPU Little cores 0–3, GPU 0, GPU 1, DRAM.
    * **Modem**: 5G Sub-6 Modem, 4G LTE Modem, 3G Modem.
    * **RF Power Amplifiers**: RF NTC, NR PA NTC, LTE PA NTC.
    * **Power Management**: PMIC and board thermals.
* **Active WAN & Data Call Session**:
  * Connection Status (`Connected / Active`), Interface (`ccmni1`), APN Profile (`airtelgprs.com`), PDP Type (`IPv4` / `IPv6`), Assigned WAN IP Address, Subnet Mask, Gateway, Primary & Secondary DNS, MTU (`1500`), and Cumulative TX / RX byte counters.
* **Collapsible Raw AT Response Drawer**:
  * Expandable drawer revealing the unprocessed output of:
    * `AT+ECELL` (Carrier Aggregation serving and neighbor cells)
    * `AT+EDMFAPP=6,4` (Active serving cell parameters)
    * `AT+EDMFAPP=6,9` (Per-antenna RX0–RX3 telemetry)
    * `AT+EDMFAPP=6,10` (Bandwidth and carrier configuration)
    * `AT+CESQ` & `AT+CSQ` (Signal quality metrics)
    * `AT+QTEMP` (Thermal sensors)
    * `mipc_wan_cli --data_call_get` (Active PDP data session)
* **Configurable Auto-Refresh**:
  * Live updates with user-selectable polling intervals: **3s** (fast alignment), **5s**, **10s**, **30s**, or **Paused**.

---

### 3. Directional Antenna Alignment Helper

The Zyxel AOD450ZY features 4 internal high-gain directional patch antenna arrays. The new Cellular status page decodes individual antenna metrics directly via `AT+EDMFAPP=6,9`:

```
+---------------------------------------------------------------------------------------+
|                 Directional Antenna Alignment Helper (4x4 MIMO)                       |
+---------------------------------------------------------------------------------------+
|  Antenna RX0 (Main)       | RSRP: -76 dBm [||||||||||||||||||||    ]  SINR: 24.5 dB   |
|  Antenna RX1 (Diversity)  | RSRP: -78 dBm [|||||||||||||||||||     ]  SINR: 22.0 dB   |
|  Antenna RX2 (MIMO 1)     | RSRP: -81 dBm [|||||||||||||||||       ]  SINR: 19.5 dB   |
|  Antenna RX3 (MIMO 2)     | RSRP: -82 dBm [||||||||||||||||        ]  SINR: 18.0 dB   |
+---------------------------------------------------------------------------------------+
```

#### How to use during outdoor installation:
1. Mount the ODU on your pole or wall mount with the bracket loosely secured.
2. Connect your laptop or mobile phone to the ODU via Ethernet, Wi-Fi router, or USB-C tethering.
3. Open `http://192.168.10.1:4153/cgi-bin/luci/admin/telephony/cellular`.
4. Set **Auto-Refresh** to **3 seconds**.
5. Slowly rotate the ODU horizontally (azimuth) by 5–10 degrees at a time.
6. Observe the **Antenna RX0–RX3 RSRP & SINR** bars:
   * **Target RSRP**: Between `-70 dBm` and `-85 dBm` (closer to 0 is better).
   * **Target SINR**: Above `18 dB` (higher is better; indicates low interference).
7. Once peak signal levels are achieved across all 4 antenna paths, tighten the mounting bracket securely.

---

### 4. Telephony SMS Manager (`Telephony -> SMS`)

Navigate to **Telephony ➔ SMS** (`/cgi-bin/luci/admin/telephony/sms`):

* **Send SMS**: Compose and dispatch SMS up to 160 characters with a live remaining character counter.
* **Save Drafts**: Save unfinished messages locally to finish and send later.
* **Incoming SMS & Unicode Decoder**:
  * Handles standard single-part messages (`"PduContent"`).
  * Automatically concatenates multi-part messages (`"PduContent000"`, `"PduContent001"`, etc.).
  * Decodes `\uXXXX` UTF-16 Unicode escape sequences into readable UTF-8 text (essential for multilingual and carrier service SMS).
  * Synchronizes and parses incoming notifications from `/xdata/SMS/sms_new.txt` and `/xdata/SMS/Inbox/`.
* **Tabbed Views**: Instantly switch between **Inbox**, **Sent**, **Drafts**, and **All Messages**, with an active **Unread Counter Badge**.
* **Message Actions**: One-click **Reply**, **Load Draft**, **Mark as Read / Unread**, and **Delete**.
* **Modem Storage Diagnostics**: Live readout of SIM card SMS storage slots (`AT+CPMS?`) and the configured SMS Service Center (`AT+CSCA?`).
* **Security Hardened**: Protected by LuCI CSRF session tokens (`test_post_security()`), strict alphanumeric filename allowlisting, safe process spawning (`luci.sys.process.exec` without shell interpolation), and XSS-safe DOM text rendering (`textContent`).

---

### 5. Persistent 2-Second DHCP Watchdog

* **The Problem**: On stock Airtel firmware, when Bridge Mode is disabled or after an Ethernet cable flap / power cycle, the proprietary `/usr/bin/hachi` daemon only evaluates `udhcpd` every 300 seconds (5 minutes). This causes connected PCs or routers to wait up to 5 minutes before receiving an IP address lease.
* **The Solution**: A lightweight `procd`-supervised daemon (`/etc/init.d/dhcp-watchdog` + `/usr/sbin/dhcp-watchdog.sh`) monitors the ODU every **2 seconds**:
  * If `bridge_mode_control` is `0` (Router Mode) and DHCP Server is enabled in configuration, it ensures `/usr/sbin/udhcpd` is running immediately.
  * If Bridge Mode is active (`bridge_mode_control` is `1`), the watchdog automatically stays dormant to avoid interfering with transparent WAN passthrough.

---

### 6. Persistent ADB Root Daemon & USB Tethering (RNDIS)

A custom `procd` init service (`/etc/init.d/adbd`) unlocks root debugging and USB tethering:

* **Network ADB (`0.0.0.0:5555`)**:
  * Persistent `adbd_usb` service listening on port 5555 across all interfaces.
  * Instant passwordless root shell: `adb connect 192.168.10.1:5555` followed by `adb shell` (`uid=0(admin) gid=0(admin)`).
  * Fast file uploads and downloads (`adb push` / `adb pull`) bypassing SSH/SFTP overhead.
  * Port forwarding: forward port 4153 to `localhost` to administer LuCI over ADB.
* **USB-C Tethering (RNDIS / USB Ethernet)**:
  * Automatically provisions the MediaTek MTU3 SuperSpeed USB controller (`11201000.usb`) using Linux ConfigFS composite gadget.
  * Combines `functions/rndis.usb0` (Ethernet) + `functions/ffs.adb` (ADB).
  * Bridges the `rndis0` interface directly into `br0` (`master br0`).
  * **Plug & Play**: Connect a USB Type-C cable from the ODU's USB port directly to any Windows PC, Mac, or Linux laptop. The PC recognizes an **RNDIS USB Ethernet Adapter**, automatically receives a DHCP IP lease (`192.168.10.x`), and gets high-speed 5G internet access directly over USB without requiring a PoE data switch!

---

### 7. 100% Offline & Upgrade-Persistent

* **Completely Offline**: Bundles all 9 official OpenWrt 21.02.7 `aarch64_cortex-a53` / `all` IPK packages — no WAN internet connection is required during installation.
* **Compact Overlay Footprint**: Consumes less than 1.2 MB in `/overlay` (`~8%` of available space).
* **Firmware Upgrade Persistence**: All installed configuration files, daemons, models, views, and controllers are automatically registered in `/etc/sysupgrade.conf`.
* **Dynamic Credentials**: Automatically detects and adopts the ODU's existing administrative password hash from `/etc/passwd` or `/etc/shadow`.

---

## Visual Interface Tour

### Cellular & Signal Dashboard Mockup

```text
+---------------------------------------------------------------------------------------------------+
| OpenWrt LuCI  |  Status  |  System  |  Network  |  Telephony v  |                  admin @ AOD450 |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  Telephony  >  Cellular & Signal                                      [ Auto-refresh: [3s  v] ]   |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  |  SIGNAL QUALITY: [||||] EXCELLENT (Primary Band: n78 | Bandwidth: 100MHz | PCI: 342)       |  |
|  |                                                                                             |  |
|  |  RSRP: -78 dBm       RSRQ: -11 dB          SINR: 24.5 dB         RSSI: -52 dBm              |  |
|  |  PCI: 342            Cell ID: 0x4A1B2      eNB ID: 303538        Sector: 2                  |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                                                                   |
|  Serving Cells & Carrier Aggregation (CA)                                                         |
|  +------+------+------+-----------+---------+-----+------------+--------+--------+------+------+  |
|  | Type | RAT  | Band | Bandwidth | ARFCN   | PCI | Cell ID    | eNB ID | RSRP   | RSRQ | SINR |  |
|  +------+------+------+-----------+---------+-----+------------+--------+--------+------+------+  |
|  | PCC  | NR5G | n78  | 100 MHz   | 627264  | 342 | 0x0004A1B2 | 303538 | -78dBm | -11dB| 24dB |  |
|  | SCC1 | LTE  | B3   | 20 MHz    | 1800    | 342 | 0x0004A1B3 | 303538 | -82dBm | -10dB| 19dB |  |
|  | SCC2 | LTE  | B1   | 10 MHz    | 2100    | 118 | 0x0004A1B4 | 303538 | -85dBm | -12dB| 17dB |  |
|  +------+------+------+-----------+---------+-----+------------+--------+--------+------+------+  |
|                                                                                                   |
|  Directional Antenna Alignment Helper (4x4 MIMO Chains)                                           |
|  +---------------------------------------------------------------------------------------------+  |
|  |  Antenna RX0 (Main):      -76 dBm  [============================        ]  SINR: 25.0 dB   |  |
|  |  Antenna RX1 (Diversity): -78 dBm  [==========================          ]  SINR: 23.5 dB   |  |
|  |  Antenna RX2 (MIMO 1):    -81 dBm  [======================              ]  SINR: 20.0 dB   |  |
|  |  Antenna RX3 (MIMO 2):    -82 dBm  [====================                ]  SINR: 18.5 dB   |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                                                                   |
|  SIM Card & Registration                       Modem & System Hardware                            |
|  +------------------------------------------+  +-----------------------------------------------+  |
|  | Status:       Ready / Inserted           |  | Modem:       Quectel RG500L-AR                |  |
|  | SIM State:    Active (Unlocked)          |  | SoC:         MediaTek MT6890 / T750 (4x A55)  |  |
|  | PIN / PUK:    PIN1: 3 left | PUK1: 10 left| | Firmware:    RG500LAR01A03M4G                |  |
|  | Operator:     airtel (PLMN 404-10)       |  | IMEI:        864987050012345 (SVN: 01)        |  |
|  | IMSI / ICCID: 404100... / 8991...        |  | System:      Zyxel AOD450ZY (Linux 5.4 aarch64)| |
|  +------------------------------------------+  +-----------------------------------------------+  |
|                                                                                                   |
|  Thermal Sensors (21 Sensors - AT+QTEMP)                                                          |
|  +---------------------------------------------------------------------------------------------+  |
|  |  SoC Max: 48°C | CPU0: 45°C | CPU1: 45°C | CPU2: 46°C | CPU3: 46°C | DRAM: 42°C | GPU: 44°C |  |
|  |  Modem 5G: 46°C | Modem 4G: 44°C | RF NTC: 41°C | NR PA NTC: 47°C | LTE PA: 43°C | PMIC: 49°C|  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                                                                   |
|  Active WAN & Data Call (ccmni1)                                                                  |
|  +---------------------------------------------------------------------------------------------+  |
|  |  State: Connected | APN: airtelgprs.com | PDP: IPv4 | IP: 100.72.184.212/29                 |  |
|  |  Gateway: 100.72.184.209 | DNS: 125.63.254.2, 125.63.254.3 | RX: 1.42 GB | TX: 384 MB       |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                                                                   |
|  [> Show Diagnostic Raw AT Responses (AT+ECELL, AT+EDMFAPP, AT+CESQ, AT+QTEMP)                 ]  |
+---------------------------------------------------------------------------------------------------+
```

---

## Repository Structure

```text
zyxel-aod450-luci-sms/
├── luci-sms-aod450.tar.gz             # Self-contained offline deployment archive (~1.1 MB)
├── install-from-pc.ps1                # One-click Windows PowerShell automated deployer
├── install.sh                         # Offline installer executed on the ODU
├── LICENSE                            # MIT License
├── README.md                          # Full user guide, technical specs, and API documentation
├── ipks/                              # 9 official OpenWrt 21.02.7 aarch64 / all packages
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
    │   ├── opkg/
    │   │   └── arch.conf              # opkg architecture compatibility mapping
    │   ├── config/
    │   │   ├── uhttpd                 # LuCI web server configuration (listens on port 4153)
    │   │   ├── luci                   # LuCI base ubus and path configuration
    │   │   └── rpcd                   # Dynamic admin authentication configuration
    │   └── init.d/
    │       ├── dhcp-watchdog          # procd init script for 2s DHCP watchdog service
    │       └── adbd                   # procd init script for network ADB and USB-C RNDIS
    └── usr/
        ├── sbin/
        │   └── dhcp-watchdog.sh       # udhcpd supervisor daemon
        └── lib/lua/luci/
            ├── controller/admin/
            │   └── telephony.lua      # LuCI dispatcher routes for SMS & Cellular pages
            ├── model/
            │   └── cellular.lua       # Real-time AT / MIPC RF & hardware telemetry decoder
            └── view/admin_telephony/
                ├── sms.htm            # SMS web application view
                └── cellular.htm       # Cellular, RF & antenna alignment dashboard view
```

---

## Installation Guide

### Prerequisites
* A Zyxel AOD450ZY ODU powered on and connected to your PC via Ethernet or Wi-Fi.
* Default ODU IP: `192.168.10.1` (or your configured subnet IP).
* Admin credentials (username: `admin`, password found on the ODU device label or your custom password).

---

### Method 1: One-Command Windows PowerShell Deployer (Recommended)

1. Clone or download this repository on your Windows PC:
   ```powershell
   git clone https://github.com/dexdigi-tech/zyxel-aod450-luci-sms.git
   cd zyxel-aod450-luci-sms
   ```
2. Run `install-from-pc.ps1` with your ODU password:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install-from-pc.ps1 -OduIp 192.168.10.1 -Password "<YOUR_ODU_ADMIN_PASSWORD>"
   ```
   *The script automatically detects PuTTY `plink.exe` or standard OpenSSH `scp`/`ssh`, streams the offline archive, runs the installation, and verifies the LuCI HTTP endpoint.*

---

### Method 2: Manual Upload & Install via SCP / SSH

1. Upload [`luci-sms-aod450.tar.gz`](luci-sms-aod450.tar.gz) to the `/tmp/` folder on the ODU:
   ```sh
   scp luci-sms-aod450.tar.gz admin@192.168.10.1:/tmp/
   ```
2. SSH into the ODU:
   ```sh
   ssh admin@192.168.10.1
   ```
3. Extract and execute `install.sh`:
   ```sh
   cd /tmp
   tar -xzf luci-sms-aod450.tar.gz
   cd luci-sms-aod450
   sh install.sh
   ```
4. Once completed, clean up the temporary files:
   ```sh
   cd /tmp && rm -rf luci-sms-aod450 luci-sms-aod450.tar.gz
   ```

---

### Method 3: Install via ADB (Network or USB)

If you already have ADB connected:
```sh
adb connect 192.168.10.1:5555
adb push luci-sms-aod450.tar.gz /tmp/
adb shell "cd /tmp && tar -xzf luci-sms-aod450.tar.gz && cd luci-sms-aod450 && sh install.sh && rm -rf /tmp/luci-sms-aod450*"
```

---

## Accessing the Web Interfaces

* **OpenWrt LuCI Web Interface**:
  * URL: **`http://192.168.10.1:4153/`**
  * Username: `admin`
  * Password: *(Your ODU admin password)*
  * Navigate to **Telephony ➔ Cellular & Signal** for RF metrics and antenna alignment.
  * Navigate to **Telephony ➔ SMS** to send and read messages.

* **Stock Airtel / Zyxel Web Interface**:
  * URL: **`http://192.168.10.1/`** (port 80 / 443 — untouched and fully functional).

---

### Important Browser Caching Notice

> [!IMPORTANT]
> The OpenWrt LuCI Bootstrap theme aggressively caches the navigation menu structure in browser `sessionStorage` (`sessionStorage['luci-session-store']`).
> 
> If you previously accessed LuCI before installing or updating this suite, the new **Cellular & Signal** menu item will **not** appear until you:
> 1. Click **Log Out** in the top-right corner of LuCI, then **Log In** again.
> 2. Or open an **Incognito / Private Browsing window** to `http://192.168.10.1:4153/`.

---

## ADB & USB Tethering Guide

### Network ADB Connection

The persistent `/etc/init.d/adbd` daemon runs on port `5555`. No passwords or SSH keys are required:

1. **Connect from your PC terminal**:
   ```cmd
   adb connect 192.168.10.1:5555
   ```
2. **Open a root shell**:
   ```cmd
   adb shell
   ```
   *(You will immediately enter `root@AOD450:/#` with full root privileges).*
3. **Forward LuCI port over ADB**:
   ```cmd
   adb forward tcp:4153 tcp:4153
   ```
   You can now open `http://localhost:4153/` in your browser even if Ethernet is unplugged.
4. **Push / Pull files**:
   ```cmd
   adb push myfile.txt /tmp/
   adb pull /tmp/syslog.txt .
   ```

---

### USB Tethering (RNDIS over USB Type-C)

The Zyxel AOD450ZY features a physical USB Type-C port connected to the MediaTek MTU3 SuperSpeed 5Gbps USB controller (`11201000.usb`).

Our persistent `/etc/init.d/adbd` service automatically initializes Linux ConfigFS composite gadget:
- Function 1: `rndis.usb0` (USB Ethernet network adapter)
- Function 2: `ffs.adb` (ADB debugging endpoint)

The resulting `rndis0` network interface is permanently added to bridge `br0` (`master br0`).

#### How to use USB Tethering:
1. Connect a USB Type-C cable from the ODU's USB port directly into your PC / laptop.
2. Windows, macOS, and Linux will immediately detect an **RNDIS / USB Ethernet** network adapter.
3. Your PC receives an IP lease via DHCP (`192.168.10.x`) and gains instant gigabit 5G internet connectivity.
4. **No PoE data port or external Ethernet switch needed** — perfect for direct high-speed testing, field diagnostics, or using the ODU as a direct USB modem.

---

## REST JSON API Endpoints

Both custom Telephony pages expose high-speed, lightweight JSON endpoints for integration into **Home Assistant**, **Prometheus**, **Node-RED**, or custom scripts.

### Cellular & Signal Telemetry API

* **Endpoint**: `GET /cgi-bin/luci/admin/telephony/cellular_info`
* **Authentication**: LuCI session cookie or HTTP basic auth
* **Response Time**: ~35–45 ms

#### Sample JSON Response:
```json
{
  "signal": {
    "rsrp": -78,
    "rsrq": -11,
    "sinr": 24.5,
    "rssi": -52,
    "band": "n78",
    "bandwidth": "100 MHz",
    "pci": 342,
    "cell_id": "0x0004A1B2",
    "enb_id": "303538",
    "sector": 2,
    "tac": 10521,
    "plmn": "404-10",
    "grade": "Excellent"
  },
  "serving_cells": [
    {
      "type": "PCC",
      "rat": "NR5G",
      "band": "n78",
      "bandwidth": "100 MHz",
      "arfcn": 627264,
      "pci": 342,
      "cell_id": "0x0004A1B2",
      "enb_id": "303538",
      "sector": 2,
      "tac": 10521,
      "rsrp": -78,
      "rsrq": -11,
      "sinr": 24.5,
      "status": "Serving"
    },
    {
      "type": "SCC1",
      "rat": "LTE",
      "band": "B3",
      "bandwidth": "20 MHz",
      "arfcn": 1800,
      "pci": 342,
      "cell_id": "0x0004A1B3",
      "enb_id": "303538",
      "sector": 2,
      "tac": 10521,
      "rsrp": -82,
      "rsrq": -10,
      "sinr": 19.0,
      "status": "Active"
    }
  ],
  "antennas": {
    "rx0": { "name": "Antenna RX0 (Main)", "rsrp": -76, "rsrq": -10, "rssi": -50, "sinr": 25.0 },
    "rx1": { "name": "Antenna RX1 (Diversity)", "rsrp": -78, "rsrq": -11, "rssi": -52, "sinr": 23.5 },
    "rx2": { "name": "Antenna RX2 (MIMO 1)", "rsrp": -81, "rsrq": -12, "rssi": -55, "sinr": 20.0 },
    "rx3": { "name": "Antenna RX3 (MIMO 2)", "rsrp": -82, "rsrq": -12, "rssi": -56, "sinr": 18.5 }
  },
  "sim": {
    "status": "Ready / Inserted",
    "sim_state": "Active",
    "pin_state": "Unlocked",
    "pinc_attempts": { "pin1": 3, "pin2": 3, "puk1": 10, "puk2": 10 },
    "operator": "airtel",
    "plmn": "404-10",
    "imsi": "404100123456789",
    "iccid": "8991101234567890123F",
    "registration": "Home Network",
    "rat_mode": "5G NR / LTE Auto"
  },
  "modem": {
    "manufacturer": "Quectel",
    "model": "RG500L-AR",
    "revision": "RG500LAR01A03M4G",
    "soc": "MediaTek MT6890 / T750",
    "imei": "864987050012345",
    "imei_svn": "01",
    "temperatures": {
      "soc_max": 48,
      "cpu0": 45,
      "cpu1": 45,
      "cpu2": 46,
      "cpu3": 46,
      "dram": 42,
      "gpu0": 44,
      "gpu1": 44,
      "modem_5g": 46,
      "modem_4g": 44,
      "rf_ntc": 41,
      "nr_pa_ntc": 47,
      "lte_pa_ntc": 43,
      "pmic": 49
    }
  },
  "wan": {
    "connected": true,
    "ifname": "ccmni1",
    "apn": "airtelgprs.com",
    "pdp_type": "IPv4",
    "ip": "100.72.184.212",
    "netmask": "255.255.255.248",
    "gateway": "100.72.184.209",
    "dns1": "125.63.254.2",
    "dns2": "125.63.254.3",
    "mtu": 1500,
    "rx_bytes": 1524719280,
    "tx_bytes": 402653184
  }
}
```

#### Python Quick-Query Example:
```python
import requests

session = requests.Session()
# Login to LuCI
login_data = {"luci_username": "admin", "luci_password": "<YOUR_PASSWORD>"}
session.post("http://192.168.10.1:4153/cgi-bin/luci/", data=login_data)

# Fetch live metrics
resp = session.get("http://192.168.10.1:4153/cgi-bin/luci/admin/telephony/cellular_info")
data = resp.json()

print(f"Signal: {data['signal']['grade']} ({data['signal']['rsrp']} dBm)")
print(f"Band: {data['signal']['band']} ({data['signal']['bandwidth']})")
print(f"Antenna RX0: {data['antennas']['rx0']['rsrp']} dBm | SINR: {data['antennas']['rx0']['sinr']} dB")
```

---

### SMS Management API

* **List Messages & Modem Info**:
  ```http
  GET /cgi-bin/luci/admin/telephony/sms_list?modem_info=1
  ```
* **Send SMS**:
  ```http
  POST /cgi-bin/luci/admin/telephony/sms_send
  Content-Type: application/x-www-form-urlencoded

  token=<LUCI_CSRF_TOKEN>&phone=9876543210&content=Hello+from+AOD450
  ```
* **Delete Message**:
  ```http
  POST /cgi-bin/luci/admin/telephony/sms_delete
  Content-Type: application/x-www-form-urlencoded

  token=<LUCI_CSRF_TOKEN>&filename=msg_1731420000.txt&folder=Inbox
  ```

---

## Troubleshooting & Verification

### Verify Running Services on ODU
```sh
# Check LuCI web server
netstat -lntp | grep 4153          # Should show uhttpd listening on 0.0.0.0:4153 and [::]:4153

# Check Network ADB daemon
netstat -lntp | grep 5555          # Should show adbd_usb listening on 0.0.0.0:5555

# Check DHCP watchdog process
ps w | grep '[d]hcp-watchdog.sh'   # Should show active background watchdog

# Check RNDIS tethering interface in bridge
brctl show br0                     # Should list rndis0 under br0 interfaces
```

### Test Lua Models & Templates
```sh
lua -e 'assert(loadfile("/usr/lib/lua/luci/controller/admin/telephony.lua"))'
lua -e 'assert(loadfile("/usr/lib/lua/luci/model/cellular.lua"))'
lua -e 'local c = require "luci.model.cellular"; print(require("luci.jsonc").stringify(c.get_cellular_info(), true))'
```

### Verify Upgrade Persistence Configuration
```sh
cat /etc/sysupgrade.conf
```
*Expected entries:*
```text
/usr/lib/lua/luci/controller/admin/telephony.lua
/usr/lib/lua/luci/model/cellular.lua
/usr/lib/lua/luci/view/admin_telephony/sms.htm
/usr/lib/lua/luci/view/admin_telephony/cellular.htm
/usr/sbin/dhcp-watchdog.sh
/etc/init.d/dhcp-watchdog
/etc/init.d/adbd
```

---

## License

This project is open-source under the [MIT License](LICENSE).
OpenWrt IPK packages are copyright their respective OpenWrt project authors under the GNU General Public License v2.
