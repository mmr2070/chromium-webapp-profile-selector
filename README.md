# Chromium Webapp Profile Selector

A lightweight **OmarchyOS plugin** that lets each Chromium webapp use its own Chromium profile. Works transparently through the existing Omarchy webapp launcher — no daemons, no background services, no PATH manipulation.

---

## Features

- **Per-webapp profile selection** — each webapp can use a different Chromium profile
- **Temporary (one-time) selection** — use a profile for a single launch without saving it
- **Permanent profile assignment** — skip the selector on all future launches of that webapp
- **Dynamic profile detection** — discovers all your Chromium profiles automatically from `~/.config/chromium/Local State`
- **Clean TUI labels** — unique profile names show only the human-readable name; duplicate names are disambiguated using Chromium's internal profile directory
- **Stable URL-based webapp identity** — no mapping collisions between webapps, even if two have the same display name
- **Missing profile detection** — if a saved profile is deleted in Chromium, the selector reappears automatically
- **Reset and repair tools** — `webapp-profile-reset` with `--status` and `--repair` flags
- **Normal Chromium untouched** — regular `chromium` launches completely bypass the plugin
- **Reboot persistent** — mappings survive reboots and Chromium restarts
- **Atomic configuration** — all config writes use `mktemp` + `mv`; the config is always in a valid state
- **Fully detached webapp** — the Chromium webapp process is completely independent of the TUI terminal via `setsid` + stdio redirection

---

## Requirements

- **OmarchyOS** (Hyprland-based, with `omarchy launch tui` available)
- **Chromium** installed at `/usr/bin/chromium`
- **uwsm** / **uwsm-app** (included with OmarchyOS)
- **jq** — JSON processor (typically pre-installed on OmarchyOS)
- **gum** — charmbracelet TUI tool (typically pre-installed on OmarchyOS)
- **setsid** — standard Linux utility, part of `util-linux`

---

## Installation

```bash
git clone https://github.com/mmr2070/chromium-webapp-profile-selector.git
cd chromium-webapp-profile-selector
bash install.sh
```

Verify the installation:

```bash
webapp-profile-reset --status
```

Expected output:

```
Chromium Webapp Profile Selector
Status: OK

Desktop entry:
  ~/.local/share/applications/chromium.desktop
System desktop entry:
  /usr/share/applications/chromium.desktop
Wrapper:
  ~/.local/bin/chromium-webapp-wrapper
Configuration (OK):
  ~/.config/webapp-profile-selector/config.json

Webapp interception: ACTIVE
```

---

## Usage

### First Launch — Profile Selector Appears

When you launch a webapp that has no saved profile mapping, the selector TUI appears automatically:

```
Press Omarchy keyboard shortcut (e.g. ChatGPT)
    ↓
Profile selector TUI opens in a terminal window
    ↓
Arrow keys to navigate, Enter to select a profile
    ↓
"Set this profile as default for this webapp?" → YES or NO
    ↓
TUI terminal closes
    ↓
Chromium webapp opens using the selected profile
```

---

### Temporary Selection (choose NO)

Select a profile and choose **No** when asked to save it as default:

- The webapp opens using the selected profile for **this launch only**.
- No mapping is saved.
- The **next launch** of the same webapp will show the TUI again.

---

### Permanent Assignment (choose YES)

Select a profile and choose **Yes** when asked to save it as default:

- The webapp opens using the selected profile.
- The mapping is saved permanently.
- All **future launches** of this webapp skip the TUI entirely and go directly to Chromium.

---

## Resetting Mappings

```bash
# Interactive TUI: reset a specific webapp or reset all mappings
webapp-profile-reset

# Check plugin health / interception status
webapp-profile-reset --status

# Rebuild the desktop override after a Chromium or OmarchyOS update
webapp-profile-reset --repair
```

**Safe by design:** reset only removes webapp→profile mappings from the plugin's own config file. Chromium profiles and all browsing data are never touched.

---

## Configuration

The plugin stores its configuration at:

