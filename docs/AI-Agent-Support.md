---
doc_type: explanation
---

# AI Agent Support

**Claude Code is the only supported agent.** This document describes how it is configured for the Flutter-AdaptiveCards monorepo. For the install / update commands, see [ai-agent-skills-install.md](ai-agent-skills-install.md).

Cursor, Antigravity, and Copilot were supported until August 2026. The `.agents` → `.claude` symlink, the `scripts/setup-claude.sh`/`.ps1` scripts, the `folderOpen` VS Code task, and `.cursor/settings.json` existed only to feed those agents, and were removed with them. Nothing in the repo is arranged for a second agent now; adding one back means re-creating that bridge.

## Overview

AI instructions are organized in two layers:

| Layer           | Location                                | Purpose                                                                                                                                                                             |
| --------------- | --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Always-on rules | [`AGENTS.md`](../AGENTS.md)             | Project guardrails: FVM, monorepo hygiene, Riverpod patterns, linting, documentation                                                                                                |
| Always-on rules | [`CLAUDE.md`](../CLAUDE.md)             | Link to `AGENTS.md` to support the same guardrails. Claude Code reads `CLAUDE.md`, not `AGENTS.md`                                                                                  |
| Task playbooks  | [`.claude/skills/`](../.claude/skills/) | Project-authored skills loaded when a task matches (spec compliance, HostConfig theming, element registry, testing, release engineering, …). Claude Code reads this directly.       |
| Task playbooks  | Claude Code plugins                     | Dart/Flutter team skills, Superpowers, and skill-creator. Installed from marketplaces declared in [`.claude/settings.json`](../.claude/settings.json) — not checked into this repo. |

Supporting files:

- [`.claude/settings.json`](../.claude/settings.json) — declares the plugin marketplaces and enabled plugins at project scope, plus the `SessionStart` hooks that install them
- [`.claude/rules/README.md`](../.claude/rules/README.md) — pointer to `AGENTS.md` and `.claude/skills/`

