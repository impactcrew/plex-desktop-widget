import SwiftUI
import MediaPlayer

struct ContentView: View {
    @StateObject private var plexAPI: PlexAPI
    @State private var mediaController = MediaRemoteController.shared

    init() {
        // Load configuration
        if let config = ConfigManager.shared.loadConfig() {
            _plexAPI = StateObject(wrappedValue: PlexAPI(
                serverUrl: config.plexServerUrl,
                token: config.plexToken
            ))
        } else {
            // Fallback to empty API (will show error)
            _plexAPI = StateObject(wrappedValue: PlexAPI(
                serverUrl: "",
                token: ""
            ))
        }
    }

    var body: some View {
        ZStack {
            // Black transparent background like terminal
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

            // Content
            Group {
                if plexAPI.isLoading {
                    LoadingView()
                } else if let errorMessage = plexAPI.errorMessage {
                    ErrorView(message: errorMessage)
                } else if let nowPlaying = plexAPI.nowPlaying {
                    NowPlayingView(nowPlaying: nowPlaying)
                        .onAppear {
                            updateMediaRemote(nowPlaying: nowPlaying)
                        }
                        .onChange(of: nowPlaying.id) { _ in
                            updateMediaRemote(nowPlaying: nowPlaying)
                        }
                } else {
                    NotPlayingView()
                }
            }
        }
        .frame(width: 420, height: 120)
        .onAppear {
            plexAPI.startUpdating(interval: 2.0)
        }
        .onDisappear {
            plexAPI.stopUpdating()
            mediaController.clearNowPlayingInfo()
        }
    }

    private func updateMediaRemote(nowPlaying: NowPlaying) {
        let durationSeconds = TimeInterval(nowPlaying.duration) / 1000.0
        let currentSeconds = TimeInterval(nowPlaying.viewOffset) / 1000.0

        mediaController.updateNowPlayingInfo(
            title: nowPlaying.title,
            artist: nowPlaying.artist,
            album: nowPlaying.album,
            duration: durationSeconds,
            currentTime: currentSeconds
        )

        mediaController.updatePlaybackState(isPlaying: nowPlaying.state == "playing")
    }
}

struct LoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 0.8)
                            .repeatForever(autoreverses: false)
                    ) {
                        rotation = 360
                    }
                }

            Text("Loading...")
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .padding(20)
    }
}

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(Color.white.opacity(0.6))

            Text("Error")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.8))

            Text(message)
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(20)
    }
}

struct NotPlayingView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 24))
                .foregroundColor(Color.white.opacity(0.4))

            Text("Nothing playing")
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.5))
        }
        .padding(20)
    }
}

// Visual Effect View for glassmorphism
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ContentView()
}
