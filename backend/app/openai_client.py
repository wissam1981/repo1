import json
from typing import Any

from app.claude_client import BadAIResponseError, _strip_fence


class OpenAIClient:
    """OpenAI (GPT) implementation of the ClaudeClient protocol.

    Exposes the same ``complete_json(system, user, *, fast=False)`` interface
    used throughout the app, so it is a drop-in replacement for the Anthropic
    client. Uses Chat Completions with JSON response mode.
    """

    def __init__(self, sdk: Any, model: str, fast_model: str):
        self._sdk = sdk
        self._model = model
        self._fast_model = fast_model

    def complete_json(self, system: str, user: str, *, fast: bool = False) -> Any:
        # JSON mode requires the word "json" somewhere in the prompt.
        system_prompt = system
        if "json" not in system.lower():
            system_prompt = system + " Respond with JSON only."

        resp = self._sdk.chat.completions.create(
            model=self._fast_model if fast else self._model,
            max_tokens=4096,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user},
            ],
        )
        raw = resp.choices[0].message.content or ""
        try:
            return json.loads(_strip_fence(raw))
        except json.JSONDecodeError as exc:
            raise BadAIResponseError(f"OpenAI returned non-JSON: {raw[:200]}") from exc


def build_openai_client() -> OpenAIClient:
    import openai

    from app.config import get_settings

    settings = get_settings()
    sdk = openai.OpenAI(api_key=settings.openai_api_key)
    return OpenAIClient(
        sdk=sdk,
        model="gpt-4o",
        fast_model="gpt-4o-mini",
    )


def synthesize_speech(text: str) -> bytes:
    """Natural AI speech (OpenAI tts-1, 'nova' voice) as MP3 bytes.

    Used for word pronunciation and clause read-aloud, replacing robotic
    system voices.
    """
    import openai

    from app.config import get_settings

    settings = get_settings()
    sdk = openai.OpenAI(api_key=settings.openai_api_key)
    resp = sdk.audio.speech.create(
        model="tts-1",
        voice="nova",
        input=text,
        response_format="mp3",
    )
    return resp.content
