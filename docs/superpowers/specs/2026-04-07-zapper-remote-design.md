# Zapper — iOS Smart TV Remote Control App

**Date:** 2026-04-07
**Status:** Design approved, pending implementation plan

---

## 1. Overview

Zapper is a standalone iOS app that turns an iPhone into a universal smart TV remote control. It auto-discovers TVs on the local network and provides a context-adaptive UI that changes based on what the TV is doing (navigating, playing media, text input, or app browsing).

**Phase 1 scope:** Android TV platform only (TCL, Sony, Hisense, Xiaomi, Nvidia Shield, Google TV devices).

**Future phases:** Roku (REST ECP), Samsung Tizen (WebSocket), LG webOS (SSAP/WebSocket), Fire TV (ADB).

**Monetization:** Free, no monetization for now.

---

## 2. Architecture

### 2.1 Protocol Abstraction Layer

The core architectural pattern. The UI talks to a single unified interface; platform-specific drivers handle the differences.

```
SwiftUI Views (Context-Adaptive UI)
        │
RemoteViewModel (@Observable)
        │
  TVProtocol (Unified Interface)
        │
   ┌────┼────┬────────┬────────┐
   │    │    │        │        │
Android  Roku Samsung  LG    Fire TV
  TV    (future) (future) (future) (future)
```

### 2.2 Core Protocols & Models

**TVProtocol** — defines the contract every platform driver must implement:
- `connect(to device: TVDevice) async throws`
- `disconnect() async`
- `sendCommand(_ command: TVCommand) async throws`
- `sendText(_ text: String) async throws`
- `var state: TVState { get }` (published, observable property)
- `getInstalledApps() async throws -> [TVApp]`
- `launchApp(_ app: TVApp) async throws`

**TVDevice** — discovered device model:
- `id: UUID`
- `name: String` (e.g., "Living Room TCL")
- `ipAddress: String`
- `platform: TVPlatform` (enum: .androidTV, .roku, .samsung, .lgWebOS, .fireTV)
- `macAddress: String?`
- `capabilities: Set<TVCapability>`
- `pairingStatus: PairingStatus`

**TVState** — observable state published by the driver:
- `connectionStatus: ConnectionStatus` (.disconnected, .connecting, .connected)
- `powerState: PowerState` (.on, .off, .unknown)
- `currentApp: TVApp?`
- `playbackState: PlaybackState` (.idle, .playing, .paused, .buffering)
- `mediaInfo: MediaInfo?` (title, subtitle, artwork URL, duration, position)
- `volume: Float` (0.0–1.0)
- `isMuted: Bool`
- `isTextInputFocused: Bool`

**TVCommand** — enum of all possible commands:
- `.dpad(Direction)` — up, down, left, right
- `.select`, `.back`, `.home`, `.menu`
- `.playPause`, `.play`, `.pause`, `.stop`
- `.skipForward`, `.skipBackward`
- `.seekForward(seconds: Int)`, `.seekBackward(seconds: Int)`
- `.volumeUp`, `.volumeDown`, `.mute`
- `.power`

### 2.3 Supporting Services

**DiscoveryService:**
- Scans via mDNS (`_androidtvremote2._tcp` for Android TV) and SSDP simultaneously
- Returns `AsyncStream<TVDevice>` as devices are found
- Fingerprints devices to determine platform
- Caches known devices for instant reconnection

**ConnectionManager:**
- Manages pairing handshake (PIN-based for Android TV)
- Stores auth tokens/certificates in Keychain
- Auto-reconnects on network change with exponential backoff
- Publishes connection state changes

**StateObserver:**
- Polls or subscribes to TV state changes
- Detects current app, playback status, text input focus
- Publishes state changes that drive UI mode switching

---

## 3. Android TV Driver (Phase 1)

### 3.1 Protocol

Android TV Remote Service v2 — a TLS-based protocol using protocol buffers over a persistent TCP connection.

**Connection flow:**
1. Discover via mDNS service `_androidtvremote2._tcp`
2. Establish TLS connection (self-signed certificates)
3. First-time pairing: TV displays a PIN code, user enters it on phone
4. Certificate exchange — phone's client cert is stored on TV for future connections
5. Subsequent connections: auto-authenticate via stored certificate (no PIN needed)

**Capabilities:**
- D-pad navigation and button presses
- Text input (IME protocol)
- Volume control
- Power on/off (via Wake-on-LAN for power on)
- App launch via intent
- Current app detection
- Playback state reporting

### 3.2 Dependencies

- TLS socket connection (Network.framework — NWConnection with TLS options)
- Protocol buffer serialization (swift-protobuf)
- mDNS discovery (NWBrowser from Network.framework)
- Wake-on-LAN (UDP magic packet)

---

## 4. UI Design

### 4.1 Design System

High-fidelity mockups have been provided and are the source of truth. Key design tokens:

