---
updated: 2026-09-27
covers: [input, controllers, retroarch]
status: current
---

# Controllers & input

Preconfigured keyboard, Xbox 360 (wired + wireless receiver), Xbox One / Series (USB and Bluetooth)
and PlayStation Classic mappings, in both ES and RetroArch (RetroArch 1.7.3 from Ubuntu 22.04).

## Key files & entry points

- `config/es_input.cfg`: ES keyboard + joystick `<inputConfig>`s. ES matches by SDL GUID first, then by
  `deviceName` (first match wins). The Xbox One / Series / PS Classic block was generated from
  SDL_GameControllerDB Linux entries (SDL `a/b/x/y` → ES `a/b/y/x`, `guide` → `hotkeyenable`). The
  first `Xbox Wireless Controller` entry (Bluetooth `02fd`, firmware 0903) is the by-name fallback.
- `config/retroarch.cfg`: base RetroArch config: dirs, video/audio, keyboard P1 keys, `udev` joypad
  driver, 2 users, L3+R3 = menu (`input_menu_toggle_gamepad_combo = "2"`). **No** global
  `input_exit_emulator_btn`: it would override the per-profile one.
- `config/retroarch-autoconfig/*.cfg` → `/etc/retroarch/autoconfig/`: one udev profile per
  vendor/product ID. Each carries its own exit hotkey (RetroArch falls back to autoconfig binds when
  the global bind is unset):
  - 360: `Microsoft X-Box 360 pad`, `Xbox 360 Wireless Receiver` (02a1, 0719). Guide = button 8.
  - Xbox One/Series USB (xpad, d-pad on hat 0): `02d1`, `02dd`, `02ea`, `0b12`. Guide = 8.
  - Xbox One S Bluetooth (hid-microsoft): `02fd` (gapped numbering: Back 15, Start 11, Guide 16,
    LT/RT axes 5/4) and `02e0` (Guide 10).
  - PlayStation Classic `054c:0cda`: d-pad on axes 0/1; hotkeys via `input_enable_hotkey_btn` =
    Select, Select+Start = exit, Select+Triangle = menu.

## How it works

- `es_input.cfg` and `retroarch.cfg` go to `/etc/emulationstation/defaults/` and are copied into the
  volumes on first run only. Autoconfig profiles are read from the image on every run.
- The controllers reach the container through `/dev/input` + `/run/udev` mounts and `device_cgroup_rules: c 13:* rmw`.
  Bluetooth pads appear there as regular evdev devices. The entrypoint adds `es` to the host GID that
  owns the devices. See [entrypoint](entrypoint.md).
- SDL and RetroArch-udev number buttons/axes the same way (evdev code order, hats excluded from axes),
  so an SDL_GameControllerDB entry translates directly to both files.

## Gotchas & constraints

- Changes to `es_input.cfg`/`retroarch.cfg` **don't reach existing installs** (volume copy wins).
  Users need `docker compose down -v`. See [recipes](../recipes.md#change-a-default-config).
- Buttons map by physical position: RetroPad B (bottom) = Xbox A = PS Cross.
- RetroArch matches autoconfig by vendor/product ID + name, not firmware. Bluetooth `02fd` on newer
  firmware (5.x) reports xpad-style numbering but gets the 0903 profile; ES handles it (separate GUID).
- Bluetooth `0b13`/`0b20`/`0b22` are not covered: upstream sources disagree on their numbering.
  ES shows its mapping wizard; in RetroArch map them in *Settings → Input*.
- In RetroArch 1.7.3 joypad hotkeys only work for the player-1 device. A PS Classic pad as player 1
  also requires Select held for keyboard hotkeys (Esc).
- Linux hosts only. `input_joypad_driver = "udev"` needs `/run/udev` mounted.

## Related

- [deploy](deploy.md), README section "Mandos"
