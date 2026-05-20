---
name: release-engineer
description: >
  Release engineering protocol for the Flutter-AdaptiveCards monorepo.
  Covers versioning, tagging, pushing packages to pub.dev, post-release minor
  bumps, changelog updates, and pubspec.yaml dependency sync.
---

# Release Engineer Protocol

As a release engineer, you are responsible for managing version numbers, tagging the repository, and publishing packages to pub.dev. Follow this procedure strictly to ensure consistency across the monorepo.

## 1. Versioning Standard

- **Shared Versioning**: Every `pubspec.yaml` that declares a `version:` field MUST use the **same version number** across the monorepo.
- **Semantic Versioning**: Tags and versions follow `<major>.<minor>.<patch>` in `pubspec.yaml`.
- **Post-release bumps**: After a successful pub.dev publish, bump the **minor** segment by 1 and reset **patch** to `0` (e.g. `0.6.0` → `0.7.0`, `0.7.3` → `0.8.0`). Do **not** bump patch for the next development cycle.
- **Git Tags**: Repository tags use `v<major>.<minor>.<patch>` based on the version **published** (before the post-release bump).
- **Individual Package Tags**: Each published package is also tagged `v<package>-<version>` (e.g. `vflutter_adaptive_cards_fs-0.7.0`).

## 2. Monorepo Files (Version & Changelog)

### `pubspec.yaml` files (all must stay in sync)

| File                                                 | Published to pub.dev?   |
| ---------------------------------------------------- | ----------------------- |
| `packages/flutter_adaptive_cards_fs/pubspec.yaml`    | Yes                     |
| `packages/flutter_adaptive_charts_fs/pubspec.yaml`   | Yes                     |
| `packages/flutter_adaptive_template_fs/pubspec.yaml` | Yes                     |
| `adaptive_explorer/pubspec.yaml`                     | No (`publish_to: none`) |
| `widgetbook/pubspec.yaml`                            | No (`publish_to: none`) |

The root `pubspec.yaml` has no `version:` field (workspace manifest only).

### `CHANGELOG.md` files (add a section for each new version)

| File                                                 |
| ---------------------------------------------------- |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md`    |
| `packages/flutter_adaptive_charts_fs/CHANGELOG.md`   |
| `packages/flutter_adaptive_template_fs/CHANGELOG.md` |
| `adaptive_explorer/CHANGELOG.md`                     |
| `widgetbook/CHANGELOG.md`                            |

### In-repo package dependencies (pub version constraints)

Only **published** packages that depend on another in-repo package need a `^` constraint updated on post-release bump:

| Dependent package                                  | Dependency to update                        |
| -------------------------------------------------- | ------------------------------------------- |
| `packages/flutter_adaptive_charts_fs/pubspec.yaml` | `flutter_adaptive_cards_fs: ^<new-version>` |

Apps (`adaptive_explorer`, `widgetbook`) use `path:` dependencies — sync their `version:` field only; do not add pub version constraints for path deps.

## 3. Pre-Release Checklist

Before tagging and publishing:

1. All `version:` fields match the release you are about to ship (e.g. `0.7.0`).
2. Every `CHANGELOG.md` has a `## [<version>]` section at the top with complete release notes for that version.
3. `flutter_adaptive_charts_fs` declares `flutter_adaptive_cards_fs: ^<same-release-version>`.
4. `fvm flutter pub get` (from repo root) succeeds.
5. `fvm flutter analyze` and `fvm flutter test` pass.

## 4. Tagging the Repository

Tag the version you are **releasing**, not the post-bump development version:

1. Read the shared version from any `pubspec.yaml` (e.g. `0.7.0`).
2. Create the repo tag: `git tag v0.7.0`
3. Create per-package tags for each published package, e.g. `git tag vflutter_adaptive_cards_fs-0.7.0`
4. Push tags: `git push origin v0.7.0 vflutter_adaptive_cards_fs-0.7.0 ...`

## 5. Publishing to pub.dev

After tags are pushed, publish **only** the three library packages (in dependency order):

1. `packages/flutter_adaptive_cards_fs` — no in-repo pub dependency
2. `packages/flutter_adaptive_template_fs`
3. `packages/flutter_adaptive_charts_fs` — depends on `flutter_adaptive_cards_fs`; publish after cards is live

From each package directory:

```bash
cd packages/flutter_adaptive_cards_fs
fvm flutter pub publish --dry-run   # verify first
fvm flutter pub publish             # requires pub.dev credentials / token
```

Repeat for `flutter_adaptive_template_fs` and `flutter_adaptive_charts_fs`.

## 6. Post-Release Version Bump (Required)

**CRITICAL**: Run this only after all target packages are successfully published and verified on pub.dev.

**CRITICAL**: Do not change `pubspec.yaml` `version:` fields for a release that has not yet been published.

### 6.1 Compute the next version

Increment the **minor** segment by 1; set **patch** to `0`:

| Released (just published) | Next development version |
| ------------------------- | ------------------------ |
| `0.6.0`                   | `0.7.0`                  |
| `0.7.0`                   | `0.8.0`                  |
| `1.2.0`                   | `1.3.0`                  |

### 6.2 Update all `pubspec.yaml` `version:` fields

Set `version: <next-version>` in every file listed in §2 (all five packages).

### 6.3 Update in-repo pub dependencies

In `packages/flutter_adaptive_charts_fs/pubspec.yaml`, set:

```yaml
flutter_adaptive_cards_fs: ^<next-version>
```

Use the same `<next-version>` as the shared monorepo version (e.g. `^0.8.0`).

### 6.4 Add new `CHANGELOG.md` sections

At the **top** of each of the five `CHANGELOG.md` files (below the title/header), insert:

```markdown
## [<next-version>]

- no changes yet
```

Replace `<next-version>` with the new version (e.g. `## [0.8.0]`). Move or refine the placeholder bullet when features land during the cycle.

### 6.5 Verify and commit

```bash
fvm flutter pub get    # from repo root
fvm flutter analyze
fvm flutter test       # or per-package as needed
```

Commit with a message such as: `Bump monorepo to <next-version> for next development cycle`.

## 7. Release Cycle Summary

```text
Develop at 0.7.0  →  fill ## [0.7.0] changelogs
       ↓
Tag v0.7.0  →  publish to pub.dev
       ↓
Post-release bump  →  all versions 0.8.0, new ## [0.8.0] sections, charts dep ^0.8.0
       ↓
Develop at 0.8.0  →  repeat
```
