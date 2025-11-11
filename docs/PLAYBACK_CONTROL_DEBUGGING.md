# Playback Control Debugging Guide

## Quick Diagnostics

### Is the Player Connected?

Check the Xcode console for timeline polling activity:

```
✅ GOOD: Timeline poll requests happening every 5 seconds
❌ BAD: No timeline poll requests = player not connected
```

### Are Commands Being Sent?

Enable network debugging to see HTTP requests:

1. In Xcode: Product > Scheme > Edit Scheme
2. Run > Arguments > Environment Variables
3. Add: `CFNETWORK_DIAGNOSTICS = 3`

Look for:
```
GET http://127.0.0.1:32433/player/timeline/poll?wait=0&commandID=X
GET http://127.0.0.1:32433/player/playback/play?commandID=X
```

### Common Issues

#### Issue 1: "Commands don't work"
**Symptoms:**
- Media keys do nothing
- No response from player

**Debug Steps:**
1. Check if music is playing in Plex Desktop
2. Verify PlexWidget shows current track
3. Check console for "MediaRemote: Play command received"
4. Check if timeline polling is active

**Solution:**
- Ensure Plex Desktop is running and playing music
- Check that player information is captured in NowPlaying:
  ```swift
  print("Player URL: \(nowPlaying?.playerAddress):\(nowPlaying?.playerPort)")
  ```

#### Issue 2: "Timeline polling not starting"
**Symptoms:**
- No HTTP requests to `/player/timeline/poll`
- Commands fail silently

**Debug Steps:**
1. Check if player info is available:
   ```swift
   print("Address: \(playerAddr), Port: \(playerPort), Protocol: \(playerProtocol)")
   ```
2. Verify `currentPlayerBaseUrl` is set:
   ```swift
   print("Player base URL: \(currentPlayerBaseUrl ?? "nil")")
   ```

**Solution:**
- Ensure `/status/sessions` returns player info
- Verify Player object has address, port, and protocol fields
- Check that player is in "playing" or "paused" state

#### Issue 3: "HTTP 404 on playback commands"
**Symptoms:**
- Timeline poll succeeds
- Playback commands return 404

**Debug Steps:**
1. Verify Plex Desktop API port (should be 32433)
2. Check endpoint format:
   ```
   http://127.0.0.1:32433/player/playback/play?commandID=X
   ```
3. Verify X-Plex-Client-Identifier header is sent

**Solution:**
- Confirm Plex Desktop app is running (not just web player)
- Check if firewall is blocking port 32433
- Try accessing `http://127.0.0.1:32433/player/timeline/poll?wait=0` in browser

#### Issue 4: "Commands work intermittently"
**Symptoms:**
- Sometimes works, sometimes doesn't
- Commands work right after timeline poll

**Debug Steps:**
1. Check timeline polling interval (should be 5 seconds)
2. Verify timer isn't being invalidated prematurely
3. Check if polling stops when it shouldn't

**Solution:**
- Ensure `timelineTimer` is not nil during playback
- Verify timer runs on main thread
- Check that timer is invalidated only in `stopUpdating()` and `deinit`

## Manual Testing

### Test Timeline Poll
```bash
# Replace CLIENT_ID with your client identifier
curl -H "X-Plex-Client-Identifier: plex-desktop-widget-123" \
  "http://127.0.0.1:32433/player/timeline/poll?wait=0&commandID=1"
```

Expected response: XML with timeline data for music, video, and photo types

### Test Play Command
```bash
# IMPORTANT: Run timeline poll FIRST
curl -H "X-Plex-Client-Identifier: plex-desktop-widget-123" \
  "http://127.0.0.1:32433/player/timeline/poll?wait=0&commandID=1"

# Then send play command
curl -H "X-Plex-Client-Identifier: plex-desktop-widget-123" \
  "http://127.0.0.1:32433/player/playback/play?commandID=2"
```

Expected response: 200 OK with empty body

### Check Player Info
```bash
# Replace with your Plex server URL and token
curl -H "X-Plex-Token: YOUR_TOKEN" \
  "http://your-plex-server:32400/status/sessions" | python -m json.tool
```

Look for:
```json
{
  "Player": {
    "address": "127.0.0.1",
    "port": "32433",
    "protocol": "http",
    "machineIdentifier": "unique-player-id"
  }
}
```

