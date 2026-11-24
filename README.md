# sddm-noctalia-blurry

A macOS-inspired, matte Qt6 SDDM login theme crafted for **CachyOS / Arch + Noctalia** setups — featuring clean Gaussian-blurred wallpaper syncing and live Noctalia color palette integration.

## Features

- **Noctalia Wallpaper Sync:** Automatically mirrors your active Noctalia wallpaper into `/var/lib/noctalia-sddm/wallpaper.png` with a clean ImageMagick Gaussian blur (`-blur 0x18`) via a systemd user timer.
- **Noctalia Palette Sync:** Reads your active Noctalia color scheme (`custom`, `wallpaper`, or GTK/Qt fallback) and generates `/var/lib/noctalia-sddm/Palette.qml` so the login accents, matte surfaces, and text match your desktop theme automatically.
- **macOS-Inspired Matte Layout:**
  - Upper-center 24h clock and date (`en_US` by default, configurable in `theme.conf`).
  - Top-right session switcher (and keyboard layout badge when multiple layouts are enabled).
  - Circular avatar (`92x92`) with a subtle hairline ring and automatic monogram fallback if no photo is set.
  - Matte password capsule (`radius: 16`) with inline submit button, focus/error accent ring, shake-on-error animation, and Caps Lock indicator.
  - Bottom `Sleep`, `Restart`, and `Shut Down` controls.
- **Multi-Monitor Friendly:** Renders the blurred wallpaper across all outputs while showing the interactive login controls only on the primary display.
- **Passwordless Background Sync:** Uses `sysusers.d` + `tmpfiles.d` (`noctalia-sddm` group owning `/var/lib/noctalia-sddm`) so user-level syncs never prompt for `sudo`.

## Requirements

- `sddm` (Qt6 greeter: `sddm-greeter-qt6`)
- `qt6-declarative`
- `imagemagick` (`magick`)
- `python` (`python3`)
- Optional: `noctalia` (for automatic wallpaper & palette sync), `hyprland` (for primary monitor auto-detection)

## Installation

### Arch / CachyOS (`makepkg`)

```bash
git clone https://github.com/munraitoo13/sddm-noctalia-blurry.git
cd sddm-noctalia-blurry/packaging/arch
makepkg -si
```

Then complete the one-time setup printed after installation:

```bash
sudo usermod -aG noctalia-sddm "$USER"
sudo install -Dm644 /usr/share/doc/sddm-noctalia-blurry/10-noctalia-blurry.conf /etc/sddm.conf.d/10-noctalia-blurry.conf
```

Log out and back in (or run `sudo chown "$USER":noctalia-sddm /var/lib/noctalia-sddm` once) so your current session can write to `/var/lib/noctalia-sddm`, then enable the timer and sync immediately:

```bash
noctalia-sddm-sync --force
systemctl --user enable --now noctalia-sddm-sync.timer
```

### Generic Linux (`install.sh`)

```bash
git clone https://github.com/munraitoo13/sddm-noctalia-blurry.git
cd sddm-noctalia-blurry
./install.sh --install
```

## Setting Your Avatar

Generate a `256x256` circular avatar cleanly from any image:

```bash
noctalia-sddm-sync --avatar ~/Pictures/avatar.jpg
```

If no avatar image exists, the theme displays a matching circular monogram using the user's initial.

## Preview Without Logging Out

Preview locally from the repository before installing:

```bash
./install.sh --preview
```

Or preview the installed system theme:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/noctalia-blurry
```

## Configuration

### Sync behavior (`~/.config/noctalia-sddm/config`)

Optional shell variables read by `noctalia-sddm-sync`:

```bash
MONITOR=""              # Auto-detected from Hyprland if empty, e.g. "DP-1"
BLUR_SIGMA="18"         # ImageMagick Gaussian blur sigma
RESIZE_MAX="1920x1080>" # Max wallpaper dimensions before blurring
MODULATE="94,108,100"   # Brightness,Saturation,Hue
SYNC_WALLPAPER="true"
SYNC_COLORS="true"
```

### Theme appearance (`theme/theme.conf`)

Settings under `[General]` in `/usr/share/sddm/themes/noctalia-blurry/theme.conf`:

- `fontFamily` (default `Adwaita Sans`)
- `dateLocale` / `dateFormat` / `timeFormat` (default `en_US` / `dddd, MMMM d` / `HH:mm`)
- `glassOpacity` (default `0.78`) and `cornerRadius` (default `16`)
- Fallback hex colors (`surfaceColor`, `primaryColor`, etc., overridden automatically when `/var/lib/noctalia-sddm/Palette.qml` exists)

## Uninstall

- **Package:** `sudo pacman -R sddm-noctalia-blurry-git` and remove `/etc/sddm.conf.d/10-noctalia-blurry.conf`.
- **Script:** `./install.sh --uninstall`

## License

[MIT](LICENSE)
