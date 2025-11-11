# PlexWidget Testing Checklist

**Last Updated:** 2025-11-10
**Status:** App is currently working, needs comprehensive testing before release

---

## Pre-Testing Setup

Before running any tests, ensure you have:
- [ ] Clean macOS Keychain (no existing PlexWidget entries)
- [ ] Clean UserDefaults: `defaults delete com.plexwidget.app`
- [ ] No running PlexWidget instances: `killall PlexWidget`
- [ ] Valid Plex server credentials available
- [ ] Plex server running and accessible
- [ ] Music playing on Plex to test widget display

---

## Test 1: First Launch & Onboarding (Clean Install)

**Purpose:** Verify onboarding flow works correctly for new users

### Steps:
1. **Clean State**
   ```bash
   defaults delete com.plexwidget.app
   security delete-generic-password -s "com.plexwidget.credentials" -a "plex-token"
   killall PlexWidget
   ```

2. **Launch App**
   ```bash
   open "/Users/lemon/Library/Developer/Xcode/DerivedData/PlexWidget-ekdjkaiigyfuxzbyeenegnfaddic/Build/Products/Release/PlexWidget.app"
   ```

3. **Verify Initial State**
   - [ ] Onboarding window appears (centered, borderless)
   - [ ] Plex logo visible
   - [ ] Menu bar icon (Plex chevron) appears
   - [ ] Two text fields: Server URL and Token
   - [ ] "Continue" button present but disabled (until fields filled)
   - [ ] Close button (X) in top-right corner

4. **Enter Credentials**
   - [ ] Enter Plex server URL (e.g., `http://192.168.1.2:32400`)
   - [ ] Enter Plex token (get from Plex Web → Get Info → View XML)
   - [ ] "Continue" button becomes enabled with orange gradient
   - [ ] Fields validate (no error messages)

5. **Complete Onboarding**
   - [ ] Click "Continue" button
   - [ ] Validation spinner appears briefly
   - [ ] **macOS Keychain permission dialog appears** (modern, clean UI)
   - [ ] Dialog says something like "PlexWidget wants to access Keychain"
   - [ ] Click "Always Allow" (recommended) or "Allow"
   - [ ] "Setup Complete!" alert appears
   - [ ] Alert says "Your Plex credentials have been saved. Please relaunch PlexWidget to start using it."
   - [ ] Click "Quit" button
   - [ ] App quits cleanly (no crash)

6. **Verify Saved State**
   ```bash
   defaults read com.plexwidget.app
   security find-generic-password -s "com.plexwidget.credentials" -a "plex-token"
   ```
   - [ ] UserDefaults contains `plex-server-url`
   - [ ] Keychain contains token entry

7. **Relaunch App**
   ```bash
   open "/Users/lemon/Library/Developer/Xcode/DerivedData/PlexWidget-ekdjkaiigyfuxzbyeenegnfaddic/Build/Products/Release/PlexWidget.app"
   ```
   - [ ] App launches without onboarding
   - [ ] Main widget appears in bottom-right corner
   - [ ] Menu bar icon present

**Expected Result:** ✅ Smooth onboarding experience, credentials saved securely, app launches successfully

**Known Issues:**
- Keychain permission appears AFTER clicking Continue (expected behavior)
- Requires quit-and-relaunch (by design, avoids window transition crashes)

---

## Test 2: Main Widget Display

**Purpose:** Verify widget displays currently playing media correctly

### Prerequisites:
- App already onboarded (credentials saved)
- Music playing on Plex server

### Steps:
1. **Launch App**
   ```bash
   open "/Users/lemon/Library/Developer/Xcode/DerivedData/PlexWidget-ekdjkaiigyfuxzbyeenegnfaddic/Build/Products/Release/PlexWidget.app"
   ```

2. **Verify Widget Appearance**
   - [ ] Widget appears in bottom-right corner of screen
   - [ ] Window is floating (stays on top)
   - [ ] Window is borderless with rounded corners
   - [ ] Window has shadow
   - [ ] Widget displays:
     - [ ] Album art (left side, protruding)
     - [ ] Track title
     - [ ] Artist name
     - [ ] Album name
     - [ ] Progress bar
     - [ ] Play/pause button
     - [ ] Previous/next track buttons
     - [ ] Current time / Total time

