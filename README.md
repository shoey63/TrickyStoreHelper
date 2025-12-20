# TrickyStore Helper

**A helper module for [TrickyStore](https://github.com/5ec1cff/TrickyStore) to automatically generate and manage `target.txt`.**

> **Note:** This is an enhanced fork of [CaptainThrowback's original helper](https://github.com/CaptainThrowback/TrickyStoreHelper), optimized for speed and compatibility with KernelSU, APatch, and Magisk.

## 🚀 Features

* **Automated Generation:** Automatically populates `target.txt` with installed packages on every boot.
* **Stream Processing Engine:** Uses a high-performance, single-pass pipeline (Awk stream) to process package lists instantly without creating temporary files.
* **Action Button Support:**
    * **Magisk / KernelSU / APatch:** Fully supported with a UI action button to refresh the list on demand.
    * **On-Boot:** Runs silently at boot; can be triggered manually via terminal.
* **Smart Configuration:** Supports custom exclusions, forced inclusions, and specific "hack" modes (Leaf/Cert).
* **Conflict Detection:** Automatically prevents invalid configurations (e.g., enabling both Leaf and Cert hacks simultaneously).

---

## 🛠️ Installation & Usage

1.  **Prerequisite:** Ensure **TrickyStore** is installed first.
2.  **Install:** Flash the `TrickyStoreHelper` zip in Magisk, KernelSU or APatch.
3.  **Reboot:** The module will automatically run the generation script on boot.

### On-Demand Refresh
* **Magisk / KernelSU / APatch:** Go to the Module list and press the **Action Button** to regenerate the list immediately.
* **Terminal:** Run the script manually as root:
    ```bash
    su
    sh /data/adb/modules/trickystorehelper/action.sh
    ```

---

## ⚙️ Configuration

All configuration files are located in:
`/data/adb/tricky_store/helper/`

### 1. `config.txt`
Controls the global behavior of the script.

| Option | Default | Description |
| :--- | :--- | :--- |
| `USE_DEFAULT_EXCLUSIONS` | `true` | `true` = Include **User Apps** only (plus critical system apps like GMS/Vending).<br>`false` = Include **All Apps** (System + User). |
| `FORCE_LEAF_HACK` | `false` | If `true`, appends `?` to packages to force the **Leaf Certificate Hack**. |
| `FORCE_CERT_GEN` | `false` | If `true`, appends `!` to packages to force **Certificate Generation**. |

### 2. `exclude.txt`
Add package names here (one per line) to **exclude** them from `target.txt`, even if they are installed.
* *Example:* `com.banking.app`

### 3. `force.txt`
Add package names here (one per line) to **force include** them, even if they aren't in the standard package list.
* *Note:* If a specific hack mode is enabled in config, it will be applied to these packages only.

---

## 📜 How It Works

1.  **Boot Script (`service.sh`):** Waits for boot completion, ensures script permissions are correct, and runs the generator in "silent" mode.
2.  **Stream Processor (`action.sh`):**
    * Reads the list of installed packages.
    * Loads `exclude.txt` and `force.txt` into memory.
    * Processes everything in a single pass using `awk`.
    * Writes the final `target.txt` and restarts `com.google.android.gms.unstable` and `com.android.vending` to apply changes immediately.

---

## 📝 Changelog
### v0.3.1
* Disable sleep commands during boot plus code optimisations

### v0.3.0
* **New Engine:** Rewrote generation logic using a stream processor (Pipe -> Sort -> Awk) for massive performance gains.
* **UI:** Added Action Button support for Magisk, KernelSU and APatch with live status output.
* **Boot:** Optimized boot script with permission auto-fixer.
* **Fixes:** Improved handling of Windows line endings (`\r`) in config files.

---

## 🤝 Credits

* **CaptainThrowback:** Original concept and module.
* **shoey63:** Stream optimization, UI enhancements, and APatch/KSU support.
* **5ec1cff:** Creator of TrickyStore.
