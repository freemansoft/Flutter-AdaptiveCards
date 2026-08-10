# Adaptive Chat Server — Ollama Context-Window Observability + History Turn-Window Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bound the conversation history sent to Ollama to the last _N_ turns and make context-window fill observable, without pruning the server's retained history.

**Architecture:** All behavior changes live in `OllamaResponder` (`adaptive_chat_server/app/ollama_responder.py`): a send-only history trim, an explicit `num_ctx` on the request, and tiered post-response token-fill logging. Two new settings (`num_ctx`, `history_turns`) are threaded through the existing CLI → env → responder plumbing. `main.py`'s history-building and `EchoResponder` are untouched.

**Tech Stack:** Python 3, FastAPI, httpx (mocked via `httpx.MockTransport` in tests), pytest, `caplog` for log assertions.

## Global Constraints

- **Trim is send-only.** The server store (`ConversationStore`) and the caller's `history` list are never mutated. Trimming rebinds a local variable inside `reply()`.
- **Never crash a request.** Every new failure mode (missing token count, bad env int, `history_turns <= 0`) degrades to a logged warning or a safe default.
- **Defaults:** `num_ctx = 4096`, `history_turns = 10`.
- **Observability tiers** (from `prompt_eval_count / num_ctx`): `>= 0.76` → `WARNING`; `>= 0.50 and < 0.76` → `INFO`; `< 0.50` → no extra line.
- **Config pattern:** CLI arg → env var → responder, mirroring `--ollama-model` / `--system-prompt-file` (env survives uvicorn `--reload`).
- **Commit gate (repo rule):** subagents implement + run tests only. They do NOT run `git commit`. The orchestrator shows each diff and commits after user confirmation. The "Commit" step in each task is an orchestrator action, gated on the user.
- **Run commands from** `adaptive_chat_server/` using the venv: `.venv/bin/python -m pytest ...`.
- No `packages/` changelog gate — this is the sample server, not a published package.

**Reference:** design spec `docs/superpowers/specs/2026-07-20-adaptive-chat-ollama-context-window-design.md`.

---

### Task 1: History turn-window trim (send-only)

**Files:**

- Modify: `adaptive_chat_server/app/ollama_responder.py`
- Test: `adaptive_chat_server/tests/test_ollama_responder.py`

**Interfaces:**

- Consumes: existing `OllamaResponder.__init__(ollama_url, model, client, system_prompt_file)` and `reply(text, history)`; the test helper `_responder(handler, system_prompt_file=None)` and `_ok_capturing_handler(captured)` already present in the test file.
- Produces: `OllamaResponder.__init__(..., history_turns: int = DEFAULT_HISTORY_TURNS)`; module constant `DEFAULT_HISTORY_TURNS = 10`; private `_trim_history(self, history: list[tuple[str, str]]) -> list[tuple[str, str]]`. `reply()` now sends only the last `history_turns` interactions.

- [ ] **Step 1: Extend the test helper to pass `history_turns`**

In `adaptive_chat_server/tests/test_ollama_responder.py`, update `_responder` to forward `history_turns` (Task 2 will add `num_ctx` to this same helper):

```python
def _responder(handler, system_prompt_file=None, history_turns=10):
    return OllamaResponder(
        OLLAMA_URL,
        model=OLLAMA_MODEL,
        client=_client(handler),
        system_prompt_file=system_prompt_file,
        history_turns=history_turns,
    )
```

- [ ] **Step 2: Write the failing tests**

Add to `adaptive_chat_server/tests/test_ollama_responder.py`:

