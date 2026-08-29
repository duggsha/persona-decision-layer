import SwiftUI

// Persona runs your life. This app is only the decision layer.
// One ask per screen, TikTok-paged. Acting turns the card into a live
// agent run; the run and the reasoning both speak in real apps.

struct HomeView: View {
    @EnvironmentObject var day: DayEngine

    var body: some View {
        ZStack {
            Ink.bg.ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(count: 3) {
                    withAnimation(.snappy(duration: 0.25)) { day.hudVisible.toggle() }
                }

            QueueView()

            if day.payConfirming {
                SideButtonConfirm()
                    .transition(.opacity)
            }

            if day.voiceActive {
                VoiceOverlay()
                    .transition(.opacity)
            }

            if day.bandVisible {
                BandOverlay()
                    .transition(.opacity)
            }

            if day.historyVisible {
                HistoryOverlay()
                    .transition(.opacity)
            }

            if day.hudVisible {
                DemoHUD()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: day.hudVisible)
    }
}

// The tick draws, then the proof: the thread itself.
struct SentSeal<Thread: View>: View {
    @ViewBuilder var thread: Thread
    @State private var drawn = false
    @State private var showThread = false

    var body: some View {
        VStack(spacing: 12) {
            if !showThread {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 3)
                        .frame(width: 46, height: 46)
                    Circle()
                        .trim(from: 0, to: drawn ? 1 : 0)
                        .stroke(Color(red: 0.19, green: 0.82, blue: 0.35),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 46, height: 46)
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(red: 0.19, green: 0.82, blue: 0.35))
                        .scaleEffect(drawn ? 1 : 0.4)
                        .opacity(drawn ? 1 : 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .transition(.opacity)
            } else {
                thread
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { drawn = true }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 850_000_000)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { showThread = true }
            }
        }
    }
}

// Tonight's paper trail: every action, one place.
struct HistoryOverlay: View {
    @EnvironmentObject var day: DayEngine

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.25)) { day.historyVisible = false }
                }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Tonight")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Ink.primary)
                    Spacer()
                    Text("7:42 PM")
                        .font(.clock())
                        .foregroundStyle(Ink.tertiary)
                }
                .padding(.horizontal, 18)
                .frame(height: 48)

                LedgerDivider()

                ForEach(Array(day.history.enumerated()), id: \.offset) { i, item in
                    HStack(spacing: 12) {
                        Image(systemName: item.0)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Ink.secondary)
                            .frame(width: 22)
                        Text(item.1)
                            .font(.system(size: 14.5))
                            .foregroundStyle(Ink.primary.opacity(0.92))
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Ink.tertiary)
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 46)
                    if i < day.history.count - 1 {
                        LedgerDivider().padding(.leading, 52)
                    }
                }
            }
            .background(Ink.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Ink.hairline, lineWidth: 1)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 54)
        }
    }
}

// MARK: - The same moment, on the band. Their hardware future, previewed.

struct BandOverlay: View {
    @EnvironmentObject var day: DayEngine
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.25)) { day.bandVisible = false }
                }

            VStack(spacing: 26) {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(white: 0.10))
                        .frame(width: 92, height: 34)
                    ZStack {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(
                                LinearGradient(colors: [Color(white: 0.16), Color(white: 0.06)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 224, height: 92)
                            .overlay {
                                RoundedRectangle(cornerRadius: 34, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                            }
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Dinner \u{2192} 8:00")
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Ink.primary)
                                HStack(spacing: 5) {
                                    AutoArc(progress: 0.35)
                                    Text("7:52")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Ink.tertiary)
                                }
                            }
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.black)
                                    .frame(width: 24, height: 24)
                                    .background(Color.white, in: Circle())
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Ink.secondary)
                                    .frame(width: 24, height: 24)
                                    .overlay { Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 1) }
                            }
                        }
                    }
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(white: 0.10))
                        .frame(width: 92, height: 34)
                }

                Text("The same moment, on the band.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Ink.secondary)
            }
            .scaleEffect(appeared ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { appeared = true }
            }
        }
    }
}

// MARK: - The pager. Rotated TabView: strict one-card paging that still
// turns on a lazy drag.

struct QueueView: View {
    @EnvironmentObject var day: DayEngine

