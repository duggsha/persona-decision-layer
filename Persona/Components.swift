import SwiftUI

// Mock-card ledger: mono label, plain value, optional trailing.
struct LedgerRow<Trailing: View>: View {
    let label: String
    let value: String
    @ViewBuilder var trailing: Trailing

    init(_ label: String, _ value: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.label = label
        self.value = value
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .regular))
                .kerning(0.44)
                .foregroundStyle(Ink.tertiary)
                .frame(width: 56, alignment: .leading)
            Text(value)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(Ink.primary.opacity(0.92))
            Spacer(minLength: 0)
            trailing
        }
        .frame(minHeight: 26)
    }
}

// A real contact photo from the app bundle, circled.
struct PhotoAvatar: View {
    let name: String
    var size: CGFloat = 44
    var body: some View {
        Group {
            if let ui = UIImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Avatar(initial: String(name.prefix(1)).uppercased(), size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(Ink.hairline, lineWidth: 1) }
    }
}

// iMessage-style default contact avatar: grey gradient, white initial.
struct Avatar: View {
    let initial: String
    var size: CGFloat = 34
    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.95))
            .frame(width: size, height: size)
            .background {
                Circle().fill(
                    LinearGradient(
                        colors: [Color(white: 0.42), Color(white: 0.26)],
                        startPoint: .top, endPoint: .bottom))
            }
            .overlay { Circle().strokeBorder(Ink.hairline, lineWidth: 1) }
    }
}

struct LedgerDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.055))
            .frame(height: 1)
    }
}

// Small warm dot that stands in for the presence on cards.
struct PresenceDot: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)
                .opacity(0.35 + 0.4 * (0.5 + 0.5 * sin(t * 1.1)))
        }
        .frame(width: 6, height: 6)
    }
}

// The quiet countdown. A clock time, not a timer bar.
struct AutoArc: View {
    var progress: Double
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 2)
            Circle()
                .trim(from: 0, to: max(0.001, 1 - progress))
                .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 15, height: 15)
    }
}

// Irreversible needs its own motor action. Press and hold, ring fills,
// let go early and it springs back. Never the same gesture as dismiss.
struct HoldToSend: View {
    var label: String = "Send"
    var onComplete: () -> Void
    @State private var pressing = false
    @State private var progress: CGFloat = 0
    @State private var hinting = false
    private let holdTime: Double = 0.8

    var body: some View {
        Text(hinting ? "Hold to send" : label)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Ink.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .trim(from: 0, to: progress)
                    .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .padding(-4)
                    .opacity(progress > 0.001 ? 1 : 0)
            }
            .scaleEffect(pressing ? 0.955 : 1)
            .animation(.snappy(duration: 0.2), value: pressing)
            .onLongPressGesture(minimumDuration: holdTime, maximumDistance: 60) {
                onComplete()
            } onPressingChanged: { p in
                pressing = p
                if p {
                    Haptic.soft()
                    withAnimation(.linear(duration: holdTime)) { progress = 1 }
                } else if progress < 1 {
                    Haptic.light()
                    let wasQuickTap = progress < 0.35
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { progress = 0 }
                    if wasQuickTap {
                        withAnimation(.snappy(duration: 0.2)) { hinting = true }
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            withAnimation(.snappy(duration: 0.25)) { hinting = false }
                        }
                    }
                }
            }
    }
}

// Decline is an answer, not a dead end. One optional tap of why,
// and the reason rides the next run.
struct ReasonChips: View {
    let reasons: [String]
    let picked: String?
    let ack: String
    let onPick: (String) -> Void

    var body: some View {
        Group {
            if let _ = picked {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Ink.secondary)
                    Text(ack)
                        .font(.sub14())
                        .foregroundStyle(Ink.secondary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                HStack(spacing: 8) {
                    ForEach(reasons, id: \.self) { r in
                        Button(r) { onPick(r) }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Ink.primary.opacity(0.85))
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(Color.white.opacity(0.07),
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

struct ReceiptRow: View {
    let receipt: Receipt
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: receipt.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Ink.tertiary)
                .frame(width: 16)
            Text(receipt.text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Ink.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
        .background(Color.white.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .transition(.asymmetric(
            insertion: .offset(y: 12).combined(with: .opacity),
            removal: .opacity))
    }
}

// Working state pulse.
struct WorkingDot: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .opacity(0.35 + 0.55 * (0.5 + 0.5 * sin(t * 4.2)))
        }
        .frame(width: 8, height: 8)
    }
}
