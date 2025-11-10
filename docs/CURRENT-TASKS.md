# Plex Desktop Widget - Current Tasks

**Last Updated:** 2025-11-10

## Active Tasks

### Production Testing & Release
**Status:** App Stable - Ready for Systematic Testing
**Priority:** HIGH

**Current State:**
App is fully functional and stable after critical bug fixes:
- Threading issue with @MainActor fixed (no more crashes)
- Album art updates correctly when tracks change
- Quit-and-relaunch onboarding flow working
- Keychain integration working properly
- Comprehensive testing checklist created

**Next Steps:**
1. **Systematic Testing** - Follow TESTING-CHECKLIST.md (10 test scenarios)
   - Test 1: First Launch & Onboarding (highest priority)
   - Test 8: DMG Installation
2. **Create Production DMG** with verified working build
3. **Documentation** - Update README with screenshots, installation instructions, Keychain permission explanation
4. **GitHub Release** with DMG attached

---

## Completed Tasks

### Fixed Critical Threading Crash During Onboarding
**Status:** ✅ RESOLVED
**Date Completed:** 2025-11-10

**The Problem:**
App crashed with SIGSEGV (EXC_BAD_ACCESS) 15-30 seconds after clicking "Continue" during onboarding. Crash occurred in `objc_release` during autorelease pool cleanup.

**Root Cause:**
PlexAPI (ObservableObject with @Published properties) was being created inside `Task {}` without `@MainActor` in OnboardingView.swift:358. This caused initialization on background thread, and when @Published tried to update, it caused memory corruption.

**The Fix:**
Added `@MainActor` to Task in OnboardingView:
```swift
Task { @MainActor in
    let testAPI = PlexAPI(serverUrl: cleanUrl, token: cleanToken)
    // Validation logic...
}
```

**Additional Improvements:**
1. **Quit-and-relaunch workaround** - After saving config, app shows success dialog and quits. User manually relaunches. This avoids complex window transition crashes.
2. **Atomic config save** - Keychain save happens FIRST, UserDefaults only saves if Keychain succeeds (prevents inconsistent state)
3. **Lazy settings initialization** - `lazy var settings = WidgetSettings.shared` in AppDelegate to delay @AppStorage access

**Verified:**
- Onboarding completes without crashes
- Keychain permission dialog appears correctly (modern macOS UI)
- App relaunches successfully after onboarding
- Widget displays and updates correctly

---

### Fixed Album Art Not Updating on Track Change
**Status:** ✅ RESOLVED
**Date Completed:** 2025-11-10

**The Problem:**
When track changed in Plex, text updated correctly but album art showed previous album's image.

**Root Cause:**
`onChange(of: url)` was calling `loadImage()` but not clearing old image first. Old image stayed visible until new one loaded.

**The Fix:**
Clear image immediately in NowPlayingView.swift:
```swift
.onChange(of: url) { _ in
    image = nil  // Clear immediately
    loadImage()
}
```

**Verified:**
- Album art clears immediately when track changes (shows vinyl placeholder)
- New album art loads within 1-2 seconds
- No "stuck" old album art

---

## Files Modified This Session

### Core App Files
- `PlexWidget/PlexWidget/OnboardingView.swift` - Added @MainActor to Task, fixed onChange syntax
- `PlexWidget/PlexWidget/NowPlayingView.swift` - Clear image immediately in onChange
- `PlexWidget/PlexWidget/PlexWidgetApp.swift` - Quit-and-relaunch onboarding flow, lazy settings
- `PlexWidget/PlexWidget/Config.swift` - Atomic config save (Keychain first), DEBUG mode for testing

### Documentation Created
- `.docs/TESTING-CHECKLIST.md` - Comprehensive testing document with 10 test scenarios, commands, and known issues
- `.docs/CURRENT-TASKS.md` - Updated session summary (this file)

---

## Important Context

### What's Working
- ✅ App stable and fully functional
- ✅ Onboarding flow with Keychain integration
- ✅ Main widget displays and updates in real-time
- ✅ Album art updates correctly on track changes
- ✅ Menu bar integration with settings panel
- ✅ Media controls (play/pause, previous/next)
- ✅ Launch at login functionality
- ✅ All settings persist across restarts

### Critical Lessons Learned
1. **@MainActor is essential for ObservableObject creation in async contexts** - Creating SwiftUI ObservableObjects with @Published in background threads causes memory corruption
2. **Clear UI state before async operations** - Prevents showing stale data while new data loads
3. **Atomic configuration saves** - Critical operations (Keychain) must complete before marking process complete (UserDefaults flag)
4. **Quit-and-relaunch is acceptable UX** - Better than complex window transitions that risk crashes
5. **DEBUG builds are essential for isolating issues** - Being able to skip Keychain helped identify the real problem wasn't Keychain-related
6. **User feedback is the best debugging tool** - "never got asked for credentials" was the key insight that led to the fix

### Known Issues & Workarounds
1. **Keychain permission appears AFTER credentials entered** - This is by design and better UX
2. **User must click "Always Allow" for best experience** - Otherwise permission prompt appears on every launch (documented in testing checklist)
3. **Gatekeeper warning on unsigned app** - Users must right-click → Open on first launch (documented for README)
4. **Quit-and-relaunch required after onboarding** - Acceptable workaround for window transition crashes

