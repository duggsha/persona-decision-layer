import SwiftUI

@main
struct PersonaApp: App {
    @StateObject private var day = DayEngine()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(day)
                .preferredColorScheme(.dark)
                .onAppear {
                    let args = ProcessInfo.processInfo.arguments
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if args.contains("-stage") {
                            var t = Transaction()
                            t.disablesAnimations = true
                            withTransaction(t) { day.bootstrap(from: args) }
                        } else {
                            day.openFeed()
                        }
                    }
                }
        }
    }
}
