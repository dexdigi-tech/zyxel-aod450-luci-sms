#!/bin/sh
# Ensures udhcpd starts immediately on boot and recovers within 2s after
# link-flap or WAN reload kills when Bridge Mode is disabled.
while true; do
  if [ -s /etc/udhcpd.conf ] && \
     [ "$(cat /proc/ccmni/bridge_mode_control 2>/dev/null)" = "0" ] && \
     grep -q 'DHCPServerEnable.*>1<' /var/pdm/config.xml 2>/dev/null; then
    if ! pidof udhcpd >/dev/null 2>&1; then
      logger -t dhcp-watchdog "udhcpd missing in Router mode; starting /usr/sbin/udhcpd"
      /usr/sbin/udhcpd &
    fi
  fi
  sleep 2
done