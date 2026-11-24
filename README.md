# Lumina

Lumina is a lightweight macOS menu bar utility that adjusts display color temperature to filter blue light across all connected monitors. Built with Swift and SwiftUI using public Core Graphics display transfer APIs.

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
