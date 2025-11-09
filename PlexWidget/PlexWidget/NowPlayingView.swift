import SwiftUI

struct NowPlayingView: View {
    let nowPlaying: NowPlaying
    @ObservedObject var plexAPI: PlexAPI
    @ObservedObject var settings: WidgetSettings

    @State private var albumImage: NSImage?
    @State private var displayTime: Int = 0
    @State private var timer: Timer?
    @State private var titleOffset: CGFloat = 0
    @State private var shouldScrollTitle = false

    var progress: Double {
        guard nowPlaying.duration > 0 else { return 0 }
        return Double(displayTime) / Double(nowPlaying.duration)
    }

    // Theme colors based on settings
    var isDarkMode: Bool {
        settings.theme == .dark
    }

    var backgroundColor: Color {
        isDarkMode ? Color(red: 13/255, green: 13/255, blue: 13/255).opacity(0.80) : Color.white
    }

    var titleColor: Color {
        isDarkMode ? Color.white : Color(hex: "1d1d1f")
    }

    var subtitleColor: Color {
        isDarkMode ? Color.white.opacity(0.85) : Color(hex: "86868b")
    }

    var shadowColors: [(Color, CGFloat, CGFloat, CGFloat)] {
        if isDarkMode {
            return [
                (Color.black.opacity(0.4), 15, 0, 5),
                (Color.black.opacity(0.3), 6, 0, 2)
            ]
        } else {
            return [
                (Color.black.opacity(0.15), 15, 0, 5),
                (Color.black.opacity(0.1), 6, 0, 2)
            ]
        }
    }

    var body: some View {
        Group {
            if settings.layoutStyle == .side {
                sideLayout
            } else {
                overlayLayout
            }
        }
        .onAppear {
            displayTime = nowPlaying.viewOffset
            startTimer()
        }
        .onChange(of: nowPlaying.viewOffset) { newValue in
            displayTime = newValue
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    var overlayLayout: some View {
        ZStack(alignment: .leading) {
            // Album art positioned absolutely
            AlbumArtView(url: nowPlaying.albumArtUrl, image: $albumImage, plexAPI: plexAPI)
                .frame(width: 190, height: 190)
                .clipShape(settings.albumArtShape == .circular ?
                    AnyShape(Circle()) :
                    AnyShape(RoundedRectangle(cornerRadius: 20)))
                .shadow(color: .black.opacity(0.25), radius: 12.5, x: 0, y: 3.75)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 1.25)
                .offset(x: -75, y: 0)
                .zIndex(10)

            // Main content card with left padding for album art overlap
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        // Scrolling title
                        GeometryReader { geo in
                            HStack(spacing: 30) {
                                if shouldScrollTitle {
                                    Text(nowPlaying.title)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(titleColor)
                                        .fixedSize()
                                    Text(nowPlaying.title)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(titleColor)
                                        .fixedSize()
                                } else {
                                    Text(nowPlaying.title)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(titleColor)
                                        .lineLimit(1)
                                }
                            }
                            .offset(x: shouldScrollTitle ? titleOffset : 0)
                            .onAppear {
                                let textWidth = (nowPlaying.title as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 20, weight: .semibold)]).width
                                if textWidth > geo.size.width {
                                    shouldScrollTitle = true
                                    startScrolling(textWidth: textWidth, containerWidth: geo.size.width)
                                }
                            }
                        }
                        .frame(height: 24)
                        .clipped()

                        Text(nowPlaying.artist)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(subtitleColor)
                            .lineLimit(1)

                        Text(nowPlaying.album)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(subtitleColor)
                            .lineLimit(1)
                            .padding(.top, 2)
                    }

