# Repository Guidelines

## Project Structure & Module Organization

This repository contains the iOS app `Likehate`. App code lives under `Likehate/`:

- `App/`: SwiftUI app entry point and `AppDelegate`.
- `Features/`: feature-oriented SwiftUI screens and feature-local UI. Current features include `Home`, `Entries`, `People`, `Comparison`, `Premium`, `Settings`, and `Onboarding`.
- `CoreUI/`: cross-feature UI foundations and reusable UI. `Theme/` contains app-wide styling, `Components/` contains shared SwiftUI components, and `Integrations/` contains UIKit or SDK bridge views such as AdMob, Lottie, and crop UI.
- `Models/`: shared app model types such as `EntryKind`.
- `Stores/`: observable state and persistence, currently `LikeHateStore`.
- `Services/`: app services, notification names, and haptics helpers.
- `Resources/`: asset catalogs, Lottie JSON, and `.xcstrings` localization files.
- `SupportingFiles/`: `Info.plist`, entitlements, and Firebase config.

When adding a screen or UI that belongs to one user-facing area, put it under the matching `Features/<Feature>/` folder. Put UI in `CoreUI/` only when it is reused across multiple features or is an app-wide UI foundation.

## Build, Test, and Development Commands

- `open Likehate.xcodeproj`: open the app in Xcode.
- `xcodebuild -quiet -project Likehate.xcodeproj -scheme Likehate -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build`: quieter verification build used by automation.

Dependencies are managed with Swift Package Manager through the Xcode project. Do not reintroduce CocoaPods or a workspace.

## Coding Style & Naming Conventions

Use SwiftUI-first implementations. Keep UIKit only where it bridges SDKs that still require it, such as Lottie or AdMob. Use 3-space indentation. Types use `UpperCamelCase`; methods, properties, enum cases, and notification names use `lowerCamelCase`. Avoid suffixes like `SwiftUIView`; name views by purpose, for example `HomeView`.

## Testing Guidelines

Unit test and UI test targets are intentionally removed for now. For verification, run the command-line build and manually check affected flows in Xcode or Simulator. When tests return, prefer focused XCTest coverage for store logic and critical navigation, purchase, and persistence flows.

## Localization & Assets

Use `.xcstrings` for strings: `Resources/Localizable.xcstrings` and `Resources/InfoPlist.xcstrings`. Do not add per-language `.lproj` string files. Use localized asset catalog variants in `Resources/Assets.xcassets` instead of names like `_Ja` or `_Ara`. Keep Lottie files in `Resources/Lottie`.

When adding or changing any user-facing text, update the appropriate `.xcstrings` entry in the same change. Do not leave Japanese or English UI strings hardcoded in Swift unless they are internal identifiers or analytics/event names that are not shown to users.

## Commit & Pull Request Guidelines

Recent history uses short Japanese commit messages. Keep commits focused and describe the actual change. Pull requests should include a summary, build result, and screenshots for visible UI changes. Call out changes to SPM dependencies, Firebase, AdMob, purchases, localization, or entitlements.

## Security & Configuration Tips

Treat `SupportingFiles/GoogleService-Info.plist`, entitlements, bundle identifiers, AdMob IDs, and purchase product IDs as release-sensitive configuration. Do not add local signing assets or new secrets to the repository.
