# TrickyStore Helper

A lightweight, robust, and high-performance companion module for [TrickyStore](https://github.com/5ec1cff/TrickyStore).

This module automates the generation of `target.txt`, allowing you to easily manage which apps bypass keybox attestation. It features a new stream-based processing engine that is incredibly fast and compatible with Magisk, KernelSU, and APatch.

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
