from __future__ import annotations

import json
from typing import Any

from .config import CATALOG_KEY, REDIS_URL

try:
    import redis.asyncio as redis
except Exception:  # pragma: no cover
    redis = None


class InMemoryStore:
    def __init__(self) -> None:
        self.catalog: dict[str, Any] = {
            "models": [],
            "status": "unavailable",
            "updated_at": None,
        }
        self.users: dict[str, dict[str, Any]] = {}


memory_store = InMemoryStore()
redis_client = redis.from_url(REDIS_URL, decode_responses=True) if REDIS_URL and redis else None


async def read_json(key: str) -> dict[str, Any] | None:
    if redis_client:
        raw = await redis_client.get(key)
        return json.loads(raw) if raw else None
    if key == CATALOG_KEY:
        return memory_store.catalog
    return None


async def write_json(key: str, value: dict[str, Any]) -> None:
    if redis_client:
        await redis_client.set(key, json.dumps(value))
        return
    if key == CATALOG_KEY:
        memory_store.catalog = value
