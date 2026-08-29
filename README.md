# Persona — the decision layer

Built for the Persona founding design engineer challenge: the moment an AI agent asks for your okay before acting in your life.

One idea holds the app together: **friction should match reversibility.**

- **Reservation (low stakes)** — reversible, so it proceeds on its own at a stated clock time unless you stop it. Undo stays on screen after.
- **Message (high stakes)** — a text to a real person can't be unsent, so nothing moves without you. Approval is hold-to-send, a different motor action than dismiss. Edit by tapping the bubble, or tell it the change by voice.
- **Payment (high stakes)** — money uses the operating system's own ritual: the App Store style double-click confirm.

Approving turns the card into a live agent run — the apps it touches, step by step. Declining asks one optional why, and the reason rides the next run. Loading, in-progress, failed, and undo are all built.

## Run it

Open `Persona.xcodeproj` in Xcode 16+, pick any iPhone simulator, run. Everything is hardcoded; no backend, no auth.

- The first card's countdown is live on launch: leave it alone and it moves the reservation itself.
- Triple-tap the background for the demo HUD (jump to any state, including the failed booking).

Swift / SwiftUI only. No dependencies.
