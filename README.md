# G615JPR ASUS Lightbar Fix

This repository contains an AI experiment to get ASUS Aura file overrides that made the front RGB lightbar work on a `G615JPR` laptop.

## Tested On

- Product family: `ROG Strix G16`
- Board name: `G615JPR`
- Aura USB device: `0B05:19B6`
- `asusctl` / `asusd`: `6.3.4`

## What It Changes

- Replaces `/usr/share/asusd/aura_support.ron` with a copy that adds an explicit `G615JPR` entry with `Keyboard` and `Lightbar`
- Replaces `/etc/asusd/aura_19b6.ron` with a copy that enables the `Lightbar` power zone
- Restarts `asusd`

## Repository Layout

- [`files/aura_support.ron`](files/aura_support.ron): patched ASUS support table
- [`files/aura_19b6.ron`](files/aura_19b6.ron): patched live Aura config
- [`reference/aura_support.ron.original`](reference/aura_support.ron.original): original system support table captured before the patch
- [`reference/aura_19b6.ron.original`](reference/aura_19b6.ron.original): original Aura config captured before the patch
- [`install.sh`](install.sh): installer that backs up the current files, installs the bundled versions, and restarts `asusd`
- [`scripts/toggle-lightbar`](scripts/toggle-lightbar): user-level helper that toggles the lightbar power zone on and off
- [`hypr/m5-lightbar-bind.conf`](hypr/m5-lightbar-bind.conf): Hyprland bind snippet for the ASUS `M5` key

## Install

Run from the repository root:

```bash
./install.sh
```

The installer:

- checks that the board is `G615JPR`
- creates a timestamped backup in `/var/tmp`
- installs the bundled files with `sudo`
- restarts `asusd`

## Force Install On Another Board

If you want to try this on a similar machine, inspect the bundled files first and then run:

```bash
./install.sh --force
```

Only do this if you are confident the Aura layout is compatible.

## Verify

Check the `asusd` logs:

```bash
sudo journalctl -b -u asusd --no-pager | grep -E "Matched to G615JPR|no entry for this model"
```

Expected result:

- `Matched to G615JPR` appears
- `no entry for this model` does not appear
- the front RGB strip lights up physically

## M5 Toggle

On this `G615JPR`, the ASUS `M5` key emits Linux `KEY_PROG1`, which Hyprland sees as `code:156`.

The bundled helper toggles the lightbar power zone:

```bash
./scripts/toggle-lightbar
```

To install it for your user:

```bash
install -Dm755 ./scripts/toggle-lightbar ~/.local/bin/toggle-lightbar
```

To bind `M5` in Hyprland, add the line from [`hypr/m5-lightbar-bind.conf`](hypr/m5-lightbar-bind.conf) to your personal Hypr config, for example `~/.config/hypr/bindings.conf`:

```ini
bindrd = , code:156, Toggle lightbar, exec, ~/.local/bin/toggle-lightbar
```

Then reload Hyprland:

```bash
hyprctl reload
```

Notes:

- `bindrd` triggers on key release, which avoids repeated toggles while the key is held
- the helper stores its last known state in `~/.local/state/lightbar-state`
- the helper tries `asusctl` first, then `sudo -n`, then `pkexec`

## Rollback

The installer prints the backup directory path, for example `/var/tmp/g615-lightbar-backup-YYYYMMDD-HHMMSS`.

To roll back, copy the backed-up files back into place and restart `asusd`:

```bash
sudo cp /var/tmp/g615-lightbar-backup-YYYYMMDD-HHMMSS/aura_support.ron /usr/share/asusd/aura_support.ron
sudo cp /var/tmp/g615-lightbar-backup-YYYYMMDD-HHMMSS/aura_19b6.ron /etc/asusd/aura_19b6.ron
sudo systemctl restart asusd
```

If the original `/etc/asusd/aura_19b6.ron` did not exist on your system, only restore the files that were actually backed up.

## Notes

- This is a full-file replacement, not a package-managed patch
- If your distro updates `asusctl` or `asusd`, rerun the installer or port the `G615JPR` entry into the newer packaged `aura_support.ron`
- This repository is intended for `G615JPR` first; use it on other boards only if you understand the risk