    private var pageIndex: Int {
        guard let p = day.feedPage, let i = day.queue.firstIndex(of: p) else { return 0 }
        return i
    }
    private var atEnd: Bool { day.queue.isEmpty || pageIndex == day.queue.count - 1 }

    @ViewBuilder
    private func cardView(_ s: Scenario) -> some View {
        switch s {
        case .dinner: DinnerCard()
        case .message: MessageCard()
        case .deposit: PayCard()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                BrandOrb(size: 17)
                Text("PERSONA")
                    .font(.system(size: 14, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(Ink.primary)
                Spacer()
                HStack(spacing: 6) {
                    Text(day.queue.isEmpty ? "done" : "\(pageIndex + 1) of \(day.queue.count)")
                        .foregroundStyle(Ink.secondary)
                        .contentTransition(.numericText())
                    Text(day.queue.isEmpty ? "" : (atEnd ? "end of queue" : "scroll"))
                        .foregroundStyle(Ink.tertiary)
                    if !atEnd {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Ink.tertiary)
                    }
                }
                .font(.system(size: 12))
                .animation(.snappy(duration: 0.25), value: pageIndex)
            }
            .padding(.horizontal, 12)
            .frame(height: 24)

            GeometryReader { geo in
                let slot = geo.size.height * 0.78
                let topGap: CGFloat = 16
                ScrollView(.vertical) {
                    LazyVStack(spacing: 22) {
                        if day.queue.isEmpty {
                            AllDonePage()
                                .frame(height: slot)
                                .padding(.horizontal, 12)
                        }
                        ForEach(day.queue) { s in
                            Group {
                                if s == day.queue.first {
                                    VStack(alignment: .leading, spacing: 16) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            if s == .dinner {
                                                Text("Welcome back, Shaurya")
                                                    .font(.system(size: 22, weight: .light))
                                                    .foregroundStyle(Ink.primary)
                                            }
                                            Text(day.pending.isEmpty
                                                 ? "Nothing needs you tonight."
                                                 : "\(day.pending.count) thing\(day.pending.count == 1 ? " needs" : "s need") your okay tonight.")
                                                .font(.system(size: 22, weight: .light))
                                                .foregroundStyle(Ink.primary)
                                                .contentTransition(.numericText())
                                                .animation(.snappy(duration: 0.3), value: day.pending.count)
                                        }
                                        .padding(.horizontal, 2)
                                        cardView(s)
                                            .frame(maxHeight: .infinity)
                                    }
                                } else {
                                    cardView(s)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(height: slot)
                            .id(s)
                            .padding(.horizontal, 12)
                            .opacity((day.feedPage ?? day.queue.first ?? .dinner) == s ? 1 : 0.75)
                            .animation(.snappy(duration: 0.3), value: day.feedPage)
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .move(edge: .trailing).combined(with: .opacity)))
                        }
                    }
                    .scrollTargetLayout()
                    .animation(.spring(response: 0.5, dampingFraction: 0.86), value: day.queue)
                }
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .scrollPosition(id: $day.feedPage)
                .scrollIndicators(.hidden)
                .contentMargins(.top, topGap, for: .scrollContent)
                .contentMargins(.bottom, max(12, geo.size.height - slot - topGap), for: .scrollContent)
                .overlay(alignment: .bottom) {
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(red: 0.19, green: 0.82, blue: 0.35))
                            Text(day.pending.isEmpty ? "All handled tonight." : "Last one tonight.")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundStyle(Ink.secondary)
                        }
                        .padding(.horizontal, 15)
                        .frame(height: 36)
                        .background(Ink.surface, in: Capsule())
                        .overlay { Capsule().strokeBorder(Ink.hairline, lineWidth: 1) }

                        if !day.history.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    day.historyVisible.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Past actions")
                                        .font(.system(size: 13.5, weight: .medium))
                                }
                                .foregroundStyle(Ink.secondary)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .background(Ink.surface, in: Capsule())
                                .overlay { Capsule().strokeBorder(Ink.hairline, lineWidth: 1) }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 2)
                    .opacity(atEnd ? 1 : 0)
                    .offset(y: atEnd ? 0 : 10)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: atEnd)
                }
            }
        }
    }
}

