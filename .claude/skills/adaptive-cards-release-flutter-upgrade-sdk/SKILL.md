---
name: adaptive-cards-release-flutter-upgrade-sdk
description: >
  Use when upgrading the pinned Flutter/Dart SDK version across the monorepo —
  updating FVM config, GitHub Actions, pubspec.yaml SDK constraints, and
  changelogs so every package and CI pipeline stays in sync.
---

# Flutter SDK Upgrade Protocol

Follow this procedure when upgrading the Flutter and Dart SDK versions used in this monorepo. Ensuring all configurations, packages, and CI pipelines stay in sync is critical for monorepo health.

## 1. Upgrade FVM (Flutter Version Management)

FVM is the source of truth for the local development environment. `fvm flutter --version` will automatically update the fvm managed local flutter to the correct version if it is not already installed.

You can manually update flutter versions by running:

- Run `fvm install <new-flutter-version>` (e.g., `fvm install 3.41.2`) in the root of the repository if the new target version of flutter is not already installed.
- Run `fvm use <new-flutter-version>` (e.g., `fvm use 3.41.2`) in the root of the repository.
- Verify that `.fvm/fvm_config.json` has been updated with the new version.

## 2. Update CI/CD Workflows

The GitHub Actions workflows must use the exact same Flutter version as FVM to prevent CI drifts.

There is more than one pin, in more than one workflow file. Find them all rather than working from a remembered list:

```bash
grep -rn "flutter-version:\|sdk:" .github/workflows/
```

- For each `subosito/flutter-action` step, set `flutter-version:` to the new FVM version exactly.
- For each `dart-lang/setup-dart` step, set `sdk:` to the Dart version that Flutter ships (`fvm dart --version` after step 1).
- Re-run the grep and confirm nothing was left behind.

Missing one leaves a job building against a different SDK than every other job. For the jobs that run `dart format`, that surfaces as CI failing on code that is clean locally, with no local command reproducing it.

## 3. Update Package `pubspec.yaml` Files

All packages in the monorepo should share the same minimum Dart/Flutter SDK requirements.

Find them the same way — a hand-maintained list here goes stale every time a package is added:

```bash
git grep -n "^  sdk:" -- '*/pubspec.yaml' 'pubspec.yaml'
```

That currently spans the four published packages, `flutter_adaptive_cards_test_support`, `adaptive_explorer`, `widgetbook`, both Adaptive Chat apps, and the root workspace `pubspec.yaml`.

- Update each `environment:` constraint to match the new minimum Dart SDK (and optionally Flutter SDK) corresponding to the new Flutter version.

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
