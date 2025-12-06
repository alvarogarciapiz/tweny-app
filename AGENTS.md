# AI Code Review Agent Guidelines for Swift (iOS 26, 2025/2026)

## SwiftUI Modifiers

* Replace `foregroundColor()` with `foregroundStyle()` because the former is deprecated and the latter supports advanced styling such as gradients.
* Replace `cornerRadius()` with `clipShape(.rect(cornerRadius:))`, which supports uneven corner radii and is the modern API.
* Avoid the 1-parameter variant of `onChange()`. Use either the two-parameter closure or the empty variant.
* Replace `onTapGesture()` with a real `Button` unless tap location or tap count is required. This improves VoiceOver and visionOS eye tracking.
* Reduce use of `fontWeight()`; prefer Dynamic Type and updated typography approaches.

## Navigation and Tabs

* Replace the old `tabItem()` modifier with the new Tab API for type-safe selection and iOS 26 tab design.
* Avoid the old inline-destination `NavigationLink` in lists; use `navigationDestination(for:)` or similar modern APIs.
* Replace `NavigationView` with `NavigationStack` unless supporting iOS 15.

## Data Models and State

* Prefer `@Observable` over `ObservableObject` unless Combine publishers are needed.
* Avoid `@Attribute(.unique)` in SwiftData when syncing with CloudKit.
* Do not break up views into computed properties. Use separate SwiftUI view types because computed properties do not benefit from `@Observable` intelligent view invalidation.

## Typography

* Replace `.font(.system(size:` usages with Dynamic Type–compatible fonts.
* If targeting iOS 26 or later, you can scale fonts like `.font(.body.scaled(by: 1.5))`.

## Buttons and Labels

* Prefer inline button label initializers such as `Button("Tap me", systemImage: "plus")`.
* Avoid `Label` for primary button labels unless appropriate.
* Avoid image-only buttons, which are problematic for assistive technologies.

## Lists, Loops, and Collections

* Replace `ForEach(Array(x.enumerated()), id: \.element.id)` with `ForEach(x.enumerated(), id: \.element.id)`; the array initializer is unnecessary.

## File System and URLs

* Replace manual document directory lookups with `URL.documentsDirectory`.

## Concurrency and Task API

* Replace `Task.sleep(nanoseconds:)` with `Task.sleep(for:)` such as `.seconds(1)`.
* Remove excessive `DispatchQueue.main.async` calls; they're often unnecessary.
* New app projects use main actor isolation by default, so explicit `@MainActor` decoration may not be needed.

## Number Formatting

* Replace C-style formatting such as `String(format: "%.2f", abs(myNumber))` with modern Swift formatting, e.g. `Text(abs(myNumber), format: .number.precision(.fractionLength(2)))`.

## Rendering

* Replace `UIGraphicsImageRenderer` with `ImageRenderer` when rendering SwiftUI views.

## Project Structure

* Avoid placing many types in a single file; it increases build times.

---

# App Context: Tweny

## Project Overview
- **Purpose:** Native iOS app (SwiftUI) for the 20-20-20 eye health technique. Tracks focus sessions, streaks, and user stats. UI/UX inspired by Apple and Vercel.
- **Architecture:**
  - **Views/**: SwiftUI screens (Profile, History, Timer, Settings, Onboarding, etc.)
  - **Services/**: Data management, timer logic, notification handling
  - **Models/**: CoreData entities, session state/configuration
  - **ViewModels/**: State management for views
  - **TwenyWidget/**: Live ActivityKit widget code

## Current Architecture & Patterns (Transitioning)
*Note: The codebase currently uses some legacy patterns (e.g. `NavigationView`, `ObservableObject`) which should be updated to match the Guidelines above where possible.*

- **SwiftUI-first:** All UI is declarative, using custom components (e.g., `BentoCard`, `HealthTipRow`) for a premium feel.
- **CoreData:** Session logs and user data are persisted via CoreData (`SessionLog`, `PersistenceController`). Use `DataManager` for badge logic and presets.
- **AppStorage:** User settings (durations, feedback toggles, goals) use `@AppStorage` for instant sync.
- **Singletons:** `DataManager` and `TimerManager` are singletons for global state and logic. `TimerManager` also integrates with `ActivityKit` for Live Activities.
- **Navigation:** Currently uses `NavigationView`. Target migration to `NavigationStack`.
- **Animations:** Spring and ease animations are used for transitions. 
- **Design Language:** Mimic Apple/Vercel style: soft backgrounds, rounded corners, subtle shadows, clean typography.

## Developer Workflows
- **Build:** Open in Xcode, build/run as a standard SwiftUI app.
- **Test:** Manual testing via simulator/device.
- **Debug:** Use Xcode's debugger and SwiftUI previews.
- **Widget:** `TwenyWidget/` contains ActivityKit code.

## Integration Points
- **PhotosUI:** For profile image picker.
- **ActivityKit:** For Live Activity countdowns and controls.
- **AppIntents:** Siri shortcuts.
- **Charts:** For session details.
- **Notifications:** Local reminders.

## Examples & References
- **ProfileView.swift:** Bento grid layout, badge system.
- **SettingsView.swift:** Custom stepper, AppStorage.
- **Services/DataManager.swift:** Badge logic, presets.
- **Services/TimerManager.swift:** Session lifecycle.

## Project-Specific Advice
- **Avoid AI-style gradients:** Use system colors.
- **Respect existing UI conventions:** Reuse custom card, pill, and stepper components.
- **Persist settings via AppStorage.**
- **Reusable Components:** Leverage `BentoCard` and `HealthTipRow`.
