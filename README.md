# Plex Desktop Widget

A native macOS application that displays what's currently playing on your Plex Media Server as a sleek, always-on-top floating desktop widget.

<div align="center">
  <p>
    <strong>A lightweight, performant replacement for the original Electron version</strong><br/>
    Built with Swift and SwiftUI for native macOS integration
  </p>
</div>

---

## Overview

Plex Desktop Widget brings your Plex Media Server content to the forefront of your desktop. Whether you're working, browsing, or streaming music, this native macOS widget keeps you updated with what's currently playing without cluttering your interface.

The application has been completely rebuilt from Electron to native Swift/SwiftUI, delivering improved performance, seamless native media controls integration via macOS MediaRemote framework, and a more polished user experience.

### Key Features

- **Real-time Now Playing Information**: Album art, track title, artist name, and album name
- **Scrolling Track Title**: Long song titles scroll smoothly for full visibility
- **Playback Controls**: Play/pause, next, and previous track controls integrated directly in the widget
- **Progress Bar**: Visual progress indicator with current time and total duration
- **Native Media Controls**: Full integration with macOS MediaRemote framework for system-level playback control
- **Glassmorphic Design**: Modern dark theme with 420×120px floating widget aesthetic
- **Always-on-Top Window**: Stay visible while working in other applications
- **Universal Binary**: Optimized for both Intel and Apple Silicon Macs
- **Low Resource Footprint**: Native Swift implementation with minimal memory usage

---

## System Requirements

- **macOS 13.0 or later** (Ventura or newer)
- **Intel Mac or Apple Silicon Mac** (universal binary support)
- **Plex Media Server** with at least one playback session
- **Network access** to your Plex Media Server

---

## Getting Started

### Step 1: Download and Install

1. Download the latest release from [Releases](../../releases)
2. Move `Plex Widget.app` to your Applications folder
3. Launch the application from Applications

**Note**: On first launch, you may need to allow the application in Security & Privacy preferences.

### Step 2: Get Your Plex Authentication Token

Your Plex authentication token is required for the app to connect to your Plex server. Follow these steps to obtain it:

#### Method 1: Via Plex Web Interface (Recommended)

