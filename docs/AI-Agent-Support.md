# AI Agent Support

This document describes how LLM agents (Cursor, Antigravity, Claude Code, and others) are configured for the Flutter-AdaptiveCards monorepo.

## Overview

AI instructions are organized in two layers:

| Layer           | Location                                | Purpose                                                                                                      |
| --------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Always-on rules | [`AGENTS.md`](../AGENTS.md)             | Project guardrails: FVM, monorepo hygiene, Riverpod patterns, linting, documentation                         |
| Task playbooks  | [`.agents/skills/`](../.agents/skills/) | Modular skills loaded when a task matches (testing, spec compliance, TDD, debugging, release engineering, …) |

Supporting files:

- [`skills-lock.json`](../skills-lock.json) — tracks vendored skills from upstream GitHub repos (source, path, content hash) for reproducible installs and updates
- [`.agents/rules/README.md`](../.agents/rules/README.md) — pointer to `AGENTS.md` and `.agents/skills/`

`AGENTS.md` is derived from the [Flutter team AI rules](https://docs.flutter.dev/ai/ai-rules), trimmed for Antigravity’s ~12K character limit, and customized for this repo (Very Good Analysis, Adaptive Cards architecture, semantic labels, localization, FVM).

---

## Skill sources

Skills in `.agents/skills/` come from four sources:

### 1. Dart team — [dart-lang/skills](https://github.com/dart-lang/skills)

General Dart development workflows (unit tests, static analysis, mocks, pattern matching, coverage, …).

### 2. Flutter team — [flutter/skills](https://github.com/flutter/skills)

Flutter app workflows (widget tests, integration tests, responsive layout, localization, routing, …).

> **Conflict note:** The `flutter-implement-json-serialization` skill teaches manual `dart:convert`. This repo uses `json_serializable` code generation — follow [`adaptive-cards-flutter-standard-practices`](../.agents/skills/adaptive-cards-flutter-standard-practices/SKILL.md) instead for model classes.

### 3. Superpowers — [obra/superpowers](https://github.com/obra/superpowers)

Agentic development methodology: brainstorming before coding, implementation plans, TDD, systematic debugging, code review, git worktrees, and subagent-driven execution.

### 4. Project-specific skills

Authored for this monorepo (Adaptive Cards spec, HostConfig theming, element registry, testing patterns, release engineering, FVM wrapper):

| Skill                                       | Focus                                            |
| ------------------------------------------- | ------------------------------------------------ |
| `adaptive-cards-dart-flutter-fvm`           | Prefix all `flutter`/`dart` commands with `fvm`  |
| `adaptive-cards-monorepo-workspace`         | Package layout and working directories           |
| `adaptive-cards-element-registry`           | Implementing new element types                   |
| `adaptive-cards-flutter-standard-practices` | Theming and JSON serialization in this repo      |
| `adaptive-cards-hostconfig-theme`           | HostConfig → Flutter theme mapping               |
| `adaptive-cards-spec-compliance`            | Microsoft Adaptive Cards spec parity             |
| `adaptive-cards-templating`                 | `flutter_adaptive_template_fs` templating engine |
| `adaptive-cards-backend-host`               | `flutter_adaptive_cards_host_fs` invoke bridge   |
| `adaptive-cards-testing`                    | Library test and golden image conventions        |
| `widgetbook-overlay-demos`                  | **Sample app:** widgetbook overlay knob demos    |
| `code-review`                               | Pre-merge quality checklist                      |
| `release-engineer`                          | Versioning, pub.dev, changelogs                  |
| `release-flutter-upgrade-sdk`               | Flutter SDK upgrade procedure                    |

Project-specific skills are **not** listed in `skills-lock.json`; edit them directly under `.agents/skills/`.

### Documentation scope

- **`docs/`** documents the four published packages under `packages/`. See [`documentation-scope.md`](documentation-scope.md).
- **`widgetbook/`** is a sample demonstration app — tag references in canonical docs as **Example (widgetbook sample)**; widgetbook-only guides must include **`widgetbook` in the filename** (e.g. [`widgetbook-overlay-demos.md`](widgetbook-overlay-demos.md)).

---

### Token usage tweaking

I (Joe) currently have `Cursor Settings --> Agents --> Start Agent Review on Commit` disabled because of token costs.

- On a recent bill. Agent review took 59.8% of my API tokens accounting for 143M of 188M API tokens used. auto (overflow) consumed 42M API tokens. Auto + Composer consumed 422M tokens during the same time period. 'auto' aggregated consumed 457M tokens in that month.

---

## Installation

All vendored skills are installed with the [`skills` CLI](https://www.npmjs.com/package/skills) (`npx skills`). The `--agent universal` flag installs into `.agents/skills/`, which Cursor, Antigravity, and other agents recognize.

Run these commands from the **repository root**.

### Dart team skills

```bash
npx skills add dart-lang/skills --skill '*' --agent universal --yes
```

Source: [github.com/dart-lang/skills](https://github.com/dart-lang/skills)

### Flutter team skills

```bash
npx skills add flutter/skills --skill '*' --agent universal --yes
```

Source: [github.com/flutter/skills](https://github.com/flutter/skills)

### Superpowers (project — shared with the repo)

```bash
npx skills add obra/superpowers --skill '*' --agent universal --yes
```

Source: [github.com/obra/superpowers](https://github.com/obra/superpowers)

This installs 14 skills (brainstorming, writing-plans, test-driven-development, systematic-debugging, …) into `.agents/skills/` and updates `skills-lock.json`.

### Superpowers (Cursor — user-level)

For skills available in **all** projects when using Cursor:

```bash
npx skills add obra/superpowers --skill '*' --agent cursor --global --yes
```

Skills are copied to `~/.agents/skills/`.

#### Optional: Cursor plugin (hooks and commands)

For automatic skill activation via Cursor hooks (recommended when using Cursor Agent):

1. Open **Agent** chat (`Cmd+L` / `Ctrl+L`).
2. Run:

   ```text
   /add-plugin superpowers
   ```

3. Start a new Agent session and verify with: `Do you have superpowers?`

Update or remove the plugin:

```text
/plugin-update superpowers
/plugin-remove superpowers
```

See [Superpowers — Install on Cursor](https://obra-superpowers.mintlify.app/installation/cursor).

---

## Updating vendored skills

From the repository root:

```bash
npx skills update
```

Or update a single upstream repo:

```bash
npx skills update dart-add-unit-test flutter-add-widget-test brainstorming
```

Review diffs under `.agents/skills/` after updating. Reconcile project-specific overrides (for example `adaptive-cards-dart-flutter-fvm` wrapping bare `flutter` commands from upstream skills).

Restore from lock file after a fresh clone:

```bash
npx skills experimental_install
```

---

## How agents use skills

1. **Always-on:** `AGENTS.md` is injected every session (FVM, naming, Riverpod document overlays, lint rules).
2. **On demand:** Agents read `SKILL.md` when the task matches the skill description (e.g. “add a widget test” → `flutter-add-widget-test`).
3. **Superpowers workflow:** For new features, Superpowers skills encourage design → plan → TDD implementation → review before merge. Start with `using-superpowers` or `brainstorming` when kicking off substantial work.

List installed skills:

```bash
npx skills list
```

---

## Related documentation

- [`AGENTS.md`](../AGENTS.md) — always-on agent rules
- [`doc/reactive-riverpod.md`](./reactive-riverpod.md) — Riverpod patterns referenced in `AGENTS.md`
- [Flutter AI rules](https://docs.flutter.dev/ai/ai-rules) — upstream `AGENTS.md` template
- [dart-lang/skills README](https://github.com/dart-lang/skills#installation)
- [flutter/skills README](https://github.com/flutter/skills#installation)
- [obra/superpowers README](https://github.com/obra/superpowers#installation)
