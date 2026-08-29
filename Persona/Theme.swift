import SwiftUI
import UIKit

// Monochrome system. Black room, white ink, glass surfaces.
// One warm tone lives in the orb only. Color never decorates chrome.
// Black and white only. Exact values from duggai.com/mock-card.
enum Ink {
    static let bg        = Color(red: 0.031, green: 0.031, blue: 0.031) // #080808
    static let surface   = Color(red: 0.075, green: 0.075, blue: 0.075) // #131313
    static let sunken    = Color(red: 0.039, green: 0.039, blue: 0.039) // #0a0a0a
    static let primary   = Color.white
    static let secondary = Color.white.opacity(0.55)
    static let tertiary  = Color.white.opacity(0.34)
    static let hairline  = Color.white.opacity(0.10)
}

extension Font {
    static func title22() -> Font { .system(size: 21, weight: .semibold) }
    static func body15() -> Font { .system(size: 15, weight: .regular) }
    static func sub14() -> Font { .system(size: 14, weight: .regular) }
    static func micro() -> Font { .system(size: 10.5, weight: .medium, design: .monospaced) }
    static func clock() -> Font { .system(size: 13, weight: .medium, design: .monospaced) }
}

// mock-card .mc-fk: 11px uppercase, 0.04em tracking, dim.
struct MicroLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .regular))
            .kerning(0.44)
            .foregroundStyle(Ink.tertiary)
    }
}

// The one card surface. Flat panel, squared continuous corners, hairline edge.
// No glow, no blur mush. The duggai.com/mock-card language.
struct Panel: ViewModifier {
    var radius: CGFloat = 10
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Ink.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Ink.hairline, lineWidth: 1)
            }
            .overlay(alignment: .top) {
                // a faint top light, so the surface reads as glass, not a hole
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color.white.opacity(0.05), .clear],
                                       startPoint: .top, endPoint: .bottom))
                    .frame(height: 44)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension View {
    func glassCard(radius: CGFloat = 10) -> some View { modifier(Panel(radius: radius)) }
}

// Buttons. Three weights of intent, one shape language.
// Primary = the landing page CTA: white, black text, tight radius.
// Secondary = mock-card dark bordered.
struct FillButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 17)
            .frame(height: 38)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct QuietButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Ink.primary.opacity(0.85))
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct GhostButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Ink.secondary)
            .padding(.horizontal, 10)
            .frame(height: 42)
            .opacity(configuration.isPressed ? 0.5 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

enum Haptic {
    static func soft()  { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func rigid() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
