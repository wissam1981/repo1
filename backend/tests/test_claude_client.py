import json
from app.claude_client import RealClaudeClient, BadAIResponseError
import pytest


class _FakeMessages:
    def __init__(self, payload: str):
        self._payload = payload

    def create(self, **kwargs):
        class _Block:
            text = self._payload
        class _Resp:
            content = [_Block()]
        return _Resp()


class _FakeAnthropic:
    def __init__(self, payload: str):
        self.messages = _FakeMessages(payload)


def test_complete_json_parses_object():
    payload = json.dumps({"clauses": ["a", "b"]})
    client = RealClaudeClient(sdk=_FakeAnthropic(payload), model="m", fast_model="m")
    result = client.complete_json("system", "user")
    assert result == {"clauses": ["a", "b"]}


def test_complete_json_strips_markdown_fence():
    payload = "```json\n{\"x\": 1}\n```"
    client = RealClaudeClient(sdk=_FakeAnthropic(payload), model="m", fast_model="m")
    assert client.complete_json("s", "u") == {"x": 1}


def test_complete_json_raises_on_garbage():
    client = RealClaudeClient(sdk=_FakeAnthropic("not json"), model="m", fast_model="m")
    with pytest.raises(BadAIResponseError):
        client.complete_json("s", "u")