3. **Verify Album Art**
   - [ ] Album art loads correctly
   - [ ] Album art matches currently playing track
   - [ ] Album art has appropriate shape (circular or square based on settings)
   - [ ] Album art has shadow/glow effect (if enabled)

4. **Verify Real-Time Updates**
   - [ ] Progress bar updates smoothly
   - [ ] Time counter updates every second
   - [ ] Widget updates within 2 seconds of track change

**Expected Result:** ✅ Widget displays all information correctly and updates in real-time

---

## Test 3: Album Art Updates

**Purpose:** Verify album art changes when track changes

### Steps:
1. **Ensure Widget is Displaying**
   - [ ] Widget showing current track with album art

2. **Change Track in Plex**
   - Play a different song with different album art
   - Note the exact time of track change

3. **Verify Album Art Update**
   - [ ] Within 2 seconds, album art clears (shows vinyl placeholder briefly)
   - [ ] New album art loads
   - [ ] New album art matches the new track
   - [ ] Track title updates to new song
   - [ ] Artist/album info updates

4. **Repeat Multiple Times**
   - [ ] Change to 3-4 different tracks
   - [ ] Verify album art updates correctly each time
   - [ ] No "stuck" old album art

**Expected Result:** ✅ Album art updates correctly on every track change

**Fixed Issue:** Previously album art would show old image until manual refresh. Now cleared immediately when URL changes.

---

## Test 4: Menu Bar Integration

**Purpose:** Verify menu bar icon and settings panel work correctly

### Steps:
1. **Verify Menu Bar Icon**
   - [ ] Plex chevron icon visible in menu bar (top-right)
   - [ ] Icon is template-based (adapts to light/dark mode)
   - [ ] Icon size is appropriate (~18x18 points)

2. **Open Settings Panel**
   - [ ] Click menu bar icon
   - [ ] Settings panel appears below icon
   - [ ] Panel is left-aligned with icon
   - [ ] Panel has dark background with blur effect
   - [ ] Panel has rounded bottom corners

3. **Verify Settings Options**
   - [ ] **Theme**: Light / Dark segmented control
   - [ ] **Layout Style**: Side / Overlay segmented control
   - [ ] **Album Art Shape**: Square / Circular segmented control
   - [ ] **Glow Effect**: On / Off toggle
   - [ ] **Glow Colour**: Color picker (6 colors, only visible when glow is On)
   - [ ] **Launch at Login**: Toggle switch

4. **Test Settings Changes**
   - [ ] Change theme → widget updates immediately
   - [ ] Change layout → widget layout changes
   - [ ] Change album art shape → album art shape changes
   - [ ] Toggle glow → glow effect appears/disappears
   - [ ] Change glow color → glow color changes
   - [ ] Toggle launch at login → setting persists across restarts

5. **Close Settings Panel**
   - [ ] Click outside panel → panel closes
   - [ ] Click menu bar icon again → panel closes
   - [ ] Panel closes smoothly without errors

**Expected Result:** ✅ Settings panel works correctly, changes apply immediately

---

## Test 5: Media Controls

**Purpose:** Verify playback controls work correctly

### Steps:
1. **Test Play/Pause**
   - [ ] Click pause button → playback pauses in Plex
   - [ ] Widget shows pause icon changes to play icon
   - [ ] Progress bar stops moving
   - [ ] Click play button → playback resumes
   - [ ] Widget shows play icon changes to pause icon
   - [ ] Progress bar resumes

2. **Test Previous Track**
   - [ ] Click previous button
   - [ ] Plex skips to previous track
   - [ ] Widget updates to show previous track info
   - [ ] Album art updates

3. **Test Next Track**
   - [ ] Click next button
   - [ ] Plex skips to next track
   - [ ] Widget updates to show next track info
   - [ ] Album art updates

**Expected Result:** ✅ All media controls work correctly and sync with Plex

---

## Test 6: Keychain Permission Handling

**Purpose:** Verify Keychain permission flow works correctly

### Scenarios to Test:

#### Scenario A: Always Allow
1. Clean install, go through onboarding
2. When Keychain dialog appears, click "Always Allow"
3. Quit and relaunch app multiple times
4. **Expected:** No more Keychain prompts

#### Scenario B: Allow (not Always)
1. Clean install, go through onboarding
2. When Keychain dialog appears, click "Allow" (not Always Allow)
3. Quit and relaunch app
4. **Expected:** Keychain prompt appears again on each launch

