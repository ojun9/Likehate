# Repository Guidelines

## Project Structure & Module Organization

This repository contains an iOS app named `Likehate`. Main app code lives under `Likehate/`, grouped by feature: `Home/`, `Write/`, `TableView/`, `Setting/`, `Chose/`, and shared extensions in `Extention/`. Storyboards are in `Likehate/Base.lproj/` and localized string files are in language folders such as `ja.lproj`, `en.lproj`, `fr.lproj`, and `zh-Hans.lproj`. Image assets are in `Likehate/Assets.xcassets/`; Lottie animations are in `Likehate/Lottie/`. Unit tests are in `LikehateTests/`, and UI tests plus screenshot flows are in `LikehateUITests/`.

## Build, Test, and Development Commands

- `pod install`: install CocoaPods dependencies from `Podfile` and refresh the workspace.
- `open Likehate.xcworkspace`: open the app with Pods linked; prefer the workspace over the project when developing locally.
- `xcodebuild -workspace Likehate.xcworkspace -scheme Likehate -destination 'platform=iOS Simulator,name=iPhone 15' build`: build the app from the command line.
- `xcodebuild -workspace Likehate.xcworkspace -scheme Likehate -destination 'platform=iOS Simulator,name=iPhone 15' test`: run unit and UI tests configured in the shared scheme.

Use an installed simulator name available on your machine if `iPhone 15` is not present.

## Coding Style & Naming Conventions

Use Swift and UIKit patterns already present in the project. Keep feature-specific controllers and helpers in their existing folders. Prefer 3-space indentation when touching existing files, matching the current code style. Use `UpperCamelCase` for types (`ViewController`, `WriteLike`) and `lowerCamelCase` for methods, properties, and local variables. Keep storyboard accessibility identifiers aligned with constants or names used by UI tests, such as `RegiButton`, `LikeTextField`, and `OKButton`.

## Testing Guidelines

Tests use XCTest. Add unit tests to `LikehateTests` for isolated logic and UI flows to `LikehateUITests` when behavior depends on navigation, buttons, text fields, or screenshots. Name test methods with the `test...` prefix so Xcode discovers them. UI tests currently rely on accessibility identifiers and `snapshot(...)`; update identifiers and screenshot names together when changing screens.

## Commit & Pull Request Guidelines

History uses short, descriptive commits in English and Japanese, for example `コード整形完了` and `ViewDidLoadを見やすくした`. Keep commits focused on one behavior or cleanup. Pull requests should include a brief summary, test results or simulator details, and screenshots for visible UI changes. Mention any localization, Firebase, CocoaPods, or storyboard changes because they can affect build setup and release behavior.

## Security & Configuration Tips

Treat `GoogleService-Info.plist`, entitlements, and Firebase configuration as sensitive app configuration. Do not add new secrets or local signing files. When adding dependencies, update both `Podfile` and `Podfile.lock` intentionally.