```python
def test_reply_trims_history_to_last_n_turns(tmp_path):
    missing = tmp_path / "no_prompt.txt"  # no system message, keep body exact
    captured = {}
    history = [
        ("user", "u1"), ("assistant", "a1"),
        ("user", "u2"), ("assistant", "a2"),
        ("user", "u3"), ("assistant", "a3"),
    ]
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        history_turns=2,
    ).reply("now", history)

    # Only the last 2 exchanges survive, then the current turn.
    assert captured["body"]["messages"] == [
        {"role": "user", "content": "u2"},
        {"role": "assistant", "content": "a2"},
        {"role": "user", "content": "u3"},
        {"role": "assistant", "content": "a3"},
        {"role": "user", "content": "now"},
    ]


def test_reply_sends_no_prior_history_when_turns_zero(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    history = [("user", "u1"), ("assistant", "a1")]
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        history_turns=0,
    ).reply("now", history)

    assert captured["body"]["messages"] == [{"role": "user", "content": "now"}]


def test_reply_does_not_mutate_caller_history(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    history = [("user", "u1"), ("assistant", "a1"), ("user", "u2"), ("assistant", "a2")]
    original = list(history)
    _responder(
        _ok_capturing_handler(captured),
        system_prompt_file=str(missing),
        history_turns=1,
    ).reply("now", history)

    assert history == original  # trim is send-only
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `.venv/bin/python -m pytest tests/test_ollama_responder.py -k "trims_history or turns_zero or does_not_mutate" -v`
Expected: FAIL — `OllamaResponder.__init__() got an unexpected keyword argument 'history_turns'`.

- [ ] **Step 4: Add the constant, constructor param, and trim helper**

In `adaptive_chat_server/app/ollama_responder.py`, add the constant near `DEFAULT_OLLAMA_MODEL`:

```python
# Default number of prior interactions (user+assistant exchanges) replayed to
# Ollama. Bounds only the outbound prompt — the server store keeps full history.
DEFAULT_HISTORY_TURNS = 10
```

Add the parameter to `__init__` (after `system_prompt_file`) and store it:

```python
        system_prompt_file: str | None = None,
        history_turns: int = DEFAULT_HISTORY_TURNS,
    ) -> None:
        self._ollama_url = ollama_url
        self._model = model
        self._client = client or httpx.Client(timeout=60)
        self._history_turns = history_turns
```

(Keep the existing `self._system_prompt_path = (...)` assignment.)

Add the helper method:

```python
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
```

- [ ] **Step 5: Use the trim in `reply()`**

In `reply()`, change the history extension to trim first:

```python
        messages.extend(
            {"role": role, "content": content}
            for (role, content) in self._trim_history(history)
        )
```

- [ ] **Step 6: Run the new tests and the full suite**

Run: `.venv/bin/python -m pytest tests/test_ollama_responder.py -k "trims_history or turns_zero or does_not_mutate" -v`
Expected: PASS.

Run: `.venv/bin/python -m pytest -q`
Expected: all pass (existing 28 + 3 new).

- [ ] **Step 7: Commit (orchestrator, after user confirmation)**

```bash
git add adaptive_chat_server/app/ollama_responder.py adaptive_chat_server/tests/test_ollama_responder.py
git commit -m "feat(adaptive_chat_server): trim Ollama history to last N turns (send-only)"
```

---

### Task 2: Explicit `num_ctx` + tiered token-fill logging

**Files:**

- Modify: `adaptive_chat_server/app/ollama_responder.py`
- Test: `adaptive_chat_server/tests/test_ollama_responder.py`

**Interfaces:**

- Consumes: `OllamaResponder.__init__(..., history_turns=...)` from Task 1; the `reply()` success block that parses `response.json()`.
- Produces: `OllamaResponder.__init__(..., num_ctx: int = DEFAULT_NUM_CTX)`; module constant `DEFAULT_NUM_CTX = 4096`; private `_log_context_fill(self, data: dict) -> None`. Request payload now includes `options.num_ctx`.

- [ ] **Step 1: Add `num_ctx` to the test helper**

Update `_responder` in the test file to forward `num_ctx`:

```python
def _responder(handler, system_prompt_file=None, history_turns=10, num_ctx=4096):
    return OllamaResponder(
        OLLAMA_URL,
        model=OLLAMA_MODEL,
        client=_client(handler),
        system_prompt_file=system_prompt_file,
        history_turns=history_turns,
        num_ctx=num_ctx,
    )
```

- [ ] **Step 2: Write the failing tests**

Add a handler factory that lets a test set `prompt_eval_count`, plus the tests:

```python
def _handler_with_prompt_tokens(captured, prompt_eval_count):
    def handler(request: httpx.Request) -> httpx.Response:
        captured["body"] = json.loads(request.content)
        return httpx.Response(
            200,
            json={
                "message": {"role": "assistant", "content": "ok"},
                "prompt_eval_count": prompt_eval_count,
            },
        )

    return handler


def test_reply_sends_num_ctx_option(tmp_path):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    _responder(
        _handler_with_prompt_tokens(captured, 10),
        system_prompt_file=str(missing),
        num_ctx=2048,
    ).reply("hi", [])

    assert captured["body"]["options"] == {"num_ctx": 2048}


def test_fill_below_50pct_logs_nothing(tmp_path, caplog):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _handler_with_prompt_tokens(captured, 400),  # 40% of 1000
            system_prompt_file=str(missing),
            num_ctx=1000,
        ).reply("hi", [])
    assert "context filling" not in caplog.text
    assert "context near limit" not in caplog.text


