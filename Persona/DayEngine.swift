import SwiftUI

// One evening, hardcoded. The engine walks a scripted day and owns every
// timer so views stay dumb. Reversible asks proceed unless stopped.
// Irreversible asks wait.

enum Stage: Equatable {
    case idle
    case lowAsk, lowDeclined, lowWorking, lowDone, lowUndoing, lowFailed
    case msgAsk, msgDeclined, msgSent
    case payAsk, payDeclined, payDone
}

enum Scenario: Int, CaseIterable, Identifiable, Hashable {
    case dinner, message, deposit
    var id: Int { rawValue }
}

struct Receipt: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let text: String
}

// One row of an agent run: an app it touched, a verb, an object.
enum AppLogo {
    case persona, calendar, messages, phone, wallet, opentable
}

struct RunStep: Identifiable, Equatable {
    let id = UUID()
    let logo: AppLogo
    let verb: String
    let object: String
}

@MainActor
final class DayEngine: ObservableObject {

    @Published var stage: Stage = .idle
    @Published var receipts: [Receipt] = []

    // Dinner: reversible, so it proceeds unless stopped.
    @Published var dinnerTime = "8:00"
    @Published var editingLow = false
    @Published var autoArmed = false
    @Published var autoProgress: Double = 0
    @Published var lowReasonPicked: String? = nil
    @Published var undoOpen = false
    @Published var dinnerResolved: String? = nil   // nil | "moved" | "kept"

    // Message: a real person, so it waits.
    @Published var editingHigh = false
    @Published var customDraft: String? = nil
    @Published var highReasonPicked: String? = nil
    @Published var mayaNote: String? = nil         // nil | "texted 7:41" | "you'll tell her"

    // Voice edit: tell Persona what to change instead of typing it.
    @Published var voiceActive = false
    @Published var voiceHeard: String? = nil
    @Published var voiceEdited = false

    // Deposit: money, so it waits too. Confirmation borrows the OS ritual:
    // the App Store double-click, aimed at the side button.
    @Published var payReasonPicked: String? = nil
    @Published var depositNote: String? = nil      // nil | "held" | "you'll pay there"
    @Published var payConfirming = false

    // The queue IS the app. One card per page, swipe like a feed.
    @Published var feedOpen = true
    @Published var feedPage: Scenario? = .dinner

    // The live run: steps stream in while the agent works.
    @Published var runSteps: [RunStep] = []

    // Trust graduates: approve once, offer to stop asking for the small stuff.
    @Published var graduated = false
    @Published var graduatedMsg = false
    @Published var graduatedPay = false

    // The same moment, on the band.
    @Published var bandVisible = false

    // Tonight's paper trail.
    @Published var historyVisible = false

    // The thread behind the message ask.
    @Published var threadVisible = false

    // The payoff of trust: one thing handled without asking.
    @Published var autoCardVisible = false
    @Published var autoCardDismissed = false

    var history: [(String, String)] {
        var h: [(String, String)] = []
        if autoCardDismissed {
            h.append(("bolt.fill", "Auto: told Maya you're on the way"))
        }
        if let d = dinnerResolved {
            h.append(("calendar", d == "moved" ? "Dinner moved to \(dinnerTime) at Carbone" : "Dinner kept at 7:30"))
        }
        if let m = mayaNote {
            h.append(("paperplane.fill", m == "texted 7:41" ? "Told Maya · 7:41" : "Maya left to you"))
        }
        if let p = depositNote {
            h.append(("creditcard", p == "held" ? "Paid $25 table hold" : "Deposit skipped"))
        }
        return h
    }

    // Demo control
    @Published var failNextBooking = false
    @Published var hudVisible = false

    let autoWindow: Double = 8.0

    private var autoTask: Task<Void, Never>?
    private var flowTask: Task<Void, Never>?
    private var didBootstrap = false

    var draft: String {
        customDraft ?? "Running 10 late, moved us to \(dinnerTime). See you there."
    }

    var dinnerRowTime: String { dinnerResolved == "moved" ? dinnerTime : "7:30" }

