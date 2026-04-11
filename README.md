<p align="center">
  <img src="https://img.icons8.com/sf-symbols/96/eye.png" width="80" alt="SteamPack Icon"/>
</p>

<h1 align="center">SteamPack</h1>

<p align="center">
  <strong>macOS menu bar app to prevent your Mac from sleeping</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?logo=apple" alt="Platform"/>
  <img src="https://img.shields.io/badge/language-Swift-F05138?logo=swift&logoColor=white" alt="Swift"/>
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License"/>
  <img src="https://img.shields.io/badge/build-swiftc-lightgrey" alt="Build"/>
</p>

<p align="center">
  <a href="README_ko.md">한국어</a>
</p>

---

## What is SteamPack?

SteamPack is a lightweight macOS menu bar utility that toggles your Mac's sleep mode with a single click. It uses `pmset -a disablesleep` under the hood — no more typing long terminal commands.

### Menu Bar Icons

| State | Icon | Meaning |
|-------|------|---------|
| Normal | `eye.half.closed.fill` | Sleep is **enabled** — Mac can sleep normally |
| Active | `eye.trianglebadge.exclamationmark.fill` | Sleep is **disabled** — Mac stays awake |

## Features

- **One-click toggle** — Enable or disable sleep from the menu bar
- **Secure password storage** — sudo password is stored in macOS Keychain
- **Lightweight** — No dock icon, no window, just a menu bar icon
- **Universal Binary** — Runs natively on both Apple Silicon and Intel Macs
- **No dependencies** — Built with pure AppKit, no third-party libraries

## Installation

### Option 1: Download DMG

1. Download `SteamPack.dmg` from [Releases](../../releases)
2. Open the DMG and drag **SteamPack** to **Applications**
3. Launch SteamPack from Applications

### Option 2: Build from Source

```bash
git clone https://github.com/tykimos/steampack.git
cd steampack
bash scripts/build.sh
open build/SteamPack.app
```

**Requirements:** Xcode Command Line Tools (`xcode-select --install`)

## Usage

1. **Launch** — SteamPack appears as an eye icon in the menu bar
2. **First run** — Enter your sudo password (stored securely in Keychain)
3. **Toggle** — Click the icon and select **Disable Sleep** / **Enable Sleep**
4. **Change password** — Click the icon → **Change Password**
5. **Quit** — Click the icon → **Quit** (or `Cmd+Q`)

### Menu Items

| Item | Description |
|------|-------------|
| Sleep Enabled / Sleep Disabled | Current status (read-only) |
| Enable Sleep / Disable Sleep | Toggle sleep mode |
| Change Password | Update stored sudo password |
| Quit | Exit SteamPack |

## How It Works

SteamPack executes `sudo pmset -a disablesleep 1` (disable sleep) or `sudo pmset -a disablesleep 0` (enable sleep) using the password stored in your macOS Keychain.

```
┌─────────────────────────────────────────┐
│           macOS Menu Bar                │
│   ┌───┐                                │
│   │ 👁 │ ← SteamPack icon              │
│   └─┬─┘                                │
│     │                                   │
│     ▼                                   │
│  ┌──────────────────┐                   │
│  │ Sleep Enabled    │ ← status          │
│  │──────────────────│                   │
│  │ Disable Sleep  ⌘T│ ← toggle         │
│  │──────────────────│                   │
│  │ Change Password  │                   │
│  │ Quit           ⌘Q│                   │
│  └──────────────────┘                   │
└─────────────────────────────────────────┘
```

## Project Structure

```
steampack/
├── src/
│   ├── AppMain.swift          # App entry point, NSStatusItem menu bar
│   ├── SleepToggle.swift      # pmset execution & state detection
│   ├── KeychainHelper.swift   # Keychain Services wrapper
│   └── PasswordPrompt.swift   # Password input dialog
├── scripts/
│   ├── build.sh               # Build automation (swiftc)
│   └── create-dmg.sh          # DMG packaging (hdiutil)
├── AppInfo.plist              # App bundle configuration
└── README.md
```

## Security

- Passwords are stored exclusively in **macOS Keychain** (service: `com.steampack.sudo`)
- Password is passed to sudo via stdin pipe — not visible in process list
- If authentication fails, the app prompts for re-entry
- Ad-hoc code signed

## License

MIT License. See [LICENSE](LICENSE) for details.
