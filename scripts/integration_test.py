#!/usr/bin/env python3
"""Integration test for the AI Gateway.

Tests Azure OpenAI backend connectivity and (optionally) the LiteLLM gateway.

Required env vars:
  AZURE_OPENAI_ENDPOINT        - e.g. https://my-resource.cognitiveservices.azure.com
  AZURE_OPENAI_API_KEY         - Azure OpenAI subscription key

Optional env vars:
  AZURE_OPENAI_EMBEDDING_DEPLOYMENT - Embedding deployment name (default: text-embedding-3-large)
  AZURE_OPENAI_API_VERSION          - API version (default: 2024-02-01)
  AZURE_OPENAI_CODEX_MODEL          - Codex/responses model (default: gpt-5.3-codex)
  AZURE_OPENAI_CODEX_API_VERSION    - Codex API version (default: 2025-04-01-preview)
  GATEWAY_URL                       - LiteLLM gateway URL (skip gateway tests if unset)
  AIGATEWAY_KEY                     - Gateway auth key (required if GATEWAY_URL is set)

Usage:
  # Test Azure OpenAI backend only
  export AZURE_OPENAI_ENDPOINT=https://...
  export AZURE_OPENAI_API_KEY=...
  python3 scripts/integration_test.py

  # Test backend + gateway
  export GATEWAY_URL=https://...azurecontainerapps.io
  export AIGATEWAY_KEY=...
  python3 scripts/integration_test.py
"""
import json
import os
import sys
from pathlib import Path
from urllib import error, request


def load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        raw = line.strip()
        if not raw or raw.startswith("#") or "=" not in raw:
            continue
        key, value = raw.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def http_request(method: str, url: str, headers: dict, payload: dict | None = None):
    body = None
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = request.Request(url=url, method=method, data=body, headers=headers)
    try:
        with request.urlopen(req, timeout=30) as resp:
            text = resp.read().decode("utf-8", errors="replace")
            try:
                return resp.status, json.loads(text)
            except json.JSONDecodeError:
                return resp.status, {"raw": text}
    except error.HTTPError as exc:
        text = exc.read().decode("utf-8", errors="replace")
        try:
            data = json.loads(text)
        except json.JSONDecodeError:
            data = {"raw": text}
        return exc.code, data
    except Exception as exc:  # noqa: BLE001
        return 0, {"error": str(exc)}


def get_message(data: dict) -> str:
    if not isinstance(data, dict):
        return str(data)
    if "error" in data:
        err = data["error"]
        if isinstance(err, dict):
            return str(err.get("message") or err)
        return str(err)
    return str(data)


class TestResult:
    def __init__(self, name: str, passed: bool, detail: str = ""):
        self.name = name
        self.passed = passed
        self.detail = detail


def test_aoai_deployments(endpoint: str, api_key: str) -> TestResult:
    """List Azure OpenAI deployments."""
    url = f"{endpoint}/openai/deployments?api-version=2024-02-01"
    code, data = http_request("GET", url, {"api-key": api_key})
    if 200 <= code < 300 and isinstance(data, dict):
        items = data.get("data") or data.get("value") or []
        names = []
        for item in items:
            if isinstance(item, dict):
                name = item.get("id") or item.get("name") or "?"
                model = item.get("model", "?")
                if isinstance(model, dict):
                    model = model.get("name", "?")
                names.append(f"{name} (model={model})")
        return TestResult(
            "AOAI list deployments",
            True,
            f"HTTP {code}, {len(names)} deployments: {', '.join(names[:10])}" if names else f"HTTP {code}, 0 deployments",
        )
    return TestResult("AOAI list deployments", False, f"HTTP {code}: {get_message(data)}")


def test_aoai_embedding(endpoint: str, api_key: str, deployment: str, api_version: str) -> TestResult:
    """Test embedding endpoint directly against Azure OpenAI."""
    url = f"{endpoint}/openai/deployments/{deployment}/embeddings?api-version={api_version}"
    code, data = http_request("POST", url, {"api-key": api_key}, {"input": "integration test"})
    if 200 <= code < 300:
        try:
            dim = len(data["data"][0]["embedding"])
            return TestResult(f"AOAI embedding ({deployment})", True, f"HTTP {code}, dimension={dim}")
        except (KeyError, IndexError, TypeError):
            return TestResult(f"AOAI embedding ({deployment})", True, f"HTTP {code}, response OK but unexpected shape")
    return TestResult(f"AOAI embedding ({deployment})", False, f"HTTP {code}: {get_message(data)}")


def test_aoai_chat(endpoint: str, api_key: str, model: str, api_version: str) -> TestResult:
    """Test chat completions endpoint directly against Azure OpenAI."""
    url = f"{endpoint}/openai/deployments/{model}/chat/completions?api-version={api_version}"
    payload = {"messages": [{"role": "user", "content": "Respond with exactly: OK"}], "max_tokens": 5}
    code, data = http_request("POST", url, {"api-key": api_key}, payload)
    if 200 <= code < 300:
        try:
            content = data["choices"][0]["message"]["content"]
            return TestResult(f"AOAI chat ({model})", True, f"HTTP {code}, response: {content[:50]}")
        except (KeyError, IndexError, TypeError):
            return TestResult(f"AOAI chat ({model})", True, f"HTTP {code}, response OK")
    return TestResult(f"AOAI chat ({model})", False, f"HTTP {code}: {get_message(data)}")


