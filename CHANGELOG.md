# Changelog

PagerRTTY versions (the payload in `library/user/general/PagerRTTY`). Newest first.

## 1.0.0-beta.2
- No more binary: RTTY audio is built by `rtty.awk` (BusyBox awk) and played on the Pager's buzzer sound card (`pager-pcm`) with `aplay`. Removed `rtty-tx`, its source and the download/SHA-256 code.
- Offers to install `alsa-utils` on first run if `aplay` is missing.
- Tones 3909/4091 Hz (about 170 Hz shift, center 4000 Hz): each bit holds whole cycles, so audio builds in about 0.2 s and streams instantly.
- Removed the CLASSIC tone option (too faint on the buzzer).
- Phone Phreak sounds built by `tones.awk` as square waves so they stay audible.
- Volume setting is now a percentage (default 80%).
- Requires Pager firmware 2.1.0 or newer (adds the buzzer sound card, `pager-pcm`).

## 1.0.0-beta.1
- First release.
- RTTY (ITA2, 45.45 baud, 170 Hz shift) through the Pager buzzer with `rtty-tx`: exact bit timing, LOUD (4000 Hz center) or CLASSIC (2125/2295 Hz) tones.
- Send position, SALUTE, SITREP, free text, beacon and test tones; checksum on every message.
- Phone Phreak menu: 2600 Hz whistle, plus DTMF, blue box, red box and call progress as sound FX.
- `rtty-tx` found in the payload's own `bin/` folder; if missing, optional download from the GitHub release, kept only if the SHA-256 matches.
- Receiver service (minimodem) and Node-RED flow to put messages on TAK as markers and GeoChat.
