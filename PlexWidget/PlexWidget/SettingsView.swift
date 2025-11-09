import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: WidgetSettings
    @StateObject private var launchAtLogin = LaunchAtLoginManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                // Theme
                VStack(alignment: .leading, spacing: 10) {
                    Text("Theme")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))

                    SegmentedControl(
                        options: [Theme.light, Theme.dark],
                        selection: $settings.theme
                    )
                }

                // Layout Style
                VStack(alignment: .leading, spacing: 10) {
                    Text("Layout Style")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))

                    SegmentedControl(
                        options: [LayoutStyle.side, LayoutStyle.overlay],
                        selection: $settings.layoutStyle
                    )
                }

                // Album Art Shape
                VStack(alignment: .leading, spacing: 10) {
                    Text("Album Art Shape")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))

                    SegmentedControl(
                        options: [AlbumArtShape.square, AlbumArtShape.circular],
                        selection: $settings.albumArtShape
                    )
                }

                // Glow Effect
                VStack(alignment: .leading, spacing: 10) {
                    Text("Glow Effect")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))

                    SegmentedControlBool(
                        labels: ["On", "Off"],
                        selection: $settings.blueGlowEnabled
                    )
                }

                // Glow Colour (only visible when Glow Effect is On)
                if settings.blueGlowEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Glow Colour")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))

                        ColourPicker(selection: $settings.glowColour)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)

                // Launch at Login
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Text("Start widget when you log in")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    PlexToggle(isOn: $launchAtLogin.isEnabled)
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(24)
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    Color(red: 13/255, green: 13/255, blue: 13/255).opacity(0.85)
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 20,
                        topTrailingRadius: 0
                    )
                )
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 20,
                    bottomTrailingRadius: 20,
                    topTrailingRadius: 0
                )
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 40, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.4), radius: 60, x: 0, y: 20)
        }
        .frame(width: 280)
        .onAppear {
            launchAtLogin.checkStatus()
        }
    }
}

// MARK: - Segmented Control
struct SegmentedControl<T: RawRepresentable & Equatable>: View where T.RawValue == String {
    let options: [T]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                }) {
                    Text(option.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selection == option ? .black : .white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Group {
                                if selection == option {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 229/255, green: 160/255, blue: 13/255),
                                            Color(red: 204/255, green: 123/255, blue: 2/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    Color.clear
                                }
                            }
                        )
                        .cornerRadius(8)
                        .shadow(color: selection == option ? Color.black.opacity(0.15) : .clear, radius: 4, x: 0, y: 2)
                        .contentShape(Rectangle())
                        .zIndex(selection == option ? 2 : 1)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
    }
}

// MARK: - Boolean Segmented Control (for On/Off)
struct SegmentedControlBool: View {
    let labels: [String]
    @Binding var selection: Bool

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<labels.count, id: \.self) { index in
                let isOn = index == 0
                let isSelected = (isOn && selection) || (!isOn && !selection)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = isOn
                    }
                }) {
                    Text(labels[index])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Group {
                                if isSelected {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 229/255, green: 160/255, blue: 13/255),
                                            Color(red: 204/255, green: 123/255, blue: 2/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    Color.clear
                                }
                            }
                        )
                        .cornerRadius(8)
                        .shadow(color: isSelected ? Color.black.opacity(0.15) : .clear, radius: 4, x: 0, y: 2)
                        .contentShape(Rectangle())
                        .zIndex(isSelected ? 2 : 1)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
    }
}

// MARK: - Colour Picker
struct ColourPicker: View {
    @Binding var selection: GlowColour

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(GlowColour.allCases, id: \.self) { colour in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = colour
                    }
                }) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colour.gradient)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selection == colour ? Color.white.opacity(0.9) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
                        .shadow(
                            color: selection == colour ? Color.black.opacity(0.3) : Color.clear,
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                        .scaleEffect(selection == colour ? 1.0 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Plex Toggle Switch
struct PlexToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isOn ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 229/255, green: 160/255, blue: 13/255),
                                Color(red: 204/255, green: 123/255, blue: 2/255)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 24)

                // Knob
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 40, height: 24)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            SettingsView(settings: WidgetSettings.shared)
        }
        .frame(width: 500, height: 700)
    }
}
