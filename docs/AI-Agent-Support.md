---
doc_type: explanation
---

# AI Agent Support

This document describes how LLM agents (Cursor, Antigravity, Claude Code, and others) are configured for the Flutter-AdaptiveCards monorepo. For the install / update commands, see [ai-agent-skills-install.md](ai-agent-skills-install.md).

## Overview

AI instructions are organized in two layers:

| Layer           | Location                                | Purpose                                                                                                      |
| --------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Always-on rules | [`AGENTS.md`](../AGENTS.md)             | Project guardrails: FVM, monorepo hygiene, Riverpod patterns, linting, documentation                         |
| Always-on rules | [`CLAUDE.md`](../CLAUDE.md)             | Link to `Agents.md` to support the same guardrails. Claude doesn't support `AGENTS.md`                       |
| Task playbooks  | [`.agents/skills/`](../.agents/skills/) | Modular skills loaded when a task matches (testing, spec compliance, TDD, debugging, release engineering, …) |
| Task playbooks  | [`.claude/skills`](../.claude/skills/)  | Copied from `.agents/skills/` by a vscode tasks. Users can manually copy with a provided script.             |

Supporting files:

- [`skills-lock.json`](../skills-lock.json) — tracks vendored skills from upstream GitHub repos (source, path, content hash) for reproducible installs and updates
- [`.agents/rules/README.md`](../.agents/rules/README.md) — pointer to `AGENTS.md` and `.agents/skills/`

`AGENTS.md` is derived from the [Flutter team AI rules](https://docs.flutter.dev/ai/ai-rules), trimmed for Antigravity’s ~12K character limit, and customized for this repo (Very Good Analysis, Adaptive Cards architecture, semantic labels, localization, FVM). `CLAUDE.md` has an internal link to `AGENTS.md`

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

| Skill                                        | Focus                                            |
| -------------------------------------------- | ------------------------------------------------ |
| `adaptive-cards-dart-flutter-fvm`            | Prefix all `flutter`/`dart` commands with `fvm`  |
| `adaptive-cards-monorepo-workspace`          | Package layout and working directories           |
| `adaptive-cards-element-registry`            | Implementing new element types                   |
| `adaptive-cards-flutter-standard-practices`  | Theming and JSON serialization in this repo      |
| `adaptive-cards-hostconfig-theme`            | HostConfig → Flutter theme mapping               |
| `adaptive-cards-spec-compliance`             | Microsoft Adaptive Cards spec parity             |
| `adaptive-cards-templating`                  | `flutter_adaptive_template_fs` templating engine |
| `adaptive-cards-backend-host`                | `flutter_adaptive_cards_host_fs` invoke bridge   |
| `adaptive-cards-testing`                     | Library test and golden image conventions        |
| `adaptive-cards-diataxis-docs`               | Diátaxis doc-mode classification/audit           |
| `adaptive-cards-public-api-docs`             | Public `///` API doc standard (why/how)          |
| `adaptive-cards-widgetbook-overlay-demos`    | **Sample app:** widgetbook overlay knob demos    |
| `adaptive-cards-code-review`                 | Pre-merge quality checklist                      |
| `adaptive-cards-release-engineer`            | Versioning, pub.dev, changelogs                  |
| `adaptive-cards-release-flutter-upgrade-sdk` | Flutter SDK upgrade procedure                    |

Project-specific skills are **not** listed in `skills-lock.json`; edit them directly under `.agents/skills/`.

### Documentation scope

- **`docs/`** documents the four published packages under `packages/`. See [`documentation-scope.md`](documentation-scope.md).
- **`widgetbook/`** is a sample demonstration app — tag references in canonical docs as **Example (widgetbook sample)**; widgetbook-only guides must include **`widgetbook` in the filename** (e.g. [`widgetbook-overlay-demos.md`](widgetbook-overlay-demos.md)).

---

### Token usage tweaking

#### Cursor

- I (Joe) currently have `Cursor Settings --> Agents --> Start Agent Review on Commit` disabled because of token costs.

## Installing and updating skills

Install commands (Dart / Flutter / Superpowers, project and user-level, plus the optional Cursor
plugin) and the update / restore-from-lock commands live in the how-to companion:
[ai-agent-skills-install.md](ai-agent-skills-install.md).

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
