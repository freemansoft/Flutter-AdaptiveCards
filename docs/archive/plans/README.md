# Archived implementation plans

Superseded, duplicate, or fully-implemented plans moved here from [`docs/plans/`](../../plans/) and [`docs/superpowers/plans/`](../../superpowers/plans/) for historical reference. **Do not execute** — use the canonical replacement in the right column below (older entries also carry a status banner inside the file itself).

| Archived file | Canonical replacement |
| --- | --- |
| `2026-05-31-reactive_riverpod_in_library_2c717ed6.plan.md` | [`2026-05-31-reactive_riverpod_in_flutter_adaptive_cards_fs_d78f1610.plan.md`](../../plans/2026-05-31-reactive_riverpod_in_flutter_adaptive_cards_fs_d78f1610.plan.md) |
| `2026-01-26-implement_isvisible_feature_066e549a.plan.md` | [`2026-01-27-implement_isvisible_feature_875ea9e9.plan.md`](../../plans/2026-01-27-implement_isvisible_feature_875ea9e9.plan.md) — see also [`reactive-riverpod.md`](../../reactive-riverpod.md#visibility-isvisible) |
| `2026-06-02-overlay_test_coverage_skill_f45d8c5a.plan.md` | [`2026-06-01-overlay_test_coverage_bd9b10a4.plan.md`](../../plans/2026-06-01-overlay_test_coverage_bd9b10a4.plan.md) and [`reactive-riverpod.md`](../../reactive-riverpod.md#overlay-test-coverage) |
| `2026-06-03-statehaserror_vs_isinvalid_d84e66e6.plan.md` | [`2026-06-03-statehaserror_vs_isinvalid_ae92fdbe.plan.md`](../../plans/2026-06-03-statehaserror_vs_isinvalid_ae92fdbe.plan.md) (implemented unified overlay validation) |
| `2026-07-18-adaptive-chat-sdui.md` | Python `adaptive_chat_server` implementation plan; package removed in favor of the Dart port — see [`adaptive_chat_server_dart/README.md`](../../../adaptive_chat_server_dart/README.md) |
| `2026-07-20-adaptive-chat-card-replies.md` | Python-only; feature ported unchanged to `adaptive_chat_server_dart` |
| `2026-07-20-adaptive-chat-ollama-context-window.md` | Python-only; feature ported unchanged to `adaptive_chat_server_dart` |
| `2026-07-21-card-json-leaked-prefix.md` | Python-only; fix ported unchanged to `adaptive_chat_server_dart`'s `card_detect.dart` |
| `2026-07-23-ollama-structured-json-output.md` | Python-only; feature ported unchanged to `adaptive_chat_server_dart` |
| `2026-08-03-chat-server-token-stats.md` | Python-only; feature ported unchanged to `adaptive_chat_server_dart` |
| `2026-08-09-adaptive-chat-server-dart.md` | Implemented. Build plan for the Dart port, written while the Python server still existed — its "behavior source of truth" references to `adaptive_chat_server/app/*.py` point at deleted files. Current usage: [`adaptive_chat_server_dart/README.md`](../../../adaptive_chat_server_dart/README.md); design rationale: [`2026-08-09-adaptive-chat-server-dart-design.md`](../../superpowers/specs/2026-08-09-adaptive-chat-server-dart-design.md) |
