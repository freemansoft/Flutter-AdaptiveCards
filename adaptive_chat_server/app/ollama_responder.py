"""Responder that calls a local Ollama chat model over HTTP.

Opt-in: only constructed when the server is started with `--ollama-url`
(or the `OLLAMA_URL` env var is set). Never raises to the caller — on any
failure it logs the full context (see the server console) and returns a short
diagnostic string, so a missing/unreachable/misconfigured Ollama never crashes
a request.
"""
from __future__ import annotations

import json
import logging
from pathlib import Path

import httpx

from app.card_detect import card_parse_failure_reason, try_parse_card_body
from app.responder import Reply

# uvicorn installs a handler on the "uvicorn.error" logger, so these messages
# appear in the server console when running via `python -m app` / uvicorn.
logger = logging.getLogger("uvicorn.error")

# Single source of truth for the fallback model name; the CLI (`--ollama-model`)
# and env (`OLLAMA_MODEL`) override it. qwen2.5-coder:7b is the recommended
# default: it cleared every documented card failure mode at temperature 0 and
# fits a 16 GB Mac (~4.7 GB). See the model/settings addendum in
# docs/superpowers/specs/2026-07-23-ollama-structured-json-output-design.md.
DEFAULT_OLLAMA_MODEL = "qwen2.5-coder:7b"

# Default number of prior interactions (user+assistant exchanges) replayed to
# Ollama. Bounds only the outbound prompt — the server store keeps full history.
DEFAULT_HISTORY_TURNS = 10

# Context window (in tokens) requested from Ollama via options.num_ctx. Making it
# explicit means the window is a known value we can measure prompt fill against,
# rather than a per-model default we are blind to. 16K leaves ample room for a
# multi-page card reply plus history, so Ollama does not silently drop tokens.
DEFAULT_NUM_CTX = 16384

# Values: "none" (no format constraint — prompt-only), "json" (Ollama's generic
# valid-JSON grammar), "schema" (grammar-constrained against CARD_SCHEMA_PATH).
# Default is "none": with a capable model (e.g. qwen2.5-coder:7b) at temperature
# 0, the prompt alone produces reliable card JSON, and the schema grammar adds
# latency and can distort output without measurably improving reliability.
# "schema" remains available as a safety net for weaker/other models. See
# docs/superpowers/specs/2026-07-23-ollama-structured-json-output-design.md
# (none-vs-schema addendum) for the measurements behind this default.
DEFAULT_JSON_FORMAT = "none"

# Sampling temperature sent on every Ollama request (all json_format modes).
# 0 = greedy / deterministic decoding, the single highest-leverage setting for
# minimizing malformed card JSON (see the design-doc model/settings addendum).
DEFAULT_CARD_TEMPERATURE = 0.0

# System prompt injected as the first message on every chat request. Resolved
# relative to this file (not the process cwd) so it is found no matter where the
# server is launched from; overridden by `--system-prompt-file` / the
# `OLLAMA_SYSTEM_PROMPT_FILE` env var. See README "System prompt".
DEFAULT_SYSTEM_PROMPT_PATH = Path(__file__).with_name("default_system_prompt.txt")

# Bundled schema for "schema" mode (see DEFAULT_JSON_FORMAT below), resolved
# relative to this file, not the process cwd.
CARD_SCHEMA_PATH = Path(__file__).with_name("card_schema.json")


def _load_card_schema(path: Path) -> dict | None:
    """Load and sanity-check the card-reply JSON Schema; None on any problem.

    Only a syntax/shape guard (valid JSON, has the expected top-level keys) —
    Ollama performs the actual grammar-constrained decoding against this
    schema, so this is not a full JSON-Schema-spec validation. Never raises:
    a missing, unreadable, or malformed file is logged and returns None so the
    caller can fall back to a less-strict json_format instead of crashing.
    """
    try:
        schema = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        logger.error(
            "Card schema unusable (%s: %s) at %s — falling back to "
            "json_format=none for this process.",
            type(exc).__name__,
            exc,
            path,
        )
        return None
    if not isinstance(schema, dict) or "oneOf" not in schema or "$defs" not in schema:
        logger.error(
            "Card schema at %s missing expected 'oneOf'/'$defs' keys — "
            "falling back to json_format=none for this process.",
            path,
        )
        return None
    return schema