                    // Progress bar with time
                    VStack(spacing: 2) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: "e5e5e5"))
                                    .frame(height: 6)

                                // Fill with gradient
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "ffcb7d"),
                                                Color(hex: "ff920c")
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)

                        // Time codes
                        HStack {
                            Text(formatTime(displayTime))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(subtitleColor)

                            Spacer()

                            Text(formatTime(nowPlaying.duration))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(subtitleColor)
                        }
                        .padding(.horizontal, 2)
                    }
                    .padding(.top, 5)
                }
                .frame(width: 320)
                .padding(.top, 20)
                .padding(.bottom, 12)
                .padding(.horizontal, 16)
            }
            .padding(.leading, 125)
            .background(
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                    .overlay(backgroundColor)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .compositingGroup()
            .applyConditionalShadows(
                baseShadows: shadowColors,
                glowEnabled: settings.blueGlowEnabled,
                glowColour: settings.glowColour
            )
        }
        .frame(height: 140)
        .padding(.leading, 75)  // Increased to accommodate artwork extending left
    }

    var sideLayout: some View {
        HStack(spacing: 0) {
            // Album art on the left - 140px (square to match height)
            ZStack {
                Color.black.opacity(0.3)
                AlbumArtView(url: nowPlaying.albumArtUrl, image: $albumImage, plexAPI: plexAPI)
            }
            .frame(width: 140, height: 140)
            .clipShape(settings.albumArtShape == .circular ?
                AnyShape(UnevenRoundedRectangle(cornerRadii: .init(
                    topLeading: 28,
                    bottomLeading: 28,
                    bottomTrailing: 20,
                    topTrailing: 20
                ))) :
                AnyShape(UnevenRoundedRectangle(cornerRadii: .init(
                    topLeading: 28,
                    bottomLeading: 28,
                    bottomTrailing: 0,
                    topTrailing: 0
                ))))

            // Content area - 260px width, padding: 20px 16px 12px 16px
            VStack(alignment: .leading, spacing: 8) {
                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    // Scrolling title
                    GeometryReader { geo in
                        HStack(spacing: 30) {
                            if shouldScrollTitle {
                                Text(nowPlaying.title)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(titleColor)
                                    .fixedSize()
                                Text(nowPlaying.title)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(titleColor)
                                    .fixedSize()
                            } else {
                                Text(nowPlaying.title)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(titleColor)
                                    .lineLimit(1)
                            }
                        }
                        .offset(x: shouldScrollTitle ? titleOffset : 0)
                        .onAppear {
                            let textWidth = (nowPlaying.title as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 20, weight: .semibold)]).width
                            if textWidth > geo.size.width {
                                shouldScrollTitle = true
                                startScrolling(textWidth: textWidth, containerWidth: geo.size.width)
                            }
                        }
                    }
                    .frame(height: 24)
                    .clipped()

                    Text(nowPlaying.artist)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(subtitleColor)
                        .lineLimit(1)

                    Text(nowPlaying.album)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(subtitleColor)
                        .lineLimit(1)
                }

                Spacer()

                // Progress bar with time
                VStack(spacing: 2) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: "e5e5e5"))
                                .frame(height: 6)

                            // Fill with gradient
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "ffcb7d"),
                                            Color(hex: "ff920c")
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)

                    // Time codes
                    HStack {
                        Text(formatTime(displayTime))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(subtitleColor)

                        Spacer()

                        Text(formatTime(nowPlaying.duration))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(subtitleColor)
                    }
                    .padding(.horizontal, 2)
                }
            }
            .frame(width: 320)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
        }
        .frame(height: 140)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .overlay(backgroundColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .compositingGroup()
        .applyConditionalShadows(
            baseShadows: shadowColors,
            glowEnabled: settings.blueGlowEnabled,
            glowColour: settings.glowColour
        )
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if displayTime < nowPlaying.duration {
                displayTime += 1000
            }
        }
    }

    private func formatTime(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func startScrolling(textWidth: CGFloat, containerWidth: CGFloat) {
        // Gap of 30px is defined in HStack spacing
        let scrollDistance = textWidth + 30

        withAnimation(
            Animation.linear(duration: Double(scrollDistance) / 50.0)
                .repeatForever(autoreverses: false)
        ) {
            titleOffset = -scrollDistance
        }
    }
}

