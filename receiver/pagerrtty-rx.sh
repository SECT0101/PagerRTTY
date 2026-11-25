#!/bin/bash
# PagerRTTY receiver - decodes RTTY from a sound card and forwards each line
# to Node-RED over UDP. Settings come from /etc/default/pagerrtty-rx.
set -u
: "${NR_HOST:=127.0.0.1}" "${NR_PORT:=4545}"
: "${MARK:=3909}" "${SPACE:=4091}" "${ALSA_DEV:=}" "${SRC_TAG:=$(hostname)}"

ALSA_ARG=(); [ -n "$ALSA_DEV" ] && ALSA_ARG=(--alsa="$ALSA_DEV")

while true; do
    # -q: no carrier banners; text only. stdbuf keeps characters flowing live.
    stdbuf -o0 minimodem --rx -q "${ALSA_ARG[@]}" -M "$MARK" -S "$SPACE" rtty \
    | tr -d '\r' \
    | while IFS= read -r line; do
        line="${line//[^A-Z0-9 ?:(),.\/-]/}"
        [ -z "$line" ] && continue
        logger -t pagerrtty-rx "$line"
        printf '%s|%s\n' "$SRC_TAG" "$line" > "/dev/udp/$NR_HOST/$NR_PORT" 2>/dev/null
      done
    logger -t pagerrtty-rx "minimodem exited, restarting in 5 s"
    sleep 5
done
