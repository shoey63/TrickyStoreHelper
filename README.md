# TrickyStore Helper (by CaptainThrowback, fork maintained by Shoey63)

This helper module rebuilds `target.txt` for **TrickyStore** automatically at device boot (or via Action Button), 
so spoofing targets stay consistent without manual edits.

It now supports:
- All **user-installed apps**
- Core Google components (`Play Store` and `Play Services`)
- Optional **selected system apps** from `system.txt`

---

## 📂 File Structure

All files are stored in:
/data/adb/tricky_store/helper

| File | Description |
|------|--------------|
| **config.txt** | Configures module behavior. |
| **exclude.txt** | Lists packages to skip in `target.txt`. |
| **force.txt** | Lists packages to apply force flags (`?` or `!`). |
| **system.txt** | Lists system apps you want added to `target.txt`. |
| **TSHelper.log** | Logs all helper operations. |

---

### `config.txt`
Default contents:
FORCE_LEAF_HACK=false FORCE_CERT_GEN=false

CUSTOM_LOGLEVEL can be added manually if needed
#### FORCE_LEAF_HACK
Appends `?` to package names — used for forcing Leaf Hack.

#### FORCE_CERT_GEN
Appends `!` to package names — used for forcing Certificate Generation.

#### CUSTOM_LOGLEVEL
(Optional) Enables additional debug logging to logcat with the tag `TSHelper`.

---

### `exclude.txt`
List packages you don’t want spoofed.  
If empty, all eligible packages are included.

Example:
com.google.android.tts com.android.chrome

---

### `force.txt`
Define packages that should have either the Leaf Hack (`?`) or Certificate Generation (`!`) applied.

Example:
com.google.android.gms com.android.vending

---

### `system.txt`
Allows you to include selected system apps in `target.txt`.  
Created automatically if missing.

Example:
com.google.android.setupwizard com.android.settings com.google.android.inputmethod.latin

🧰 Notes
Permissions for .sh scripts are auto-verified at boot (fixed only if wrong).
No “default exclusions” are used in this fork — all behavior is explicit and user-controlled.
Safe to run manually at any time; no reboot or apply step required.
🔧 Credits
Original concept and base code: Captain_Throwback
Fork enhancements and maintenance: Shoey63
