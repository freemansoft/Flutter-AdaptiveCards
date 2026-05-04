---
name: flutter-upgrade-sdk
description: >
  Procedure for upgrading the Flutter and Dart SDK versions across the monorepo.
  Covers FVM config, GitHub actions, pubspec.yaml constraints, and changelogs.
---

# Flutter SDK Upgrade Protocol

Follow this procedure when upgrading the Flutter and Dart SDK versions used in this monorepo. Ensuring all configurations, packages, and CI pipelines stay in sync is critical for monorepo health.

## 1. Upgrade FVM (Flutter Version Management)

FVM is the source of truth for the local development environment.

- Run `fvm install <new-flutter-version>` (e.g., `fvm install 3.41.2`) in the root of the repository if the new target version of flutter is not already installed.
- Run `fvm use <new-flutter-version>` (e.g., `fvm use 3.41.2`) in the root of the repository.
- Verify that `.fvm/fvm_config.json` has been updated with the new version.

## 2. Update CI/CD Workflows

The GitHub Actions workflows must use the exact same Flutter version as FVM to prevent CI drifts.

- Open `.github/workflows/test.yml`.
- Locate the `subosito/flutter-action` step.
- Update the `flutter-version:` parameter to match the new FVM version exactly.

## 3. Update Package `pubspec.yaml` Files

All packages in the monorepo should share the same minimum Dart/Flutter SDK requirements.

- Locate all `pubspec.yaml` files across the repository. This includes:
  - `packages/flutter_adaptive_cards_fs/pubspec.yaml`
  - `packages/flutter_adaptive_charts_fs/pubspec.yaml`
  - `packages/flutter_adaptive_template_fs/pubspec.yaml`
  - `adaptive_explorer/pubspec.yaml`
  - `widgetbook/pubspec.yaml`
- Update the `environment:` constraints to match the new minimum Dart SDK (and optionally Flutter SDK) corresponding to the new Flutter version.

  ```yaml
  environment:
    sdk: ^<new-dart-version>
  ```

## 4. Update Changelogs

Document the SDK bump so consumers of the packages are aware of the new minimum requirements.

- Add a bullet point to the `CHANGELOG.md` file for every updated package under the `Unreleased` or upcoming version heading.
- Example: `- Require Dart SDK <new-dart-version> and Flutter <new-flutter-version>`

## 5. Verify the Upgrade

Ensure that the new SDK version does not break existing code or cause new linting errors.

- Ensure dependencies are resolved (using `fvm flutter pub get` or `upgrade` at the workspace root).
- Run `fvm flutter analyze` to catch any new static analysis errors or deprecations introduced by the newer SDK.
- Run `fvm flutter test` to ensure all tests continue to pass.
- Fix any deprecations or breaking changes introduced by the new Flutter/Dart version before committing.
