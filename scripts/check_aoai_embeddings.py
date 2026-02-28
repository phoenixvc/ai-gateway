#!/usr/bin/env python3
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


def http_json(method: str, url: str, api_key: str, payload: dict | None = None):
    body = None
    headers = {
        "api-key": api_key,
    }
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


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    load_dotenv(root / ".env.local")

    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT", "").rstrip("/")
    api_key = os.getenv("AZURE_OPENAI_API_KEY", "")
    api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2023-05-15")
    preferred = os.getenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT", "text-embedding-3-large")

    if not endpoint:
        print("Missing AZURE_OPENAI_ENDPOINT")
        return 1
    if not api_key:
        print("Missing AZURE_OPENAI_API_KEY (set it in .env.local)")
        return 1

    print(f"Endpoint: {endpoint}")
    print(f"API version (embeddings): {api_version}")
    print(f"Preferred embedding deployment: {preferred}")
    print()

    candidates = []

    dep_url = f"{endpoint}/openai/deployments?api-version=2023-03-15-preview"
    dep_code, dep_data = http_json("GET", dep_url, api_key)
    print(f"Deployments API: HTTP {dep_code}")

    if dep_code == 200 and isinstance(dep_data, dict):
        dep_items = dep_data.get("data") or dep_data.get("value") or []
        for item in dep_items:
            if not isinstance(item, dict):
                continue
            deployment_name = item.get("id") or item.get("name") or ""
            model_name = item.get("model")
            if isinstance(model_name, dict):
                model_name = model_name.get("name") or ""
            if not isinstance(model_name, str):
                model_name = ""

            if deployment_name:
                print(f"- deployment={deployment_name} model={model_name or 'unknown'}")

            text = f"{deployment_name} {model_name}".lower()
            if "embedding" in text:
                candidates.append(deployment_name)
    else:
        print(f"Deployments API error: {get_message(dep_data)}")

    print()

    model_url = f"{endpoint}/openai/models?api-version=2024-10-21"
    model_code, model_data = http_json("GET", model_url, api_key)
    print(f"Models API: HTTP {model_code}")
    if model_code == 200 and isinstance(model_data, dict):
        model_items = model_data.get("data") or model_data.get("value") or []
        model_ids = []
        for item in model_items:
            if isinstance(item, dict):
                model_id = item.get("id") or item.get("name")
                if model_id:
                    model_ids.append(str(model_id))
        if model_ids:
            print("Available model IDs:")
            for model_id in model_ids:
                print(f"- {model_id}")
    else:
        print(f"Models API error: {get_message(model_data)}")

    print()

    probe_list = [preferred] + candidates
    seen = set()
    probe_list = [x for x in probe_list if x and not (x in seen or seen.add(x))]

    if not probe_list:
        print("No embedding deployment candidates found to probe.")
        return 1

    print("Probing embedding endpoint by deployment:")
    any_ok = False
    for deployment in probe_list:
        emb_url = (
            f"{endpoint}/openai/deployments/{deployment}/embeddings"
            f"?api-version={api_version}"
        )
        code, data = http_json("POST", emb_url, api_key, {"input": "smoke test"})
        ok = 200 <= code < 300
        status = "OK" if ok else "FAIL"
        print(f"- {deployment}: HTTP {code} ({status})")
        if not ok:
            print(f"  reason: {get_message(data)}")
        any_ok = any_ok or ok

    return 0 if any_ok else 1


if __name__ == "__main__":
    sys.exit(main())
