# TrickyStore Helper

**A helper module for [TrickyStore](https://github.com/5ec1cff/TrickyStore) to automatically generate and manage `target.txt`.**

> **Note:** This is an enhanced fork of [CaptainThrowback's original helper](https://github.com/CaptainThrowback/TrickyStoreHelper), optimized for speed and compatibility with KernelSU, APatch, and Magisk.

## ⚡ Features (v0.3.1)

* **🚀 Stream Engine:** Completely rewritten generation logic using a high-performance pipeline (`Pipe` -> `Sort` -> `Awk`). Zero temporary files, instant results.
* **🛡️ Pollution-Proof:** Smart filtering ignores garbage output from root managers (fixing empty lists on APatch/crDroid).
* **🔒 Atomic Boot Lock:** Prevents double-execution race conditions during boot on all root solutions.
* **⚙️ Robust Config:** New config parser ignores accidental spaces, tabs, and Windows line endings (`\r`).
* **📱 Live UI:** Full support for "Action" buttons in Magisk, KernelSU, and APatch with real-time status logs.
* **✅ Smart Verification:** Verifies if GMS/Play Store were actually running before attempting to restart them.

## 📦 Installation

1.  Ensure **TrickyStore** is already installed.
2.  Flash `TrickyStoreHelper_v0.3.1.zip` in your root manager (Magisk/KSU/APatch).
3.  Reboot.

## 🛠️ Usage

### Automatic (Boot)
The module automatically generates a fresh `target.txt` on every boot to ensure your app list is always up to date.
* *Note: This can be disabled in `config.txt` by setting `RUN_ON_BOOT=false`.*

### Manual (Action Button)
You can manually trigger a regeneration at any time:
* **KernelSU / APatch:** Go to the Modules tab, tap **TrickyStore Helper**, and select **Action** (or "Generate List").
* **Magisk:** Run the command `su -c sh /data/adb/modules/trickystorehelper/action.sh` in a terminal (Termux).

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

| Option | Values | Default | Description |
| :--- | :--- | :--- | :--- |
| `FORCE_LEAF_HACK` | `true`/`false` | `false` | Appends `?` to all packages (Soft bypass). |
| `FORCE_CERT_GEN` | `true`/`false` | `false` | Appends `!` to all packages (Hard bypass). |
| `USE_DEFAULT_EXCLUSIONS` | `true`/`false` | `true` | Excludes system apps, keeps user apps & GMS. |
| `RUN_ON_BOOT` | `true`/`false` | `true` | Controls if the script runs automatically at startup. |

## 📝 Changelog

### v0.4.0: 
The "Set & Forget" Update
​This major release introduces a zero-configuration Live Monitor, changing how you manage your target.txt. You no longer need to reboot or manually regenerate your list after installing new apps—TrickyStore Helper now watches the system and updates your configuration instantly.

### ✨ New Features
​* **👁️ Live Monitor Daemon:** Installs a lightweight background service that watches for new app installations.
​Instant: Adds new apps to target.txt seconds after installation.
* **​Smart:** Automatically ignores apps you have excluded in exclude.txt or system apps (configurable).
* **​Safe:** Only appends new apps. It never overwrites your manual edits, custom suffixes (?/!), or existing configuration.
​* **🏎️ Optimized Performance:**
​Event-Driven: Uses inotifyd to sleep until needed. Zero battery drain.
​Keep-Alive Architecture: The daemon automatically recovers if the system rotates package logs, ensuring 24/7 reliability.
​* **🛡️ Conflict Prevention:**
​Added "Settle Time" logic to prevent race conditions when uninstalling/reinstalling apps rapidly.
​Uses unique temporary files to handle simultaneous installs without data corruption.

### ​🛠️ Improvements
​* **Logic Parity:** The monitor now shares the exact same exclusion logic as the main generator (respecting USE_DEFAULT_EXCLUSIONS).
​* **Robust Service:** Rewrote service.sh to properly detach background processes, fixing issues where the monitor would die after a few minutes on some Root Managers (KSU/APatch).
​* **Atomic Locking:** Improved boot protection to prevent double-execution scenarios.

## ⚙️ How it works now
​* **Boot:** The helper generates your initial list (configurable) and starts the Live Monitor.
* **​Daily Use:** You install an app (e.g., Uber). The Monitor detects it, adds com.ubercab to target.txt, and soft-restarts TrickyStore. It just works.
* **​Maintenance:** You can still use the "Action" button in your Root Manager to perform a full "Clean & Rebuild" if you want to remove uninstalled apps or apply global suffixes.

## 📦 Installation
* Flash the zip in Magisk/KernelSU/APatch.
Reboot.
* (Optional) Customize behavior in /data/adb/tricky_store/helper/config.txt.

### v0.3.1
* **Critical Fix:** Added `grep` filter to ignore "Failure calling service" errors polluting the stream on APatch.
* **New:** Implemented atomic locking (`mkdir`) to prevent double-execution on boot.
* **New:** Added `RUN_ON_BOOT` config option to optionally skip boot generation.
* **Improvement:** Startup logic now verifies TrickyStore folder existence before creating helper files.
* **Improvement:** Config parser now strips all invisible whitespace/tabs for better compatibility.

### v0.3.0
* **New Engine:** Rewrote generation logic using a stream processor for massive performance gains.
* **UI:** Added Action Button support with live status output.
* **Boot:** Optimized boot script with permission auto-fixer.
* **Fixes:** Improved handling of Windows line endings in config files.
