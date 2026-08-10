# Archived design specs

Superseded specs (moved from [`docs/superpowers/specs/`](../superpowers/specs/) after implementation) plus **historical design/proposal notes** that no longer describe current integration. **Do not use for day-to-day integration** — use the canonical guide in the right column.

| Archived spec | Canonical guide |
| --- | --- |
| `2026-06-07-backend-host-integration-design.md` | [`backend-host-integration.md`](../../backend-host-integration.md) |
| `2026-06-06-hostconfig-style-pipeline-design.md` | [`adaptive-style.md`](../../adaptive-style.md) and [`hostconfig.md`](../../hostconfig.md) |
| `Column-ColumnSet-Fill-Vertical-Height.md` | Fixed-bug history (equal column heights); current behavior in the [`flutter_adaptive_cards_fs` README status table](../../../packages/flutter_adaptive_cards_fs/README.md#implementation-status) (ColumnSet / Column) |
| `semantic-label-localization.md` | Localization proposal / findings (no code changed at authoring); semantic-label localization has since been implemented — see [`AGENTS.md`](../../../AGENTS.md) localization rules and the accessibility sections of [`form-inputs.md`](../../form-inputs.md) |
| `form-inputs-key-naming-2026-01-30.md` | Pre-2026-01-30 input key-naming notes extracted from `form-inputs.md`; current rules in [`AdaptiveWidget-Key-Generation.md`](../../AdaptiveWidget-Key-Generation.md) |
| `templating-csharp-design-samples.md` | Original C# SDK API samples that guided the Dart templating design; extracted from `adaptive-template-design.md`. Runnable Dart usage: [`flutter_adaptive_template_fs` README](../../../packages/flutter_adaptive_template_fs/README.md#usage) |
| `2026-07-18-adaptive-chat-sdui-design.md` | Original **Python** `adaptive_chat_server` SDUI design. That package was removed in favor of the Dart port; see [`adaptive_chat_server_dart/README.md`](../../../adaptive_chat_server_dart/README.md) and its [design doc](../superpowers/specs/2026-08-09-adaptive-chat-server-dart-design.md) |
| `2026-07-20-adaptive-chat-card-replies-design.md` | Python-only card-replies design; behavior ported unchanged to `adaptive_chat_server_dart` — see its README's "Card replies (display-only)" section |
| `2026-07-20-adaptive-chat-ollama-context-window-design.md` | Python-only Ollama context-window design; behavior ported unchanged to `adaptive_chat_server_dart` — see its README's "Conversation context" section |
| `2026-07-21-card-json-leaked-prefix-design.md` | Python-only fix design for a card-JSON leaked-prefix bug; same detection logic now lives in `adaptive_chat_server_dart`'s `card_detect.dart` |
| `2026-07-23-ollama-structured-json-output-design.md` | Python-only structured-output (`--json-format`) design; behavior ported unchanged to `adaptive_chat_server_dart` — see its README's "Structured output" section |
| `2026-08-03-chat-server-token-stats-design.md` | Python-only token-stats design; behavior ported unchanged to `adaptive_chat_server_dart` — see its README's "Status endpoint" section |

Remaining active specs stay under [`docs/superpowers/specs/`](../superpowers/specs/).