    var dinnerRowNote: String? {
        var parts: [String] = []
        if let d = dinnerResolved { parts.append(d) }
        if depositNote == "held" { parts.append("held") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var pending: [Scenario] {
        var p: [Scenario] = []
        if dinnerResolved == nil { p.append(.dinner) }
        if mayaNote == nil { p.append(.message) }
        if depositNote == nil { p.append(.deposit) }
        return p
    }

    func isResolved(_ s: Scenario) -> Bool {
        switch s {
        case .dinner: return dinnerResolved != nil
        case .message: return mayaNote != nil
        case .deposit: return depositNote != nil
        }
    }

    func isActive(_ s: Scenario) -> Bool {
        switch s {
        case .dinner:
            switch stage {
            case .lowAsk, .lowDeclined, .lowWorking, .lowDone, .lowUndoing, .lowFailed: return true
            default: return false
            }
        case .message:
            switch stage {
            case .msgAsk, .msgDeclined, .msgSent: return true
            default: return false
            }
        case .deposit:
            switch stage {
            case .payAsk, .payDeclined, .payDone: return true
            default: return false
            }
        }
    }

    // Done things leave the queue. The queue is only what needs you.
    var queue: [Scenario] {
        Scenario.allCases.filter { !isResolved($0) || isActive($0) }
    }

    var cardUp: Bool { stage != .idle && !feedOpen }

    var highStakes: Bool {
        switch stage {
        case .msgAsk, .msgDeclined, .msgSent, .payAsk, .payDeclined, .payDone: return true
        default: return false
        }
    }

    var clock: String { "7:31" }

    // MARK: entry points

    func agendaTapped() {
        guard stage == .idle, !feedOpen else { return }
        guard let next = pending.first else { resetDay(); return }
        present(next)
    }

    // The feed never presents on scroll. Pages are self-sufficient; stage
    // only changes when the user acts on a card. Scrolling stays cheap.
    // On open, the reversible ask arms itself: it moves unless stopped.
    func openFeed() {
        cancelTimers()
        stage = .idle
        feedPage = pending.first ?? .dinner
        feedOpen = true
        if dinnerResolved == nil, feedPage == .dinner { presentLow() }
    }

    func present(_ s: Scenario) {
        switch s {
        case .dinner: presentLow()
        case .message: presentMsg()
        case .deposit: presentPay()
        }
    }

    // The queue is mechanical: finish one thing, the next rises.
    private func advanceSoon(_ delay: UInt64 = 550_000_000) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard let self, self.feedOpen else { return }
            if let next = self.pending.first {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                    self.feedPage = next
                }
            }
        }
    }

    // Once the queue is clear and trust exists, show one thing it did alone.
    func maybeAutoDemo() {
        guard graduatedMsg, !autoCardDismissed, queue.isEmpty else { return }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard let self, !self.autoCardDismissed else { return }
            Haptic.soft()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { self.autoCardVisible = true }
            try? await Task.sleep(nanoseconds: 6_500_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                self.autoCardVisible = false
                self.autoCardDismissed = true
            }
        }
    }

    func graduate() {
        Haptic.success()
        withAnimation(.snappy(duration: 0.3)) { graduated = true }
    }

    func graduateMsg() {
        Haptic.success()
        withAnimation(.snappy(duration: 0.3)) { graduatedMsg = true }
    }

    func graduatePay() {
        Haptic.success()
        withAnimation(.snappy(duration: 0.3)) { graduatedPay = true }
    }

    func resetDay() {
        cancelTimers()
        receipts = []
        graduated = false
        graduatedMsg = false
        graduatedPay = false
        autoCardVisible = false
        autoCardDismissed = false
        dinnerResolved = nil
        mayaNote = nil
        depositNote = nil
        dinnerTime = "8:00"
        customDraft = nil
        withAnimation(.snappy(duration: 0.3)) { stage = .idle }
    }

    // MARK: dinner

    func presentLow() {
        cancelTimers()
        dinnerTime = "8:00"
        editingLow = false
        lowReasonPicked = nil
        undoOpen = false
        setStage(.lowAsk)
        armAuto()
    }

    private func armAuto() {
        autoTask?.cancel()
        autoArmed = true
        autoProgress = 0
        withAnimation(.linear(duration: autoWindow)) { autoProgress = 1 }
        autoTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(8.0 * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            if self.stage == .lowAsk && !self.editingLow { self.approveLow(auto: true) }
        }
    }

    func pauseAuto() {
        autoTask?.cancel()
        autoArmed = false
        withAnimation(.snappy(duration: 0.3)) { autoProgress = 0 }
    }

    func beginEditLow() {
        pauseAuto()
        withAnimation(.snappy(duration: 0.35)) { editingLow = true }
        Haptic.light()
    }

    func pick(time: String) {
        withAnimation(.snappy(duration: 0.35)) {
            dinnerTime = time
            editingLow = false
        }
        Haptic.light()
        armAuto()
    }

    private func stream(_ steps: [RunStep], every interval: UInt64 = 620_000_000,
                        then finish: @escaping () -> Void) {
        runSteps = []
        flowTask = Task { [weak self] in
            for s in steps {
                try? await Task.sleep(nanoseconds: interval)
                guard let self, !Task.isCancelled else { return }
                Haptic.light()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    self.runSteps.append(s)
                }
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    func approveLow(auto: Bool = false) {
        pauseAuto()
        if !auto { Haptic.light() }
        setStage(.lowWorking)
        let fails = failNextBooking
        var steps: [RunStep] = [
            RunStep(logo: .calendar, verb: "Checked", object: "tonight's plan"),
            RunStep(logo: .opentable, verb: "Asked", object: "Carbone for \(dinnerTime)"),
        ]
        if !fails {
            steps.append(RunStep(logo: .phone, verb: "Confirmed", object: "with the host"))
            steps.append(RunStep(logo: .persona, verb: "Moved", object: "7:30 \u{2192} \(dinnerTime)"))
        }
        stream(steps) { [weak self] in
            guard let self else { return }
            if fails {
                self.failNextBooking = false
                Haptic.warning()
                self.setStage(.lowFailed)
            } else {
                Haptic.success()
                self.setStage(.lowDone)
                self.openUndoWindow()
            }
        }
    }

    private func openUndoWindow() {
        undoOpen = true
        flowTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 9_000_000_000)
            guard let self, !Task.isCancelled else { return }
            self.settleLow()
        }
    }

    func settleLow() {
        guard stage == .lowDone else { return }
        undoOpen = false
        withAnimation(.snappy(duration: 0.35)) { dinnerResolved = "moved" }
        setStage(.idle)
        advanceSoon()
    }

    func undo() {
        flowTask?.cancel()
        undoOpen = false
        Haptic.light()
        setStage(.lowUndoing)
        stream([
            RunStep(logo: .phone, verb: "Called", object: "Carbone back"),
            RunStep(logo: .persona, verb: "Restored", object: "7:30"),
        ], every: 700_000_000) { [weak self] in
            guard let self else { return }
            withAnimation(.snappy(duration: 0.35)) { self.dinnerResolved = "kept" }
            self.setStage(.idle)
            self.advanceSoon()
        }
    }

    func declineLow() {
        pauseAuto()
        Haptic.light()
        setStage(.lowDeclined)
    }

    func pickLowReason(_ reason: String) {
        withAnimation(.snappy(duration: 0.3)) { lowReasonPicked = reason }
        Haptic.light()
        flowTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard let self, !Task.isCancelled else { return }
            withAnimation(.snappy(duration: 0.35)) { self.dinnerResolved = "kept" }
            self.setStage(.idle)
            self.advanceSoon()
        }
    }

    func resolveFail(take830: Bool) {
        Haptic.light()
        if take830 {
            dinnerTime = "8:30"
            setStage(.lowWorking)
            stream([
                RunStep(logo: .opentable, verb: "Took", object: "the 8:30 table"),
                RunStep(logo: .persona, verb: "Moved", object: "7:30 \u{2192} 8:30"),
            ], every: 700_000_000) { [weak self] in
                guard let self else { return }
                Haptic.success()
                self.setStage(.lowDone)
                self.openUndoWindow()
            }
        } else {
            withAnimation(.snappy(duration: 0.35)) { dinnerResolved = "kept" }
            setStage(.idle)
            advanceSoon()
        }
    }

    // MARK: message

    func presentMsg() {
        cancelTimers()
        editingHigh = false
        customDraft = nil
        highReasonPicked = nil
        withAnimation(.spring(response: 0.62, dampingFraction: 0.93)) {
            stage = .msgAsk
        }
        Haptic.soft()
    }

    func beginEditHigh() {
        withAnimation(.snappy(duration: 0.35)) { editingHigh = true }
        Haptic.light()
    }

    func endEditHigh(_ text: String) {
        customDraft = text.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.snappy(duration: 0.35)) { editingHigh = false }
    }

    func voiceStart() {
        Haptic.soft()
        voiceHeard = nil
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { voiceActive = true }
        flowTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            guard let self, !Task.isCancelled else { return }
            withAnimation(.snappy(duration: 0.3)) { self.voiceHeard = "\u{201C}make it warmer\u{201D}" }
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            guard !Task.isCancelled else { return }
            Haptic.success()
            withAnimation(.snappy(duration: 0.35)) {
                self.customDraft = "Heads up, moved us to \(self.dinnerTime) at Carbone tonight. Can't wait to see you."
                self.voiceEdited = true
                self.voiceActive = false
            }
        }
    }

    func voiceCancel() {
        flowTask?.cancel()
        Haptic.light()
        withAnimation(.snappy(duration: 0.25)) { voiceActive = false }
    }

    func sendHigh() {
        Haptic.rigid()
        setStage(.msgSent)
        stream([
            RunStep(logo: .messages, verb: "Opened", object: "the thread with Maya"),
            RunStep(logo: .messages, verb: "Sent", object: "as you"),
            RunStep(logo: .persona, verb: "Delivered", object: "7:41"),
        ], every: 560_000_000) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                withAnimation(.snappy(duration: 0.35)) { self.mayaNote = "texted 7:41" }
                self.setStage(.idle)
                self.advanceSoon()
            }
        }
    }

    func declineHigh() {
        Haptic.light()
        setStage(.msgDeclined)
    }

    func pickHighReason(_ reason: String) {
        withAnimation(.snappy(duration: 0.3)) { highReasonPicked = reason }
        Haptic.light()
        flowTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard let self, !Task.isCancelled else { return }
            withAnimation(.snappy(duration: 0.35)) { self.mayaNote = "you'll tell her" }
            self.setStage(.idle)
            self.advanceSoon()
        }
    }

    // MARK: deposit

    func presentPay() {
        cancelTimers()
        payReasonPicked = nil
        withAnimation(.spring(response: 0.62, dampingFraction: 0.93)) {
            stage = .payAsk
        }
        Haptic.soft()
    }

    func payTapped() {
        Haptic.light()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { payConfirming = true }
    }

    func cancelPayConfirm() {
        Haptic.light()
        withAnimation(.snappy(duration: 0.25)) { payConfirming = false }
    }

    func sendPay() {
        withAnimation(.snappy(duration: 0.25)) { payConfirming = false }
        Haptic.rigid()
        setStage(.payDone)
        stream([
            RunStep(logo: .wallet, verb: "Charged", object: "Amex \u{00B7}\u{00B7}\u{00B7} 4 \u{00B7} $25.00"),
            RunStep(logo: .opentable, verb: "Held", object: "the \(dinnerTime) table"),
            RunStep(logo: .persona, verb: "Saved", object: "the receipt"),
        ], every: 560_000_000) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_400_000_000)
                withAnimation(.snappy(duration: 0.35)) { self.depositNote = "held" }
                self.setStage(.idle)
                self.advanceSoon()
            }
        }
    }

    func declinePay() {
        Haptic.light()
        setStage(.payDeclined)
    }

    func pickPayReason(_ reason: String) {
        withAnimation(.snappy(duration: 0.3)) { payReasonPicked = reason }
        Haptic.light()
        flowTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard let self, !Task.isCancelled else { return }
            withAnimation(.snappy(duration: 0.35)) { self.depositNote = "you'll pay there" }
            self.setStage(.idle)
            self.advanceSoon()
        }
    }

    // MARK: plumbing

    private func setStage(_ s: Stage) {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            stage = s
        }
    }

    private func cancelTimers() {
        autoTask?.cancel()
        flowTask?.cancel()
        autoArmed = false
        autoProgress = 0
    }

    // Screenshot-driving hook: `simctl launch com.dugg.persona -stage msgAsk`
    func bootstrap(from arguments: [String]) {
        guard !didBootstrap else { return }
        didBootstrap = true
        guard let i = arguments.firstIndex(of: "-stage"), arguments.indices.contains(i + 1) else { return }
        switch arguments[i + 1] {
        case "lowAsk": presentLow()
        case "lowEdit": presentLow(); beginEditLow()
        case "lowDeclined": presentLow(); declineLow()
        case "lowReason": presentLow(); declineLow(); lowReasonPicked = "Ask first"; flowTask?.cancel()
        case "working": setStage(.lowWorking)
        case "done":
            presentLow()
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 400_000_000)
                self?.approveLow()
            }
        case "failed":
            dinnerTime = "8:00"
            setStage(.lowFailed)
        case "highAsk", "msgAsk": dinnerResolved = "moved"; presentMsg()
        case "highEdit", "msgEdit": dinnerResolved = "moved"; presentMsg(); beginEditHigh()
        case "highDeclined", "msgDeclined": dinnerResolved = "moved"; presentMsg(); declineHigh()
        case "sent", "msgSent": dinnerResolved = "moved"; presentMsg(); stage = .msgSent; flowTask?.cancel()
        case "payAsk": dinnerResolved = "moved"; mayaNote = "texted 7:41"; presentPay()
        case "payDeclined": dinnerResolved = "moved"; mayaNote = "texted 7:41"; presentPay(); declinePay()
        case "payDone": dinnerResolved = "moved"; mayaNote = "texted 7:41"; presentPay(); stage = .payDone; flowTask?.cancel()
        case "feed": openFeed()
        case "band":
            openFeed()
            bandVisible = true
        case "feedLast":
            dinnerResolved = "moved"
            mayaNote = "texted 7:41"
            openFeed()
        case "receipts":
            dinnerTime = "8:00"
            dinnerResolved = "moved"
            mayaNote = "texted 7:41"
            depositNote = "held"
        default: openFeed()
        }
        switch stage {
        case .lowAsk, .lowDeclined, .lowWorking, .lowDone, .lowUndoing, .lowFailed:
            feedPage = .dinner
        case .msgAsk, .msgDeclined, .msgSent:
            feedPage = .message
        case .payAsk, .payDeclined, .payDone:
            feedPage = .deposit
        default: break
        }
    }

    // MARK: demo control (triple-tap HUD)

    func jump(_ s: Stage, failing: Bool = false) {
        cancelTimers()
        editingLow = false
        editingHigh = false
        lowReasonPicked = nil
        highReasonPicked = nil
        payReasonPicked = nil
        customDraft = nil
        undoOpen = false
        failNextBooking = failing
        hudVisible = false
        feedOpen = true
        switch s {
        case .lowAsk:
            withAnimation(.snappy(duration: 0.3)) { feedPage = .dinner }
            presentLow()
        case .msgAsk:
            withAnimation(.snappy(duration: 0.3)) { feedPage = .message }
            presentMsg()
        case .payAsk:
            withAnimation(.snappy(duration: 0.3)) { feedPage = .deposit }
            presentPay()
        case .lowFailed:
            withAnimation(.snappy(duration: 0.3)) { feedPage = .dinner }
            dinnerTime = "8:00"
            setStage(.lowFailed)
        case .lowDone:
            withAnimation(.snappy(duration: 0.3)) { feedPage = .dinner }
            presentLow()
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 400_000_000)
                self?.approveLow()
            }
        case .idle:
            resetDay()
            withAnimation(.snappy(duration: 0.3)) { feedPage = .dinner }
            presentLow()
        default:
            setStage(s)
        }
    }
}
