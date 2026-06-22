---
name: release-engineer
description: >
  Release engineering protocol for the Flutter-AdaptiveCards monorepo.
  Covers versioning, tagging, pushing packages to pub.dev, post-release minor
  bumps, changelog updates, and pubspec.yaml dependency sync.
---

# Release Engineer Protocol

> Shell commands below use bare `flutter` / `dart`. In this repo, apply
> **`adaptive-cards-dart-flutter-fvm`** before running them.

As a release engineer, you are responsible for managing version numbers, tagging the repository, and publishing packages to pub.dev. Follow this procedure strictly to ensure consistency across the monorepo.

## 1. Versioning Standard

- **Shared Versioning**: Every `pubspec.yaml` that declares a `version:` field MUST use the **same version number** across the monorepo.
- **Semantic Versioning**: Tags and versions follow `<major>.<minor>.<patch>` in `pubspec.yaml`.
- **Post-release bumps**: After a successful pub.dev publish, bump the **minor** segment by 1 and reset **patch** to `0` (e.g. `0.6.0` → `0.7.0`, `0.7.3` → `0.8.0`). Do **not** bump patch for the next development cycle.
- **Git Tags**: Repository tags use `v<major>.<minor>.<patch>` based on the version **published** (before the post-release bump).
- **Individual Package Tags**: Each published package is also tagged `v<package>-<version>` (e.g. `vflutter_adaptive_cards_fs-0.7.0`).

## 2. Monorepo Files (Version & Changelog)

### `pubspec.yaml` files (all must stay in sync)

| File                                                   | Published to pub.dev?   |
| ------------------------------------------------------ | ----------------------- |
| `packages/flutter_adaptive_cards_fs/pubspec.yaml`      | Yes                     |
| `packages/flutter_adaptive_charts_fs/pubspec.yaml`     | Yes                     |
| `packages/flutter_adaptive_template_fs/pubspec.yaml`   | Yes                     |
| `packages/flutter_adaptive_cards_host_fs/pubspec.yaml` | Yes                     |
| `adaptive_explorer/pubspec.yaml`                       | No (`publish_to: none`) |
| `widgetbook/pubspec.yaml`                              | No (`publish_to: none`) |

The root `pubspec.yaml` has no `version:` field (workspace manifest only).

### `CHANGELOG.md` files (add a section for each new version)

| File                                                   |
| ------------------------------------------------------ |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md`      |
| `packages/flutter_adaptive_charts_fs/CHANGELOG.md`     |
| `packages/flutter_adaptive_template_fs/CHANGELOG.md`   |
| `packages/flutter_adaptive_cards_host_fs/CHANGELOG.md` |
| `adaptive_explorer/CHANGELOG.md`                       |
| `widgetbook/CHANGELOG.md`                              |

### In-repo package dependencies (pub version constraints)

Only **published** packages that depend on another in-repo package need a `^` constraint updated on post-release bump:

| Dependent package                                      | Dependency to update                        |
| ------------------------------------------------------ | ------------------------------------------- |
| `packages/flutter_adaptive_charts_fs/pubspec.yaml`     | `flutter_adaptive_cards_fs: ^<new-version>` |
| `packages/flutter_adaptive_cards_host_fs/pubspec.yaml` | `flutter_adaptive_cards_fs: ^<new-version>` |

Apps (`adaptive_explorer`, `widgetbook`) use `path:` dependencies — sync their `version:` field only; do not add pub version constraints for path deps.

## 3. Pre-Release Checklist

Before tagging and publishing:

1. All `version:` fields match the release you are about to ship (e.g. `0.7.0`) — **six** packages (four published libraries + two apps).
2. Every `CHANGELOG.md` has a `## [<version>]` section at the top with complete release notes for that version — **six** changelog files.
3. `flutter_adaptive_charts_fs` and `flutter_adaptive_cards_host_fs` declare `flutter_adaptive_cards_fs: ^<same-release-version>`.
4. `flutter pub get` (from repo root) succeeds.
5. `flutter analyze` and `flutter test` pass (include `packages/flutter_adaptive_cards_host_fs` when host code changed).

## 3.1 Promote `[Unreleased]` to the Release Version

During development, AGENTS.md instructs contributors to append bullets to `## [Unreleased]` in each `CHANGELOG.md`. Before tagging you must collapse that section into the versioned heading. For each of the **six** changelog files:

1. **Check whether `## [<release-version>]` already exists** in the file.

   - **It does not exist** — rename `## [Unreleased]` to `## [<release-version>]`. Done.

   - **It exists and its only content is `- no changes yet`** — delete the `## [<release-version>]` placeholder entirely, then rename `## [Unreleased]` to `## [<release-version>]`.

   - **It exists and has real content** — move all bullets from `## [Unreleased]` into `## [<release-version>]` (append below the existing bullets), then remove the now-empty `## [Unreleased]` heading.

