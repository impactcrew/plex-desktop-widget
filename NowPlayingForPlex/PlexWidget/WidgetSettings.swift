import Foundation
import SwiftUI

enum Theme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
}

enum LayoutStyle: String, CaseIterable {
    case side = "Side"
    case overlay = "Overlay"
}

enum AlbumArtShape: String, CaseIterable {
    case square = "Square"
    case circular = "Circular"
}

enum GlowColour: String, CaseIterable {
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case orange = "orange"
    case green = "green"
    case cyan = "cyan"

    var gradient: LinearGradient {
        switch self {
        case .blue:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 20/255, green: 120/255, blue: 255/255).opacity(0.8),
                    Color(red: 40/255, green: 140/255, blue: 255/255).opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .purple:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 160/255, green: 80/255, blue: 200/255).opacity(0.8),
                    Color(red: 180/255, green: 100/255, blue: 220/255).opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pink:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 80/255, blue: 150/255).opacity(0.8),
                    Color(red: 255/255, green: 100/255, blue: 170/255).opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 140/255, blue: 40/255).opacity(0.8),
                    Color(red: 255/255, green: 160/255, blue: 60/255).opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 40/255, green: 200/255, blue: 120/255).opacity(0.8),
                    Color(red: 60/255, green: 220/255, blue: 140/255).opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cyan:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 40/255, green: 200/255, blue: 220/255).opacity(0.8),
                    Color(red: 60/255, green: 220/255, blue: 240/255).opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

class WidgetSettings: ObservableObject {
    static let shared = WidgetSettings()

    @AppStorage("theme") var theme: Theme = .light
    @AppStorage("layoutStyle") var layoutStyle: LayoutStyle = .side
    @AppStorage("albumArtShape") var albumArtShape: AlbumArtShape = .square
    @AppStorage("blueGlowEnabled") var blueGlowEnabled: Bool = true
    @AppStorage("glowColour") var glowColour: GlowColour = .blue

    private init() {}
}

extension Theme: RawRepresentable {
    init?(rawValue: String) {
        switch rawValue {
        case "Light": self = .light
        case "Dark": self = .dark
        default: return nil
        }
    }
}

extension LayoutStyle: RawRepresentable {
    init?(rawValue: String) {
        switch rawValue {
        case "Side": self = .side
        case "Overlay": self = .overlay
        default: return nil
        }
    }
}

extension AlbumArtShape: RawRepresentable {
    init?(rawValue: String) {
        switch rawValue {
        case "Square": self = .square
        case "Circular": self = .circular
        default: return nil
        }
    }
}

extension GlowColour: RawRepresentable {
    init?(rawValue: String) {
        switch rawValue {
        case "blue": self = .blue
        case "purple": self = .purple
        case "pink": self = .pink
        case "orange": self = .orange
        case "green": self = .green
        case "cyan": self = .cyan
        default: return nil
        }
    }
}
