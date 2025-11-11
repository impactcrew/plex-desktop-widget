# Plex Playback Control Fix

## Problem Summary

Playback control buttons (play/pause/skip) were not working when trying to control the Plex Desktop app from PlexWidget.

## Root Cause

The original implementation had two critical issues:

1. **Commands sent through Plex Media Server instead of directly to player**
   - The code was sending playback commands through the Plex Media Server using the `/player/playback/*` endpoints
   - This approach requires the `X-Plex-Target-Client-Identifier` header but doesn't work reliably for local Plex Desktop players

2. **Missing Timeline Polling Requirement**
   - According to Plex Media Player Remote Control API documentation, playback commands ONLY work AFTER establishing a timeline polling connection
   - Without calling `/player/timeline/poll`, the player ignores all playback control commands
   - This is a documented requirement: "these commands only work after a request is made to /player/timeline/poll"

## Solution Implemented

### 1. Direct Player Connection

**Added player connection information to NowPlaying struct:**
```swift
struct NowPlaying: Identifiable {
    // ... existing fields ...
    let playerAddress: String?
    let playerPort: String?
    let playerProtocol: String?
    let machineIdentifier: String?
}
```

**Capture player details from /status/sessions API:**
- Player address (e.g., "127.0.0.1" for local player)
- Player port (typically "32433" for Plex Desktop)
- Player protocol (typically "http")

### 2. Timeline Polling Mechanism

**Implemented automatic timeline polling:**
```swift
private func startTimelinePolling() {
    // Initial poll to establish connection
    Task { @MainActor in
        await pollTimeline()
    }

    // Poll every 5 seconds to maintain connection
    timelineTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
        Task { @MainActor in
            await self?.pollTimeline()
        }
    }
}

private func pollTimeline() async {
    guard let playerUrl = currentPlayerBaseUrl else { return }

    let pollUrl = "\(playerUrl)/player/timeline/poll?wait=0&commandID=\(commandID)"

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

    // This establishes the connection that enables playback commands
    let (_, _) = try await URLSession.shared.data(for: request)
}
```

**Timeline polling lifecycle:**
- Starts automatically when a player is detected in `fetchNowPlaying()`
- Polls every 5 seconds to maintain the connection
- Stops when playback ends or player disconnects
- Cleaned up properly in `stopUpdating()` and `deinit`

### 3. Direct Playback Commands

**Send commands directly to player instead of through server:**
```swift
private func sendPlaybackCommand(_ endpoint: String) async {
    guard let playerUrl = currentPlayerBaseUrl else {
        // Fallback to server-based control if no direct player connection
        await sendPlaybackCommandViaServer(endpoint)
        return
    }

    // Increment command ID for each command
    commandID += 1

    // Send command directly to player
    let fullUrl = "\(playerUrl)\(endpoint)?commandID=\(commandID)"

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

    let (_, response) = try await URLSession.shared.data(for: request)
}
```

**Command ID management:**
- Each command increments the `commandID` counter
- This allows the player to track command order and ignore duplicate commands
- Required for proper command debouncing per Plex API specification

### 4. Fallback Mechanism

**Graceful degradation for remote players:**
```swift
private func sendPlaybackCommandViaServer(_ endpoint: String) async {
    guard let machineId = nowPlaying?.machineIdentifier else { return }

    let fullUrl = "\(serverUrl)\(endpoint)?type=music&commandID=\(cmdID)"

    var request = URLRequest(url: url)
    request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
    request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
    request.setValue(machineId, forHTTPHeaderField: "X-Plex-Target-Client-Identifier")

    let (_, _) = try await URLSession.shared.data(for: request)
}
```

If direct player connection fails, the code automatically falls back to server-based control for compatibility with remote players.

### 5. Media Key Integration

**Connected media key notifications to PlexAPI:**
```swift
private func setupMediaRemoteHandlers() {
    NotificationCenter.default.addObserver(
        forName: .mediaRemotePlay,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        Task { @MainActor in
            await self?.play()
        }
    }
    // ... similar for pause, togglePlayPause, skipNext, skipPrevious
}
```

This allows users to control Plex playback using:
- macOS media keys (F7, F8, F9)
- Touch Bar media controls
- Bluetooth headphone buttons
- External keyboard media keys

## Architecture Flow

```
User Action (Media Key / Button)
         ↓
MediaRemoteController sends notification
         ↓
PlexAPI receives notification
         ↓
PlexAPI.sendPlaybackCommand()
         ↓
Direct HTTP request to player: http://127.0.0.1:32433/player/playback/play?commandID=X
         ↓
Plex Desktop Player responds (200 OK)
         ↓
Next fetchNowPlaying() reflects updated state
```

## API Endpoints Used

### Sessions Endpoint (Existing)
```
GET http://plex-server:32400/status/sessions
Headers:
  X-Plex-Token: <token>
  X-Plex-Client-Identifier: <client-id>
```