**Colors (Material 3 dark theme):**
- Surface: `#131318`
- Surface Container: `#1f1f25`
- Surface Container Lowest: `#0e0e13`
- Primary Container: `#2563eb`
- Primary (light): `#b4c5ff`
- Secondary: `#a4c9ff`
- Error: `#ffb4ab`
- Error Container: `#93000a`
- On Surface: `#e4e1e9`
- On Surface Variant: `#c3c6d7`
- Outline: `#8d90a0`
- Outline Variant: `#434655`

**Typography:**
- Headlines: Manrope (600–800 weight)
- Body/Labels: Inter (400–600 weight)
- Icons: Material Symbols Outlined (variable weight/fill)

**Component Patterns:**
- Glass panels: `rgba(31, 31, 37, 0.6)` + `backdrop-filter: blur(24px)` + inset top highlight
- Jewel buttons: `scale(0.92)` on press, spring animation
- Card corners: 2rem–2.5rem radius
- Bottom nav: `slate-900/60` + `blur-2xl` + `rounded-t-[2rem]`
- Active tab: `blue-600/20` bg + `blue-200` text + `ring-1 ring-blue-400/30` + filled icon
- Ambient glows: large radial blurs positioned behind content

**Haptic Feedback:**
- Light impact: D-pad swipes, navigation taps
- Medium impact: OK/select, app launch
- Heavy impact: Power toggle
- Selection feedback: Mode switching

### 4.2 Context-Adaptive UI Modes

The remote has 4 modes. The UI auto-switches based on `TVState`, with manual override via bottom tab bar or left/right swipe.

#### Mode 1: Navigation (Default)

Active when TV is on home screen or browsing menus (`playbackState == .idle && !isTextInputFocused`).

- Full-screen circular touchpad with dot-grid haptic texture
- Gradient inner glow (primary → secondary)
- Center OK button with glass border
- D-pad directional arrow overlays on touchpad edges
- Power button (top-left) with red glow
- Voice + keyboard quick-access buttons (top-right)
- Back / Home / Menu as glass pill buttons
- Volume slider (gradient fill with draggable scrubber)
- Status bar: device name + green connection dot + signal strength

#### Mode 2: Media Playback

Auto-activates when `playbackState != .idle`.

- Ambient radial gradient background tinted from media artwork
- Large poster/artwork card with gradient bottom overlay
- Quality badge (e.g., "4K Ultra HD • 5.1")
- Title + subtitle (show name, episode, source app)
- Progress bar with gradient fill + glow scrubber + timestamps
- Bento grid layout:
  - Left: glass playback cluster (±10s seek, large play/pause, CC, speed)
  - Right: vertical glass volume column with fill indicator
- Mode indicator dots

#### Mode 3: Keyboard Input

Auto-activates when `isTextInputFocused == true`.

- Context label showing target ("Typing into YouTube → Search")
- Glass text input field with cursor
- Autocomplete suggestion pills
- Clear + Send action buttons
- iOS native keyboard appears below
- Design follows same glass panel + Material 3 system (mockup to be created matching existing design language)

#### Mode 4: App Launcher

Manual activation via bottom tab or swipe-up gesture.

- Search bar integrated in top app bar
- Favorites section: horizontal scroll of wide glass tiles with brand-tinted gradients
- All Apps section: responsive grid (adapts 2–5 columns)
- Square glass cards with 3xl rounded corners
- Scale-up animation on hover/press (1.05)
- Dashed-border "Store" card for discovering new apps
- Long-press to pin/unpin favorites

### 4.3 Bottom Navigation Bar

Persistent across all modes:
- 4 tabs: Navigation (gamepad), Media (play_circle), Keyboard (keyboard), Apps (apps)
- Active tab is highlighted with blue glow ring
- Tapping a tab manually overrides the auto-switching

### 4.4 Device Discovery Screen

Shown on first launch or when no saved device is available.

- Scanning animation: pulsing router icon with concentric orbit rings
- "Searching for TVs..." headline + Wi-Fi network reminder
- Device list: glass cards (2rem rounded) with TV icon, name, IP (mono font), chevron
- "Add by IP Address" manual entry button at bottom
- Ambient background blurs (primary + secondary positioned off-screen)

### 4.5 Pairing Screen

Shown after selecting an unpaired device.

- TV ↔ Phone visual
- PIN entry: 4 digit boxes with glass styling + blue focus border
- Connect button (primary gradient)
- Expiry countdown text

---

## 5. User Flows

### 5.1 First Launch
1. App opens → request local network permission
2. Auto-scan begins → scanning animation shown
3. Devices appear in list as discovered
4. User taps a device → pairing screen
5. User enters PIN shown on TV → certificate exchange
6. Connected → navigate to Navigation Mode

