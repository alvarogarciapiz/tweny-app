# Copilot Instructions for `tweny-app`

## Project Overview
- **Purpose:** Native iOS app (SwiftUI) for the 20-20-20 eye health technique. Tracks focus sessions, streaks, and user stats. UI/UX inspired by Apple and Vercel.
- **Architecture:**
  - **Views/**: SwiftUI screens (Profile, History, Timer, Settings, Onboarding, etc.)
  - **Services/**: Data management, timer logic, notification handling
  - **Models/**: CoreData entities, session state/configuration
  - **ViewModels/**: State management for views
  - **TwenyWidget/**: Live ActivityKit widget code

## Key Patterns & Conventions
- **SwiftUI-first:** All UI is declarative, using custom components (e.g., `BentoCard`, `HealthTipRow`) for a premium feel.
- **CoreData:** Session logs and user data are persisted via CoreData (`SessionLog`, `PersistenceController`). Use `DataManager` for badge logic and presets.
- **AppStorage:** User settings (durations, feedback toggles, goals) use `@AppStorage` for instant sync.
- **Singletons:** `DataManager` and `TimerManager` are singletons for global state and logic. `TimerManager` also integrates with `ActivityKit` for Live Activities.
- **Navigation:** Uses `NavigationView` and `NavigationLink` for screen transitions. Detail views (e.g., session details) are presented modally or via navigation.
- **Animations:** Spring and ease animations are used for transitions, steppers, and card reveals. For example, `withAnimation(.spring(response: 0.5, dampingFraction: 0.8))` is used in `OnboardingView`.
- **Design Language:** Mimic Apple/Vercel style: soft backgrounds, rounded corners, subtle shadows, clean typography. Avoid excessive gradients; prefer neutral system colors.

## Developer Workflows
- **Build:** Open in Xcode, build/run as a standard SwiftUI app. No custom build scripts required.
- **Test:** No formal test suite; manual testing via simulator/device. (Add unit/UI tests in `Tests/` if needed.)
- **Debug:** Use Xcode's debugger and SwiftUI previews. CoreData issues can be debugged via `PersistenceController.preview`.
- **Widget:** `TwenyWidget/` contains ActivityKit code for Live Activities. Update attributes and state via `TimerManager`.

## Integration Points
- **PhotosUI:** For profile image picker.
- **ActivityKit:** For Live Activity countdowns and controls. `TwenyAttributes` defines dynamic and fixed properties for activities.
- **AppIntents:** `TwenyShortcuts` provides Siri shortcuts for starting/stopping sessions.
- **Charts:** For session detail time distribution (use neutral colors).
- **Notifications:** Local notifications for session/break reminders.

## Examples & References
- **ProfileView.swift:** Bento grid layout, badge system, custom card components.
- **SettingsView.swift:** Custom stepper, AppStorage, reset logic.
- **HistoryView.swift:** Grouped session cards, summary dashboard, navigation to details.
- **SessionDetailView.swift:** Hero ring, stat grid, chart, Apple-style cards.
- **Services/DataManager.swift:** Badge logic, presets, user profile management.
- **Services/TimerManager.swift:** Session lifecycle, configuration, ActivityKit integration.
- **Utilities/TimeFormatter.swift:** Helper for formatting time intervals.

## Project-Specific Advice
- **Avoid AI-style gradients:** Use system colors and subtle effects for a professional look.
- **Respect existing UI conventions:** Reuse custom card, pill, and stepper components for consistency.
- **Persist settings via AppStorage:** Sync with `TimerManager` and update CoreData as needed.
- **When adding features:** Follow the Apple/Vercel design language and use spring animations for interactivity.
- **Reusable Components:** Leverage `BentoCard` for stats and `HealthTipRow` for tips to maintain consistency.

---

For questions or unclear patterns, review the referenced files or ask for clarification from maintainers.