struct AllDonePage: View {
    @EnvironmentObject var day: DayEngine
    @State private var drawn = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 3)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: drawn ? 1 : 0)
                    .stroke(Color(red: 0.19, green: 0.82, blue: 0.35),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color(red: 0.19, green: 0.82, blue: 0.35))
                    .scaleEffect(drawn ? 1 : 0.4)
                    .opacity(drawn ? 1 : 0)
            }
            Text("All handled tonight.")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Ink.primary)
            Text("Go enjoy dinner.")
                .font(.system(size: 14))
                .foregroundStyle(Ink.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard(radius: 14)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { drawn = true }
        }
    }
}

// The Persona mark: one small iridescent sphere in a monochrome app.
struct BrandOrb: View {
    var size: CGFloat = 26
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.73, blue: 0.55),
                        Color(red: 0.72, green: 0.62, blue: 0.90),
                        Color(red: 0.45, green: 0.55, blue: 0.92),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Circle()
                    .fill(
                        RadialGradient(colors: [Color.white.opacity(0.5), .clear],
                                       center: UnitPoint(x: 0.32, y: 0.25),
                                       startRadius: 0, endRadius: size * 0.6))
            }
            .frame(width: size, height: size)
    }
}

// MARK: - App logos, drawn. Third-party things keep their own colors.

struct AppLogoView: View {
    let logo: AppLogo
    var size: CGFloat = 22

    var body: some View {
        Group {
            switch logo {
            case .persona:
                BrandOrb(size: size)
            case .calendar:
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(Color.white)
                    Text("FRI")
                        .font(.system(size: size * 0.24, weight: .semibold))
                        .foregroundStyle(Color(red: 0.95, green: 0.26, blue: 0.21))
                        .padding(.top, size * 0.09)
                    Text("29")
                        .font(.system(size: size * 0.44, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(.top, size * 0.34)
                }
                .frame(width: size, height: size)
            case .messages:
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(
                            LinearGradient(colors: [Color(red: 0.36, green: 0.9, blue: 0.44),
                                                    Color(red: 0.13, green: 0.77, blue: 0.35)],
                                           startPoint: .top, endPoint: .bottom))
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(.white)
                        .offset(y: -size * 0.02)
                }
                .frame(width: size, height: size)
            case .phone:
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(
                            LinearGradient(colors: [Color(red: 0.36, green: 0.9, blue: 0.44),
                                                    Color(red: 0.13, green: 0.77, blue: 0.35)],
                                           startPoint: .top, endPoint: .bottom))
                    Image(systemName: "phone.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(.white)
                }
                .frame(width: size, height: size)
            case .wallet:
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(Color(white: 0.13))
                    VStack(spacing: size * 0.055) {
                        Capsule().fill(Color(red: 0.28, green: 0.62, blue: 0.99)).frame(height: size * 0.14)
                        Capsule().fill(Color(red: 1.0, green: 0.8, blue: 0.25)).frame(height: size * 0.14)
                        Capsule().fill(Color(red: 0.3, green: 0.82, blue: 0.45)).frame(height: size * 0.14)
                        RoundedRectangle(cornerRadius: size * 0.07)
                            .fill(Color(white: 0.85))
                            .frame(height: size * 0.26)
                    }
                    .padding(size * 0.16)
                }
                .frame(width: size, height: size)
            case .opentable:
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(Color(red: 0.855, green: 0.22, blue: 0.263))
                    Circle()
                        .strokeBorder(Color.white, lineWidth: size * 0.09)
                        .frame(width: size * 0.52, height: size * 0.52)
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.16, height: size * 0.16)
                }
                .frame(width: size, height: size)
            }
        }
    }
}

// MARK: - Card scaffold

struct QueueCard<Hero: View, Content: View>: View {
    let kind: String
    @ViewBuilder var hero: Hero
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(kind)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Ink.secondary)
                Spacer()
                Text("just now")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Ink.tertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 42)

            LedgerDivider()

            hero
                .frame(maxWidth: .infinity)

            LedgerDivider()

            content
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard(radius: 14)
    }
}