## Logging Additions for Debugging

Add these temporary debug logs to PlexAPI.swift:

### In fetchNowPlaying():
```swift
if let addr = playerAddr, let port = playerPort, let proto = playerProtocol {
    let newPlayerUrl = "\(proto)://\(addr):\(port)"
    print("🎵 Player detected: \(newPlayerUrl)")
    if currentPlayerBaseUrl != newPlayerUrl {
        currentPlayerBaseUrl = newPlayerUrl
        print("🔗 Starting timeline polling for: \(newPlayerUrl)")
        startTimelinePolling()
    }
}
```

### In pollTimeline():
```swift
private func pollTimeline() async {
    guard let playerUrl = currentPlayerBaseUrl else {
        print("⚠️ No player URL for timeline poll")
        return
    }

    let pollUrl = "\(playerUrl)/player/timeline/poll?wait=0&commandID=\(commandID)"
    print("📊 Timeline poll: \(pollUrl)")

    // ... rest of implementation

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Timeline poll success: \(httpResponse.statusCode)")
        }
    } catch {
        print("❌ Timeline poll failed: \(error.localizedDescription)")
    }
}
```

### In sendPlaybackCommand():
```swift
private func sendPlaybackCommand(_ endpoint: String) async {
    guard let playerUrl = currentPlayerBaseUrl else {
        print("⚠️ No player URL, using server fallback for: \(endpoint)")
        await sendPlaybackCommandViaServer(endpoint)
        return
    }

    commandID += 1
    let fullUrl = "\(playerUrl)\(endpoint)?commandID=\(commandID)"
    print("🎮 Sending command: \(fullUrl)")

    // ... rest of implementation

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Command success: \(httpResponse.statusCode)")
        }
    } catch {
        print("❌ Command failed: \(error.localizedDescription)")
        await sendPlaybackCommandViaServer(endpoint)
    }
}
```

## Expected Console Output (Working)

```
🎵 Player detected: http://127.0.0.1:32433
🔗 Starting timeline polling for: http://127.0.0.1:32433
📊 Timeline poll: http://127.0.0.1:32433/player/timeline/poll?wait=0&commandID=1
✅ Timeline poll success: 200
MediaRemote: Toggle play/pause command received
🎮 Sending command: http://127.0.0.1:32433/player/playback/pause?commandID=2
✅ Command success: 200
📊 Timeline poll: http://127.0.0.1:32433/player/timeline/poll?wait=0&commandID=2
✅ Timeline poll success: 200
```

## Expected Console Output (Not Working)

```
❌ Timeline poll failed: The operation couldn't be completed. Connection refused
MediaRemote: Play command received
⚠️ No player URL, using server fallback for: /player/playback/play
```

This indicates Plex Desktop is not running or not accessible on port 32433.

## Network Capture with tcpdump

For deep debugging, capture network traffic:

```bash
# Capture HTTP traffic on port 32433
sudo tcpdump -i lo0 -A -s 0 'port 32433'
```

Look for:
- GET requests to `/player/timeline/poll`
- GET requests to `/player/playback/*`
- HTTP response codes (200 = success, 404 = not found)

## Xcode Breakpoints

Set breakpoints at:
1. `startTimelinePolling()` - Verify this is called
2. `pollTimeline()` - Check if polling happens
3. `sendPlaybackCommand()` - Verify commands are sent
4. `setupMediaRemoteHandlers()` - Ensure notifications are registered

## Performance Monitoring

Timeline polling should have minimal impact:
- Request every 5 seconds
- ~200-500ms latency per request
- ~500 bytes per request/response
- CPU usage: <0.1%

Monitor with Activity Monitor:
- Network: Should see periodic requests to localhost:32433
- CPU: PlexWidget should stay under 1% when idle
- Memory: Stable, no leaks from timers

## Clean Up Test

Verify timers are cleaned up properly:

1. Start playing music in Plex Desktop
2. Verify timeline polling starts
3. Stop music in Plex Desktop
4. Check console: Timeline polling should stop
5. Close PlexWidget
6. Check Activity Monitor: No orphaned timers or network connections

## Support Resources

- Plex API Documentation: https://github.com/plexinc/plex-media-player/wiki/Remote-control-API
- Plex Forums: https://forums.plex.tv/
- PlexAPI Python Library (reference): https://python-plexapi.readthedocs.io/
