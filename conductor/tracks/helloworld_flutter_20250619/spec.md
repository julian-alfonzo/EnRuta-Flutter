# Track: Create EnRuta Flutter app with Android and iOS support

## Objective
Create a minimal Flutter application that displays "EnRuta" on the screen and runs natively on both Android and iOS devices/emulators. This establishes the foundational project structure and validates the cross-platform development pipeline.

## Scope
- Initialize a Flutter project using the `flutter create` command
- Replace the default counter app with a simple "EnRuta" UI
- Verify the app builds and runs on both Android and iOS
- Ensure the project follows the Dart code style guide
- Set up the testing infrastructure with at least one passing test

## Out of Scope
- Complex state management
- Navigation/routing
- Network requests
- Local storage
- Theming beyond defaults

## Acceptance Criteria
1. App displays "EnRuta" as the main text on screen
2. App builds successfully with `flutter build apk` (Android)
3. App builds successfully with `flutter build ios` (iOS) — no simulator required
4. `flutter test` passes with at least one meaningful test
5. Code follows dart.md style guide conventions
6. No lint errors from `flutter analyze`
