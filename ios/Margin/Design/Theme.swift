import SwiftUI

// MARK: - Colour helpers

extension Color {
    /// "2B7A6F" or "#2B7A6F"
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }

    /// Readable text colour for a background hex (same luminance rule as the web app).
    static func readable(on hex: String) -> Color {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF), g = Double((v >> 8) & 0xFF), b = Double(v & 0xFF)
        let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        return luminance > 0.62 ? Color(hex: "1D1916") : Color(hex: "FFF8EB")
    }
}

// MARK: - Design tokens (mirrors the web app: navy + pastel cards)

enum Theme {
    static let navy = Color(hex: "0F2236")
    static let navyDeep = Color(hex: "0B1A2B")
    static let panel = Color(hex: "060F19")      // dark shelf panel
    static let mint = Color(hex: "B9F1E0")
    static let lime = Color(hex: "C8F52F")
    static let pink = Color(hex: "F9D4EC")
    static let blue = Color(hex: "5DB4EE")
    static let cream = Color(hex: "EFE7D6")
    static let ink = Color(hex: "10243A")        // text on pastel cards
    static let text = Color(hex: "E8F2F0")       // text on navy
    static let title = Color(hex: "F1F7F5")      // page titles
    static let muted = Color(hex: "8EA6BB")
    static let line = Color(hex: "2C4258")

    /// Cover / spine colours handed out to new books in order.
    static let bookColors = ["E8531E", "F2C230", "1F3A6B", "2B7A6F", "D94B7B", "6B4EA0", "C0392B"]
}

/// One spacing system for every screen: 16 gutter, 10 between stacked cards, 22 between sections.
enum Space {
    static let gutter: CGFloat = 16
    static let card: CGFloat = 10
    static let section: CGFloat = 22
    static let cardRadius: CGFloat = 30
}

// MARK: - Card + buttons

struct CardStyle: ViewModifier {
    let fill: Color
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Theme.ink)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: Space.cardRadius, style: .continuous))
    }
}

extension View {
    /// Pastel card used on every screen.
    func card(_ fill: Color) -> some View { modifier(CardStyle(fill: fill)) }

    /// Page title style (heavy sans, same as the web app).
    func pageTitle() -> some View {
        font(.system(size: 30, weight: .heavy))
            .foregroundStyle(Theme.title)
            .padding(.horizontal, 4)
    }
}

/// Small outlined pill ("Recap", "Change", "+ Add event").
struct OutlinePill: ButtonStyle {
    var color: Color = Theme.ink
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(Capsule().stroke(color, lineWidth: 1.5))
            .foregroundStyle(color)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// Big navy pill with lime text ("Start reading").
struct SolidPill: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.ink, in: Capsule())
            .foregroundStyle(Theme.lime)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Thin capsule progress bar on a pastel card.
struct ProgressBar: View {
    let value: Double   // 0...1
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ink.opacity(0.18))
                Capsule().fill(Theme.ink).frame(width: geo.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: 10)
    }
}
