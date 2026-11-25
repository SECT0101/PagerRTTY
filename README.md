# PagerRTTY – RTTY from the [WiFi Pineapple Pager](https://hak5.org/products/wifi-pineapple-pager)

<p align="center"><img src="docs/logo-animated.png" width="260" alt="PagerRTTY shield: Tac-Pine in a phone booth blowing a 2600 Hz whistle into the handset"></p>

[![Buy Me a Coffee](https://img.shields.io/badge/Buy_me_a_coffee-support-FFDD00?logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/sect0101)

Send position and field reports from a **Hak5 WiFi Pineapple Pager** as **RTTY**
(ITA2/Baudot) through the Pager's own buzzer. No network needed: hold a radio's
mic to the Pager, or let any RTTY decoder listen. On the receiving end, a small
receiver service turns the audio back into text and a Node-RED flow puts it on
TAK as markers and GeoChat. A **Phone Phreak** menu adds the 2600 Hz whistle and
classic phreaking tones for fun.

> **Version 1.0.0-beta.2.** Tested on a Pager: RTTY decodes cleanly with minimodem. No binaries: the audio is built by small awk scripts and played on the Pager's buzzer sound card.

**Written in DuckyScript™ + Bash and awk for the WiFi Pineapple Pager. A community payload, not supported or guaranteed by Hak5.**

Sister projects: [PagerTAK](https://github.com/SECT0101/PagerTAK) puts the Pager on TAK, [PagerMesh](https://github.com/SECT0101/PagerMesh) adds Meshtastic. The layout follows the official [hak5/wifipineapplepager-payloads](https://github.com/hak5/wifipineapplepager-payloads) library, so the payload folder can be copied straight to the Pager.

```
Pager buzzer ))) radio / air ))) sound card + minimodem ── UDP ──> Node-RED ──> TAK Server
```

## Requirements

- **Pager firmware 2.1.0 or newer** (adds the buzzer sound card, `pager-pcm`).
  Check with `cat /proc/asound/cards`: it should list *Pager buzzer*.
- **aplay** from `alsa-utils`. If it's missing, the payload offers to install it
  (`opkg install alsa-utils`, needs internet once).


## Signal

| Setting   | Value                                   |
|-----------|-----------------------------------------|
| Mode      | RTTY, ITA2 (US-TTY figures)             |
| Baud      | 45.45                                   |
| Shift     | ~170 Hz (mark 3909 Hz, space 4091 Hz)   |
| Center    | 4000 Hz, normal polarity                |
| Stop bits | 1.5                                     |

Any standard RTTY decoder (fldigi, DroidRTTY, minimodem) reads it at its normal
170 Hz setting: just tune the center to 4000 Hz. The tones sit at the buzzer's
loudest spot (lower tones come out too faint to decode). Each tone fits a whole
number of cycles into one 22 ms bit, so the waveform is seamless and the timing
is exact.

## Message format

```
DE <CALL> <TYPE> [POS <lat> <lon>] [TXT <text>] <HHMM>Z CK<xx>
DE SECT-PAGER LOC POS 37.7749N 122.4194W 1430Z CK15
DE SECT-PAGER SITREP POS 37.7749N 122.4194W TXT AMBER ROAD BLOCKED 1430Z CK0D
```

- `TYPE` is `LOC`, `SALUTE`, `SITREP`, `MSG` or `TEST`
- `POS` is included when the Pager has a GPS fix (decimal degrees, 4 places)
- `CK` is an XOR checksum of everything from `DE` up to the space before `CK`
- Text is limited to `A-Z 0-9 ? : ( ) , . / -` so every decoder agrees on it

*(Coordinates above are demo values.)*

## Pager payload

Copy `library/user/general/PagerRTTY/` to `/root/payloads/user/general/PagerRTTY/`
on the Pager and run it from the payload menu.

| Menu            | What it does                                              |
|-----------------|-----------------------------------------------------------|
| Send position   | Sends `LOC` with the current GPS fix                      |
| SALUTE report   | Prompts S-A-L-U-T-E, sends it with position               |
| SITREP          | Status (GREEN/AMBER/RED/BLACK) + remarks                  |
| Free text       | Sends any short message                                   |
| Beacon position | Sends `LOC` every N minutes until the payload is stopped  |
| Test tones      | `RYRYRY THE QUICK BROWN FOX 0123456789`                   |
| Phone Phreak    | 2600 Hz whistle, plus DTMF, blue box, red box, call progress as sound FX |
| Settings        | Callsign (default: hostname), volume, lead-in, repeat, beacon interval |

**Tips**
- Using a radio with VOX: raise the lead-in to 1500 ms or more so the radio keys up first.
- Noisy channel: set Repeat to 2. The Node-RED flow drops duplicates.

### How the audio is made

`rtty.awk` turns a message into ITA2 RTTY audio (raw 8-bit, 16 kHz) using only
BusyBox `awk`, and the payload streams it to the buzzer's sound card with
`aplay`. A message is built in about 0.2 s on the Pager, so the tones start
right away. `tones.awk` does the same for the Phone Phreak sounds.

```
awk -v msg="DE TEST" -f rtty.awk | aplay -q -t raw -f U8 -r 16000 -c 1
awk -v seq="2600:1000" -f tones.awk | aplay -q -t raw -f U8 -r 16000 -c 1   # Hz:ms, F1+F2 = two tones
```

## Phone Phreak menu

A nod to the phone phreakers.

| Item                     | Tones                                                  | Decodes? |
|--------------------------|--------------------------------------------------------|----------|
| 2600 Hz whistle          | Cap'n Crunch: 2600 Hz for 1 s                          | Yes      |
| DTMF (sound FX)          | 0-9 * # A-D (697-941 + 1209-1633 Hz)                   | No       |
| Blue box (sound FX)      | 2600 Hz seize, then KP + digits + ST (700-1700 Hz pairs) | No     |
| Red box (sound FX)       | 1700+2200 Hz: nickel 1 beep, dime 2, quarter 5         | No       |
| Call progress (sound FX) | Dial tone, ringback, busy, reorder (350-620 Hz pairs)  | No       |

**Why "sound FX":** the Pager's buzzer can't reproduce sound below about
1.5-2 kHz, so the low tones of DTMF, blue box, red box and call progress never
leave the speaker and real decoders don't recognize them. `tones.awk` plays them
as square waves, whose harmonics keep them audible. They're here for fun and
history. A future release may add USB or Bluetooth audio for the real thing.

Phone networks have signaled out-of-band for decades, so none of this does
anything on a phone line today.

## Receiver (Raspberry Pi or any Debian box)

Needs a sound-card input fed from the radio's speaker or earphone jack (a cheap
USB sound card works; keep the level low so it doesn't clip).

```
cd receiver
sudo ./install.sh
sudo nano /etc/default/pagerrtty-rx     # NR_HOST, NR_PORT, ALSA_DEV
sudo systemctl enable --now pagerrtty-rx
```

Each decoded line is sent to Node-RED as UDP `<receiver-hostname>|<line>`.

## Node-RED flow

Import `nodered/PagerRTTY-to-TAK.json`, then:

1. Open the **PagerRTTY cert** TLS config and set this feed's client cert and key.
2. Open **TAK Server (PagerRTTY)** and set your TAK Server host (port 8089).
3. Make sure the UDP port (4545) matches `NR_PORT` on the receiver.
4. Deploy, then send **Test tones** from the Pager.

The flow checks the checksum, drops repeats inside 120 s, and sends:
- positions as a friendly ground unit marker (`a-f-G-U-C`), stale 30 minutes
- SALUTE / SITREP / MSG / TEST as GeoChat to **All Chat Rooms**

## Radio use

The payload only makes sound. Whoever keys a transmitter with it is responsible
for operating within that radio service's rules: an amateur license on ham
frequencies, and your agency's policy on public-safety channels. Messages are
plain text and are not encrypted.

## License

GPL-3.0. See [LICENSE](LICENSE).