// The live run: the card gone flat, streaming what the agent is doing.
struct RunSurface<Terminal: View>: View {
    let kind: String
    let steps: [RunStep]
    let running: Bool
    @ViewBuilder var terminal: Terminal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    BrandOrb(size: 15)
                    Text("Persona")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Ink.primary.opacity(0.9))
                }
                Spacer()
                if running {
                    WorkingDot()
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 52)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(steps) { s in
                    HStack(spacing: 12) {
                        AppLogoView(logo: s.logo, size: 24)
                        Text(s.verb)
                            .font(.system(size: 15.5, weight: .semibold))
                            .foregroundStyle(Ink.primary)
                        Text(s.object)
                            .font(.system(size: 15.5))
                            .foregroundStyle(Ink.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .frame(height: 44)
                    .transition(.asymmetric(
                        insertion: .offset(y: 10).combined(with: .opacity),
                        removal: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 6)

            terminal
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 14)
    }
}

// "How it got here" — the reasoning, in the apps it came from.
struct HowItGotHere: View {
    let rows: [(AppLogo, String)]
    var initiallyOpen = false
    @State private var open = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.3)) { open.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 13))
                    Text("How it got here")
                        .font(.system(size: 14.5, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .rotationEffect(.degrees(open ? 180 : 0))
                }
                .foregroundStyle(Ink.tertiary)
                .frame(height: 40)
            }
            .buttonStyle(.plain)
            .onAppear { if initiallyOpen { open = true } }

            if open {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 11) {
                            AppLogoView(logo: row.0, size: 21)
                            Text(row.1)
                                .font(.system(size: 14))
                                .foregroundStyle(Ink.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
    }
}

// Dark bordered buttons, the DUGGOS pair. Primary is the lighter one.
struct DarkButton: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Ink.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Color.white.opacity(prominent ? 0.13 : 0.045),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.white.opacity(prominent ? 0.24 : 0.11), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Card 1: dinner

struct DinnerCard: View {
    @EnvironmentObject var day: DayEngine
    private let times = ["7:45", "8:00", "8:15", "8:30"]

    private var inRun: Bool {
        switch day.stage {
        case .lowWorking, .lowDone, .lowUndoing: return true
        default: return false
        }
    }