2. After promotion there must be **no** `## [Unreleased]` heading remaining in any changelog — the post-release bump (§6.4) will create the next one.

3. **Version subheadings** — within the promoted `## [<release-version>]` section, every `### <heading>` must include the version number: `### Added 0.11.0`, `### Changed 0.11.0`, `### Fixed 0.11.0`, `### My Feature 0.11.0 (sub-label)`, etc. The version goes immediately after the main heading name, before any parenthetical qualifier.

4. **Merge duplicate subheadings** — a released version must never contain two `### <heading> <version>` entries with the same name. If duplicates exist (e.g., two `### Changed 0.11.0`), consolidate all their bullets into a single section. Order: Added → Changed → Fixed → custom headings.

> **Note:** If `## [Unreleased]` is absent (already promoted manually), skip this step and verify §3 checklist item 2 is satisfied.

## 3.2 Confirmation Gate — Changelog Review

**STOP. Do not proceed until the user confirms.**

Before creating any commit, tag, or push:

1. Run `git diff` to show every changelog change made in §3.1.
2. Present a summary of what was promoted (which packages had `[Unreleased]` content vs. placeholder-only) and what the resulting `## [<release-version>]` sections contain.
3. Ask the user to review and confirm before continuing to §4.

> This gate exists because changelog content is what appears on pub.dev and is hard to change after publish. The user must approve it before the commit is made.

## 4. Tagging the Repository

Tag the version you are **releasing**, not the post-bump development version:

1. Read the shared version from any `pubspec.yaml` (e.g. `0.7.0`).
2. Create the repo tag: `git tag v0.7.0`
3. Create per-package tags for each published package, e.g. `git tag vflutter_adaptive_cards_fs-0.7.0`, `git tag vflutter_adaptive_cards_host_fs-0.7.0`
4. Push tags: `git push origin v0.7.0 vflutter_adaptive_cards_fs-0.7.0 ...`

## 5. Publishing to pub.dev

After tags are pushed, publish **only** the four pub.dev library packages (in dependency order):

1. `packages/flutter_adaptive_cards_fs` — no in-repo pub dependency
2. `packages/flutter_adaptive_template_fs`
3. `packages/flutter_adaptive_charts_fs` — depends on `flutter_adaptive_cards_fs`; publish after cards is live
4. `packages/flutter_adaptive_cards_host_fs` — depends on `flutter_adaptive_cards_fs`; publish after cards is live (`lib/flutter_adaptive_cards_host_fs.dart` is the package entry barrel)

From each package directory:

```bash
cd packages/flutter_adaptive_cards_fs
flutter pub publish --dry-run   # verify first
flutter pub publish             # requires pub.dev credentials / token
```

Repeat for `flutter_adaptive_template_fs`, `flutter_adaptive_charts_fs`, and `flutter_adaptive_cards_host_fs`.

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

Set `version: <next-version>` in every file listed in §2 (all **six** packages with a `version:` field).

### 6.3 Update in-repo pub dependencies

In `packages/flutter_adaptive_charts_fs/pubspec.yaml` and `packages/flutter_adaptive_cards_host_fs/pubspec.yaml`, set:

```yaml
flutter_adaptive_cards_fs: ^<next-version>
```

Use the same `<next-version>` as the shared monorepo version (e.g. `^0.8.0`).

### 6.4 Add new `CHANGELOG.md` sections

At the **top** of each of the **six** `CHANGELOG.md` files (below the title/header), insert:

```markdown
## [<next-version>]

- no changes yet
```

Replace `<next-version>` with the new version (e.g. `## [0.8.0]`). Move or refine the placeholder bullet when features land during the cycle.

### 6.5 Verify, confirm, and commit

```bash
flutter pub get    # from repo root
flutter analyze
flutter test       # or per-package as needed
```

**STOP. Do not commit until the user confirms.**

1. Run `git diff` to show all version bumps, dependency changes, and new `## [Unreleased]` sections.
2. Present a summary of what will be committed.
3. Wait for the user to explicitly approve before running `git commit` and `git push`.

Commit with a message such as: `Bump monorepo to <next-version> for next development cycle`.

## 7. Release Cycle Summary

```text
Develop at 0.7.0  →  fill ## [0.7.0] changelogs
       ↓
Tag v0.7.0  →  publish to pub.dev
       ↓
Post-release bump  →  all versions 0.8.0, new ## [0.8.0] sections (six changelogs), charts + host dep ^0.8.0
       ↓
Develop at 0.8.0  →  repeat
```
