import SwiftUI

struct NowPlayingView: View {
    let nowPlaying: NowPlaying

    @State private var albumImage: NSImage?
    @State private var scrollOffset: CGFloat = 0
    @State private var needsScroll = false

    var body: some View {
        HStack(spacing: 12) {
            // Album Art
            AlbumArtView(url: nowPlaying.albumArtUrl, image: $albumImage)
                .frame(width: 96, height: 96)

            // Track Info
            VStack(alignment: .leading, spacing: 4) {
                // Track Title with scrolling
                ScrollingTextView(text: nowPlaying.title)
                    .frame(height: 20)

                // Artist Name
                Text(nowPlaying.artist)
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Album Name
                Text(nowPlaying.album)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.55))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)

                // Progress Bar
                ProgressBarView(
                    currentTime: nowPlaying.viewOffset,
                    duration: nowPlaying.duration
                )
            }

            // Playback Controls
            VStack(spacing: 8) {
                Spacer()
                PlaybackControlsView()
                Spacer()
            }
        }
        .padding(12)
    }
}

struct PlaybackControlsView: View {
    var body: some View {
        HStack(spacing: 12) {
            // Previous Button
            Button(action: {
                MediaRemoteController.shared.previousTrack()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.8))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())

            // Play/Pause Button
            Button(action: {
                MediaRemoteController.shared.togglePlayPause()
            }) {
                Image(systemName: "playpause.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.9))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())

            // Next Button
            Button(action: {
                MediaRemoteController.shared.nextTrack()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.8))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
        }
    }
}

struct AlbumArtView: View {
    let url: String?
    @Binding var image: NSImage?

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.white.opacity(0.1)
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }

    private func loadImage() {
        guard let urlString = url, let imageUrl = URL(string: urlString) else {
            image = nil
            return
        }

        URLSession.shared.dataTask(with: imageUrl) { data, _, _ in
            if let data = data, let nsImage = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.image = nsImage
                }
            }
        }.resume()
    }
}

struct ScrollingTextView: View {
    let text: String

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Measure text width
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.clear)
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeometry.size.width
                                    containerWidth = geometry.size.width
                                }
                        }
                    )

                // Display scrolling or static text
                if textWidth > containerWidth {
                    // Scrolling text
                    HStack(spacing: 30) {
                        Text(text)
                        Text(text)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.95))
                    .offset(x: offset)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.85),
                                .init(color: .clear, location: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 10)
                                .repeatForever(autoreverses: false)
                        ) {
                            offset = -(textWidth + 30)
                        }
                    }
                } else {
                    // Static text
                    Text(text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.95))
                }
            }
        }
    }
}

struct ProgressBarView: View {
    let currentTime: Int
    let duration: Int

    @State private var displayTime: Int = 0
    @State private var timer: Timer?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(displayTime) / Double(duration)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 3)

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.6))
                        .frame(width: geometry.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)

            // Time Display
            Text("\(formatTime(displayTime)) / \(formatTime(duration))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.5))
                .frame(width: 70, alignment: .trailing)
        }
        .onAppear {
            displayTime = currentTime
            startTimer()
        }
        .onChange(of: currentTime) { newValue in
            displayTime = newValue
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if displayTime < duration {
                displayTime += 1000 // Add 1 second in milliseconds
            }
        }
    }

    private func formatTime(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