    var body: some View {
        Group {
            if inRun {
                RunSurface(kind: "Reservation", steps: day.runSteps, running: day.stage != .lowDone) {
                    runTerminal
                }
                .transition(.asymmetric(
                    insertion: .offset(y: 18).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)))
            } else {
                askCard
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .trailing).combined(with: .opacity)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: inRun)
    }

    private var askCard: some View {
        QueueCard(kind: "Reservation") {
            VStack(spacing: 14) {
                Button {
                    guard day.stage == .lowAsk else { return }
                    if day.editingLow { day.pick(time: day.dinnerTime) } else { day.beginEditLow() }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text("7:30")
                            .font(.system(size: 30, weight: .medium, design: .monospaced))
                            .foregroundStyle(Ink.tertiary)
                            .strikethrough(day.dinnerResolved != "kept", color: Ink.tertiary.opacity(0.7))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Ink.secondary)
                        Text(day.dinnerTime)
                            .font(.system(size: 54, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Ink.primary)
                            .contentTransition(.numericText())
                            .overlay(alignment: .bottom) {
                                if day.stage == .lowAsk && day.dinnerResolved == nil {
                                    Rectangle()
                                        .fill(Ink.tertiary.opacity(day.editingLow ? 0.9 : 0.5))
                                        .frame(height: 2)
                                        .offset(y: 6)
                                }
                            }
                    }
                }
                .buttonStyle(.plain)
                if day.stage == .lowAsk && day.autoArmed && !day.editingLow {
                    HStack(spacing: 8) {
                        AutoArc(progress: day.autoProgress)
                        Text("moves itself at 7:52 unless you stop it")
                            .font(.system(size: 13.5))
                            .foregroundStyle(Ink.tertiary)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.vertical, 24)
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your 6:30 with Sana is running 25 over. You won't make 7:30.")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Ink.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                HowItGotHere(rows: [
                    (.calendar, "The 6:30 review started late and is still going."),
                    (.opentable, "Carbone shows an open two-top at 8:00."),
                    (.persona, "Reversible, so it proceeds unless stopped."),
                ], initiallyOpen: true)

                Spacer(minLength: 6)

                substate
            }
            .animation(.snappy(duration: 0.3), value: day.stage)
        }
    }

    @ViewBuilder
    private var runTerminal: some View {
        switch day.stage {
        case .lowDone:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Ink.primary)
                Text("Dinner's at \(day.dinnerTime)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Ink.primary)
                Spacer()
                Button("Undo until 7:45") { day.undo() }
                    .buttonStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Ink.secondary)
                    .opacity(day.undoOpen ? 1 : 0)
                    .allowsHitTesting(day.undoOpen)
            }
            .frame(height: 50)
            .transition(.opacity)

            graduationRow
                .padding(.bottom, 4)
        default:
            HStack { Spacer() }.frame(height: 6)
        }
    }

    @ViewBuilder
    private var graduationRow: some View {
        if day.graduated {
            HStack(spacing: 7) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Ink.secondary)
                Text("Won't ask for reservation moves again.")
                    .font(.system(size: 13))
                    .foregroundStyle(Ink.secondary)
            }
            .frame(height: 34)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        } else {
            Button {
                day.graduate()
            } label: {
                Text("Always allow reservation moves")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Ink.secondary)
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(Color.white.opacity(0.05), in: Capsule())
                    .overlay { Capsule().strokeBorder(Ink.hairline, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var substate: some View {
        switch day.stage {
        case .lowFailed:
            VStack(alignment: .leading, spacing: 12) {
                Text("Carbone can't do 8:00. They have 8:30.")
                    .font(.system(size: 15.5))
                    .foregroundStyle(Ink.primary)
                HStack(spacing: 10) {
                    Button("Keep 7:30") { day.resolveFail(take830: false) }
                        .buttonStyle(DarkButton())
                    Button("Take 8:30") { day.resolveFail(take830: true) }
                        .buttonStyle(DarkButton(prominent: true))
                }
            }
        case .lowDeclined:
            VStack(alignment: .leading, spacing: 12) {
                Text("Keeping 7:30.")
                    .font(.system(size: 15.5))
                    .foregroundStyle(Ink.primary)
                ReasonChips(
                    reasons: ["Wrong call", "Ask first", "Just tonight"],
                    picked: day.lowReasonPicked,
                    ack: day.lowReasonPicked == "Ask first" ? "Will do." : "Got it.",
                    onPick: { day.pickLowReason($0) })
            }
        default:
            if day.dinnerResolved != nil {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Ink.primary)
                    Text(day.dinnerResolved == "moved" ? "Moved. Table's yours at \(day.dinnerTime)." : "Kept at 7:30.")
                        .font(.system(size: 15.5, weight: .medium))
                        .foregroundStyle(Ink.primary)
                    Spacer()
                }
                .frame(height: 48)
            } else if day.editingLow {
                HStack(spacing: 8) {
                    ForEach(times, id: \.self) { t in
                        Button {
                            day.pick(time: t)
                        } label: {
                            Text(t)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundStyle(t == day.dinnerTime ? .black : Ink.primary.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    t == day.dinnerTime ? Color.white : Color.white.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .strokeBorder(Color.white.opacity(t == day.dinnerTime ? 0 : 0.10), lineWidth: 1)
                                }
                        }
                    }
                }
                .transition(.opacity.combined(with: .offset(y: 5)))
            } else {
                HStack(spacing: 10) {
                    Button("Keep 7:30") { day.declineLow() }
                        .buttonStyle(DarkButton())
                    Button("Move it") { day.approveLow() }
                        .buttonStyle(DarkButton(prominent: true))
                }
            }
        }
    }
}

// MARK: - Card 2: the message

struct MessageCard: View {
    @EnvironmentObject var day: DayEngine
    @State private var editText = ""
    @FocusState private var editing: Bool

    private var inRun: Bool { day.stage == .msgSent }

