import ProjectDescription

// Generates the .xcodeproj/.xcworkspace that wraps ios/App (composition
// root) and its local SPM packages (ios/Packages/*) into a real, installable
// .app — plain `xcodebuild build -scheme <name>` against a bare
// `.iOSApplication` SPM product does not produce an app bundle from the CLI
// (verified: it only emits a raw Mach-O), so Tuist is the generation step
// that makes `xcrun simctl install`/`launch` possible for real device/
// simulator verification. The packages themselves remain plain SPM (buildable
// and testable with `swift test` / `xcodebuild test` with no Tuist involved
// at all) — Tuist only wraps the App target.
let config = Config()
