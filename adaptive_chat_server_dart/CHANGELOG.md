# Changelog

## [Unreleased]

- Initial Dart port of `adaptive_chat_server` (echo + Ollama responders, card
  detection, `/status` endpoint).
- Resolves standalone (no longer a root pub workspace member) — this package
  has no Flutter dependency, and workspace membership was forcing CI to
  install the full Flutter SDK just to satisfy unrelated Flutter packages
  elsewhere in the repo.
