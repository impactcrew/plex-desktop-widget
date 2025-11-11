import SwiftUI
import MediaPlayer

struct ContentView: View {
    @StateObject private var plexAPI: PlexAPI
    @State private var mediaController = MediaRemoteController.shared
    @ObservedObject var settings: WidgetSettings
    @AppStorage("hasPlayedBefore") private var wasPlaying = false

    init(settings: WidgetSettings) {
        self.settings = settings
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

    var placeholderNowPlaying: NowPlaying {
        NowPlaying(
            id: "placeholder",
            title: "—",
            artist: "—",
            album: "—",
            albumArtUrl: nil,
            state: "stopped",
            duration: 0,
            viewOffset: 0,
            sessionKey: nil,
            playerAddress: nil,
            playerPort: nil,
            playerProtocol: nil,
            machineIdentifier: nil
        )
    }

    var body: some View {
        Group {
            if plexAPI.isLoading && !wasPlaying {
                LoadingView()
            } else if let errorMessage = plexAPI.errorMessage {
                ErrorView(message: errorMessage)
            } else if let nowPlaying = plexAPI.nowPlaying {
                NowPlayingView(nowPlaying: nowPlaying, plexAPI: plexAPI, settings: settings)
                    .onAppear {
                        wasPlaying = true
                        updateMediaRemote(nowPlaying: nowPlaying)
                    }
                    .onChange(of: nowPlaying.id) { _ in
                        wasPlaying = true
                        updateMediaRemote(nowPlaying: nowPlaying)
                    }
            } else if wasPlaying {
                // Show blank player with placeholder data
                NowPlayingView(nowPlaying: placeholderNowPlaying, plexAPI: plexAPI, settings: settings)
            } else {
                NotPlayingView()
            }
        }
        .frame(width: 552, height: 192)
        .padding(20)
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

struct BlankPlayerView: View {
    @ObservedObject var settings: WidgetSettings

    var isDarkMode: Bool {
        settings.theme == .dark
    }

    var backgroundColor: Color {
        isDarkMode ? Color(red: 13/255, green: 13/255, blue: 13/255).opacity(0.80) : Color.white
    }

    var body: some View {
        HStack(spacing: 0) {
            // Default vinyl artwork
            if settings.layoutStyle == .overlay {
                // Overlay mode - vinyl on left
                ZStack(alignment: .leading) {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .frame(width: 140, height: 140)
                        .foregroundColor(Color.white.opacity(0.1))
                        .clipShape(settings.albumArtShape == .circular ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 16)))
                        .offset(x: -10, y: 0)
                }
                .frame(width: 75, height: 140)
            } else {
                // Side mode - vinyl on left
                Image(systemName: "circle.fill")
                    .resizable()
                    .frame(width: 140, height: 140)
                    .foregroundColor(Color.white.opacity(0.1))
                    .clipShape(settings.albumArtShape == .circular ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 16)))
            }

            // Blank content area
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 12)
                    .cornerRadius(6)
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 150, height: 10)
                    .cornerRadius(5)
                Spacer()
            }
            .padding(.leading, settings.layoutStyle == .overlay ? 30 : 20)

            Spacer()
        }
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                backgroundColor
            }
        )
        .cornerRadius(28)
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
    ContentView(settings: WidgetSettings.shared)
}