`AGENTS.md` is derived from the [Flutter team AI rules](https://docs.flutter.dev/ai/ai-rules) and customized for this repo (Very Good Analysis, Adaptive Cards architecture, semantic labels, localization, FVM). `CLAUDE.md` has an internal link to `AGENTS.md`

---

## Skill sources

Skills come from two places: the `.claude/skills/` directory in this repo, and Claude Code plugins installed from external marketplaces.

### 1. Dart and Flutter teams — the `dart-flutter` plugin

The Dart and Flutter teams publish their skills as a single official Claude Code plugin from [`flutter/agent-plugins`](https://github.com/flutter/agent-plugins). It carries 22 skills — 12 `dart-*` (unit tests, static analysis, mocks, pattern matching, coverage, FFI, …) and 10 `flutter-*` (widget tests, integration tests, responsive layout, localization, routing, …) — plus an MCP server entry for `dart mcp-server`.

These are **not** checked into this repo. See [the plugin section below](#dart-and-flutter-skills--the-dart-flutter-plugin-not-vendored).

> **Serialization note:** Models here are **hand-written** (`fromJson`/`toJson` factories, no `json_serializable` code-gen). The generic `flutter-implement-json-serialization` skill's manual `dart:convert` approach is directionally right, but follow this repo's conventions in [`adaptive-cards-flutter-standard-practices`](../.claude/skills/adaptive-cards-flutter-standard-practices/SKILL.md) for model classes.

### 2. Project-specific skills

Authored for this monorepo (Adaptive Cards spec, HostConfig theming, element registry, testing patterns, release engineering, FVM wrapper):

| Skill                                        | Focus                                              |
| -------------------------------------------- | -------------------------------------------------- |
| `adaptive-cards-dart-flutter-fvm`            | Prefix all `flutter`/`dart` commands with `fvm`    |
| `adaptive-cards-monorepo-workspace`          | Package layout and working directories             |
| `adaptive-cards-element-registry`            | Implementing new element types                     |
| `adaptive-cards-accessibility`               | Semantics contract for elements and inputs         |
| `adaptive-cards-localization`                | Who owns which strings; the `AdaptiveStrings` seam |
| `adaptive-cards-chat-prompt-tuning`          | Ollama card-reply diagnosis in the chat server     |
| `adaptive-cards-flutter-standard-practices`  | Hand-written serialization + theming divergences   |
| `adaptive-cards-hostconfig-theme`            | HostConfig → Flutter theme mapping                 |
| `adaptive-cards-spec-compliance`             | Microsoft Adaptive Cards spec parity               |
| `adaptive-cards-templating`                  | `flutter_adaptive_template_fs` templating engine   |
| `adaptive-cards-backend-host`                | `flutter_adaptive_cards_host_fs` invoke bridge     |
| `adaptive-cards-testing`                     | Library test and golden image conventions          |
| `adaptive-cards-diataxis-docs`               | Diátaxis doc-mode classification/audit             |
| `adaptive-cards-public-api-docs`             | Public `///` API doc standard (why/how)            |
| `adaptive-cards-widgetbook-overlay-demos`    | **Sample app:** widgetbook overlay knob demos      |
| `adaptive-cards-code-review`                 | Pre-merge quality checklist                        |
| `adaptive-cards-release-engineer`            | Versioning, pub.dev, changelogs                    |
| `adaptive-cards-release-flutter-upgrade-sdk` | Flutter SDK upgrade procedure                      |

These are the only skills checked into this repo. Edit them directly under `.claude/skills/`.

### Documentation scope

- **`docs/`** documents the four published packages under `packages/`. See [`documentation-scope.md`](documentation-scope.md).
- **`widgetbook/`** is a sample demonstration app — tag references in canonical docs as **Example (widgetbook sample)**; widgetbook-only guides must include **`widgetbook` in the filename** (e.g. [`widgetbook-overlay-demos.md`](widgetbook-overlay-demos.md)).

---

## Dart and Flutter skills — the `dart-flutter` plugin (not vendored)

The Dart and Flutter team skills were vendored into `.claude/skills/` and tracked in a `skills-lock.json` until the teams shipped them as an official Claude Code plugin. This repo now consumes the plugin instead.

The marketplace and plugin are both named `dart-flutter`, published from [`flutter/agent-plugins`](https://github.com/flutter/agent-plugins) and declared at project scope in [`.claude/settings.json`](../.claude/settings.json):

```json
{
  "enabledPlugins": {
    "dart-flutter@dart-flutter": true
  },
  "extraKnownMarketplaces": {
    "dart-flutter": {
      "source": { "source": "github", "repo": "flutter/agent-plugins" }
    }
  }
}
```

A `SessionStart` hook in the same file runs `claude plugin marketplace add` and `claude plugin install` so a fresh clone picks it up.

### What changed

The plugin is a superset of what was vendored. Every one of the 19 removed skills is in it, plus `dart-setup-ffi-assets`, `dart-use-ffigen`, and `dart-use-primary-constructors`. Two other things came along:

- **The `flutter/skills` repo is now `flutter/agent-plugins`.** GitHub redirects the old URL. `dart-lang/skills` still exists and still publishes the `dart-*` skills separately, but the plugin already carries them.
- **An MCP server.** The plugin's `.mcp.json` registers `dart-mcp-server`, launched as `dart mcp-server`.

### Two caveats

- **The MCP entry invokes a bare `dart`.** This repo pins its SDK through FVM, so whichever `dart` is first on `PATH` is what the MCP server runs — not necessarily the pinned SDK. Treat MCP-server output as advisory when SDK version matters, and run the authoritative commands through `fvm` yourself.
- **Rules are not bundled.** Claude Code plugins cannot ship rules files, so the `rules/` directory in `flutter/agent-plugins` does not come along. That is not a gap here: [`AGENTS.md`](../AGENTS.md) already carries this repo's guardrails, and it was derived from the same [Flutter AI rules](https://docs.flutter.dev/ai/ai-rules).

### Do not vendor these back

Copying the plugin's skills into `.claude/skills/` puts a second copy in front of Claude Code alongside the plugin, so every session loads and pays for both. That duplication is what removing the vendored copies fixed. If you want these skills in some other tool, install them at **user level** — see [ai-agent-skills-install.md](ai-agent-skills-install.md).

---

## Superpowers — Claude Code plugin (not vendored)

[Superpowers](https://github.com/obra/superpowers) supplies the agentic development methodology: brainstorming before coding, implementation plans, TDD, systematic debugging, code review, git worktrees, and subagent-driven execution.

It is **not** vendored into `.claude/skills/`. It is installed as a Claude Code plugin, enabled for this project in [`.claude/settings.json`](../.claude/settings.json):

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true
  }
}
```

Because it is enabled at **project scope**, Claude Code prompts each collaborator to install it the first time they trust the repository folder — no manual setup, but also no silent install (plugins can execute arbitrary code). If it has not been installed yet, Claude Code reports the plugin as not installed and prints the `claude plugin install` command to run.

One consequence worth remembering: **skills are namespaced.** Invoke `superpowers:brainstorming`, not `brainstorming`.

Rationale for un-vendoring: the vendored copies drifted out of date against upstream and were loaded _alongside_ the plugin, so every session paid for both. The same reasoning applies to the [`dart-flutter` plugin](#dart-and-flutter-skills--the-dart-flutter-plugin-not-vendored).

---

## Installing and updating skills

Install commands (the `dart-flutter` plugin, the Superpowers and skill-creator plugins, and
user-level skills for non-Claude agents) and the update commands live in the how-to companion:
[ai-agent-skills-install.md](ai-agent-skills-install.md).

---

## How agents use skills

1. **Always-on:** `AGENTS.md` is injected every session (FVM, naming, Riverpod document overlays, lint rules).
2. **On demand:** Agents read `SKILL.md` when the task matches the skill description (e.g. “add a widget test” → `flutter-add-widget-test`, from the `dart-flutter` plugin).
3. **Superpowers workflow:** For new features, Superpowers skills encourage design → plan → TDD implementation → review before merge. Start with `superpowers:brainstorming` when kicking off substantial work. These come from the [Claude Code plugin](#superpowers--claude-code-plugin-not-vendored), so they are namespaced and available in Claude Code only.

List what Claude Code has loaded:

```bash
claude plugin list
claude plugin marketplace list
```

---

## Related documentation

- [`AGENTS.md`](../AGENTS.md) — always-on agent rules
- [`doc/reactive-riverpod.md`](./reactive-riverpod.md) — Riverpod patterns referenced in `AGENTS.md`
- [Flutter AI rules](https://docs.flutter.dev/ai/ai-rules) — upstream `AGENTS.md` template
- [Get started developing with AI](https://docs.flutter.dev/ai/get-started) — official plugin install instructions
- [flutter/agent-plugins README](https://github.com/flutter/agent-plugins#readme) — the `dart-flutter` plugin
- [dart-lang/skills README](https://github.com/dart-lang/skills#installation) — `dart-*` skills outside the plugin
- [obra/superpowers README](https://github.com/obra/superpowers#installation)
