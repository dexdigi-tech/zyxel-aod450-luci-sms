# Zyxel AOD450ZY (Airtel 5G CPE) — Full OpenWrt LuCI + SMS & DHCP Persistence Suite

[![OpenWrt](https://img.shields.io/badge/OpenWrt-21.02.7-blue.svg)](https://openwrt.org)
[![Architecture](https://img.shields.io/badge/Arch-aarch64%20(Cortex--A55%2FA53)-green.svg)](https://openwrt.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Complete offline installation bundle and guide to enable the **full OpenWrt 21.02.7 LuCI Web UI**, interactive **Telephony -> SMS** manager (send, receive, drafts, inbox/outbox), and a persistent **2-second DHCP Watchdog** on the **Zyxel AOD450ZY** (Airtel 5G Outdoor Unit / CPE) — without disturbing the stock Airtel/Zyxel Web UI.

---

## Features

* **Full OpenWrt 21.02.7 LuCI Web Interface (`uhttpd` on port `4153`)**:
  * Runs alongside the stock Airtel/Zyxel Web UI (`:80` / `:443`) with zero port conflicts.
  * **Status**: Overview, Firewall, Routes, System Log, Kernel Log (`dmesg`), Processes, Realtime Graphs.
  * **System**: System Properties, Administration/Password, SSH Access & Keys, Startup, Scheduled Tasks, LEDs, Flash/Backup, Software (`opkg`), Reboot.
  * **Network**: Interfaces, DHCP & DNS, Hostnames, Static Routes, Diagnostics (`ping`, `traceroute`, `nslookup`).
  * **Telephony**: Stock MediaTek/Zyxel Telephony Overview + new **SMS** management page.
* **Telephony -> SMS Page (`/cgi-bin/luci/admin/telephony/sms`)**:
  * **Send & Save Drafts**: Compose SMS up to 160 characters with live character counter (`smscmd send` / `smscmd save`).
  * **Incoming SMS Support**: Decodes both standard `"PduContent"` and incoming `"PduContent000"`+ (multi-part & `\uXXXX` Unicode escapes) from `/xdata/SMS/Inbox/` and auto-converts `/xdata/SMS/sms_new.txt`.
  * **Full Management**: Tabbed views (**Inbox**, **Sent**, **Drafts**, **All**), **Unread** counter badge, **Reply**, **Load Draft**, **Mark Read / Unread**, **Delete**, and **Auto-refresh (15s)**.
  * **Modem Diagnostics**: Displays SIM SMS storage slots (`AT+CPMS?`) and SMSC center (`AT+CSCA?`).
  * **Security**: Enforces LuCI CSRF `token` validation (`test_post_security()`), strict filename allowlisting, input validation, XSS-safe DOM rendering (`textContent`), and shell-free process execution (`luci.sys.process.exec`).
* **Persistent 2-Second DHCP Watchdog (`/etc/init.d/dhcp-watchdog`)**:
  * Resolves the 4–5 minute DHCP IP delay when Bridge Mode is disabled (where `/usr/bin/hachi` only polls `udhcpd` every 300s after boot or Ethernet link flaps).
  * Automatically checks every 2 seconds and restarts `/usr/sbin/udhcpd` when `bridge_mode_control` is `0` and DHCP Server is enabled, while staying inactive if Bridge Mode is turned back on.
* **Fully Offline & Persistent**:
  * Bundles all 9 official OpenWrt `21.02.7` `aarch64_cortex-a53` / `all` `.ipk` packages — no WAN internet needed on the ODU during installation.
  * Stores everything persistently in `/overlay` (`~960 KB` / `7%` used) and registers custom files in `/etc/sysupgrade.conf`.
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
            ├── controller/admin/telephony.lua  # Telephony + SMS routes & JSON API
            └── view/admin_telephony/sms.htm    # Interactive LuCI SMS web page
```

---

## Prerequisites

1. **Target Device**: Zyxel AOD450ZY running stock OpenWrt `21.02.7` (`gem6xxx/evb6890v1_64_cpe_emmc`).
2. **Network / Access**: PC connected to the ODU LAN (`192.168.10.1`) with SSH access enabled (`admin` + ODU password).
   > **Tip**: If Bridge Mode is disabled and you haven't installed the DHCP fix yet, the stock ODU can take 4–5 minutes to assign a DHCP lease after boot/unplug. You can temporarily set a static IP (`192.168.10.100/24`, gateway `192.168.10.1`) on your PC Ethernet adapter during the initial install.

---

## Installation Guide

### Method 1: One-Command Install from Windows (Recommended)

Clone or download this repository, connect to the ODU, and run `install-from-pc.ps1`:

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
   rm -rf /tmp/luci-sms-aod450 /tmp/luci-sms-aod450.tar.gz
   ```

When finished, you should see:
```text
 * uhttpd port 4153: RUNNING (OK)
 * rpcd service:     RUNNING (OK)
 * dhcp-watchdog:    RUNNING (OK)
```

---

## Accessing LuCI & SMS

* **LuCI Web UI:** `http://192.168.10.1:4153/`
* **Stock Airtel Web UI:** `http://192.168.10.1/` (ports `80` / `443` remain untouched)
* **Username:** `admin`
* **Password:** Your ODU's `admin` password (the installer reads its hash directly from the target ODU)
* **SMS Manager:** Top menu -> **Telephony -> SMS** (`http://192.168.10.1:4153/cgi-bin/luci/admin/telephony/sms`)

> **Important Note on Settings:** Network/Cellular/Bridge settings on this device are managed by Zyxel's proprietary `cm`/`pdm` daemons on port `80`. Use LuCI (`:4153`) for system monitoring, logs, diagnostics, startup services, packages, and **Telephony -> SMS**, and use the stock UI (`:80`) for Airtel APN / Bridge Mode changes.

---

## Technical Notes & Design Decisions

1. **Why `uhttpd-mod-ubus` is not used**: Stock AOD450 ships `libubus20210603`, whereas OpenWrt 21.02.7 `uhttpd-mod-ubus` expects `libubus20210630`. Instead, `/etc/config/luci` configures `option ubuspath '/cgi-bin/luci/admin/ubus'`, which routes JSON-RPC `ubus` requests natively through LuCI CGI + `rpcd`.
2. **Why `aarch64_cortex-a53` packages are used**: The ODU reports `aarch64_cortex-a55_neon-vfpv4`, which is binary-compatible with OpenWrt 21.02.7's `aarch64_cortex-a53` feed. `/etc/opkg/arch.conf` registers both architectures.
3. **Why incoming SMS needed `PduContent000` handling**: `smscmd send`/`save` writes JSON with `"PduContent"`, whereas modem-received SMS files in `/xdata/SMS/Inbox/` store message parts under `"PduContent000"`, `"PduContent001"`, etc. `extract_sms_content()` in `telephony.lua` handles both formats seamlessly.

---

## Troubleshooting

* **I already had LuCI open and don't see `Telephony -> SMS` in the menu:**
  * LuCI 21.02 caches the navigation menu inside your browser tab's `window.sessionStorage` (`luci-session-store`). Click **Logout** and log back in, or open a **new browser tab** to `http://192.168.10.1:4153/cgi-bin/luci/admin/telephony/sms`.
* **How to uninstall / revert:**
  ```sh
  /etc/init.d/uhttpd stop && /etc/init.d/uhttpd disable
  /etc/init.d/dhcp-watchdog stop && /etc/init.d/dhcp-watchdog disable
  rm -f /usr/sbin/dhcp-watchdog.sh /etc/init.d/dhcp-watchdog /usr/lib/lua/luci/view/admin_telephony/sms.htm
  [ -f /etc/telephony.lua.stock.bak ] && mv /etc/telephony.lua.stock.bak /usr/lib/lua/luci/controller/admin/telephony.lua
  opkg remove uhttpd luci-app-opkg luci-mod-admin-full luci-mod-status luci-mod-network luci-mod-system luci-theme-bootstrap luci-proto-ipv6 luci-proto-ppp
  rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
  ```

---

## License

Released under the [MIT License](LICENSE).