def test_fill_between_50_and_76pct_logs_info(tmp_path, caplog):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _handler_with_prompt_tokens(captured, 600),  # 60% of 1000
            system_prompt_file=str(missing),
            num_ctx=1000,
        ).reply("hi", [])
    assert "context filling" in caplog.text
    assert "context near limit" not in caplog.text


def test_fill_at_or_above_76pct_logs_warning(tmp_path, caplog):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        _responder(
            _handler_with_prompt_tokens(captured, 800),  # 80% of 1000
            system_prompt_file=str(missing),
            num_ctx=1000,
        ).reply("hi", [])
    assert "context near limit" in caplog.text
    assert any(r.levelname == "WARNING" for r in caplog.records)


def test_fill_logging_skipped_when_prompt_eval_count_absent(tmp_path, caplog):
    missing = tmp_path / "no_prompt.txt"
    captured = {}
    with caplog.at_level(logging.INFO, logger="uvicorn.error"):
        result = _responder(
            _ok_capturing_handler(captured),  # response has no prompt_eval_count
            system_prompt_file=str(missing),
            num_ctx=1000,
        ).reply("hi", [])
    assert result == "hi from ollama"
    assert "context filling" not in caplog.text
    assert "context near limit" not in caplog.text
```

Ensure `import logging` is present at the top of the test file (add it if missing).

- [ ] **Step 3: Run tests to verify they fail**

Run: `.venv/bin/python -m pytest tests/test_ollama_responder.py -k "num_ctx or fill" -v`
Expected: FAIL — `unexpected keyword argument 'num_ctx'`.

- [ ] **Step 4: Add the constant, constructor param, and payload option**

In `adaptive_chat_server/app/ollama_responder.py`, add near `DEFAULT_HISTORY_TURNS`:

```python
# Context window (in tokens) requested from Ollama via options.num_ctx. Making it
# explicit means the window is a known value we can measure prompt fill against,
# rather than a per-model default we are blind to.
DEFAULT_NUM_CTX = 4096
```

Add the param to `__init__` (after `history_turns`) and store it:

```python
        history_turns: int = DEFAULT_HISTORY_TURNS,
        num_ctx: int = DEFAULT_NUM_CTX,
    ) -> None:
        ...
        self._history_turns = history_turns
        self._num_ctx = num_ctx
```

In `reply()`, add `options` to the payload:

```python
        payload = {
            "model": self._model,
            "messages": messages,
            "stream": False,
            "options": {"num_ctx": self._num_ctx},
        }
```

- [ ] **Step 5: Add the fill-logging helper and call it on success**

Add the method:

```python
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
```

Change the success block of `reply()` so it captures `data`, logs fill, then returns:

```python
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
            return f"(Ollama returned an unexpected response: {type(exc).__name__})"
        self._log_context_fill(data)
        return content
```

- [ ] **Step 6: Run the new tests and the full suite**

Run: `.venv/bin/python -m pytest tests/test_ollama_responder.py -k "num_ctx or fill" -v`
Expected: PASS.

Run: `.venv/bin/python -m pytest -q`
Expected: all pass.

- [ ] **Step 7: Commit (orchestrator, after user confirmation)**

```bash
git add adaptive_chat_server/app/ollama_responder.py adaptive_chat_server/tests/test_ollama_responder.py
git commit -m "feat(adaptive_chat_server): set Ollama num_ctx and log tiered context fill"
```

---

### Task 3: Config plumbing — CLI args, env parsing, startup log

**Files:**

- Modify: `adaptive_chat_server/app/main.py`
- Modify: `adaptive_chat_server/app/__main__.py`
- Test: `adaptive_chat_server/tests/test_main.py` (create if absent; otherwise add to the existing routes/build-responder test module)

**Interfaces:**

- Consumes: `DEFAULT_NUM_CTX`, `DEFAULT_HISTORY_TURNS` from `ollama_responder.py` (Tasks 1–2); existing `build_responder(ollama_url, model, system_prompt_file=None)`.
- Produces: `build_responder(..., num_ctx: int = DEFAULT_NUM_CTX, history_turns: int = DEFAULT_HISTORY_TURNS)`; module helper `_int_env(name: str, default: int) -> int` in `main.py`; CLI flags `--num-ctx`, `--history-turns` in `__main__.py`.

- [ ] **Step 1: Locate the existing build_responder test**

Run: `.venv/bin/python -m pytest --collect-only -q | grep -i "build_responder\|test_main"`
If a test module already exercises `build_responder`, add to it. Otherwise create `adaptive_chat_server/tests/test_main.py`. Note the path you will use for Step 2.

- [ ] **Step 2: Write the failing tests for `_int_env`**

In the chosen test module, add:

```python
import logging

