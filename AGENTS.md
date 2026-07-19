# Consumables iOS App

## Product context

Consumables helps a user record household consumables and recurring life chores, estimate when an item will run out, and surface items that need attention. Keep the product local-first unless a task explicitly introduces sync or accounts.

The current implementation supports:

- consumable item creation, editing, and archiving;
- purchase and activation records;
- manual cycle and per-item reminder thresholds;
- weighted forecasts from recent usage history;
- overview, item list, detail, editor, and settings screens.

## Technical baseline

- Native SwiftUI app using SwiftData.
- iOS 17.0 deployment target and Swift 5.10 language mode.
- XcodeGen is the source of truth for project structure (`project.yml`).
- `Consumables.xcodeproj` is generated, but remains committed for convenient opening.
- No third-party runtime dependencies are currently used.
- Production data is stored in the default local SwiftData container. Do not delete or reset it during development or verification.

## Repository map

- `Consumables/App`: application entry point and root navigation.
- `Consumables/Domain`: models, forecasting rules, and view-data mapping.
- `Consumables/Data`: persistence mutations and preview/demo seeding.
- `Consumables/Features`: screen-level SwiftUI views.
- `Consumables/Shared`: reusable UI and extensions.
- `ConsumablesTests`: unit tests, currently focused on forecasting.
- `project.yml`: canonical XcodeGen project definition.

## Working agreements

- Preserve the separation between domain forecasting, persistence mutations, and SwiftUI presentation.
- Put business rules in testable domain or service types, not directly in a view body.
- Use `ConsumablesMutationService` for user-driven model changes and saves.
- Keep calendar-sensitive tests deterministic by supplying a fixed calendar, time zone, and date.
- Treat SwiftData schema changes as data migrations. Explain compatibility and migration impact before changing persisted fields.
- Do not add cloud sync, accounts, analytics, notifications, or third-party packages without an explicit product decision.
- Do not edit generated build output or Xcode user-state files.
- When source membership or build settings change, edit `project.yml`, run `xcodegen generate`, and review the generated project diff.
- Never claim a build or test passed unless the exact command completed successfully.

## Verification

Regenerate the project after changing `project.yml`:

```sh
xcodegen generate
```

Run the unit test suite on an available iOS Simulator destination:

```sh
xcodebuild test \
  -project Consumables.xcodeproj \
  -scheme Consumables \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/DerivedData
```

If that simulator is unavailable, inspect available destinations with:

```sh
xcodebuild -showdestinations -project Consumables.xcodeproj -scheme Consumables
```

For UI changes, also open the relevant SwiftUI preview or run the app in Simulator and check empty, populated, overdue, and long-text states.

## Recommended skills

Use the smallest skill that matches the task:

- `grill-me`: resolve product and design decisions one branch at a time; inspect the repository before asking questions.
- `tdd`: add or change forecast, persistence, validation, or date-sensitive behavior with a red-green-refactor loop.
- `diagnose`: investigate crashes, SwiftData failures, build errors, or performance regressions before changing code.
- `improve-codebase-architecture`: review boundaries only when architectural improvement is explicitly requested; avoid opportunistic rewrites.
- `prototype`: explore a materially uncertain interaction or forecast model in throwaway form before committing it to production code.
- `teach`: explain Swift, SwiftUI, SwiftData, or this codebase interactively when the goal is learning rather than implementation.

Skills are workflows, not permanent dependencies. Do not invoke several by default, and do not install project-local copies unless the repository needs custom instructions unavailable from the existing skills.