class _DuplicateJsonKeyError(ValueError):
    """A JSON object had a repeated key.

    Legal JSON syntax, but ``json.loads`` silently keeps only the last value
    for a repeated key, silently dropping data. Observed against a real
    Ollama under schema-constrained decoding: the model sometimes re-emits an
    object property key (e.g. Carousel's ``pages``, Table's ``rows``) once
    per item instead of appending items to one array. Subclasses
    ``ValueError`` so it is caught distinctly from — and checked before — the
    existing generic ``except ValueError`` fallback in ``reply()``.
    """


def _reject_duplicate_keys(pairs: list[tuple[str, object]]) -> dict:
    """``object_pairs_hook`` for ``json.loads`` that rejects a repeated key.

    Passed to every ``json.loads`` call on model-controlled content in the
    format-guaranteed response path, so a duplicate-key object is detected
    (raises) instead of silently collapsing to its last value.
    """
    seen: set[str] = set()
    for key, _ in pairs:
        if key in seen:
            raise _DuplicateJsonKeyError(f"duplicate key {key!r}")
        seen.add(key)
    return dict(pairs)


class OllamaResponder:
    """Calls `POST {ollama_url}/api/chat` with the conversation history."""

    def __init__(
        self,
        ollama_url: str,
        model: str = DEFAULT_OLLAMA_MODEL,
        client: httpx.Client | None = None,
        system_prompt_file: str | None = None,
        history_turns: int = DEFAULT_HISTORY_TURNS,
        num_ctx: int = DEFAULT_NUM_CTX,
        json_format: str = DEFAULT_JSON_FORMAT,
    ) -> None:
        """Configure the responder.

        The system-prompt file *path* is stored (not its contents) so edits to the
        file take effect on the next request without restarting the server.
        """
        self._ollama_url = ollama_url
        self._model = model
        self._client = client or httpx.Client(timeout=60)
        self._history_turns = history_turns
        self._num_ctx = num_ctx
        # Store the path, not the content: the file is re-read on every request
        # so edits take effect without restarting the server.
        self._system_prompt_path = (
            Path(system_prompt_file)
            if system_prompt_file
            else DEFAULT_SYSTEM_PROMPT_PATH
        )
        self._json_format = json_format
        self._card_schema: dict | None = None
        if self._json_format == "schema":
            self._card_schema = _load_card_schema(CARD_SCHEMA_PATH)
            if self._card_schema is None:
                self._json_format = "none"

    def _load_system_prompt(self) -> str | None:
        """Read the active system-prompt file, or None if unusable.

        Read per request so live edits apply without a restart. A missing,
        unreadable, or empty file is not fatal — we log and return None so the
        request proceeds with no system message (never raises to the caller).
        """
        try:
            prompt = self._system_prompt_path.read_text(encoding="utf-8").strip()
        except OSError as exc:
            logger.warning(
                "System prompt file unreadable (%s: %s) at %s — sending no "
                "system message.",
                type(exc).__name__,
                exc,
                self._system_prompt_path,
            )
            return None
        if not prompt:
            logger.warning(
                "System prompt file is empty at %s — sending no system message.",
                self._system_prompt_path,
            )
            return None
        return prompt

    def _trim_history(
        self, history: list[tuple[str, str]]
    ) -> list[tuple[str, str]]:
        """Return only the last ``history_turns`` interactions to send to Ollama.

        Send-only: operates on a slice, never mutates the caller's list or the
        store. ``history`` has two entries (user, assistant) per interaction, so
        we keep ``2 * history_turns`` entries. ``history_turns <= 0`` sends none.
        """
        if self._history_turns <= 0:
            return []
        return history[-2 * self._history_turns :]

    def _log_context_fill(self, data: dict) -> None:
        """Log prompt-token fill against ``num_ctx`` in tiers.

        Ollama silently drops the oldest tokens once a prompt exceeds num_ctx, so
        this turns that invisible truncation into a signal. Uses the actual
        ``prompt_eval_count`` from the response; if absent, logs nothing (never
        raises).
        """
        prompt_tokens = data.get("prompt_eval_count")
        if not isinstance(prompt_tokens, int) or self._num_ctx <= 0:
            return
        pct = prompt_tokens / self._num_ctx
        if pct >= 0.76:
            logger.warning(
                "Ollama context near limit: prompt=%d/%d (%.0f%%) — Ollama "
                "silently drops oldest tokens above num_ctx; lower "
                "--history-turns or raise --num-ctx.",
                prompt_tokens,
                self._num_ctx,
                pct * 100,
            )
        elif pct >= 0.50:
            logger.info(
                "Ollama context filling: prompt=%d/%d (%.0f%%).",
                prompt_tokens,
                self._num_ctx,
                pct * 100,
            )

    def reply(self, text: str, history: list[tuple[str, str]]) -> Reply:
        """Send system prompt + trimmed history + this turn to Ollama, return a Reply.

        The returned ``Reply.text`` is always the raw model output (so it threads
        into conversation history), and ``card_body`` is set when the model
        answered with an Adaptive Card fragment (see ``try_parse_card_body``).
        Never raises: transport, HTTP-status, and unexpected-body failures are
        logged and returned as a short diagnostic ``text`` with ``card_body=None``.
        """
        messages: list[dict[str, str]] = []
        system_prompt = self._load_system_prompt()
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.extend(
            {"role": role, "content": content}
            for (role, content) in self._trim_history(history)
        )
        messages.append({"role": "user", "content": text})
        endpoint = f"{self._ollama_url}/api/chat"
        options: dict[str, object] = {"num_ctx": self._num_ctx}
        payload: dict[str, object] = {
            "model": self._model,
            "messages": messages,
            "stream": False,
            "options": options,
        }
        if self._json_format == "json":
            payload["format"] = "json"
        elif self._json_format == "schema":
            payload["format"] = self._card_schema
        # Deterministic, non-thinking decoding on every Ollama request. temperature
        # 0 minimizes malformed card JSON; think=False stops a thinking-capable
        # model (e.g. qwen3.5) from emitting reasoning tokens that pollute the reply
        # and inflate latency (observed ~77s -> ~10s). think=False is safely ignored
        # by non-thinking models. Applied in all json_format modes — including the
        # default "none", where these settings (not the schema grammar) are what
        # empirically make card JSON reliable (see the none-vs-schema addendum in
        # docs/superpowers/specs/2026-07-23-ollama-structured-json-output-design.md).
        options["temperature"] = DEFAULT_CARD_TEMPERATURE
        payload["think"] = False
        logger.info(
            "Ollama request: POST %s (model=%s, %d messages)",
            endpoint,
            self._model,
            len(messages),
        )

        # 1. Transport failure — never even got a response (connection refused,
        #    DNS, timeout, TLS). This is the real "unreachable" case.
        try:
            response = self._client.post(endpoint, json=payload)
        except httpx.HTTPError as exc:
            logger.error(
                "Ollama CONNECTION FAILED: %s: %s\n"
                "  endpoint=%s model=%s\n"
                "  Is `ollama serve` running and listening there? On macOS, "
                "`localhost` can resolve to IPv6 (::1) while Ollama binds IPv4 "
                "127.0.0.1 — try --ollama-url http://127.0.0.1:11434.",
                type(exc).__name__,
                exc,
                endpoint,
                self._model,
                exc_info=True,
            )
            return Reply(
                text=(
                    f"(Ollama unreachable at {self._ollama_url} — "
                    f"{type(exc).__name__}: {exc})"
                )
            )

        # 2. Reached Ollama but it returned an error status (e.g. 404 when the
        #    model isn't pulled). Connected, so NOT "unreachable".
        if response.status_code >= 400:
            body = response.text[:1000]
            logger.error(
                "Ollama HTTP %s for %s (model=%s):\n  %s\n"
                "  A 404 usually means the model isn't pulled — run "
                "`ollama pull %s`.",
                response.status_code,
                endpoint,
                self._model,
                body,
                self._model,
            )
            return Reply(
                text=(
                    f"(Ollama error HTTP {response.status_code} at "
                    f"{self._ollama_url}: {body})"
                )
            )

        # 3. 2xx but an unexpected body shape.
        try:
            data = response.json()
            content = data["message"]["content"]
        except (ValueError, KeyError, TypeError) as exc:
            logger.error(
                "Ollama response could not be parsed (%s: %s):\n  %s",
                type(exc).__name__,
                exc,
                response.text[:1000],
                exc_info=True,
            )
            return Reply(
                text=f"(Ollama returned an unexpected response: {type(exc).__name__})"
            )
        self._log_context_fill(data)

        reply_text = content
        card_body: list | None = None
        used_format_path = False
        duplicate_key_detected = False
        if self._json_format != "none":
            try:
                parsed = json.loads(content, object_pairs_hook=_reject_duplicate_keys)
            except _DuplicateJsonKeyError:
                # A repeated object key (e.g. two "pages" keys on a Carousel) is
                # legal JSON, but card_detect.py's own json.loads has the same
                # blind spot (silently keeps the last value) — falling back to
                # it here would silently reproduce the exact data loss this
                # guard exists to catch. Skip straight to "render as text"
                # instead of the generic fallback path below.
                duplicate_key_detected = True
            except ValueError:
                pass  # unexpected: format guarantee failed; fall through below
            else:
                used_format_path = True
                if isinstance(parsed, str):
                    reply_text = parsed
                else:
                    card_body = try_parse_card_body(json.dumps(parsed))
        if not used_format_path and not duplicate_key_detected:
            card_body = try_parse_card_body(content)

        # When a reply *looked like* a card (began with JSON) but could not be
        # used, surface WHY at WARNING so it is diagnosable at the default INFO
        # level — the common cause is the model emitting malformed/truncated JSON
        # for a large, deeply nested card. Plain-prose replies return None here
        # and are not warned about (they are intentional text answers). Always
        # evaluated against the raw wire `content`, not `reply_text`, so the
        # diagnosis reflects exactly what Ollama sent.
        if duplicate_key_detected:
            logger.warning(
                "Model reply had a duplicate JSON object key (model=%s, %d "
                "chars) — rendered as text instead, since a repeated key "
                "silently drops all but its last value (observed for "
                "Carousel.pages / Table.rows). Reason: duplicate key in JSON "
                "object",
                self._model,
                len(content),
            )
        elif card_body is None:
            reason = card_parse_failure_reason(content)
            if reason is not None:
                logger.warning(
                    "Model reply looked like an Adaptive Card but was not usable "
                    "(model=%s, %d chars) — rendered as text instead. Reason: %s",
                    self._model,
                    len(content),
                    reason,
                )
        # Content-level diagnostics: logged at DEBUG so they are off in normal
        # operation but available for testing without a code change. Enable DEBUG
        # logging (e.g. `uvicorn --log-level debug`, or set the "uvicorn.error"
        # logger to DEBUG) to see the verbatim model output and whether it was
        # accepted as a card — the quickest way to diagnose a reply that renders
        # as text instead of a card. logger.debug skips formatting when disabled,
        # so this costs nothing at the default INFO level.
        logger.debug(
            "Ollama content (model=%s, %d chars, detected_card=%s):\n%r",
            self._model,
            len(content),
            card_body is not None,
            content,
        )
        return Reply(text=reply_text, card_body=card_body)