from app.main import _int_env


def test_int_env_returns_default_when_unset(monkeypatch):
    monkeypatch.delenv("SOME_INT", raising=False)
    assert _int_env("SOME_INT", 4096) == 4096


def test_int_env_parses_value(monkeypatch):
    monkeypatch.setenv("SOME_INT", "2048")
    assert _int_env("SOME_INT", 4096) == 2048


def test_int_env_falls_back_and_warns_on_bad_value(monkeypatch, caplog):
    monkeypatch.setenv("SOME_INT", "not-a-number")
    with caplog.at_level(logging.WARNING, logger="uvicorn.error"):
        assert _int_env("SOME_INT", 4096) == 4096
    assert "SOME_INT" in caplog.text
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `.venv/bin/python -m pytest <path-from-step-1> -k int_env -v`
Expected: FAIL — `ImportError: cannot import name '_int_env'`.

- [ ] **Step 4: Add `_int_env` and thread the settings through `build_responder`**

In `adaptive_chat_server/app/main.py`, extend the import:

```python
from app.ollama_responder import (
    DEFAULT_HISTORY_TURNS,
    DEFAULT_NUM_CTX,
    DEFAULT_OLLAMA_MODEL,
    OllamaResponder,
)
```

Add the helper (near the top, after `logger` is defined):

```python
def _int_env(name: str, default: int) -> int:
    """Read an int env var, falling back to ``default`` on absence or bad value.

    Never raises — a malformed value logs a warning and uses the default so a
    typo in configuration cannot crash the server at import time.
    """
    raw = os.environ.get(name)
    if raw is None:
        return default
    try:
        return int(raw)
    except ValueError:
        logger.warning("Invalid %s=%r; using default %d.", name, raw, default)
        return default
```

Extend `build_responder`:

```python
def build_responder(
    ollama_url: str | None,
    model: str,
    system_prompt_file: str | None = None,
    num_ctx: int = DEFAULT_NUM_CTX,
    history_turns: int = DEFAULT_HISTORY_TURNS,
) -> Responder:
    """Selects the responder for this process: Ollama if a URL is set, else echo."""
    if ollama_url:
        logger.info(
            "Responder: OllamaResponder (url=%s, model=%s, system_prompt=%s, "
            "num_ctx=%d, history_turns=%d)",
            ollama_url,
            model,
            system_prompt_file or "default",
            num_ctx,
            history_turns,
        )
        return OllamaResponder(
            ollama_url,
            model,
            system_prompt_file=system_prompt_file,
            num_ctx=num_ctx,
            history_turns=history_turns,
        )
    logger.info("Responder: EchoResponder (no --ollama-url / OLLAMA_URL set)")
    return EchoResponder()
```

Update the module-level `responder = build_responder(...)` call to read env:

```python
responder = build_responder(
    os.environ.get("OLLAMA_URL"),
    os.environ.get("OLLAMA_MODEL", DEFAULT_OLLAMA_MODEL),
    os.environ.get("OLLAMA_SYSTEM_PROMPT_FILE"),
    num_ctx=_int_env("OLLAMA_NUM_CTX", DEFAULT_NUM_CTX),
    history_turns=_int_env("OLLAMA_HISTORY_TURNS", DEFAULT_HISTORY_TURNS),
)
```

- [ ] **Step 5: Add CLI flags in `__main__.py`**

In `adaptive_chat_server/app/__main__.py`, extend the import:

```python
from app.ollama_responder import (
    DEFAULT_HISTORY_TURNS,
    DEFAULT_NUM_CTX,
    DEFAULT_OLLAMA_MODEL,
)
```

Add the arguments (after `--system-prompt-file`):

```python
    parser.add_argument(
        "--num-ctx",
        type=int,
        default=DEFAULT_NUM_CTX,
        help=f"Ollama context window in tokens (default: {DEFAULT_NUM_CTX}). "
        "Sent as options.num_ctx; prompt fill is logged against it.",
    )
    parser.add_argument(
        "--history-turns",
        type=int,
        default=DEFAULT_HISTORY_TURNS,
        help=f"Number of prior exchanges replayed to Ollama (default: "
        f"{DEFAULT_HISTORY_TURNS}). Bounds only the outbound prompt; the server "
        "keeps full history.",
    )
```

