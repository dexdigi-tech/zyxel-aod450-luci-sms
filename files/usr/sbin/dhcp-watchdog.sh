#!/bin/sh
# Ensures udhcpd starts immediately on boot and recovers within 2s after
# link-flap or WAN reload kills when Bridge Mode is disabled.
# Also ensures USB RNDIS interface (rndis0) is always UP and bridged to br0.
while true; do
  # 1. udhcpd watchdog for Router Mode
  if [ -s /etc/udhcpd.conf ] && \
     [ "$(cat /proc/ccmni/bridge_mode_control 2>/dev/null)" = "0" ] && \
     grep -q 'DHCPServerEnable.*>1<' /var/pdm/config.xml 2>/dev/null; then
    if ! pidof udhcpd >/dev/null 2>&1; then
      logger -t dhcp-watchdog "udhcpd missing in Router mode; starting /usr/sbin/udhcpd"
      /usr/sbin/udhcpd &
    fi
  fi

  # 2. USB RNDIS tethering bridge watchdog
  if [ -d /sys/class/net/rndis0 ]; then
    ip link set rndis0 up 2>/dev/null
    if ! brctl show br0 2>/dev/null | grep -q 'rndis0'; then
      brctl setfd br0 0 2>/dev/null
      brctl addif br0 rndis0 2>/dev/null
      logger -t dhcp-watchdog "Bridged rndis0 into br0 with 0s forward delay"
    fi
  fi

  sleep 2
done