    var body: some View {
        Group {
            if inRun {
                RunSurface(kind: "Message", steps: day.runSteps, running: day.runSteps.count < 3) {
                    if day.runSteps.count >= 3 {
                        SentSeal {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                PhotoAvatar(name: "maya", size: 24)
                                Text("Maya")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Ink.secondary)
                                Spacer()
                            }
                            HStack {
                                Spacer(minLength: 40)
                                Text(day.draft)
                                    .font(.system(size: 15.5))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color(red: 0.04, green: 0.52, blue: 1.0),
                                                in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                            }
                            HStack {
                                Spacer()
                                Text("Delivered")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(Ink.tertiary)
                            }
                        }
                        }
                        .padding(.bottom, 6)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                    } else {
                        HStack { Spacer() }.frame(height: 6)
                    }
                }
                .transition(.asymmetric(
                    insertion: .offset(y: 18).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)))
            } else {
                askCard
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .trailing).combined(with: .opacity)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: inRun)
    }

    private var askCard: some View {
        QueueCard(kind: "Message") {
            VStack(alignment: .leading, spacing: 13) {
                Text("Tell Maya dinner moved to 8:00?")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Ink.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 11) {
                    PhotoAvatar(name: "maya", size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Maya")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Ink.primary)
                        HStack(spacing: 5) {
                            AppLogoView(logo: .messages, size: 13)
                            Text("iMessage")
                                .font(.system(size: 12))
                                .foregroundStyle(Ink.tertiary)
                        }
                    }
                    Spacer()
                }

                if day.editingHigh {
                    VStack(alignment: .trailing, spacing: 8) {
                        TextEditor(text: $editText)
                            .font(.system(size: 16.5))
                            .foregroundStyle(Ink.primary)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .frame(minHeight: 78, maxHeight: 124)
                            .background(Color.white.opacity(0.07),
                                        in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                            }
                            .focused($editing)
                        Button("Done") { day.endEditHigh(editText) }
                            .buttonStyle(DarkButton(prominent: true))
                            .frame(width: 96)
                    }
                    .onAppear { if editText.isEmpty { editText = day.draft } }
                    .transition(.opacity)
                } else {
                    Button {
                        editText = day.draft
                        day.beginEditHigh()
                        editing = true
                    } label: {
                        Text(day.draft)
                            .font(.system(size: 16.5))
                            .foregroundStyle(Ink.primary.opacity(0.95))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(3)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.07),
                                        in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                            .contentTransition(.opacity)
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(width: 22, height: 22)
                                    .background(Color.white, in: Circle())
                                    .offset(x: 6, y: 6)
                            }
                    }
                    .buttonStyle(.plain)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .offset(y: -180).combined(with: .opacity).combined(with: .scale(scale: 0.94))))

                    HStack(spacing: 8) {
                        Text(day.voiceEdited ? "revised by voice" : "tap the bubble to edit, or say it")
                            .font(.system(size: 12))
                            .foregroundStyle(Ink.tertiary)
                            .padding(.leading, 4)
                        Spacer()
                        Button {
                            day.voiceStart()
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Ink.primary.opacity(0.85))
                                .frame(width: 34, height: 34)
                                .background(Color.white.opacity(0.07), in: Circle())
                                .overlay { Circle().strokeBorder(Ink.hairline, lineWidth: 1) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                HowItGotHere(rows: [
                    (.persona, "Dinner moved to \(day.dinnerTime) just now."),
                    (.calendar, "She usually heads out around 7:15."),
                    (.messages, "A text can't be unsent, so it waits for you."),
                ], initiallyOpen: true)

                Spacer(minLength: 6)

                substate
            }
            .animation(.snappy(duration: 0.3), value: day.stage)
        }
    }

    @ViewBuilder
    private var substate: some View {
        switch day.stage {
        case .msgDeclined:
            VStack(alignment: .leading, spacing: 12) {
                Text("Not sending.")
                    .font(.system(size: 15.5))
                    .foregroundStyle(Ink.primary)
                ReasonChips(
                    reasons: ["Wrong words", "I'll text her", "Never"],
                    picked: day.highReasonPicked,
                    ack: "Texting stays yours.",
                    onPick: { day.pickHighReason($0) })
            }
        default:
            if let note = day.mayaNote {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Ink.primary)
                    Text(note == "texted 7:41" ? "She knows. Sent 7:41." : "Left to you.")
                        .font(.system(size: 15.5, weight: .medium))
                        .foregroundStyle(Ink.primary)
                    Spacer()
                }
                .frame(height: 48)
            } else if !day.editingHigh {
                HStack(spacing: 10) {
                    Button("Don't send") { day.declineHigh() }
                        .buttonStyle(DarkButton())
                    HoldToSend(label: "Hold to Send") { day.sendHigh() }
                }
            }
        }
    }
}

// MARK: - Card 3: money

struct PayCard: View {
    @EnvironmentObject var day: DayEngine

    private var inRun: Bool { day.stage == .payDone }