### Testing & Development Commands
```bash
# Clean slate for testing
defaults delete com.plexwidget.app
security delete-generic-password -s "com.plexwidget.credentials" -a "plex-token"
killall PlexWidget

# Launch Release build
open "/Users/lemon/Library/Developer/Xcode/DerivedData/PlexWidget-ekdjkaiigyfuxzbyeenegnfaddic/Build/Products/Release/PlexWidget.app"

# Check saved data
defaults read com.plexwidget.app
security find-generic-password -s "com.plexwidget.credentials" -a "plex-token"

# Monitor logs
log stream --predicate 'process == "PlexWidget"' --level debug
```

---

## Next Session Priorities

### PRIORITY 1: Systematic Testing (CRITICAL)
**Follow .docs/TESTING-CHECKLIST.md systematically**

1. **Test 1: First Launch & Onboarding** - Full clean install test
   - Clean slate: `defaults delete com.plexwidget.app && security delete-generic-password -s "com.plexwidget.credentials" -a "plex-token" && killall PlexWidget`
   - Launch Release build
   - Complete onboarding flow
   - Verify Keychain permission appears (modern UI)
   - Click "Always Allow"
   - Verify quit-and-relaunch works
   - Check credentials saved correctly

2. **Test 3: Album Art Updates** - Verify fix is working
   - Play music on Plex
   - Change tracks multiple times
   - Verify album art clears immediately and loads new image

3. **Test 4: Menu Bar Integration** - Settings panel functionality
   - Click menu bar icon
   - Test all settings
   - Verify settings persist

4. **Test 5: Media Controls** - Play/pause, previous/next
   - Test all control buttons
   - Verify sync with Plex

5. **Test 6: Keychain Permission Handling** - Multiple scenarios
   - Test "Always Allow" vs "Allow" vs "Deny"
   - Document behavior

### PRIORITY 2: DMG Creation & Testing

6. **Create Production DMG:**
   ```bash
   cd /Volumes/LIME2/Work/Development/plex-desktop-widget/PlexWidget
   rm -rf /tmp/dmg-build
   rm PlexWidget.dmg
   mkdir -p /tmp/dmg-build
   cp -R "/Users/lemon/Library/Developer/Xcode/DerivedData/PlexWidget-ekdjkaiigyfuxzbyeenegnfaddic/Build/Products/Release/PlexWidget.app" /tmp/dmg-build/
   ln -s /Applications /tmp/dmg-build/Applications
   hdiutil create -volname "PlexWidget" -srcfolder /tmp/dmg-build -ov -format UDZO PlexWidget.dmg
   ```

7. **Test 8: DMG Installation** (from checklist)
   - Clean install from DMG
   - Test on /Applications install
   - Verify Gatekeeper handling

### PRIORITY 3: Documentation & Release

8. **Update README.md:**
   - Add screenshots of widget
   - Installation instructions (DMG + Gatekeeper workaround)
   - Keychain permission explanation ("Always Allow" recommendation)
   - Troubleshooting section

9. **Remove DEBUG mode code** from Config.swift (production readiness)

10. **Create GitHub Release:**
    - Tag version (e.g., v1.0.0)
    - Attach DMG
    - Write release notes
    - Link to README

### Optional Future Enhancements (Low Priority)
- Hide widget from macOS sound menu (Plex already shows there, causes duplicate entries)
- Code signing to avoid Gatekeeper warnings
- Multi-monitor position persistence
- Error handling improvements (server unreachable, no music playing)

---

## File Structure Reference

```
PlexWidget/
├── PlexWidget/
│   ├── PlexWidgetApp.swift          # Main app delegate with quit-and-relaunch flow
│   ├── OnboardingView.swift         # Onboarding UI with @MainActor fix ✅
│   ├── Config.swift                 # Keychain + UserDefaults with DEBUG mode
│   ├── SettingsView.swift           # Settings panel with all options
│   ├── WidgetSettings.swift         # Settings model
│   ├── ContentView.swift            # Main widget view
│   ├── NowPlayingView.swift         # Now playing display with album art fix ✅
│   ├── PlexAPI.swift                # Plex API client (ObservableObject)
│   ├── MediaRemoteController.swift  # Media controls
│   └── Assets.xcassets/             # App icons and images
├── PlexWidget.xcodeproj/
├── .docs/
│   ├── TESTING-CHECKLIST.md         # Comprehensive testing guide
│   └── CURRENT-TASKS.md             # This file
└── ...
```

---

## Git Status

**Current Branch:** main

**Modified Files (Staged):**
```
M .docs/CURRENT-TASKS.md
M PlexWidget/PlexWidget/Config.swift
M PlexWidget/PlexWidget/OnboardingView.swift
M PlexWidget/PlexWidget/PlexWidgetApp.swift
M PlexWidget/PlexWidget/SettingsView.swift
```

**Untracked Files:**
```
?? .design-assets/
?? github-page-mockup.html
```

**Recent Commits:**
- 2c6f9af (HEAD) feat: Add menu bar integration, settings panel, and production DMG
- a6e0775 Add Plex Desktop Widget with security features and documentation
- 37035d8 Initial commit: Plex Desktop Widget (Swift/SwiftUI)

**Ready to Commit:**
All critical bug fixes are ready to commit:
- Threading fix with @MainActor
- Album art update fix
- Quit-and-relaunch onboarding flow
- Atomic config save
- Testing documentation
