# TrickyStore Helper (by shoey63)

A helper module for **TrickyStore** that automatically maintains and updates the `target.txt` file on device boot.

Originally based on the work by CaptainThrowback — this fork adds extended automation, live update capability via **action button**, and better configuration flexibility.

---

## 📂 Folder Structure

All files for TrickyStore Helper are stored in:

```
/data/adb/tricky_store/helper
```

Inside that folder, you’ll find:

### 🧩 `config.txt`

Controls how the module behaves on each boot.  
If not present, it’s automatically created with default values.

**Default contents:**
```
FORCE_LEAF_HACK=false
FORCE_CERT_GEN=false
USE_DEFAULT_EXCLUSIONS=true
```

#### Options

| Option | Description |
|---------|-------------|
| `FORCE_LEAF_HACK` | Adds `?` to either all packages or those listed in `force.txt`. |
| `FORCE_CERT_GEN`  | Adds `!` to either all packages or those listed in `force.txt`. |
| `USE_DEFAULT_EXCLUSIONS` | Keeps the built-in exclusion list used by TrickyStore. Disable if you prefer to manage manually. |
| `CUSTOM_LOGLEVEL` *(optional)* | Enables debug logging with the `TSHelper` tag in logcat. |

---

### 📄 `exclude.txt`

List of packages to **exclude** from `target.txt`.  
Useful if an app misbehaves under spoofing.  
Leave empty if none.

---

### ⚙️ `force.txt`

List of packages that should **always** apply the configured force mode  
(`FORCE_LEAF_HACK` or `FORCE_CERT_GEN`).  
If you want the mode to apply globally, keep this file empty.

---

### 🧱 `system.txt`

Defines **system packages** (like Play Store and GMS) that will *always* be included in `target.txt`  
and treated as system apps in summaries.

**Default contents:**
```
com.android.vending
com.google.android.gms
```

---

### 🪵 `TSHelper.log`

All logs for the helper script — useful for debugging or verifying operations.

---

## 🚀 Action Button

This module includes an **action button** (`action.sh`) in Magisk or KernelSU:

- Updates `target.txt` manually without rebooting  
- Restarts Play Store & GMS automatically  
- Prints a summary:
  - Total apps included
  - Number of user & system apps
  - Forced entry count
  - Active force mode

Example output:

```
* TrickyStore Helper *
-----------------------
Starting update...
• Running helper.sh...
• Restarting Play Store & GMS...

✅ Update complete!
📊 Summary:
--------------------------------
Updated: 2025-10-24 10:41:17
- Force mode:      FORCE_LEAF_HACK
- User apps:       64
- System apps:     2
- Forced entries:  5
- Total entries:   66
--------------------------------
You can now open TrickyStore to confirm the new target list.
```

---

## 🧩 Credits

- **CaptainThrowback** – Original TrickyStore Helper concept  
- **osm0sis** – Base template for the action button  
- **shoey63** – Fork, automation, and enhancements

---

## ⚠️ Notes

- TrickyStore must be installed first (`/data/adb/tricky_store` must exist).  
- The helper will automatically set up its config and data on first boot.  
- `action.sh` can be triggered anytime from Magisk or KernelSU to refresh `target.txt` live.

---

*TrickyStore Helper – simple, reliable, and fully automated.*
