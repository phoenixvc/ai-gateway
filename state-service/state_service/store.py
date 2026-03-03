from __future__ import annotations

import json
import logging
from typing import Any

from .config import CATALOG_KEY, REDIS_URL

try:
    import redis.asyncio as redis
except Exception:  # pragma: no cover
    redis = None


logger = logging.getLogger(__name__)


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
        if not raw:
            return None
        try:
            return json.loads(raw)
        except (json.JSONDecodeError, ValueError) as exc:
            logger.warning("Invalid JSON in redis for key=%s: %s", key, exc)
            return None
    if key == CATALOG_KEY:
        return memory_store.catalog
    return None


async def write_json(key: str, value: dict[str, Any]) -> None:
    if redis_client:
        await redis_client.set(key, json.dumps(value))
        return
    if key == CATALOG_KEY:
        memory_store.catalog = value
