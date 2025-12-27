# TrickyStore Helper

**A helper module for [TrickyStore](https://github.com/5ec1cff/TrickyStore) to automatically generate and manage `target.txt`.**

> **Note:** This is an enhanced fork of [CaptainThrowback's original helper](https://github.com/CaptainThrowback/TrickyStoreHelper), optimized for speed and compatibility with KernelSU, APatch, and Magisk.

## ✨ Features (v0.4.0)

* **👁️ Live Monitor Daemon:**
    * Instantly detects when you install a new app.
    * Appends it to `target.txt` and restarts TrickyStore automatically.
    * **Smart Logic:** Respects your `exclude.txt` and ignores system updates.
    * **Conflict-Free:** Only adds *missing* apps. It never touches your existing entries or custom suffixes (`?`/`!`).
* **🎮 Interactive Control Panel:**
    * Run the service script in a terminal to view status, stop, or start the daemon.
* **🛡️ "Set & Forget" Architecture:**
    * **Zero Battery Drain:** Uses event-driven `inotifyd` (sleeps until an app is installed).
    * **Keep-Alive:** Automatically recovers if the system rotates package logs.
* **⚡ Optimized Generator:**
    * High-speed generation logic compatible with Magisk, KernelSU, and APatch.
* **🔒 Atomic Boot Lock:**
    * Prevents double-execution race conditions during boot on all root solutions.

## 📦 Installation

1.  Ensure **TrickyStore** is already installed.
2.  Flash `TrickyStoreHelper_v0.4.0.zip` in your root manager (Magisk/KSU/APatch).
3.  Reboot.

## 🛠️ Usage

### 1. Automatic (Live Monitor)
Just use your phone normally.
* **Install an App:** The Live Monitor sees it, adds it to `target.txt`, and reloads the store.
* **Uninstall an App:** The entry remains (safe) until you decide to clean it up manually.

### 2. Manual Cleanup (Action Button)
If you want to remove uninstalled apps or force global suffixes:
* Open your Root Manager (Magisk, KernelSU, or APatch).
* Go to the **Modules** tab.
* Tap the **Action** button on the TrickyStore Helper card.

### 3. The Control Panel (Terminal)
You can manage the background service manually via Termux or ADB:

```bash
su -c sh /data/adb/modules/trickystorehelper/service.sh
```

This opens the interactive menu:
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

## ⚙️ Configuration

The configuration files are located at:
`/data/adb/tricky_store/helper/`

| File | Description |
| :--- | :--- |
| **`config.txt`** | Main settings file. |
| **`exclude.txt`** | List of package names to **always ignore** (remove from `target.txt`). |
| **`force.txt`** | List of package names to **always include** (even if not installed). |
| **`TSHelper.log`** | Execution logs and debug info. |

### `config.txt` Options

| Option | Default | Description |
| :--- | :--- | :--- |
| `RUN_ON_BOOT` | `true` | If `true`, regenerates the full list on every boot. Set to `false` to preserve manual edits across reboots (Monitor still runs). |
| `USE_DEFAULT_EXCLUSIONS` | `true` | Excludes system apps, keeps user apps & GMS. |
| `FORCE_LEAF_HACK` | `false` | **Generator Only:** Appends `?` to all packages (Soft bypass) during full rebuilds. |
| `FORCE_CERT_GEN` | `false` | **Generator Only:** Appends `!` to all packages (Hard bypass) during full rebuilds. |

## 📝 Changelog

### v0.4.0: The "Set & Forget" Update
This major release introduces a zero-configuration **Live Monitor**, changing how you manage your `target.txt`.
* **New:** **Live Monitor Daemon** - Watches for new app installs and adds them instantly.
* **New:** **Interactive Control Panel** - Run `service.sh` in terminal to manage the daemon.
* **New:** **Differential Update** - Only adds *missing* apps; never duplicates or touches existing entries.
* **Improved:** **Service Persistence** - Daemon automatically recovers if the system rotates package logs (Keep-Alive).
* **Fixed:** **Race Conditions** - Added settlement delays to prevent "ghost" additions during uninstalls.

### v0.3.1
* **Critical Fix:** Added `grep` filter to ignore "Failure calling service" errors polluting the stream on APatch.
* **New:** Implemented atomic locking (`mkdir`) to prevent double-execution on boot.
* **New:** Added `RUN_ON_BOOT` config option to optionally skip boot generation.
* **Improvement:** Startup logic now verifies TrickyStore folder existence before creating helper files.

### v0.3.0
* **New Engine:** Rewrote generation logic using a stream processor (`Pipe` -> `Sort` -> `Awk`) for massive performance gains.
* **UI:** Added Action Button support with live status output.
* **Boot:** Optimized boot script with permission auto-fixer.