def test_gateway_models(gateway_url: str, auth_header: str) -> TestResult:
    """Test GET /v1/models on the LiteLLM gateway."""
    url = f"{gateway_url}/v1/models"
    code, data = http_request("GET", url, {"Authorization": auth_header})
    if 200 <= code < 300 and isinstance(data, dict):
        models = [item.get("id", "?") for item in data.get("data", []) if isinstance(item, dict)]
        return TestResult("Gateway /v1/models", True, f"HTTP {code}, models: {', '.join(models[:10])}")
    return TestResult("Gateway /v1/models", False, f"HTTP {code}: {get_message(data)}")


def test_gateway_embeddings(gateway_url: str, auth_header: str, model: str) -> TestResult:
    """Test POST /v1/embeddings on the LiteLLM gateway."""
    url = f"{gateway_url}/v1/embeddings"
    code, data = http_request("POST", url, {"Authorization": auth_header}, {"model": model, "input": "integration test"})
    if 200 <= code < 300:
        try:
            dim = len(data["data"][0]["embedding"])
            return TestResult(f"Gateway embedding ({model})", True, f"HTTP {code}, dimension={dim}")
        except (KeyError, IndexError, TypeError):
            return TestResult(f"Gateway embedding ({model})", True, f"HTTP {code}, response OK")
    return TestResult(f"Gateway embedding ({model})", False, f"HTTP {code}: {get_message(data)}")


def test_gateway_responses(gateway_url: str, auth_header: str, model: str) -> TestResult:
    """Test POST /v1/responses on the LiteLLM gateway."""
    url = f"{gateway_url}/v1/responses"
    code, data = http_request("POST", url, {"Authorization": auth_header}, {"model": model, "input": "Respond with exactly: OK"})
    if 200 <= code < 300:
        return TestResult(f"Gateway responses ({model})", True, f"HTTP {code}")
    return TestResult(f"Gateway responses ({model})", False, f"HTTP {code}: {get_message(data)}")


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    load_dotenv(root / ".env.local")

    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT", "").rstrip("/")
    api_key = os.getenv("AZURE_OPENAI_API_KEY", "")
    embedding_deployment = os.getenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT", "text-embedding-3-large")
    embedding_api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-01")
    codex_model = os.getenv("AZURE_OPENAI_CODEX_MODEL", "gpt-5.3-codex")
    codex_api_version = os.getenv("AZURE_OPENAI_CODEX_API_VERSION", "2025-04-01-preview")
    gateway_url = os.getenv("GATEWAY_URL", "").rstrip("/")
    gateway_key = os.getenv("AIGATEWAY_KEY", "")

    if not endpoint:
        print("ERROR: AZURE_OPENAI_ENDPOINT is required")
        return 1
    if not api_key:
        print("ERROR: AZURE_OPENAI_API_KEY is required")
        return 1

    print("=" * 60)
    print("AI Gateway Integration Test")
    print("=" * 60)
    print(f"Azure OpenAI endpoint:      {endpoint}")
    key_fp = __import__("hashlib").sha256(api_key.encode()).hexdigest()[:12]
    print(f"Azure OpenAI API key:       sha256:{key_fp} (len={len(api_key)})")
    print(f"Embedding deployment:       {embedding_deployment}")
    print(f"Embedding API version:      {embedding_api_version}")
    print(f"Codex model:                {codex_model}")
    print(f"Codex API version:          {codex_api_version}")
    print(f"Gateway URL:                {gateway_url or '<not set — skipping gateway tests>'}")
    print()

    results: list[TestResult] = []

    # --- Azure OpenAI backend tests ---
    print("--- Azure OpenAI Backend Tests ---")

    r = test_aoai_deployments(endpoint, api_key)
    results.append(r)
    print(f"{'PASS' if r.passed else 'FAIL'}: {r.name} — {r.detail}")

    r = test_aoai_embedding(endpoint, api_key, embedding_deployment, embedding_api_version)
    results.append(r)
    print(f"{'PASS' if r.passed else 'FAIL'}: {r.name} — {r.detail}")

    r = test_aoai_chat(endpoint, api_key, codex_model, codex_api_version)
    results.append(r)
    print(f"{'PASS' if r.passed else 'FAIL'}: {r.name} — {r.detail}")

    # --- Gateway tests (optional) ---
    if gateway_url:
        if not gateway_key:
            print("\nWARN: GATEWAY_URL is set but AIGATEWAY_KEY is missing. Skipping gateway tests.")
        else:
            auth_header = gateway_key if gateway_key.lower().startswith("bearer ") else f"Bearer {gateway_key}"
            print("\n--- LiteLLM Gateway Tests ---")

            r = test_gateway_models(gateway_url, auth_header)
            results.append(r)
            print(f"{'PASS' if r.passed else 'FAIL'}: {r.name} — {r.detail}")

            r = test_gateway_embeddings(gateway_url, auth_header, embedding_deployment)
            results.append(r)
            print(f"{'PASS' if r.passed else 'FAIL'}: {r.name} — {r.detail}")

            r = test_gateway_responses(gateway_url, auth_header, codex_model)
            results.append(r)
            print(f"{'PASS' if r.passed else 'FAIL'}: {r.name} — {r.detail}")

    # --- Summary ---
    print()
    print("=" * 60)
    passed = sum(1 for r in results if r.passed)
    failed = sum(1 for r in results if not r.passed)
    print(f"Results: {passed} passed, {failed} failed, {len(results)} total")

    if failed:
        print("\nFailed tests:")
        for r in results:
            if not r.passed:
                print(f"  FAIL: {r.name} — {r.detail}")
        print()
        print("Troubleshooting:")
        print("  1. Verify AZURE_OPENAI_API_KEY is valid for the endpoint")
        print(f"  2. Verify deployment '{embedding_deployment}' exists at {endpoint}")
        print(f"  3. Verify deployment '{codex_model}' exists at {endpoint}")
        print("  4. Check Azure Portal > your AOAI resource > Model deployments")

    print("=" * 60)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
