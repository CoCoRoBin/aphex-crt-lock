# Aphex CRT Lock

A user-owned Omarchy lock plugin derived from `omarchy.lock`. It combines a SYRO green (`#bfd630`) CRT scene with an Iosevka clock and password field. Wide screens use side-by-side artwork and authentication; narrow screens stack them.

## Files

| Path | Purpose |
| --- | --- |
| `manifest.json` | Plugin identity and authentication capability |
| `Service.qml` | Wayland session lock, PAM, fingerprint support, preview and display blanking |
| `LockView.qml` | Responsive lock layout and CRT scene |
| `AsciiRibbon.qml` | Retained ribbon component from the earlier design |
| `assets/` | Original logo, GLSL shaders and compiled Qt shader packages |

Keep the compiled `.qsb` files: the QML loads them at runtime.

## Requirements and installation

Requires an Omarchy desktop, its Quickshell modules and commands, Qt Quick/Wayland, and the `omarchy-lock-password` PAM configuration supplied by the system. Fingerprints additionally require the system fingerprint PAM configuration and enrolled prints. Iosevka is the intended font. This is an Omarchy plugin, not a standalone QML application.

The canonical repository is `~/Developer/aphex-crt-lock`. The installed path `~/.config/omarchy/plugins/neo.lock` is a compatibility symlink to that directory; `~/Projects/aphex-crt-lock` resolves through the installed path. Edit and run Git commands in the canonical repository. For another machine, back up any existing directory and `~/.config/omarchy/shell.json`, then copy the repository contents to that plugin path. Enable while unlocked:

```bash
omarchy plugin enable neo.lock
omarchy restart shell
```

The manifest declares its `omarchy.lock` origin. Keep only one lock provider enabled. No PAM configuration is included or modified by this project.

## Use and development

```bash
omarchy-shell lock preview       # Click to close; does not test authentication
omarchy-shell lock hidePreview
omarchy system lock             # Actually locks the session
omarchy-shell lock status
```

Edit `LockView.qml` for layout and typography. After changing a shader, rebuild its matching package from this directory:

```bash
/usr/lib/qt6/bin/qsb --glsl '100 es,120,150' --hlsl 50 --msl 12 -o assets/lock-crt.frag.qsb assets/lock-crt.frag
/usr/lib/qt6/bin/qsb --glsl '100 es,120,150' --hlsl 50 --msl 12 -o assets/ribbon.frag.qsb assets/ribbon.frag
```

The service blanks displays after five seconds of lock inactivity and re-arms after wake. Authentication uses the system PAM service; it has not been retested during documentation cleanup. Apply lock code changes by restarting the shell only while unlocked.

## Restore

```bash
omarchy plugin enable omarchy.lock
omarchy restart shell
```

Historical local backups: `~/.config/omarchy/shell.json.before-aphex-lock` and `~/.local/state/omarchy/aphex-backups/LockView.ticker.qml`. The previous README is retained locally as an ignored `.bak` file. Git is initialized; no commit or remote was created during organization.

## Origin

The service and plugin structure originate from Omarchy; the CRT appearance is a local customization. Original artwork is retained. No new license grant is implied for upstream code or artwork.

## Wake input and power controls

The password field restores focus after window activation, focus loss, and a completed PAM check. It sets hidden/sensitive/no-prediction input hints and ignores character auto-repeat after display wake (Backspace/Delete still repeat). This follows the stock lock's suspend focus recovery; intermittent Super-only input still needs a real suspend/resume check.

Input hints do not disable or isolate Fcitx or other input methods. This plugin shares the Omarchy shell process; it does not provide a separate input-method security boundary.

Restart and Shut down controls sit at the bottom left and require a second Confirm click. They call systemctl directly while keeping the session locked; Cancel returns to password entry. Preview cannot execute power actions. Runtime loading and QML parsing were checked; actual power actions and suspend authentication were not executed during this change.
