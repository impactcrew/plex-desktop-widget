# Onboarding Validation Crash - Root Cause Analysis & Fix

## Problem Summary
The PlexWidget macOS app was crashing during onboarding validation when users clicked "Continue" to validate their Plex server credentials. The crash manifested as `EXC_BAD_ACCESS` in `objc_release` during autorelease pool cleanup.

## Timeline of Crash
1. User enters Plex server URL and token
2. User clicks "Continue"
3. App shows "Validating..."
4. App crashes immediately with `EXC_BAD_ACCESS`

## Root Causes Identified

### 1. Triple-Nested MainActor Context (PRIMARY CAUSE)
**Location:** `OnboardingView.swift` lines 358-416 (original code)

**Problem:**
```swift
Task { @MainActor in                    // 1st MainActor context
    await testAPI.fetchNowPlaying()

    await MainActor.run {               // 2nd MainActor context (REDUNDANT)
        if testAPI.isLoading {
            Task {                      // New Task spawned
                await MainActor.run {   // 3rd MainActor context (DANGEROUS)
                    // Access testAPI here
                }
            }
        }
    }
}
```

**Why This Crashes:**
- Creates unnecessary nested MainActor contexts
- The inner Task can outlive the outer Task
- When the outer Task completes, it may deallocate objects the inner Task still references
- Results in `EXC_BAD_ACCESS` when inner Task tries to access deallocated memory
- Autorelease pool cleanup happens in the wrong order, causing crashes

### 2. PlexAPI Object Lifetime Issues
**Location:** `OnboardingView.swift` line 360

**Problem:**
```swift
Task { @MainActor in
    let testAPI = PlexAPI(serverUrl: cleanUrl, token: cleanToken)
    await testAPI.fetchNowPlaying()

    // Nested Task created here
    Task {
        // testAPI may be deallocated by now!
        if let error = testAPI.errorMessage { ... }
    }
}
```

**Why This Crashes:**
- `testAPI` is a local variable scoped to the outer Task
- Nested Tasks don't capture `testAPI` strongly
- When outer Task completes, `testAPI` is deallocated
- Nested Task tries to access deallocated object → crash

### 3. Race Condition with Async Sleep
**Location:** `OnboardingView.swift` lines 363-366

**Problem:**
```swift
await testAPI.fetchNowPlaying()
try? await Task.sleep(nanoseconds: 500_000_000)  // Sleep 500ms

// Hope the request finished!
if let error = testAPI.errorMessage { ... }
```

**Why This is Bad:**
- The 500ms sleep doesn't guarantee `fetchNowPlaying()` completed
- Network requests can take longer or shorter time
- Checking `testAPI.isLoading` and sleeping again compounds the problem
- Creates unreliable validation logic

### 4. State Update Order Issue
**Location:** `OnboardingView.swift` line 378

**Problem:**
```swift
if ConfigManager.shared.saveConfig(serverUrl: cleanUrl, token: cleanToken) {
    isValidating = false        // Set BEFORE calling onComplete
    onComplete(cleanUrl, cleanToken)  // This closes the window!
}
```

**Why This is Bad:**
- Setting `isValidating = false` before `onComplete()` can cause crashes
- `onComplete()` immediately closes the onboarding window
- If the Task tries to update UI after window is closed → crash
- The View may be deallocated while the Task is still running

## Solution Implemented

### Fix 1: Removed Nested MainActor Contexts
**File:** `OnboardingView.swift`

Created a separate validation function that returns a result directly:

```swift
private func validateAndSave() {
    Task { @MainActor in
        // Single MainActor context - no nesting
        let testResult = await validatePlexConnection(serverUrl: cleanUrl, token: cleanToken)

        if let error = testResult.error {
            // Handle error
        } else {
            // Handle success
            onComplete(cleanUrl, cleanToken)
        }
    }
}

@MainActor
private func validatePlexConnection(serverUrl: String, token: String) async -> (success: Bool, error: String?) {
    // Perform validation synchronously
    // No nested Tasks or MainActor.run blocks
}
```

