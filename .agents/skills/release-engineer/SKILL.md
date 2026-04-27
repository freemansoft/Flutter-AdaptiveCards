---
name: release-engineer
description: >
  Release engineering protocol for the Flutter-AdaptiveCards monorepo.
  Covers versioning, tagging, pushing packages to pub.dev, and pubspec.yaml management.
---

# Release Engineer Protocol

As a release engineer, you are responsible for managing version numbers, tagging the repository, and publishing packages to pub.dev. Follow this procedure strictly to ensure consistency across the monorepo.

## 1. Versioning Standard

- **Shared Versioning**: All `pubspec.yaml` files across the monorepo (especially in the `packages/` directory) MUST have the **same version number**.
- **Semantic Versioning**: Tags and versions follow the `<major>.<minor>.<patch>` format in `pubspec.yaml`.
- **Git Tags**: Repository tags follow the `v<major>.<minor>.<patch>` naming convention, strictly based on the version declared in the `pubspec.yaml` files.
- **Individual Package Tags**: Each package is also tagged with `v<package>-<version>` (e.g. `vflutter_adaptive_cards_fs-1.0.0`).

## 2. Pre-Release Checklist

Before creating a release, ensure:

1. All `pubspec.yaml` files have identical `version` fields.
2. `CHANGELOG.md` files are up-to-date and reflect the new version.
3. The project builds successfully and passes all tests/analysis (`fvm flutter analyze`, `fvm flutter test`).

## 3. Tagging the Repository

When creating a release:

1. Determine the version from the `pubspec.yaml` files (e.g., `1.0.0`).
2. Create a git tag locally using the `v` prefix: `git tag v1.0.0`
3. Push the tag to the remote repository: `git push origin v1.0.0`

## 4. Publishing to pub.dev

_After_ the tagged release is created and pushed, publish the packages:

1. Navigate to each Flutter package inside the `packages/` directory.
2. Run the publish command (e.g., `fvm flutter pub publish` - you may need to use `--dry-run` first to verify, and note that publishing requires user interaction or an automated token in CI).

## 5. Post-Release Version Bump

**CRITICAL RULE**: `pubspec.yaml` version numbers are ONLY updated _after_ pushes to pub.dev and after the release is verified

1. Once the current version is successfully pushed to pub.dev, bump the version numbers in all `pubspec.yaml` files to the next development version (e.g., if you just released `1.0.0`, bump to `1.0.1-dev` or `1.0.1` as appropriate for the next cycle).
2. Update all CHANGELOG.md files to reflect the new version and contain the new version number as the top entry. Ex: "## [0.5.0]"
3. Commit the version bumps to the repository.
