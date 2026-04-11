<div align="center">

<img src="capture.jpg" width="600" alt="SteamPack Screenshot"/>

# SteamPack

**Keep your Mac awake with a single click.**

[![MIT License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-13%2B-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Build](https://img.shields.io/badge/build-swiftc-lightgrey?style=for-the-badge)](scripts/build.sh)

*Toggle · Store · Forget — sleep control from the menu bar.*

[Getting Started](#-getting-started) · [How It Works](#-how-it-works) · [Usage](#-usage) · [Build](#-build-from-source) · [Architecture](#-architecture)

</div>

---

## What is this?

SteamPack is a **lightweight macOS menu bar utility** that toggles your Mac's sleep mode with a single click. It runs `pmset -a disablesleep` under the hood — no more typing long terminal commands.

> **Why "SteamPack"?** — Like a steam-powered jetpack that keeps you flying, SteamPack keeps your Mac running without ever touching down to sleep.

---

## ✨ Features

- **One-click toggle** — Enable or disable sleep from the menu bar
- **Secure password storage** — sudo password stored in macOS Keychain
- **Zero footprint** — No dock icon, no window, just a menu bar icon
- **Universal Binary** — Runs natively on Apple Silicon and Intel
- **No dependencies** — Pure AppKit, no third-party libraries

---

## 🚀 Getting Started

### Download DMG

1. Download `SteamPack.dmg` from [Releases](../../releases)
2. Open the DMG → drag **SteamPack** to **Applications**
3. Launch SteamPack

### Build from Source

```bash
git clone https://github.com/tykimos/steampack.git
cd steampack
bash scripts/build.sh
open build/SteamPack.app
```

> **Requires:** Xcode Command Line Tools (`xcode-select --install`)

---

## 👁 Usage

| Step | Action |
|------|--------|
| **Launch** | Eye icon appears in the menu bar |
| **First run** | Enter sudo password (stored in Keychain) |
| **Toggle** | Click icon → **Disable Sleep** / **Enable Sleep** |
| **Change password** | Click icon → **Change Password** |
| **Quit** | Click icon → **Quit** (`⌘Q`) |

### Menu Bar Icons

| Icon | State | Meaning |
|------|-------|---------|
| `eye.half.closed.fill` | Normal | Sleep **enabled** — Mac can sleep |
| `eye.trianglebadge.exclamationmark.fill` | Active | Sleep **disabled** — Mac stays awake |

---

## ⚙️ How It Works

SteamPack executes `sudo pmset -a disablesleep 1` (disable) or `0` (enable) using the password stored in your macOS Keychain.

```
┌─────────────────────────────────────────────────────┐
│                  macOS Menu Bar                     │
│                                                     │
│   ┌───┐  Click                                     │
│   │ 👁 │ ──────→ ┌──────────────────┐               │
│   └───┘          │ Sleep Enabled    │  ← status     │
│                  │──────────────────│               │
│                  │ Disable Sleep ⌘T │  ← toggle     │
│                  │──────────────────│               │
│                  │ Change Password  │               │
│                  │ Quit          ⌘Q │               │
│                  └──────────────────┘               │
│                         │                           │
│                         ▼                           │
│              ┌────────────────────┐                 │
│              │  macOS Keychain    │                 │
│              │  (sudo password)   │                 │
│              └────────┬───────────┘                 │
│                       ▼                             │
│         echo $PW | sudo -S pmset                    │
│              -a disablesleep 1/0                    │
└─────────────────────────────────────────────────────┘
```

---

## 🏗 Architecture

```
steampack/
├── src/
│   ├── AppMain.swift          # Entry point, NSStatusItem menu bar
│   ├── SleepToggle.swift      # pmset execution & state detection
│   ├── KeychainHelper.swift   # Keychain Services wrapper
│   └── PasswordPrompt.swift   # Secure password input dialog
├── scripts/
│   ├── build.sh               # Build automation (swiftc)
│   └── create-dmg.sh          # DMG packaging (hdiutil)
├── AppInfo.plist              # App bundle configuration
├── capture.jpg                # Screenshot
├── README.md                  # English
└── README_ko.md               # 한국어
```

---

## 🔒 Security

- Passwords stored exclusively in **macOS Keychain** (`com.steampack.sudo`)
- Password passed to sudo via **stdin pipe** — not visible in process list
- Authentication failure triggers password re-entry
- Ad-hoc code signed

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

<div align="center">

*Built with ❤️ and [Claude Code](https://claude.ai/code)*

</div>
