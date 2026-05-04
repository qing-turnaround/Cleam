# Cleam

A native macOS app for system maintenance and optimization. Built with Swift & SwiftUI.

Inspired by [tw93/mole](https://github.com/tw93/mole) — reimagined as a native GUI application.

## Features

### Clean
Scan and remove system caches, user caches, browser data (Safari/Chrome/Firefox/Edge/Arc/Brave/Opera/Vivaldi), developer tool caches (Xcode/Homebrew/npm/pip/cargo/Go/Gradle), application caches, cloud storage caches, and project build caches.

### Uninstall
Smart app uninstaller that finds and removes all associated files — preferences, caches, Application Support, logs, Launch Agents, containers, saved state. Homebrew Cask integration. Three-tier protection: system-critical apps are blocked, data-sensitive apps require extra confirmation.

### Analyze
Interactive disk space analyzer with color-coded progress bars, breadcrumb navigation, and large file detection. Drill into any directory. Multi-select for batch deletion.

### Status
Real-time system monitoring dashboard. CPU usage (per-core via `host_processor_info`), memory (via `host_statistics64`), disk, network throughput with sparkline history (via `getifaddrs`), battery health (via IOKit), and top processes. Health score with penalty breakdown.

### Optimize
One-click optimization tasks: flush DNS, rebuild Spotlight index, reset QuickLook cache, rebuild Launch Services database, VACUUM system SQLite databases (Mail/Safari/Messages), rebuild font cache, clean broken Launch Agents, run macOS periodic maintenance.

### Purge
Detect development projects across 13 types (Node/Swift/Rust/Go/Python/Ruby/Java/.NET/Flutter/PHP) and clean build artifacts — `node_modules`, `.build`, `target`, `DerivedData`, `__pycache__`, `.venv`, `.gradle`, and more.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for building)
- Full Disk Access permission (for complete scanning)

## Build

```bash
# Clone
git clone https://github.com/qing-turnaround/Cleam.git
cd Cleam

# Open in Xcode
open Package.swift

# Or use xcodegen
brew install xcodegen
xcodegen generate
open Cleam.xcodeproj
```

Set deployment target to **macOS 13.0**, disable **App Sandbox**, then Build & Run.

## Architecture

```
Views (SwiftUI) → ViewModels (@MainActor) → Services (actors) → System APIs
```

- **MVVM** with actor-based service layer
- **No third-party dependencies** — pure Apple frameworks
- Native system metrics via Mach calls, IOKit, sysctl, getifaddrs, proc_pidinfo
- Safety-first: 7-layer path validation, protected bundle lists, audit logging, dry-run mode

## Stats

| | |
|---|---|
| Swift files | 87 |
| Lines of code | ~6,600 |
| Service actors | 41 |
| Data models | 11 |
| Unit tests | 4 suites |

## Safety

Every destructive operation follows **Scan → Preview → Confirm → Execute**. Path validation rejects system paths, traversal attacks, and protected bundles. All file operations are logged to `~/Library/Logs/Cleam/operations.log`. Dry-run mode lets you preview without deleting.

## License

MIT
