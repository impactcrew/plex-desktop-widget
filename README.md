# Plex Desktop Widget

![Version](https://img.shields.io/badge/version-1.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A beautiful, lightweight macOS menu bar widget that displays your currently playing Plex media with album artwork and track information in real-time. Features a customizable floating overlay and smooth transitions.

**Note:** This is a display-only widget. Playback controls (play/pause/skip) are planned for a future release.

![Plex Desktop Widget](Screenshot.png)

<div align="center">
  <img src="Onboarding.webp" width="30%" alt="Onboarding screen">
  <img src="Settings.webp" width="30%" alt="Settings panel">
  <img src="Player.webp" width="30%" alt="Widget player modes">
</div>

## Features

- **Menu Bar Integration** - Menu bar icon with Plex chevron for quick access to settings
- **Beautiful Album Art** - Displays high-quality album artwork with customizable shapes (square, rounded, circle)
- **Smooth Track Transitions** - Album art persists during track changes for seamless playback experience
- **Real-time Updates** - Automatically polls and updates as your playback changes (2-second interval)
- **Native macOS Design** - Glassmorphic overlay with smooth animations
- **Secure Authentication** - Token stored securely in macOS Keychain
- **First-run Onboarding** - Easy setup with guided onboarding and connection validation
- **Customizable Appearance** - Theme (Light/Dark), Layout (Side/Overlay), Glow colors
- **Universal Binary** - Optimized for both Intel and Apple Silicon Macs
- **Hidden from Sound Menu** - Doesn't clutter macOS sound menu (Plex already shows there)

## Installation

### Download Universal Binary (Recommended)

Download the pre-built universal binary from the [Releases](https://github.com/impactcrew/plex-desktop-widget/releases) page.

1. Download the latest `PlexWidget.app.zip` from the Releases page
2. Unzip the file and move `PlexWidget.app` to your `/Applications` folder
3. Launch PlexWidget and complete the onboarding setup
4. Grant Keychain access when prompted

**Note:** First launch may show a Gatekeeper warning. Right-click the app and select "Open" to bypass this.

**Universal Binary:** Works natively on both Intel (x86_64) and Apple Silicon (arm64) Macs.

### Build from Source (Advanced)

If you want to build from source:

1. Clone this repository
2. Navigate to `PlexWidget/` directory
3. Run `./build.sh` to create universal binary
4. Copy `build/PlexWidget.app` to your Applications folder

## Requirements

- macOS 13.0 (Ventura) or later
- Compatible with both Intel and Apple Silicon Macs (Universal Binary)
- Active Plex Media Server
- Plex account with authentication token

## Configuration

On first launch, the widget will guide you through a simple onboarding process:

1. **Server URL** - Enter your Plex server URL (e.g., `http://localhost:32400`)
2. **Authentication Token** - Provide your Plex authentication token
3. **Permissions** - Grant accessibility and app monitoring permissions

To get your Plex token, see [Plex's official guide](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/).

## Settings

Access settings from the menu bar icon to customize:

- Theme (Light/Dark)
- Layout (Side/Overlay)
- Album art shape (Square/Circular)
- Glow (on/off, color: blue, purple, pink, orange, green, cyan)

## Architecture

Built with modern Swift and SwiftUI:

- **SwiftUI** - Declarative UI framework
- **Combine** - Reactive programming for real-time updates
- **Keychain Services** - Secure credential storage
- **NSWorkspace** - App monitoring and detection
- **UserDefaults** - Settings persistence

## Building from Source

### Prerequisites

- Xcode 15.0 or later
- macOS 13.0 (Ventura) or later
- Command Line Tools installed

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/impactcrew/plex-desktop-widget.git
cd plex-desktop-widget/PlexWidget

# Run the build script (creates universal binary)
./build.sh

# The app will be at: build/PlexWidget.app
# Copy to Applications folder
cp -r build/PlexWidget.app /Applications/
```

## Development

### Project Structure

```
PlexWidget/
├── PlexWidget/
│   ├── PlexWidgetApp.swift       # Main app entry point
│   ├── ContentView.swift          # Main widget view
│   ├── OnboardingView.swift       # First-run setup
│   ├── SettingsView.swift         # Settings panel
│   ├── NowPlayingView.swift       # Now playing display
│   ├── PlexAPI.swift              # Plex API integration (display only)
│   ├── Config.swift               # Configuration manager
│   ├── MediaRemoteController.swift # Media remote integration (legacy)
│   ├── PlexAppMonitor.swift       # App detection
│   ├── LaunchAtLogin.swift        # Launch on login helper
│   └── WidgetSettings.swift       # Settings model
└── Assets.xcassets/               # Icons and resources
```

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

### Widget Not Showing

- Ensure Plex is actively playing media
- Check that your Plex server is accessible
- Verify server URL and token are correct in settings
- Check Console.app for error logs (filter by "PlexWidget")

### Gatekeeper Warning

- Right-click PlexWidget.app and select "Open" (first launch only)
- Click "Open" in the security dialog
- App is not code-signed (requires $99/year Apple Developer Program)

### App Crashes During Onboarding

- This issue has been fixed in v1.0.0
- If you're using an older version, please update to the latest release
- If crashes persist after updating, please report in GitHub Issues with crash logs from: `~/Library/Logs/DiagnosticReports/PlexWidget*`

## Privacy

This app:

- Stores your Plex token securely in macOS Keychain
- Communicates only with your specified Plex server
- Does not collect or transmit any usage data
- Does not require internet access beyond your Plex server

## Recent Updates

- **v1.0.0 Release** - Fixed critical onboarding crash, added local network support
- **Improved threading** - Resolved @MainActor threading issues with network I/O
- **Smooth track transitions** - Album art now persists during track changes (no flicker)
- **Seamless onboarding** - Smooth window transition instead of app termination
- **Universal Binary** - Native support for both Intel and Apple Silicon Macs
- **Menu bar quit button** - Added quit option in settings panel
- **Universal binary** - Built for both Intel and Apple Silicon Macs
- **Hidden from sound menu** - No longer appears in macOS sound menu

## Known Issues

### Intermittent Crash After Onboarding

**Status:** Under Investigation

Some users have reported an intermittent crash that occurs after completing the onboarding process. This issue is not consistently reproducible:

- Crash may occur during or immediately after onboarding validation
- Does not affect all users or all launches
- App generally runs stably once past the initial onboarding

**Workaround:** If the app crashes during onboarding, simply relaunch it. Your credentials will be saved and the app should start normally.

*We are actively investigating this issue and working on a fix for the next release.*

## Known Limitations

### Playback Control Not Supported

PlexWidget cannot add play/pause/skip buttons due to fundamental limitations in Plex's architecture:

- **Plex Companion Protocol** - Exclusive to official Plex applications only
- **No Third-Party Discovery** - Third-party apps cannot be discovered or targeted for playback control
- **Controller-Only Desktop App** - The macOS Plex app functions only as a controller, not a receiver
- **No Public API** - No public API exists for remote playback control

*This is not a bug or missing feature - it's an architectural restriction enforced by Plex. We investigated multiple approaches and found no viable solution for third-party playback control.*

## Upcoming Development

- Mini mode for smaller screens
- Windows version

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for the [Plex](https://www.plex.tv/) community
- Designed & Developed by [IMPACT Crew](https://impactcrew.com.au)

---

<div align="center">

**Made for the macOS community**

</div>
