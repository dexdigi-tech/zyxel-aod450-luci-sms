#!/bin/sh
# ==============================================================================
# Zyxel AOD450ZY (Airtel 5G CPE) - LuCI + SMS & DHCP Fix Installer
# Installs LuCI Web UI on port 4153, full SMS support, and 2s DHCP watchdog.
# ==============================================================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
echo "=========================================================="
echo " Starting Zyxel AOD450 LuCI + SMS Installation"
echo " Working directory: $DIR"
echo "=========================================================="

# 1. System check
if [ ! -f /etc/openwrt_release ]; then
    echo "[!] Error: /etc/openwrt_release not found. Not an OpenWrt system!"
    exit 1
fi
echo "[+] Detected OpenWrt: $(grep DISTRIB_DESCRIPTION /etc/openwrt_release | cut -d= -f2)"

# 2. Configure opkg architecture compatibility
echo "[+] Configuring /etc/opkg/arch.conf..."
mkdir -p /etc/opkg /var/lock /tmp/opkg-lists
cp -f "$DIR/files/etc/opkg/arch.conf" /etc/opkg/arch.conf

# 3. Install OpenWrt 21.02.7 IPK packages
echo "[+] Installing LuCI and uhttpd packages..."
if [ ! -d "$DIR/ipks" ]; then
    echo "[!] Error: ipks/ directory not found!"
    exit 1
fi
opkg install --force-depends "$DIR/ipks/"*.ipk

# 4. Install custom LuCI Telephony SMS files (back up stock controller outside controller/)
echo "[+] Installing Telephony SMS controller and view..."
if [ -f /usr/lib/lua/luci/controller/admin/telephony.lua ] && [ ! -f /etc/telephony.lua.stock.bak ]; then
    if ! grep -q "action_sms_list" /usr/lib/lua/luci/controller/admin/telephony.lua 2>/dev/null; then
        cp -f /usr/lib/lua/luci/controller/admin/telephony.lua /etc/telephony.lua.stock.bak
    fi
fi
mkdir -p /usr/lib/lua/luci/controller/admin /usr/lib/lua/luci/view/admin_telephony
cp -f "$DIR/files/usr/lib/lua/luci/controller/admin/telephony.lua" /usr/lib/lua/luci/controller/admin/telephony.lua
cp -f "$DIR/files/usr/lib/lua/luci/view/admin_telephony/sms.htm" /usr/lib/lua/luci/view/admin_telephony/sms.htm
chmod 644 /usr/lib/lua/luci/controller/admin/telephony.lua
chmod 644 /usr/lib/lua/luci/view/admin_telephony/sms.htm
lua -e 'assert(loadfile("/usr/lib/lua/luci/controller/admin/telephony.lua"))'
lua -e 'local tp = require "luci.template.parser"; local f, _, err = tp.parse("/usr/lib/lua/luci/view/admin_telephony/sms.htm"); assert(f, err)'

# 5. Install DHCP watchdog (resolves 4-5 min DHCP offer delay when Bridge Mode is disabled)
echo "[+] Installing 2s DHCP watchdog..."
cp -f "$DIR/files/usr/sbin/dhcp-watchdog.sh" /usr/sbin/dhcp-watchdog.sh
chmod 755 /usr/sbin/dhcp-watchdog.sh
cp -f "$DIR/files/etc/init.d/dhcp-watchdog" /etc/init.d/dhcp-watchdog
chmod 755 /etc/init.d/dhcp-watchdog

# 6. Configure uhttpd (:4153), luci, and rpcd
echo "[+] Configuring uhttpd, luci, and rpcd..."
mkdir -p /etc/config
cp -f "$DIR/files/etc/config/uhttpd" /etc/config/uhttpd
cp -f "$DIR/files/etc/config/luci" /etc/config/luci

# Detect admin password hash from /etc/passwd or /etc/shadow (fallback to stock hash)
ADMIN_HASH="$(awk -F: '$1=="admin"{print $2}' /etc/passwd 2>/dev/null)"
if [ -z "$ADMIN_HASH" ] || [ "$ADMIN_HASH" = "x" ] || [ "$ADMIN_HASH" = "*" ]; then
    ADMIN_HASH="$(awk -F: '$1=="admin"{print $2}' /etc/shadow 2>/dev/null)"
fi
if [ -z "$ADMIN_HASH" ] || [ "$ADMIN_HASH" = "x" ] || [ "$ADMIN_HASH" = "*" ]; then
    ADMIN_HASH='$1$$vxm5bqjYGHwijwoWbmkiA1'
fi
echo "[+] Setting rpcd admin authentication..."
cp -f "$DIR/files/etc/config/rpcd" /etc/config/rpcd
printf "\nconfig login\n\toption username 'admin'\n\toption password '%s'\n\tlist read '*'\n\tlist write '*'\n" "$ADMIN_HASH" >> /etc/config/rpcd
chmod 600 /etc/config/rpcd

# 7. Enable and start services
echo "[+] Enabling and starting services..."
/etc/init.d/uhttpd enable
/etc/init.d/uhttpd restart
/etc/init.d/rpcd enable
/etc/init.d/rpcd restart
/etc/init.d/dhcp-watchdog enable
/etc/init.d/dhcp-watchdog restart

# 8. Add persistent files to /etc/sysupgrade.conf
echo "[+] Registering files in /etc/sysupgrade.conf for persistence..."
for p in \
  /usr/lib/lua/luci/controller/admin/telephony.lua \
  /usr/lib/lua/luci/view/admin_telephony/sms.htm \
  /usr/sbin/dhcp-watchdog.sh \
  /etc/init.d/dhcp-watchdog
do
  grep -qxF "$p" /etc/sysupgrade.conf 2>/dev/null || echo "$p" >> /etc/sysupgrade.conf
done

# 9. Clean LuCI caches
echo "[+] Flushing LuCI menu and module caches..."
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache /tmp/smstmp*
sync

# 10. Verification
echo ""
echo "=========================================================="
echo " Verification:"
echo "----------------------------------------------------------"
echo " * uhttpd port 4153: $(netstat -lntp 2>/dev/null | grep -q '4153' && echo 'RUNNING (OK)' || echo 'FAILED')"
echo " * rpcd service:     $(pidof rpcd >/dev/null 2>&1 && echo 'RUNNING (OK)' || echo 'FAILED')"
echo " * dhcp-watchdog:    $(ps w | grep -q '[d]hcp-watchdog.sh' && echo 'RUNNING (OK)' || echo 'FAILED')"
echo " * Overlay free:     $(df -h /overlay 2>/dev/null | awk 'NR==2{print $4 " available (" $5 " used)"}')"
echo "=========================================================="
echo " Installation Complete!"
echo " Access LuCI Web Interface at:"
echo "   http://<ODU_IP>:4153/"
echo "   (e.g., http://192.168.10.1:4153/)"
echo " Login:"
echo "   Username: admin"
echo "   Password: <Your ODU admin password>"
echo " SMS Feature:"
echo "   Navigate to: Telephony -> SMS"
echo "=========================================================="