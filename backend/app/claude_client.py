import json
from typing import Any, Protocol


class BadAIResponseError(ValueError):
    pass


class ClaudeClient(Protocol):
    def complete_json(self, system: str, user: str, *, fast: bool = False) -> Any: ...


def _strip_fence(text: str) -> str:
    t = text.strip()
    if t.startswith("```"):
        t = t.split("\n", 1)[1] if "\n" in t else t
        if t.endswith("```"):
            t = t[: -3]
    return t.strip()


class RealClaudeClient:
    def __init__(self, sdk: Any, model: str, fast_model: str):
        self._sdk = sdk
        self._model = model
        self._fast_model = fast_model

    def complete_json(self, system: str, user: str, *, fast: bool = False) -> Any:
        resp = self._sdk.messages.create(
            model=self._fast_model if fast else self._model,
            max_tokens=4096,
            system=system,
            messages=[{"role": "user", "content": user}],
        )
        raw = "".join(block.text for block in resp.content)
        try:
            return json.loads(_strip_fence(raw))
        except json.JSONDecodeError as exc:
            raise BadAIResponseError(f"Claude returned non-JSON: {raw[:200]}") from exc


def build_default_client() -> RealClaudeClient:
    import anthropic
    from app.config import get_settings

    settings = get_settings()
    sdk = anthropic.Anthropic(api_key=settings.anthropic_api_key)
    return RealClaudeClient(
        sdk=sdk,
        model="claude-opus-4-6",
        fast_model="claude-haiku-4-5",
    )
