# Cleam - Development Guide

## Project Overview
Cleam is a native macOS system maintenance & optimization app built with Swift/SwiftUI. It consolidates system cleaning, app uninstalling, disk analysis, system monitoring, optimization, and project artifact cleanup into one tool.

## Tech Stack
- **Language:** Swift 5.9+
- **UI:** SwiftUI (macOS 13.0+ / Ventura)
- **Architecture:** MVVM + actor-based Service layer
- **No third-party dependencies** — all native macOS APIs

## Build & Run

```bash
# Option 1: Xcode via Swift Package
open Package.swift

# Option 2: xcodegen
brew install xcodegen
xcodegen generate
open Cleam.xcodeproj

# Option 3: Command line
swift build
swift test
```

**Important Xcode settings:**
- Deployment target: macOS 13.0
- App Sandbox: OFF (requires Full Disk Access)
- Code signing: "Sign to Run Locally" for dev

## Project Structure

```
Cleam/
├── App/            # Entry point, AppDelegate, AppState, ServiceFactory
├── Models/         # Data models grouped by feature
├── Services/       # Actor-based business logic
│   ├── Core/       # PathValidation, FileOperation, ProtectionList, Logger
│   ├── Cleaning/   # 7 category scanners
│   ├── Uninstall/  # App discovery, remnant search, Homebrew
│   ├── DiskAnalysis/   # Scanner, large file detection, caching
│   ├── SystemStatus/   # Native metrics (Mach/IOKit/sysctl)
│   ├── Optimization/   # DNS, Spotlight, QuickLook, SQLite, etc.
│   └── ProjectPurge/   # Project detection, artifact scanning
├── ViewModels/     # @MainActor ObservableObject per feature
├── Views/          # SwiftUI views grouped by feature
├── Utilities/      # ByteFormatter, RingBuffer, MinHeap
└── Extensions/     # FileManager+, URL+, Color+, Process+
```

## Architecture Rules

1. **Views** only talk to their ViewModel, never to Services directly
2. **ViewModels** are `@MainActor`, call Services via `async/await`
3. **Services** are Swift `actor`s for thread safety
4. **FileOperationService** is the ONLY gateway for file deletion — no service may call `FileManager.removeItem` directly
5. **PathValidationService** must be consulted before every deletion
6. Use **ServiceFactory** for dependency wiring in View inits

## Safety

- 7-layer path validation chain before any deletion
- ~70 system-critical bundles + ~30 data-protected bundles in protection lists
- All operations logged to `~/Library/Logs/Cleam/operations.log`
- Dry-run mode available on all destructive features
- Every destructive flow: Scan → Preview → Confirm → Execute

## Testing

```bash
swift test
```

Tests cover: PathValidationService, ByteFormatter, RingBuffer, MinHeap

## Code Style

- No comments unless the WHY is non-obvious
- Prefer actors over classes with locks
- Sort scan results by size descending
- Use `ByteFormatter.format()` for all human-readable sizes
- Use `DurationFormatter.relativeDate()` for all date displays
