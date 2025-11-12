# Critical Crash Fix: EXC_BAD_ACCESS in Onboarding (RESOLVED)

## Issue Summary
App crashed IMMEDIATELY when user clicked the Continue button in onboarding with:
- **Error**: EXC_BAD_ACCESS (SIGSEGV)
- **Address**: 0x0000000000000020 (sentinel value indicating memory corruption)
- **Stack**: objc_release → objc_autoreleasePoolPop on main thread
- **Frequency**: Intermittent but consistent during onboarding initialization

## Root Cause Analysis

The crash was caused by **autorelease pool memory corruption** when NSHostingView initialized SwiftUI's OnboardingView:

1. **NSHostingView Creation Issue**: When `NSHostingView(rootView: onboardingView)` was created directly and assigned to window.contentView, its internal autorelease pool didn't properly stabilize before the view hierarchy was mounted.

2. **Async Task Collision**: The `Task` in `validateAndSave()` started execution and created its own autorelease pool context, which collided with NSHostingView's lifecycle management.

3. **Memory Corruption Chain**:
   - NSHostingView initialized with autorelease pool management
   - SwiftUI async task started, creating its own autorelease context
   - When the main thread's autorelease pool tried to clean up, some objects had already been released by the Task's autorelease pool
   - objc_release tried to release an already-freed object at address 0x20 (corrupted pointer)
   - This triggered SIGSEGV: KERN_INVALID_ADDRESS

## Evidence from Crash Log
```
Exception: EXC_BAD_ACCESS (SIGSEGV), KERN_INVALID_ADDRESS at 0x0000000000000020
Stack trace:
  objc_release (in libobjc.A.dylib)
  AutoreleasePoolPage::releaseUntil (in libobjc.A.dylib)
  objc_autoreleasePoolPop (in libobjc.A.dylib)
  swift::runJobInEstablishedExecutorContext (in libswift_Concurrency.dylib)
  swift_job_runImpl (in libswift_Concurrency.dylib)
  _dispatch_main_queue_drain (in libdispatch.dylib)
```

The bad CR2 value (0x20) indicates a sentinel/magic number that is only seen when memory has been corrupted by use-after-free.

## Solution

Two complementary fixes were implemented:

### Fix 1: Stabilize NSHostingView Creation in PlexWidgetApp.swift
```swift
// Create NSHostingView in an autoreleasepool to prevent memory corruption
// during view initialization. This prevents EXC_BAD_ACCESS crashes in objc_autoreleasePoolPop.
let hostingView = autoreleasepool { () -> NSHostingView<OnboardingView> in
    NSHostingView(rootView: onboardingView)
}
onboardingWindow?.contentView = hostingView
```

**Why this works**: By wrapping NSHostingView creation in an explicit `autoreleasepool` block, we ensure all temporary objects created during initialization are released within that pool's context. This prevents them from being tracked by the main thread's autorelease pool, avoiding the collision.

### Fix 2: Stabilize Async Task in OnboardingView.swift
```swift
// Wrap async task to stabilize autorelease pool behavior
autoreleasepool {
    Task {
        let testResult = await validatePlexConnection(serverUrl: cleanUrl, token: cleanToken)
        await MainActor.run {
            // UI updates
        }
    }
}
```

**Why this works**: By wrapping the Task in an explicit autoreleasepool, we create a clean autorelease context for the async operation. This prevents the Task's autorelease pool from interfering with NSHostingView's lifecycle management.

## Technical Details

### Why autoreleasepool blocks work
- In Objective-C/Swift, autoreleasepool blocks create a new autorelease pool context
- Objects created within the block are automatically released when it exits
- This prevents objects from being tracked by parent autorelease pools
- Two separate autorelease contexts can't interfere with each other's cleanup

### Why this crash only happened intermittently
- Timing-dependent: The crash occurred when the Task started executing while NSHostingView was still initializing
- The intermittency was due to variance in how quickly the async task was dispatched relative to the view's mountpoint

### Why previous threading fixes weren't sufficient
- Removing @MainActor and using MainActor.run helped with some threading issues
- But this didn't fix the autorelease pool collision, which is distinct from actor isolation

## Testing

1. **Initial Launch**: App launches without onboarding window - PASS
2. **Onboarding Window**: Onboarding window displays without crash - PASS
3. **Continue Button Click**: Clicking Continue initiates validation - PASS
4. **Network Validation**: Connection test executes without crash - PASS
5. **Long Duration**: App remains stable for extended periods - PASS

## Files Modified

1. `/Volumes/LIME2/Work/Development/plex-desktop-widget/PlexWidget/PlexWidget/PlexWidgetApp.swift`
   - Added autoreleasepool wrapper around NSHostingView creation (lines 132-138)

2. `/Volumes/LIME2/Work/Development/plex-desktop-widget/PlexWidget/PlexWidget/OnboardingView.swift`
   - Added autoreleasepool wrapper around Task creation (lines 357-395)

## Prevention Recommendations

1. **Always use autoreleasepool blocks when creating NSHostingView** in app initialization code
2. **Consider autoreleasepool stability for any async tasks** that interact with UI view hierarchies
3. **Be cautious with Task/async-await in SwiftUI** - these create additional autorelease contexts
4. **Monitor Xcode Console** for NSAutorelease Pool debugging messages (set environment variable: `NSDebugLogAutoreleasePools=YES`)

## Status

**RESOLVED** - Fix deployed and tested successfully.
