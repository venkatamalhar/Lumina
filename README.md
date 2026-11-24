<p align="center">
  <img src="Resources/AppIcon.png" width="128" height="128" alt="Lumina Logo" />
</p>

<h1 align="center">Lumina</h1>

<p align="center">
  A lightweight macOS menu bar utility that adjusts display color temperature to filter blue light across all connected monitors. Built with Swift and SwiftUI using public Core Graphics display transfer APIs.
</p>

<p align="center">
  <a href="https://github.com/venkatamalhar/Lumina/releases/latest"><img src="https://img.shields.io/github/v/release/venkatamalhar/Lumina?color=orange&label=Release" alt="Latest Release" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-lightgrey.svg" alt="Platform: macOS 13+" />
</p>

---

## Highlights

- **Hardware Gamma Modulation**: Modulates RGB transfer curves directly through `CGSetDisplayTransferByTable` rather than drawing overlay windows or capturing screenshots.
- **Multi-Monitor & Reconfiguration Aware**: Detects active displays and automatically re-applies warmth curves upon display reconnect, wake from sleep, or resolution changes.
- **Astronomical Solar Calculation**: Calculates sunrise and sunset locally using astronomical solar zenith formulas, requiring no remote API calls.
- **Zero-Permission Global Hotkey**: Uses Carbon `RegisterEventHotKey` for instant toggling (`Option + Shift + B`) without requesting Accessibility permissions.
- **Resource Efficient**: Runs as an accessory (`LSUIElement`) with no Dock presence, sleeping between minute-interval schedule checks.
- **Clean State Recovery**: Restores display ColorSync calibration curves on quit (`CGDisplayRestoreColorSyncSettings`).

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Download & Installation

Download the latest pre-built application bundle directly from [Releases](https://github.com/venkatamalhar/Lumina/releases/latest):

1. Download **`Lumina.zip`**.
2. Unzip and drag `Lumina.app` to your `/Applications` folder.
3. Launch Lumina. The app will run in your menu bar.

## Building from Source

### Quick Build & Package
Run the packaging script to compile in release mode and assemble `Lumina.app`:

```bash
chmod +x package_app.sh
./package_app.sh
open Lumina.app
```

### Xcode
Open the project by launching `Package.swift` in Xcode:

```bash
open Package.swift
```

Select the **Lumina** executable target and press **Run** (`⌘R`).

## Architecture

- `ColorMath.swift`: Converts correlated color temperature (Kelvin) to RGB multipliers using Planckian blackbody locus approximations.
- `GammaController.swift`: Manages hardware gamma tables across active display IDs via Core Graphics.
- `SolarCalculator.swift`: Computes local sunrise and sunset without network access.
- `LocationProvider.swift`: Obtains device coordinates or falls back to timezone-derived approximations.
- `ScheduleManager.swift`: Handles schedule transitions and evaluates day/night states.
- `HotKeyManager.swift`: Manages global shortcut registration.
- `Views/`: SwiftUI views for the menu bar popover and preferences window.

## License

This project is available under the MIT License.