    var body: some View {
        Group {
            if inRun {
                RunSurface(kind: "Payment", steps: day.runSteps, running: day.runSteps.count < 3) {
                    if day.runSteps.count >= 3 {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Ink.primary)
                            Text("Paid. Table's held.")
                                .font(.system(size: 16.5, weight: .semibold))
                                .foregroundStyle(Ink.primary)
                            Spacer()
                            Text("7:42")
                                .font(.clock())
                                .foregroundStyle(Ink.tertiary)
                        }
                        .frame(height: 46)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    } else {
                        HStack { Spacer() }.frame(height: 6)
                    }
                }
                .transition(.asymmetric(
                    insertion: .offset(y: 18).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)))
            } else {
                askCard
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .trailing).combined(with: .opacity)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: inRun)
    }

    private var askCard: some View {
        QueueCard(kind: "Payment") {
            VStack(spacing: 18) {
                CardGraphic()
                Text("$25.00")
                    .font(.system(size: 50, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Ink.primary)
            }
            .padding(.top, 36)
            .padding(.bottom, 30)
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                Text("Carbone holds the 8:00 table with a deposit. Cover it?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Ink.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                HowItGotHere(rows: [
                    (.opentable, "Carbone holds moved tables with a deposit."),
                    (.wallet, "Goes on the Amex ending 4."),
                    (.persona, "Money is irreversible, so it uses the system confirm."),
                ], initiallyOpen: true)

                Spacer(minLength: 6)

                substate
            }
            .animation(.snappy(duration: 0.3), value: day.stage)
        }
    }

    @ViewBuilder
    private var substate: some View {
        switch day.stage {
        case .payDeclined:
            VStack(alignment: .leading, spacing: 12) {
                Text("Not paying.")
                    .font(.system(size: 15.5))
                    .foregroundStyle(Ink.primary)
                ReasonChips(
                    reasons: ["Pay there", "Wrong card", "Never auto-pay"],
                    picked: day.payReasonPicked,
                    ack: "Payments stay yours.",
                    onPick: { day.pickPayReason($0) })
            }
        default:
            if let note = day.depositNote {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Ink.primary)
                    Text(note == "held" ? "Paid. Table's held." : "Skipped. Pay at the door.")
                        .font(.system(size: 15.5, weight: .medium))
                        .foregroundStyle(Ink.primary)
                    Spacer()
                }
                .frame(height: 48)
            } else {
                HStack(spacing: 10) {
                    Button("Not now") { day.declinePay() }
                        .buttonStyle(DarkButton())
                    Button("Pay $25") { day.payTapped() }
                        .buttonStyle(DarkButton(prominent: true))
                }
            }
        }
    }
}

// A drawn card. Monochrome, chip and all.
struct CardGraphic: View {
    var scale: CGFloat = 1.0
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(white: 0.34), Color(white: 0.22)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 33 * scale, height: 24 * scale)
                .overlay {
                    RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
                }
                .padding(.top, 16 * scale)
                .padding(.leading, 16 * scale)

            Spacer()

            HStack {
                Text("AMEX")
                    .font(.system(size: 11 * scale, weight: .semibold, design: .monospaced))
                    .kerning(1.2 * scale)
                    .foregroundStyle(Ink.secondary)
                Spacer()
                Text("···· 4")
                    .font(.system(size: 13 * scale, weight: .medium, design: .monospaced))
                    .foregroundStyle(Ink.secondary)
            }
            .padding(.horizontal, 16 * scale)
            .padding(.bottom, 13 * scale)
        }
        .frame(width: 176 * scale, height: 110 * scale)
        .background(
            LinearGradient(colors: [Color(white: 0.13), Color(white: 0.075)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 11 * scale, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11 * scale, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        }
    }
}

// MARK: - Voice edit. Tell it what to change; the draft revises itself.

struct VoiceOverlay: View {
    @EnvironmentObject var day: DayEngine
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { day.voiceCancel() }

            VStack(spacing: 26) {
                TimelineView(.animation) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    BrandOrb(size: 116)
                        .scaleEffect(1 + 0.045 * sin(t * 2.2))
                        .shadow(color: Color(red: 0.6, green: 0.55, blue: 0.9).opacity(0.35), radius: 42)
                }