#### Scenario C: Deny Access
1. Clean install, go through onboarding
2. When Keychain dialog appears, click "Deny"
3. **Expected:** "Failed to save configuration" error in onboarding
4. Credentials NOT saved, onboarding remains open

**Recommendations:**
- Document in README: "Click 'Always Allow' for best experience"
- Consider adding tooltip in onboarding explaining Keychain permission

---

## Test 7: Edge Cases & Error Handling

**Purpose:** Verify app handles edge cases gracefully

### Test Cases:

#### No Music Playing
1. Launch app with credentials saved
2. Stop all Plex playback
3. **Expected:** Widget shows "Nothing playing" or hides gracefully

#### Invalid Credentials
1. Clean install
2. Enter invalid server URL or token
3. Click Continue
4. **Expected:** Error message appears, onboarding stays open

#### Server Unreachable
1. App running with widget displayed
2. Stop Plex server or disconnect network
3. **Expected:** Widget shows error state or "Connection lost"

#### Network Timeout
1. App running with very slow network
2. **Expected:** Widget shows loading state, timeout after 5 seconds

---

## Test 8: DMG Installation (Production Build)

**Purpose:** Verify DMG installation works for end users

### Prerequisites:
- Production DMG file created
- Clean test Mac or VM
- No existing PlexWidget installation

### Steps:

1. **Create DMG**
   ```bash
   cd /Volumes/LIME2/Work/Development/plex-desktop-widget/PlexWidget

   # Clean previous build
   rm -rf /tmp/dmg-build
   rm PlexWidget.dmg

   # Copy app to staging
   mkdir -p /tmp/dmg-build
   cp -R "/Users/lemon/Library/Developer/Xcode/DerivedData/PlexWidget-ekdjkaiigyfuxzbyeenegnfaddic/Build/Products/Release/PlexWidget.app" /tmp/dmg-build/
   ln -s /Applications /tmp/dmg-build/Applications

   # Create DMG
   hdiutil create -volname "PlexWidget" -srcfolder /tmp/dmg-build -ov -format UDZO PlexWidget.dmg
   ```

2. **Test DMG Installation**
   - [ ] Double-click PlexWidget.dmg
   - [ ] DMG mounts successfully
   - [ ] Window shows PlexWidget.app and Applications alias
   - [ ] Drag PlexWidget.app to Applications
   - [ ] Eject DMG

3. **Launch from Applications**
   - [ ] Navigate to /Applications/PlexWidget.app
   - [ ] Double-click to launch
   - [ ] Gatekeeper may show "PlexWidget is from an unidentified developer"
   - [ ] Right-click → Open → Confirm to bypass Gatekeeper
   - [ ] App launches and shows onboarding

4. **Complete Onboarding from DMG Install**
   - [ ] Follow Test 1 steps
   - [ ] Verify everything works from /Applications install

**Expected Result:** ✅ DMG installation works, app launches from /Applications

**Known Issues:**
- Gatekeeper warning expected (unsigned app)
- User must right-click → Open on first launch
- Document this in README

---

## Test 9: Launch at Login

**Purpose:** Verify launch at login functionality works

### Steps:
1. **Enable Launch at Login**
   - Open Settings panel
   - Toggle "Launch at Login" to On
   - Verify toggle shows enabled state

2. **Verify Login Item Added**
   ```bash
   # Check if login item exists
   osascript -e 'tell application "System Events" to get the name of every login item'
   ```
   - [ ] PlexWidget appears in list

3. **Test Auto-Launch**
   - Quit PlexWidget completely
   - Log out and log back in (or restart Mac)
   - **Expected:** PlexWidget launches automatically
   - Widget appears without manual intervention

4. **Disable Launch at Login**
   - Open Settings panel
   - Toggle "Launch at Login" to Off
   - Log out and log back in
   - **Expected:** PlexWidget does NOT launch

**Expected Result:** ✅ Launch at login works correctly

---

## Test 10: Multi-Monitor Setup

**Purpose:** Verify widget positioning on multi-monitor setups

### Steps (if multi-monitor available):
1. Connect second monitor
2. Launch PlexWidget
3. **Expected:** Widget appears on primary monitor bottom-right
4. Drag widget to secondary monitor
5. Quit and relaunch
6. **Expected:** Widget position persists (if persistence implemented)

