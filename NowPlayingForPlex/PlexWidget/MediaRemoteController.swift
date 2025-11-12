import Foundation
import MediaPlayer
import CoreGraphics

class MediaRemoteController: ObservableObject {
    static let shared = MediaRemoteController()

    private var commandCenter: MPRemoteCommandCenter
    private var nowPlayingInfo = [String: Any]()

    private init() {
        commandCenter = MPRemoteCommandCenter.shared()
        setupRemoteCommands()
    }

    private func setupRemoteCommands() {
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.handlePlay()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.handlePause()
            return .success
        }

        // Toggle play/pause
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.handleTogglePlayPause()
            return .success
        }

        // Next track
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.handleNext()
            return .success
        }

        // Previous track
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.handlePrevious()
            return .success
        }
    }

    func updateNowPlayingInfo(title: String, artist: String, album: String, duration: TimeInterval, currentTime: TimeInterval, artwork: MPMediaItemArtwork? = nil) {
        // Disabled to prevent PlexWidget from appearing in macOS sound menu
        // Plex app already shows there, we don't want duplicate entries

        // nowPlayingInfo[MPMediaItemPropertyTitle] = title
        // nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        // nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        // nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        // nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        // nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

        // if let artwork = artwork {
        //     nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        // }

        // MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func updatePlaybackState(isPlaying: Bool) {
        // Disabled to prevent PlexWidget from appearing in macOS sound menu
        // nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        // MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        nowPlayingInfo.removeAll()
    }

    // Public methods to trigger playback commands using media keys
    func play() {
        sendMediaKey(key: 16) // Play/Pause key
    }

    func pause() {
        sendMediaKey(key: 16) // Play/Pause key
    }

    func togglePlayPause() {
        sendMediaKey(key: 16) // Play/Pause key
    }

    func nextTrack() {
        sendMediaKey(key: 17) // Next track key
    }

    func previousTrack() {
        sendMediaKey(key: 18) // Previous track key
    }

    private func sendMediaKey(key: Int32) {
        // Create keyboard event for media keys
        guard let event = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(key),
            keyDown: true
        ) else {
            print("Failed to create media key event")
            return
        }

        event.flags = CGEventFlags.maskNonCoalesced
        event.post(tap: .cgSessionEventTap)

        // Key up
        guard let eventUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(key),
            keyDown: false
        ) else { return }

        eventUp.flags = CGEventFlags.maskNonCoalesced
        eventUp.post(tap: .cgSessionEventTap)

        print("Sent media key: \(key)")
    }

    // These handlers would need to communicate with Plex
    // For now, they're placeholders that you can implement
    private func handlePlay() {
        print("MediaRemote: Play command received")
        NotificationCenter.default.post(name: .mediaRemotePlay, object: nil)
    }

    private func handlePause() {
        print("MediaRemote: Pause command received")
        NotificationCenter.default.post(name: .mediaRemotePause, object: nil)
    }

    private func handleTogglePlayPause() {
        print("MediaRemote: Toggle play/pause command received")
        NotificationCenter.default.post(name: .mediaRemoteTogglePlayPause, object: nil)
    }

    private func handleNext() {
        print("MediaRemote: Next track command received")
        NotificationCenter.default.post(name: .mediaRemoteNext, object: nil)
    }

    private func handlePrevious() {
        print("MediaRemote: Previous track command received")
        NotificationCenter.default.post(name: .mediaRemotePrevious, object: nil)
    }
}

// Notification names for media remote commands
extension Notification.Name {
    static let mediaRemotePlay = Notification.Name("mediaRemotePlay")
    static let mediaRemotePause = Notification.Name("mediaRemotePause")
    static let mediaRemoteTogglePlayPause = Notification.Name("mediaRemoteTogglePlayPause")
    static let mediaRemoteNext = Notification.Name("mediaRemoteNext")
    static let mediaRemotePrevious = Notification.Name("mediaRemotePrevious")
}