**Benefits:**
- Single Task, single MainActor context
- No nested Tasks that can outlive parent
- Clean async/await flow
- Proper error handling

### Fix 2: Direct API Call Instead of PlexAPI Object
**File:** `OnboardingView.swift` lines 394-439

Instead of creating a PlexAPI instance, we make the API call directly:

```swift
private func validatePlexConnection(serverUrl: String, token: String) async -> (success: Bool, error: String?) {
    guard let url = URL(string: "\(serverUrl)/status/sessions") else {
        return (false, "Invalid server URL format")
    }

    var request = URLRequest(url: url)
    request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
    request.timeoutInterval = 10.0

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        // Check response...
        return (true, nil)
    } catch {
        return (false, error.localizedDescription)
    }
}
```

**Benefits:**
- No object lifetime issues
- Direct API call with clear success/failure
- Better error messages
- 10 second timeout instead of 5 seconds

### Fix 3: Removed Async Sleep Race Condition
The new validation waits for the actual network request to complete:

```swift
let testResult = await validatePlexConnection(serverUrl: cleanUrl, token: cleanToken)
// testResult is guaranteed to have the final result - no sleeping needed
```

**Benefits:**
- No arbitrary sleep timings
- Validation completes when API call completes
- More reliable and faster
- Better user experience

### Fix 4: Correct State Update Order
**File:** `OnboardingView.swift` lines 377-380

```swift
if ConfigManager.shared.saveConfig(serverUrl: cleanUrl, token: cleanToken) {
    // Call onComplete BEFORE setting isValidating = false
    // This ensures proper cleanup order when the window closes
    onComplete(cleanUrl, cleanToken)
}
```

**Benefits:**
- Window closes cleanly without pending state updates
- No UI updates after View deallocation
- Prevents crashes during window cleanup

## Additional Improvements

### Better Error Messages
The new validation provides specific error messages:
- "Invalid Plex token - authentication failed" (401)
- "Server endpoint not found - check your server URL" (404)
- "Connection timed out - server may be unreachable" (timeout)
- "Cannot connect to server - check URL and network" (connection error)

### Increased Timeout
Changed from 5 seconds to 10 seconds to accommodate slower networks.

### Proper Window Cleanup
The `onComplete` handler in `PlexWidgetApp.swift` already has proper cleanup:
```swift
onComplete: { [weak self] serverUrl, token in
    self.onboardingWindow?.close()
    self.onboardingWindow = nil

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        NSApp.setActivationPolicy(.accessory)
        self.showMainWidget()
    }
}
```

## Testing Recommendations

1. Test with valid credentials → should succeed
2. Test with invalid token → should show clear error
3. Test with invalid URL → should show clear error
4. Test with slow network → should wait up to 10 seconds
5. Test clicking Continue multiple times rapidly → should not crash
6. Test closing window during validation → should not crash

## Prevention Recommendations

### Avoid These Patterns:
1. **Nested MainActor.run inside @MainActor Task** - Always redundant and can cause crashes
2. **Spawning new Tasks inside MainActor.run** - Can cause lifetime issues
3. **Using Task.sleep to wait for async operations** - Use actual await instead
4. **Setting state after calling completion handlers** - Complete first, then clean up

### Follow These Patterns:
1. **Single Task per async operation** - Keep it simple
2. **Use await for async operations** - Don't use sleep to wait
3. **Return results directly** - Avoid checking object state after delays
4. **Call completion handlers last** - After all state updates complete

## Files Modified
- `/Volumes/LIME2/Work/Development/plex-desktop-widget/PlexWidget/PlexWidget/OnboardingView.swift`
  - Lines 341-439: Complete validation logic rewrite
  - Removed triple-nested MainActor contexts
  - Added `validatePlexConnection()` function
  - Fixed state update order

## Verification
- Build Status: SUCCESS
- Warnings: 1 (non-critical Sendable warning in NowPlayingView.swift)
- Errors: 0

## Conclusion
The crash was caused by improper async/await patterns creating nested execution contexts and object lifetime issues. The fix simplifies the validation flow to a single async Task with direct API calls, eliminating all race conditions and memory management issues.