struct AlbumArtView: View {
    let url: String?
    @Binding var image: NSImage?
    @ObservedObject var plexAPI: PlexAPI

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Vinyl placeholder with gradient
                ZStack {
                    Color(hex: "2a2a2a")

                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "ffcb7d"),
                                    Color(hex: "ff920c")
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "444444"), lineWidth: 1)
                        )

                    // Vinyl grooves
                    ForEach([50, 38, 26], id: \.self) { radius in
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            .frame(width: CGFloat(radius * 2), height: CGFloat(radius * 2))
                    }

                    // Center label
                    Circle()
                        .fill(Color(hex: "444444"))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "555555"), lineWidth: 1)
                        )

                    // Center hole
                    Circle()
                        .fill(Color(hex: "2a2a2a"))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }

    private func loadImage() {
        guard let urlString = url else {
            image = nil
            return
        }

        // Use PlexAPI's secure method to fetch album art with token in header
        Task {
            if let data = await plexAPI.fetchAlbumArt(url: urlString),
               let nsImage = NSImage(data: data) {
                await MainActor.run {
                    self.image = nsImage
                }
            }
        }
    }
}

// Custom shape for circular album art in side layout
// Creates shape matching CSS: border-radius: 28px 50% 50% 28px
// Left side: 28px rounded corners, Right side: semicircular (50%)
struct CircularSideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 28

        // Start at top-left with corner radius
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))

        // Top edge to start of right semicircle
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Right side - semicircular (top-right to bottom-right)
        path.addArc(
            center: CGPoint(x: rect.maxX, y: rect.midY),
            radius: rect.height / 2,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))

        // Bottom-left corner - 28px radius
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))

        // Top-left corner - 28px radius
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()

        return path
    }
}

// Visual Effect Blur for backdrop-filter effect
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

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

// View extension for conditional shadows with coloured glow
extension View {
    func applyConditionalShadows(
        baseShadows: [(Color, CGFloat, CGFloat, CGFloat)],
        glowEnabled: Bool,
        glowColour: GlowColour
    ) -> some View {
        self.modifier(ConditionalShadowModifier(baseShadows: baseShadows, glowEnabled: glowEnabled, glowColour: glowColour))
    }
}

struct ConditionalShadowModifier: ViewModifier {
    let baseShadows: [(Color, CGFloat, CGFloat, CGFloat)]
    let glowEnabled: Bool
    let glowColour: GlowColour

    var glowColors: (Color, Color) {
        switch glowColour {
        case .blue:
            return (Color(red: 20/255, green: 120/255, blue: 255/255), Color(red: 40/255, green: 140/255, blue: 255/255))
        case .purple:
            return (Color(red: 160/255, green: 80/255, blue: 200/255), Color(red: 180/255, green: 100/255, blue: 220/255))
        case .pink:
            return (Color(red: 255/255, green: 80/255, blue: 150/255), Color(red: 255/255, green: 100/255, blue: 170/255))
        case .orange:
            return (Color(red: 255/255, green: 140/255, blue: 40/255), Color(red: 255/255, green: 160/255, blue: 60/255))
        case .green:
            return (Color(red: 40/255, green: 200/255, blue: 120/255), Color(red: 60/255, green: 220/255, blue: 140/255))
        case .cyan:
            return (Color(red: 40/255, green: 200/255, blue: 220/255), Color(red: 60/255, green: 220/255, blue: 240/255))
        }
    }

    func body(content: Content) -> some View {
        Group {
            if glowEnabled {
                let colors = glowColors
                content
                    .shadow(color: baseShadows[0].0, radius: baseShadows[0].1, x: baseShadows[0].2, y: baseShadows[0].3)
                    .shadow(color: baseShadows[1].0, radius: baseShadows[1].1, x: baseShadows[1].2, y: baseShadows[1].3)
                    .shadow(color: colors.0.opacity(0.5), radius: 7.5, x: 0, y: 0)
                    .shadow(color: colors.0.opacity(0.4), radius: 3.75, x: 0, y: 0)
                    .shadow(color: colors.1.opacity(0.6), radius: 2, x: 0, y: 0)
            } else {
                content
                    .shadow(color: baseShadows[0].0, radius: baseShadows[0].1, x: baseShadows[0].2, y: baseShadows[0].3)
                    .shadow(color: baseShadows[1].0, radius: baseShadows[1].1, x: baseShadows[1].2, y: baseShadows[1].3)
            }
        }
    }
}

// Type-erased shape helper
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// Hex color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