Returns player information including:
- `Player.address` - Player IP address
- `Player.port` - Player API port
- `Player.protocol` - http or https
- `Player.machineIdentifier` - Player unique ID

### Timeline Poll Endpoint (NEW)
```
GET http://127.0.0.1:32433/player/timeline/poll?wait=0&commandID=<id>
Headers:
  X-Plex-Client-Identifier: <client-id>
```

Establishes player connection and enables playback commands.

### Playback Control Endpoints (UPDATED)
```
GET http://127.0.0.1:32433/player/playback/play?commandID=<id>
GET http://127.0.0.1:32433/player/playback/pause?commandID=<id>
GET http://127.0.0.1:32433/player/playback/skipNext?commandID=<id>
GET http://127.0.0.1:32433/player/playback/skipPrevious?commandID=<id>

Headers:
  X-Plex-Client-Identifier: <client-id>
```

## Testing Instructions

### Prerequisites
1. Plex Media Server running
2. Plex Desktop app installed and running
3. Music playing in Plex Desktop
4. PlexWidget configured with server URL and token

### Test Cases

**Test 1: Media Keys**
1. Start playing music in Plex Desktop
2. Press F8 (Play/Pause) on keyboard
3. Verify playback pauses/resumes
4. Press F9 (Next) on keyboard
5. Verify next track plays

**Test 2: Direct Control**
```swift
// In Xcode console, verify these log messages:
"MediaRemote: Play command received"
"MediaRemote: Pause command received"
"MediaRemote: Toggle play/pause command received"
```

**Test 3: Timeline Polling**
1. Enable network debugging in Xcode
2. Watch for HTTP requests to `http://127.0.0.1:32433/player/timeline/poll`
3. Verify polling happens every 5 seconds while music plays
4. Verify polling stops when music stops

**Test 4: Fallback Mechanism**
1. Test with remote Plex player (not local Plex Desktop)
2. Verify commands still work through server fallback

## Technical References

### Plex Media Player Remote Control API
- https://github.com/plexinc/plex-media-player/wiki/Remote-control-API

### Key Documentation Points
1. "Controllers MUST increment the command ID every command sent"
2. "Players MUST respond to poll with the same response as is POSTed via timeline"
3. "These commands only work after a request is made to /player/timeline/poll"
4. "Player subscription times out after 90 seconds"
5. "If wait=0, the player must respond immediately"

### Plex Desktop Player Details
- Default API Port: 32433
- Protocol: HTTP (can be HTTPS)
- Local Address: 127.0.0.1 or machine's LAN IP
- Product Name: "Plex Media Player" or "Plex Desktop"

## Known Limitations

1. **Timeline polling overhead**: Polls every 5 seconds while playing
   - Minimal CPU/network impact (single GET request)
   - Necessary to maintain playback control capability

2. **Local player only**: Direct control optimized for local Plex Desktop
   - Remote players fall back to server-based control
   - Server-based control has slightly higher latency

3. **Command ID tracking**: Starts at 1 on app launch
   - Resets if app is restarted
   - No persistence needed as player doesn't validate specific values

## Future Enhancements

1. **Subscribe instead of Poll**: Use `/player/timeline/subscribe` for push-based updates
   - Requires implementing HTTP server in PlexWidget to receive timeline posts
   - More efficient than polling
   - More complex implementation

2. **Advanced playback control**: Add seek, volume, shuffle, repeat controls
   - `/player/playback/seekTo?offset=<milliseconds>`
   - `/player/playback/setParameters?volume=<0-100>&shuffle=<0/1>&repeat=<0/1/2>`

3. **Multi-player support**: Control multiple active Plex players
   - Track multiple player connections
   - UI to select active player

4. **Connection health monitoring**: Detect when player becomes unreachable
   - Automatic reconnection on network changes
   - User notification of connection issues

## Code Changes Summary

### Modified Files
- `PlexWidget/PlexAPI.swift` - Core playback control implementation
- `PlexWidget/ContentView.swift` - Updated placeholder for new NowPlaying fields

### Key Additions
- `currentPlayerBaseUrl: String?` - Tracks direct player connection URL
- `commandID: Int` - Tracks command sequence for player
- `timelineTimer: Timer?` - Maintains timeline polling connection
- `startTimelinePolling()` - Establishes player connection
- `pollTimeline()` - Performs timeline poll requests
- `setupMediaRemoteHandlers()` - Wires up media key notifications
- `sendPlaybackCommandViaServer()` - Fallback for remote players

### Behavioral Changes
- Playback commands now work for Plex Desktop local player
- Media keys (F7, F8, F9) control Plex playback
- Timeline polling maintains active connection to player
- Automatic fallback to server-based control for remote players
- Proper cleanup of timers and connections

## Version Information
- PlexWidget Version: 1.0
- macOS Target: 14.0+
- Swift Version: 5.9+
- Xcode Version: 15.0+