```
~/.config/webapp-profile-selector/config.json
```

Example:

```json
{
  "webapps": {
    "https://chatgpt.com": {
      "profile": "Profile 5"
    },
    "https://web.whatsapp.com/": {
      "profile": "Default"
    }
  }
}
```

- **Keys** are the canonical webapp URLs (from the `--app=<url>` Chromium argument).
- **Values** are Chromium's internal profile directory names (`Default`, `Profile 1`, `Profile 2`, etc.).
- **Chromium's own profile data is never read, written, or modified.**
- All writes to this file are atomic (write to `mktemp`, then `mv` into place).
- If the file becomes corrupt, it is automatically backed up and reset to a valid empty state.

---

## Architecture

```
Omarchy launcher / keyboard shortcut
        ↓
~/.local/share/applications/chromium.desktop   ← user-level override
        ↓
chromium-webapp-wrapper                        ← detects --app= flag
        ↓
  ┌─ --app= absent ─────────────────────────────→ exec /usr/bin/chromium (plugin exits, normal launch)
  │
  └─ --app= present (webapp detected)
            ↓
          config lookup by URL key
            ↓
          ┌─ saved profile found & still exists ──→ exec /usr/bin/chromium --profile-directory=...
          │
          └─ no valid saved profile
                    ↓
                  omarchy launch tui   (transient terminal window)
                    ↓
                  webapp-profile-selector-tui
                    ↓
                  user selects profile  (arrow keys + Enter)
                    ↓
                  (optional) save mapping atomically to config.json
                    ↓
                  exec setsid uwsm-app -- /usr/bin/chromium ... </dev/null >/dev/null 2>&1
                    ↓
                  TUI terminal closes — Chromium webapp runs independently
```

The `setsid` + stdio redirection ensures the Chromium webapp process is fully detached from the TUI terminal's process group and session. Closing the TUI terminal **cannot** kill the webapp.

---

## Safety & Isolation

- **Normal Chromium is completely untouched.** If `--app=` is absent, the wrapper immediately `exec`s `/usr/bin/chromium "$@"` — all original arguments are preserved unchanged.
- **No Chromium profiles are created, deleted, renamed, or modified.**
- **No Chromium browsing data is accessed.**
- **No background daemon or service is created.**
- **No PATH modification is required.**
- All Chromium arguments are passed via Bash arrays — no `eval`, no string splitting.
- Both `--profile-directory=Name` and `--profile-directory Name` argument forms are recognized.
- An empty `--app=` flag is rejected and passed through to Chromium normally.

---

## Troubleshooting

**TUI doesn't appear / webapp always opens without profile selection:**
```bash
webapp-profile-reset --status
webapp-profile-reset --repair
```

**Webapp launches but uses the wrong profile:**
```bash
webapp-profile-reset   # choose "Reset Specific Webapp" from the menu
```

**After a Chromium or OmarchyOS update (desktop entry changed):**
```bash
webapp-profile-reset --repair
```
This reads the current system `chromium.desktop`, rebuilds the user-level override, and refreshes the desktop database — preserving all new upstream metadata.

**Keyboard shortcuts work but app launcher doesn't (or vice versa):**

Log out and back in (or restart Hyprland) to ensure the application database cache is refreshed after installation.

**Webapp closes when I close the terminal:**

Make sure you are running the latest version of this plugin. The final stable release includes `setsid` + stdio redirection in the launch path, which fully detaches the webapp from the TUI terminal.

---

## Uninstallation

```bash
bash uninstall.sh
```

This removes the three scripts and the user-level desktop override. Chromium falls back to `/usr/share/applications/chromium.desktop` automatically.

Your saved webapp→profile mappings at `~/.config/webapp-profile-selector/` are **preserved**. Remove them manually if desired:

```bash
rm -rf ~/.config/webapp-profile-selector/
```

Chromium profiles and browsing data are **not modified** at any point.

---

## License

License not yet decided. Please open an issue or contact the author before redistributing.