                TimelineView(.animation) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    HStack(spacing: 5) {
                        ForEach(0..<5, id: \.self) { i in
                            Capsule()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 4,
                                       height: 10 + 17 * abs(sin(t * 3.1 + Double(i) * 0.9)))
                        }
                    }
                }
                .frame(height: 32)

                VStack(spacing: 8) {
                    if let heard = day.voiceHeard {
                        Text(heard)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Ink.primary)
                            .transition(.opacity.combined(with: .offset(y: 6)))
                    }
                    Text(day.voiceHeard == nil ? "Listening" : "Revising the draft")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Ink.tertiary)
                        .contentTransition(.opacity)
                }
                .frame(height: 64)
            }
            .scaleEffect(appeared ? 1 : 0.93)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { appeared = true }
            }
        }
    }
}

// MARK: - The OS ritual for money: the App Store sheet, faithfully.

struct SideButtonConfirm: View {
    @EnvironmentObject var day: DayEngine
    @State private var appeared = false
    private let appleBlue = Color(red: 0.04, green: 0.52, blue: 1.0)

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(count: 2) { day.sendPay() }
                .onTapGesture { day.cancelPayConfirm() }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("PERSONA")
                        .font(.system(size: 19, weight: .bold))
                        .kerning(1.6)
                        .foregroundStyle(Ink.primary)
                    Spacer()
                    Button {
                        day.cancelPayConfirm()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Ink.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.09), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

                HStack(spacing: 13) {
                    CardGraphic(scale: 0.6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carbone table hold")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Ink.primary)
                        Text("OpenTable · via Persona")
                            .font(.system(size: 13))
                            .foregroundStyle(Ink.secondary)
                        Text("Refundable until 6:00 PM")
                            .font(.system(size: 13))
                            .foregroundStyle(Ink.secondary)
                    }
                    Spacer()
                    Text("$25.00")
                        .font(.system(size: 17, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Ink.primary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 14)

                Text("Account: duggalshaurya1234@gmail.com")
                    .font(.system(size: 13))
                    .foregroundStyle(Ink.secondary)
                    .padding(.horizontal, 22)
                    .padding(.top, 14)

                VStack(spacing: 10) {
                    SideButtonGlyph(color: appleBlue)
                    Text("Confirm with Side Button")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Ink.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 26)
                .padding(.bottom, 22)
            }
            .background(
                Color(red: 0.11, green: 0.11, blue: 0.115),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
            .offset(y: appeared ? 0 : 80)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) { appeared = true }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { day.sendPay() }
        }
    }
}

// The blue phone-with-side-button mark, pulsing toward the hardware.
struct SideButtonGlyph: View {
    let color: Color
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let phase = 0.5 + 0.5 * sin(t * 2.6)
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(color, lineWidth: 2.6)
                    .frame(width: 26, height: 40)
                Capsule()
                    .fill(color)
                    .frame(width: 3.5, height: 14)
                    .offset(x: 15, y: -7)
                    .shadow(color: color.opacity(0.5 + 0.5 * phase), radius: 5)
                    .scaleEffect(y: 1 + 0.12 * phase)
                Image(systemName: "arrow.left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                    .offset(x: 28 - 5 * phase, y: -7)
                    .opacity(0.4 + 0.6 * phase)
            }
            .frame(width: 60, height: 48)
        }
    }
}

// MARK: - Demo control. Triple-tap the background. Not part of the design.

struct DemoHUD: View {
    @EnvironmentObject var day: DayEngine

    var body: some View {
        VStack(spacing: 6) {
            MicroLabel(text: "Demo")
                .padding(.bottom, 4)
            hudButton("Reset") { day.jump(.idle) }
            hudButton("Dinner ask") { day.jump(.lowAsk) }
            hudButton("Dinner ask, booking fails") { day.jump(.lowAsk, failing: true) }
            hudButton("Failed") { day.jump(.lowFailed) }
            hudButton("Message ask") { day.jump(.msgAsk) }
            hudButton("Pay ask") { day.jump(.payAsk) }
            hudButton("Band preview") {
                day.hudVisible = false
                withAnimation(.snappy(duration: 0.3)) { day.bandVisible = true }
            }
        }
        .padding(18)
        .frame(width: 236)
        .glassCard()
    }

    private func hudButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Ink.primary.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Color.white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