**Note:** This feature may need implementation if not working

---

## Performance & Stability Tests

### Memory Leaks
1. Launch app
2. Let it run for 1+ hours with continuous playback
3. Monitor memory usage in Activity Monitor
4. **Expected:** Memory usage stable, no leaks

### CPU Usage
1. Launch app
2. Check CPU usage in Activity Monitor
3. **Expected:** <1% CPU when idle, <5% when updating

### Rapid Track Changes
1. Skip through 20+ tracks rapidly
2. **Expected:** Widget updates without lag or crash
3. Album art loads correctly for each track

---

## Regression Tests (After Any Code Changes)

**Critical Tests to Run:**
- [ ] Test 1: First launch onboarding
- [ ] Test 3: Album art updates
- [ ] Test 4: Menu bar integration
- [ ] Test 5: Media controls
- [ ] Test 6: Keychain permission (Always Allow scenario)

**Optional but Recommended:**
- [ ] Test 7: Edge cases
- [ ] Test 9: Launch at login

---

## Known Issues & Workarounds

### Issue 1: Quit-and-Relaunch Required After Onboarding
**Status:** By Design (workaround for window transition crash)
**Impact:** Slightly inconvenient but acceptable
**Workaround:** None needed, users simply relaunch after setup

### Issue 2: Keychain Permission Dialog Timing
**Status:** Expected Behavior
**Impact:** Permission appears after clicking Continue, not before
**Workaround:** None needed, this is actually better UX

### Issue 3: Gatekeeper Warning on First Launch
**Status:** Expected (unsigned app)
**Impact:** Users must right-click → Open on first launch
**Workaround:** Document in README, or sign app with Developer ID

### Issue 4: Album Art Caching
**Status:** Fixed (2025-11-10)
**Impact:** Previously showed old album art until refresh
**Fix:** Clear image immediately when URL changes

---

## Testing Environment

### Recommended Setup:
- **macOS Version:** 15.6.1 (Sequoia) or later
- **Xcode Version:** Latest stable
- **Plex Server:** Running locally or accessible via network
- **Test Music:** Multiple albums with distinct artwork
- **Network:** Stable connection to Plex server

### Build Configurations to Test:
1. **Debug Build** (skips Keychain, uses UserDefaults)
   ```bash
   xcodebuild -project PlexWidget.xcodeproj -scheme PlexWidget -configuration Debug build
   ```

2. **Release Build** (uses Keychain)
   ```bash
   xcodebuild -project PlexWidget.xcodeproj -scheme PlexWidget -configuration Release build
   ```

**Always test Release builds before deployment!**

---

## Pre-Release Checklist

Before creating a production DMG and GitHub release:

- [ ] All critical tests pass (Tests 1-6)
- [ ] No known crashes
- [ ] Album art updates correctly
- [ ] Keychain integration works
- [ ] Settings persist across restarts
- [ ] DMG installation tested
- [ ] README updated with:
  - [ ] Installation instructions
  - [ ] Keychain permission explanation
  - [ ] Gatekeeper workaround
  - [ ] Screenshots of widget
  - [ ] Troubleshooting section
- [ ] CHANGELOG updated
- [ ] Git tag created
- [ ] Code committed and pushed

---

## Quick Test Commands

### Clean Slate
```bash
defaults delete com.plexwidget.app
security delete-generic-password -s "com.plexwidget.credentials" -a "plex-token"
killall PlexWidget
```

### Launch Debug Build
```bash
open "/Users/lemon/Library/Developer/Xcode/DerivedData/PlexWidget-ekdjkaiigyfuxzbyeenegnfaddic/Build/Products/Debug/PlexWidget.app"
```

### Launch Release Build
```bash
open "/Users/lemon/Library/Developer/Xcode/DerivedData/PlexWidget-ekdjkaiigyfuxzbyeenegnfaddic/Build/Products/Release/PlexWidget.app"
```

### Check Saved Data
```bash
defaults read com.plexwidget.app
security find-generic-password -s "com.plexwidget.credentials" -a "plex-token"
```

### View Logs
```bash
log stream --predicate 'process == "PlexWidget"' --level debug
```

---

## Contact & Support

**Developer:** Jan Hargreaves
**Project:** Plex Desktop Widget
**Repository:** (Add GitHub URL when available)

For bugs or feature requests, please create a GitHub issue.
