<p align="center">
  <img src="https://img.icons8.com/sf-symbols/96/eye.png" width="80" alt="SteamPack Icon"/>
</p>

<h1 align="center">SteamPack</h1>

<p align="center">
  <strong>Mac의 잠자기를 방지하는 macOS 메뉴바 앱</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?logo=apple" alt="Platform"/>
  <img src="https://img.shields.io/badge/language-Swift-F05138?logo=swift&logoColor=white" alt="Swift"/>
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License"/>
  <img src="https://img.shields.io/badge/build-swiftc-lightgrey" alt="Build"/>
</p>

<p align="center">
  <a href="README.md">English</a>
</p>

---

## SteamPack이란?

SteamPack은 Mac의 잠자기 모드를 클릭 한 번으로 토글하는 경량 macOS 메뉴바 유틸리티입니다. 내부적으로 `pmset -a disablesleep` 명령어를 사용합니다. 더 이상 터미널에서 긴 명령어를 입력할 필요가 없습니다.

### 메뉴바 아이콘

| 상태 | 아이콘 | 의미 |
|------|--------|------|
| 일반 | `eye.half.closed.fill` | 잠자기 **허용** — Mac이 정상적으로 잠들 수 있음 |
| 활성 | `eye.trianglebadge.exclamationmark.fill` | 잠자기 **차단** — Mac이 깨어 있음 |

## 주요 기능

- **원클릭 토글** — 메뉴바에서 잠자기 모드를 켜고 끄기
- **안전한 비밀번호 저장** — sudo 비밀번호를 macOS Keychain에 저장
- **경량** — 도크 아이콘 없음, 창 없음, 메뉴바 아이콘만 표시
- **Universal Binary** — Apple Silicon과 Intel Mac 모두 네이티브 지원
- **의존성 없음** — 순수 AppKit으로 제작, 서드파티 라이브러리 불필요

## 설치

### 방법 1: DMG 다운로드

1. [Releases](../../releases)에서 `SteamPack.dmg` 다운로드
2. DMG를 열고 **SteamPack**을 **Applications**로 드래그
3. Applications에서 SteamPack 실행

### 방법 2: 소스에서 빌드

```bash
git clone https://github.com/tykimos/steampack.git
cd steampack
bash scripts/build.sh
open build/SteamPack.app
```

**요구사항:** Xcode Command Line Tools (`xcode-select --install`)

## 사용법

1. **실행** — 메뉴바에 눈 모양 아이콘이 표시됩니다
2. **첫 실행** — sudo 비밀번호를 입력합니다 (Keychain에 안전하게 저장)
3. **토글** — 아이콘 클릭 → **Disable Sleep** / **Enable Sleep** 선택
4. **비밀번호 변경** — 아이콘 클릭 → **Change Password**
5. **종료** — 아이콘 클릭 → **Quit** (또는 `Cmd+Q`)

### 메뉴 항목

| 항목 | 설명 |
|------|------|
| Sleep Enabled / Sleep Disabled | 현재 상태 표시 (읽기 전용) |
| Enable Sleep / Disable Sleep | 잠자기 모드 토글 |
| Change Password | 저장된 sudo 비밀번호 변경 |
| Quit | SteamPack 종료 |

## 동작 원리

SteamPack은 macOS Keychain에 저장된 비밀번호를 사용하여 `sudo pmset -a disablesleep 1` (잠자기 차단) 또는 `sudo pmset -a disablesleep 0` (잠자기 허용) 명령어를 실행합니다.

```
┌─────────────────────────────────────────┐
│           macOS 메뉴바                   │
│   ┌───┐                                │
│   │ 👁 │ ← SteamPack 아이콘             │
│   └─┬─┘                                │
│     │                                   │
│     ▼                                   │
│  ┌──────────────────┐                   │
│  │ Sleep Enabled    │ ← 상태            │
│  │──────────────────│                   │
│  │ Disable Sleep  ⌘T│ ← 토글           │
│  │──────────────────│                   │
│  │ Change Password  │                   │
│  │ Quit           ⌘Q│                   │
│  └──────────────────┘                   │
└─────────────────────────────────────────┘
```

## 프로젝트 구조

```
steampack/
├── src/
│   ├── AppMain.swift          # 앱 진입점, NSStatusItem 메뉴바
│   ├── SleepToggle.swift      # pmset 실행 및 상태 감지
│   ├── KeychainHelper.swift   # Keychain Services 래퍼
│   └── PasswordPrompt.swift   # 비밀번호 입력 다이얼로그
├── scripts/
│   ├── build.sh               # 빌드 자동화 (swiftc)
│   └── create-dmg.sh          # DMG 패키징 (hdiutil)
├── AppInfo.plist              # 앱 번들 설정
└── README.md
```

## 보안

- 비밀번호는 **macOS Keychain**에만 저장됩니다 (서비스: `com.steampack.sudo`)
- 비밀번호는 stdin 파이프로 sudo에 전달 — 프로세스 목록에 노출되지 않음
- 인증 실패 시 비밀번호 재입력 요청
- Ad-hoc 코드 서명

## 라이선스

MIT License. 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.
