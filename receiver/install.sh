#!/bin/bash
# Installs the PagerRTTY receiver on a Raspberry Pi / Debian box.
set -e
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
cd "$(dirname "$0")"
apt-get install -y minimodem
install -m 755 pagerrtty-rx.sh /usr/local/bin/pagerrtty-rx.sh
[ -f /etc/default/pagerrtty-rx ] || install -m 644 pagerrtty-rx.env /etc/default/pagerrtty-rx
install -m 644 pagerrtty-rx.service /etc/systemd/system/pagerrtty-rx.service
systemctl daemon-reload
echo "Edit /etc/default/pagerrtty-rx (NR_HOST, ALSA_DEV), then:"
echo "  sudo systemctl enable --now pagerrtty-rx"
echo "List sound cards with: arecord -l"