1. Open **Plex Web** in your browser (https://app.plex.tv or your local server URL)
2. Start playing any media item on your Plex server
3. Click the **⋯** (three dots) menu on the player
4. Select **Get Info**
5. Click **View XML** or look at the page source
6. In the URL or XML, find the parameter: `X-Plex-Token=XXXXXXXXXXXXXXXXXXXX`
7. Copy the token (the long alphanumeric string after the equals sign)

#### Method 2: Via Local Server Settings

1. Open your Plex server web interface (usually `http://localhost:32400` or your server IP:32400)
2. Go to Settings > Users
3. Click on your user account
4. Scroll down to find your auth token
5. Copy the displayed token

**Important**: Keep your Plex token private and secure. Anyone with this token can access your Plex server.

### Step 3: Configure the Application

1. **Launch Plex Widget** for the first time
2. A settings window will appear automatically (or access Settings from the app menu)
3. Enter your **Plex Server URL**:
   - Local network: `http://192.168.1.XXX:32400` (replace XXX with your server IP)
   - Remote: Use your Plex server's remote URL
4. Paste your **Plex Authentication Token**
5. Click **Save**

The widget will immediately start displaying your currently playing content.

### Step 4: Optional - Configure Auto-Launch

To have Plex Widget launch automatically when you log in:

1. Open **System Settings** > **General** > **Login Items**
2. Click the **+** button in the "Allow these apps to start automatically" section
3. Select **Plex Widget** from Applications
4. Click **Add**

---

## Usage

### Basic Widget Display

Once configured, the widget displays:
- **Album Art** (left side): Cover art from currently playing track
- **Track Information** (center): Scrolling track title, artist name, album name
- **Progress Bar** (bottom): Visual playback progress with timing
- **Playback Controls** (right side): Play/pause, next, previous buttons

### Playback Controls

- **Play/Pause Button**: Resume or pause playback on your Plex server
- **Previous Button**: Skip to the previous track
- **Next Button**: Skip to the next track

**Note**: Controls only work while media is actively playing on a Plex client.

### Widget Behavior

- **Always-on-Top**: The widget stays visible above other windows
- **Click-Through**: Position the widget to monitor playback without blocking content
- **Auto-Refresh**: Updates every 2 seconds automatically
- **Minimal Interface**: Distraction-free design keeps focus on your work

### Accessing Settings

1. Click the **⚙️ Settings** button or menu option
2. Update your Plex server URL or authentication token
3. Click **Save** to apply changes

---

## Building from Source

### Prerequisites

- **Xcode 14.0 or later**
- **Swift 5.8 or later** (included with Xcode)
- **macOS 13.0 SDK or later**

### Build Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/plex-desktop-widget.git
   cd plex-desktop-widget
   ```

2. **Open in Xcode**:
   ```bash
   open PlexWidget/PlexWidget.xcodeproj
   ```

3. **Select Build Target**:
   - In Xcode, ensure `PlexWidget` scheme is selected
   - Select `My Mac` as the build destination

4. **Build the Application**:
   ```bash
   # Using Xcode menu: Product > Build
   # Or from command line:
   xcodebuild -scheme PlexWidget -configuration Release
   ```

5. **Run the Application**:
   ```bash
   # Using Xcode menu: Product > Run
   # Or from command line:
   xcodebuild -scheme PlexWidget -configuration Release -derivedDataPath .build
   open .build/Build/Products/Release/PlexWidget.app
   ```

### Build for Distribution

To create a universal binary (Intel + Apple Silicon), use the provided build script:

```bash
cd PlexWidget
chmod +x build.sh
./build.sh
```

The script will:
1. Build separate binaries for Intel (x86_64) and Apple Silicon (arm64)
2. Combine them into a universal binary using `lipo`
3. Output the final app to `PlexWidget/build/PlexWidget.app`

To install the built app:
```bash
cp -R PlexWidget/build/PlexWidget.app /Applications/
```

**Alternative: Using Xcode**

1. In Xcode, select `Product > Archive`
2. In the Archives window, select your archive and click **Distribute App**
3. Choose **Direct Distribution** or **Mac App Store**
4. Follow the distribution wizard

---

## Configuration Details

### Plex Server URL Formats

Depending on your setup, use the appropriate URL format:

| Setup Type | URL Format | Example |
|-----------|-----------|---------|
| Local Network | `http://IP_ADDRESS:32400` | `http://192.168.1.50:32400` |
| Local Machine | `http://localhost:32400` | `http://localhost:32400` |
| HTTPS (Secure) | `https://domain.plex.tv` | `https://plex.domain.com` |
| Remote Access | Check Plex settings | From Plex app remote access |

### Finding Your Plex Server IP Address

**On Network**:
- Open Plex Settings > Remote Access to see your server's remote URL
- Or check your router's connected devices list
- Or in Plex app: Settings > Server > About > Network Address

**Using Command Line**:
```bash
dns-sd -B _http._tcp local. | grep Plex
```

---

## Troubleshooting

### Widget Shows "No Connection"

1. **Verify your Plex server is running**
   - Check that Plex Media Server is active
   - Ensure it's running on the configured network

2. **Check network connectivity**
   - Ping your Plex server: `ping 192.168.1.XXX`
   - Ensure your Mac is on the same network

3. **Verify URL and token**
   - Confirm the server URL is correct
   - Re-enter your authentication token from Step 2
   - Remove any trailing slashes from the URL

4. **Test connectivity**
   - Try accessing the URL directly in a browser
   - Example: `http://192.168.1.50:32400/status/sessions`

### Widget Shows "Nothing Playing"

1. **Start playback on another device**
   - The widget shows what's currently playing on your Plex server
   - Start music on any Plex client (Plex app, web player, etc.)

2. **Check active sessions**
   - Verify that a Plex client is actively streaming
   - The widget only displays active sessions

3. **Refresh the widget**
   - Close and reopen the application
   - Or wait for the next auto-refresh (2 seconds)

### Authentication Token Invalid

1. **Verify token format**
   - Ensure you copied the entire token
   - Tokens are typically long strings of letters and numbers

2. **Check token permissions**
   - Regenerate your token in Plex settings
   - Some tokens may have limited permissions

3. **Server authentication**
   - If your server requires authentication, ensure the token is authorized
   - Log in to Plex Web as your user account

### Widget Not Updating

1. **Check network connection**
   - Ensure continuous network connectivity
   - Wi-Fi networks are more reliable than cellular

2. **Verify auto-refresh**
   - The widget refreshes every 2 seconds automatically
   - Manual refresh: Close and reopen the application

3. **Check server logs**
   - Verify no errors in Plex server logs
   - Ensure the server isn't experiencing issues

### Application Crashes

1. **Check macOS version**
   - Verify you're running macOS 13.0 or later
   - Update to the latest macOS version

2. **Permissions issues**
   - Check System Settings > Privacy & Security
   - Grant necessary permissions for network access

3. **Memory issues**
   - Check available system memory
   - Restart the application

---

## Known Limitations

- **Plex Client Control**: The widget can control playback on the Plex server, but some third-party Plex clients may have limited control support
- **Direct Music Metadata**: Album art and metadata are fetched from Plex server; quality depends on server content
- **Network Dependency**: The widget requires constant network access to your Plex server
- **Single Widget**: Currently displays only one active playback session at a time

---

## Privacy & Security

- **Local Storage**: Configuration data is stored locally on your Mac
- **Token Security**: Your authentication token is stored securely and never shared
- **Network Communication**: All communication with Plex server uses standard HTTP/HTTPS
- **No Telemetry**: This application does not collect usage data or telemetry

---

## Differences from Electron Version

The Swift/SwiftUI rewrite provides several improvements over the original Electron version:

| Feature | Electron | Swift/SwiftUI |
|---------|----------|---------------|
| **Performance** | Moderate | Excellent |
| **Memory Usage** | Higher | Lower |
| **System Integration** | Limited | Native (MediaRemote) |
| **Battery Life** | Moderate | Better |
| **Binary Size** | Larger | Smaller |
| **Startup Time** | Slower | Faster |
| **macOS Integration** | Limited | Full |

---

## Contributing

We welcome contributions from the community! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to submit issues, feature requests, and pull requests.

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## Support

### Getting Help

- **Issues**: Found a bug? [Create an issue](../../issues/new/choose)
- **Discussions**: Have a question? [Start a discussion](../../discussions)
- **Documentation**: Check out the [wiki](../../wiki)

### Reporting Bugs

When reporting bugs, please include:
1. macOS version
2. Plex server type and version
3. Error message (if any)
4. Steps to reproduce
5. System logs (if applicable)

See [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md) for the complete template.

---

## Related Projects

- **Plex Media Server**: [Official Website](https://www.plex.tv/)
- **macOS MediaRemote Framework**: [Apple Developer](https://developer.apple.com/documentation/mediaplayer/mediaremote)
- **SwiftUI Documentation**: [Apple Developer](https://developer.apple.com/xcode/swiftui/)

---

## Attribution

App icon sourced from [PNGEgg](https://www.pngegg.com/en/png-ozgbg) for non-commercial use.

The Plex logo and name are trademarks of Plex Inc. This is an unofficial third-party widget.

---

## Acknowledgments

This project was inspired by the need for a lightweight, native macOS widget for Plex. Thanks to all contributors and the Plex community for feedback and support.

---

**Last Updated**: November 2024
**Version**: 2.0.0 (Swift/SwiftUI Rebuild)