Bridge them to env (after the existing env assignments):

```python
    os.environ["OLLAMA_NUM_CTX"] = str(args.num_ctx)
    os.environ["OLLAMA_HISTORY_TURNS"] = str(args.history_turns)
```

- [ ] **Step 6: Run the new tests and the full suite**

Run: `.venv/bin/python -m pytest <path-from-step-1> -k int_env -v`
Expected: PASS.

Run: `.venv/bin/python -m pytest -q`
Expected: all pass.

- [ ] **Step 7: Commit (orchestrator, after user confirmation)**

```bash
git add adaptive_chat_server/app/main.py adaptive_chat_server/app/__main__.py adaptive_chat_server/tests/
git commit -m "feat(adaptive_chat_server): --num-ctx and --history-turns CLI/env knobs"
```

---

### Task 4: Documentation — README

**Files:**

- Modify: `adaptive_chat_server/README.md`

**Interfaces:**

- Consumes: behavior from Tasks 1–3 (the trim, `num_ctx`, tiers, and the two knobs).
- Produces: no code; documentation only.

- [ ] **Step 1: Revise the "Conversation context" subsection**

In `adaptive_chat_server/README.md`, replace the **"No truncation."** paragraph in the **Conversation context** subsection with:

```markdown
**Retained in full; trimmed only on send.** The store keeps the **entire**
conversation (durable log + idempotent replay). What is bounded is only the
prompt **sent to Ollama**: `OllamaResponder` replays just the last
`--history-turns` exchanges (default 10). Nothing is pruned from the store, so
raising `--history-turns` or `--num-ctx` later needs no data migration.

**Context-fill logging.** The server sends an explicit `options.num_ctx`
(default 4096) and, after each reply, logs the actual prompt tokens
(`prompt_eval_count`) against that window: an `INFO` line at ≥ 50% fill and a
`WARNING` at ≥ 76% (leaving headroom for the generated reply). This surfaces the
otherwise-silent truncation Ollama performs once a prompt exceeds `num_ctx`.
(`EchoResponder` ignores history entirely — it only echoes the current turn.)
```

- [ ] **Step 2: Document the knobs in the Ollama section**

In the **Ollama (optional)** section, after the `--system-prompt-file` guidance, add:

````markdown
**Context window & history.** Two knobs bound and observe the prompt sent to
Ollama (both also read from `OLLAMA_NUM_CTX` / `OLLAMA_HISTORY_TURNS`):

```bash
.venv/bin/python -m app --ollama-url http://127.0.0.1:11434 \
  --num-ctx 4096 --history-turns 10
```
````

- `--num-ctx` (default 4096) — context window sent as `options.num_ctx`. Prompt
  fill is logged against it (INFO ≥ 50%, WARNING ≥ 76%). Ollama silently drops
  the oldest tokens once a prompt exceeds `num_ctx`; the warning surfaces that.
- `--history-turns` (default 10) — how many prior exchanges are replayed to the
  model. Bounds only the outbound prompt; the server retains full history.

```

```

- [ ] **Step 3: Verify the docs render and cross-check values**

Confirm the README still reads coherently and every number matches the code: `num_ctx` default **4096**, `history_turns` default **10**, tiers **50% / 76%**. No test to run (docs only).

- [ ] **Step 4: Commit (orchestrator, after user confirmation)**

```bash
git add adaptive_chat_server/README.md
git commit -m "docs(adaptive_chat_server): document num_ctx fill logging and history-turns"
```

---

## Final Task: Full verification

- [ ] **Step 1: Run the full server suite**

Run (from `adaptive_chat_server/`): `.venv/bin/python -m pytest -v`
Expected: all pass — the original 28 plus the ~11 new tests (Task 1: 3, Task 2: 5, Task 3: 3). No Dart/Flutter changes, so the monorepo `fvm` suites are unaffected.

- [ ] **Step 2: Sanity-check the spec is fully covered**

Confirm against `docs/superpowers/specs/2026-07-20-adaptive-chat-ollama-context-window-design.md`: send-only trim ✓, retain-all store ✓, `num_ctx` explicit ✓, tiered fill logging ✓, both CLI+env knobs ✓, error/edge handling (`history_turns<=0`, missing `prompt_eval_count`, bad env int) ✓, README updated ✓.

- [ ] **Step 3: Invoke `superpowers:verification-before-completion`**

Paste the pytest output (exit code + pass count) before claiming completion.
