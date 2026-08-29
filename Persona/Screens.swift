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

            if day.hudVisible {
                DemoHUD()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: day.hudVisible)
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

    private var pageIndex: Int { (day.feedPage ?? .dinner).rawValue }
    private var atEnd: Bool { pageIndex == Scenario.allCases.count - 1 }

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
                    Text("\(pageIndex + 1) of \(Scenario.allCases.count)")
                        .foregroundStyle(Ink.secondary)
                        .contentTransition(.numericText())
                    Text(atEnd ? "end of queue" : "scroll")
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
                    LazyVStack(spacing: 12) {
                        ForEach(Scenario.allCases) { s in
                            Group {
                                if s == .dinner {
                                    VStack(alignment: .leading, spacing: 16) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Welcome back, Shaurya")
                                                .font(.system(size: 22, weight: .light))
                                                .foregroundStyle(Ink.primary)
                                            Text(day.pending.isEmpty
                                                 ? "Nothing needs you."
                                                 : "\(day.pending.count) thing\(day.pending.count == 1 ? "" : "s") want your okay tonight.")
                                                .font(.system(size: 22, weight: .light))
                                                .foregroundStyle(Ink.primary)
                                                .contentTransition(.numericText())
                                                .animation(.snappy(duration: 0.3), value: day.pending.count)
                                        }
                                        .padding(.horizontal, 2)
                                        DinnerCard()
                                            .frame(maxHeight: .infinity)
                                    }
                                } else {
                                    switch s {
                                    case .message: MessageCard()
                                    case .deposit: PayCard()
                                    default: EmptyView()
                                    }
                                }
                            }
                            .frame(height: slot)
                            .id(s)
                            .padding(.horizontal, 12)
                            .opacity((day.feedPage ?? .dinner) == s ? 1 : 0.75)
                            .animation(.snappy(duration: 0.3), value: day.feedPage)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .scrollPosition(id: $day.feedPage)
                .scrollIndicators(.hidden)
                .contentMargins(.top, topGap, for: .scrollContent)
                .contentMargins(.bottom, max(12, geo.size.height - slot - topGap), for: .scrollContent)
                .overlay(alignment: .bottom) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(red: 0.19, green: 0.82, blue: 0.35))
                        Text(day.pending.isEmpty ? "All handled. Go enjoy dinner." : "Last one tonight.")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(Ink.secondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(Ink.surface, in: Capsule())
                    .overlay { Capsule().strokeBorder(Ink.hairline, lineWidth: 1) }
                    .padding(.bottom, 2)
                    .opacity(atEnd ? 1 : 0)
                    .offset(y: atEnd ? 0 : 10)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: atEnd)
                    .allowsHitTesting(false)
                }
            }
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
                    removal: .opacity))
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
                Text("Won't ask for small moves next time.")
                    .font(.system(size: 13))
                    .foregroundStyle(Ink.secondary)
            }
            .frame(height: 34)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        } else {
            Button {
                day.graduate()
            } label: {
                Text("Skip asking for small moves")
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
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Ink.primary)
                            Text("Sent to Maya")
                                .font(.system(size: 16.5, weight: .semibold))
                                .foregroundStyle(Ink.primary)
                            Spacer()
                            Text("7:41")
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
                    removal: .opacity))
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
                    HoldToSend { day.sendHigh() }
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
                    removal: .opacity))
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
            VStack(spacing: 16) {
                CardGraphic()
                Text("$25.00")
                    .font(.system(size: 46, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Ink.primary)
            }
            .padding(.top, 30)
            .padding(.bottom, 24)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(white: 0.34), Color(white: 0.22)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 26, height: 19)
                .overlay {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
                }
                .padding(.top, 13)
                .padding(.leading, 13)

            Spacer()

            HStack {
                Text("AMEX")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .kerning(1.2)
                    .foregroundStyle(Ink.secondary)
                Spacer()
                Text("···· 4")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Ink.secondary)
            }
            .padding(.horizontal, 13)
            .padding(.bottom, 11)
        }
        .frame(width: 140, height: 88)
        .background(
            LinearGradient(colors: [Color(white: 0.13), Color(white: 0.075)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
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

// MARK: - The OS ritual for money. The App Store double-click, in Apple's blue.

struct SideButtonConfirm: View {
    @EnvironmentObject var day: DayEngine
    @State private var appeared = false
    private let appleBlue = Color(red: 0.04, green: 0.52, blue: 1.0)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(count: 2) { day.sendPay() }
                .onTapGesture { day.cancelPayConfirm() }

            HStack(spacing: 9) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Double-Click to Pay")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Ink.primary)
                    Text("$25.00 · Amex ··· 4")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Ink.secondary)
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 15)
                .background(Ink.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Ink.hairline, lineWidth: 1)
                }

                TimelineView(.animation) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    let phase = (t.truncatingRemainder(dividingBy: 1.1)) / 1.1
                    HStack(spacing: 1) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(appleBlue)
                            .opacity(phase < 0.5 ? 0.35 : 1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(appleBlue)
                            .opacity(phase < 0.5 ? 1 : 0.35)
                    }
                }

                TimelineView(.animation) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(appleBlue)
                        .frame(width: 5, height: 68)
                        .scaleEffect(y: 1 + 0.05 * sin(t * 3.4))
                        .shadow(color: appleBlue.opacity(0.6), radius: 8)
                }
            }
            .padding(.top, 148)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { day.sendPay() }
            .offset(x: appeared ? 0 : 26)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { appeared = true }
            }
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