### 5.2 Returning User
1. App opens → auto-connect to last device using stored certificate
2. Connection established (< 2 seconds) → last-used mode shown
3. If TV unreachable → retry with backoff → show device picker after 3 failures

### 5.3 Switching Devices
1. Tap device name in status bar → device picker overlay
2. Shows saved devices + "Scan for new" option
3. Tap to connect → if unpaired, show pairing flow

### 5.4 Context Switching
1. User watching Netflix → Media Mode auto-activates
2. User opens YouTube search → Keyboard Mode auto-activates
3. User presses Home on TV → Navigation Mode auto-activates
4. User taps Apps tab → App Launcher shown (manual)
5. User can always override by tapping bottom tab bar

---

## 6. Data Persistence

- **Saved devices:** Core Data or SwiftData (name, IP, MAC, platform, last connected)
- **Auth credentials:** Keychain (TLS client certificates, pairing tokens)
- **User preferences:** UserDefaults (last device ID, pinned apps, haptic settings)
- **App cache:** Installed apps list cached per device, refreshed on connect

---

## 7. iOS Permissions Required

- **Local Network** (`NSLocalNetworkUsageDescription`) — for mDNS/SSDP discovery
- **Bonjour Services** (`NSBonjourServices`) — `_androidtvremote2._tcp` (and others per platform)

No camera, microphone, Bluetooth, or internet permissions needed for Phase 1.

---

## 8. Dependencies (Phase 1)

| Dependency | Purpose |
|---|---|
| Network.framework | mDNS discovery (NWBrowser), TLS sockets |
| swift-protobuf | Protocol buffer serialization for Android TV Remote v2 |
| SwiftUI | All UI |
| Security.framework | Keychain storage for certificates |

Minimal dependency footprint — only `swift-protobuf` is external.

---

## 9. Project Structure

```
Zapper/
├── App/
│   ├── ZapperApp.swift
│   ├── AppState.swift (@Observable — connection state, active mode)
│   └── DependencyContainer.swift
├── Features/
│   ├── Discovery/
│   │   ├── DiscoveryView.swift
│   │   ├── DiscoveryViewModel.swift
│   │   └── PairingView.swift
│   ├── Remote/
│   │   ├── RemoteView.swift (mode container)
│   │   ├── RemoteViewModel.swift
│   │   ├── NavigationModeView.swift
│   │   ├── MediaModeView.swift
│   │   ├── KeyboardModeView.swift
│   │   └── AppLauncherView.swift
│   └── Settings/
│       └── DeviceManagerView.swift
├── Services/
│   ├── Discovery/
│   │   ├── DiscoveryService.swift
│   │   └── MDNSScanner.swift
│   ├── Connection/
│   │   ├── ConnectionManager.swift
│   │   └── KeychainService.swift
│   ├── Protocol/
│   │   ├── TVProtocol.swift (protocol definition)
│   │   ├── TVState.swift
│   │   ├── TVCommand.swift
│   │   └── TVDevice.swift
│   └── Drivers/
│       └── AndroidTV/
│           ├── AndroidTVDriver.swift (implements TVProtocol)
│           ├── AndroidTVConnection.swift (TLS socket)
│           ├── AndroidTVPairing.swift
│           └── Proto/ (generated protobuf files)
├── Navigation/
│   └── AppRouter.swift
├── Common/
│   ├── Theme/
│   │   ├── ZapperTheme.swift (Material 3 color tokens)
│   │   └── GlassModifiers.swift (glass panel, jewel button view modifiers)
│   ├── Components/
│   │   ├── TouchpadView.swift
│   │   ├── VolumeSlider.swift
│   │   ├── DeviceCard.swift
│   │   └── ModeIndicator.swift
│   └── Haptics/
│       └── HapticEngine.swift
├── Models/
│   ├── TVApp.swift
│   └── MediaInfo.swift
└── Resources/
    └── Assets.xcassets
```

---

## 10. Phasing

### Phase 1 (This spec)
- Android TV driver (discovery, pairing, commands, state)
- All 4 UI modes (navigation, media, keyboard, app launcher)
- Device discovery + pairing flow
- Multi-device save/switch
- Haptic feedback

### Phase 2 (Future)
- Roku driver (REST ECP — simplest protocol)
- Fire TV driver (shares ADB with Android TV)

### Phase 3 (Future)
- Samsung Tizen driver (WebSocket)
- LG webOS driver (SSAP/WebSocket)

### Phase 4 (Future)
- Screen mirroring
- File casting
- Voice input

---

## 11. Design Reference Files

High-fidelity HTML mockups are stored in the project and serve as the visual source of truth:
- Navigation Mode mockup
- Media Mode mockup
- Device Discovery mockup
- App Launcher mockup

These mockups define the exact glassmorphism style, Material 3 color tokens, typography, component patterns, and interaction behaviors to replicate in SwiftUI.
