# TrickyStore Helper

**A helper module for [TrickyStore](https://github.com/5ec1cff/TrickyStore) that automatically generates and maintains `target.txt`.**

> Enhanced fork of CaptainThrowback's original helper, optimized for Magisk, KernelSU and APatch with a live monitor daemon and robust config preservation.

---

## ✨ Features

### 👁️ Live Monitor Daemon
- Instantly detects newly installed apps
- Appends them to `target.txt`
- Automatically restarts required services
- Respects exclusions and never duplicates entries
- Event-driven (`inotifyd`) → zero idle battery drain

### 🧠 Smart Target Generator
- High-speed stream pipeline (pm → sort → awk)
- Alphabetically sorted discovered apps
- Forced entries preserve manual order
- Split output structure for readability:
  - **Forced section**
  - **Discovered apps section**

### ⚠️ Error Detection & Reporting
- Duplicate forced entries detected and reported
- Invalid package lines are ignored and logged
- Clear UI + log summaries after each generation

### 🎮 Interactive Control Panel
Run `service.sh` in a terminal to:

- View daemon status
- Start/stop the live monitor
- Inspect watcher PIDs

### 🛡️ Upgrade-Safe Configuration
- User config is preserved across reinstalls
- Automatic migration from legacy helper location
- Module-local configuration (no external dependency)

### 🔒 Atomic Boot Lock
Prevents race conditions during boot on all supported root solutions.

---

## 📦 Installation

1. Install **TrickyStore** first
2. Flash `TrickyStoreHelper_v1.1.8.zip` in Magisk / KernelSU / APatch
3. Reboot

### First-run behavior (important)

On installation, **all user apps are added to `exclude.txt` by default**.

This means the module starts in a safe **opt-in mode**:

- Apps listed in `exclude.txt` are *not* added to `target.txt`
- To include an app, simply **comment it out** in `exclude.txt`
- The monitor will then treat it as eligible for discovery

Upgrading over an existing install preserves your configuration automatically.

---

## 📂 File Locations (Breaking Change in v1.1.x)

### New helper directory

```
/data/adb/modules/trickystorehelper/helper/
```

All configuration and logs now live **inside the module folder**.

### Legacy migration

On upgrade, the installer will:

1. Migrate from `/data/adb/tricky_store/helper` if present
2. Fall back to the existing module helper folder
3. Otherwise create the default helper folder and config files.

The legacy folder is removed after migration.

---

## 🛠️ Usage

### Automatic (Live Monitor)

Just use your phone normally.

- Install an app → it is detected and appended
- Services restart automatically
- No manual action required

Uninstalled apps remain in `target.txt` until manually cleaned.

---

### Manual Regeneration (Action Button)

In your root manager:

Modules → TrickyStore Helper → **Action**

This rebuilds `target.txt` and prints a summary.

---

### Terminal Control Panel

```bash
su -c sh /data/adb/modules/trickystorehelper/service.sh
```

Example:

```text
========================================
   TrickyStore Helper - Control Panel
========================================
 STATUS:  🟢 RUNNING
 Watcher: 12345
 Loop:    12340
========================================
 Do you want to STOP the service? (y/n):
```

---

## 🧾 target.txt Structure

Generated output is split into three sections:

```
🛠️ End of Forced List 🛠️

🔎 Discovered Apps 🔎

🔎 Newly Installed Apps (Review) 🔎

```

- **Forced section** preserves your curated order
- **Discovered apps** are alphabetically sorted
- Suffix rules (`?` / `!`) are respected
- **Newly Installed Apps (Review)** Listed separately after discovered apps for review until next action.sh run.

---

## ⚙️ Configuration

All config lives in:

```
/data/adb/modules/trickystorehelper/helper/
```

| File | Purpose |
|------|--------|
| `config.txt` | Main behavior settings |
| `exclude.txt` | Packages that must never be added |
| `force.txt` | Packages always included |
| `TSHelper.log` | Execution logs and diagnostics |

> Do not edit `target.txt` directly for exclusions — use `exclude.txt`.

---

### config.txt Options

| Option | Default | Description |
|--------|--------|-------------|
| `RUN_ON_BOOT` | true | Regenerate full list on boot |
| `USE_DEFAULT_EXCLUSIONS` | true | Exclude system apps by default |
| `FORCE_LEAF_HACK` | false | Append `?` globally during rebuild |
| `FORCE_CERT_GEN` | false | Append `!` globally during rebuild |

---

## 📝 Changelog

### v1.1.8

- **Breaking:** Helper folder moved inside module directory
- Automatic migration from legacy helper path
- User apps initially added to exclude.txt. Simply comment out the apps you want in `target.txt`
- Split `target.txt` into forced + discovered sections
- Newly installed apps listed separately after discovered apps for review until next action.sh run.
- Alphabetical sorting for discovered apps
- Duplicate detection and invalid line reporting
- Improved installer config preservation
- Hardened pipeline and logging

### v1.0.0

- First stable release

### v0.4.x

- Introduced Live Monitor daemon
- Interactive control panel
- Differential update logic
- Boot race condition fixes

---

## Credits

- Original helper by CaptainThrowback
- TrickyStore by 5ec1cff
- 90% of this code was written by Gemini; the other 10% is the part that actually works.

---

## ⚠️ Disclaimer

Use at your own risk. This tool modifies TrickyStore configuration automatically.
