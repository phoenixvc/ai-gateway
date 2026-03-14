from __future__ import annotations

import hmac
import json
import logging
from typing import Any

from fastapi import APIRouter, Header, HTTPException, Query

from .config import CATALOG_KEY, STATE_SERVICE_SHARED_TOKEN, USERS_KEY, selection_key
from .schemas import CatalogPayload, SelectionPayload
from .store import memory_store, read_json, redis_client, write_json
from .utils import now_iso

router = APIRouter()
logger = logging.getLogger(__name__)


def require_user_id(user_id: str | None) -> str:
    if not user_id or not user_id.strip():
        raise HTTPException(status_code=400, detail="Missing X-User-Id header")
    normalized_user_id = user_id.strip()
    if ":" in normalized_user_id or any(char.isspace() for char in normalized_user_id):
        raise HTTPException(status_code=400, detail="X-User-Id contains invalid characters")
    return normalized_user_id


def require_trusted_proxy_token(token: str | None) -> None:
    if not STATE_SERVICE_SHARED_TOKEN:
        return
    if not token or not hmac.compare_digest(token, STATE_SERVICE_SHARED_TOKEN):
        raise HTTPException(status_code=403, detail="Forbidden")


@router.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok", "backend": "redis" if redis_client else "memory"}


@router.get("/state/catalog")
async def get_catalog(x_state_service_token: str | None = Header(default=None, alias="X-State-Service-Token")) -> dict[str, Any]:
    require_trusted_proxy_token(x_state_service_token)
    catalog = await read_json(CATALOG_KEY)
    return catalog or {"models": [], "status": "unavailable", "updated_at": None}


@router.put("/state/catalog")
async def put_catalog(
    payload: CatalogPayload,
    x_state_service_token: str | None = Header(default=None, alias="X-State-Service-Token"),
) -> dict[str, Any]:
    require_trusted_proxy_token(x_state_service_token)
    models = sorted({model.strip() for model in payload.models if model and model.strip()})
    catalog = {"models": models, "status": payload.status, "updated_at": now_iso()}
    await write_json(CATALOG_KEY, catalog)
    return catalog


@router.get("/state/selection")
async def get_selection(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    x_state_service_token: str | None = Header(default=None, alias="X-State-Service-Token"),
) -> dict[str, Any]:
    require_trusted_proxy_token(x_state_service_token)
    user_id = require_user_id(x_user_id)

    if redis_client:
        key = selection_key(user_id)
        raw = await redis_client.get(key)
        if raw:
            try:
                return json.loads(raw)
            except (json.JSONDecodeError, ValueError) as exc:
                logger.warning(
                    "Corrupted selection payload in redis for user_id=%s key=%s: %s",
                    user_id,
                    key,
                    exc,
                )
                try:
                    await redis_client.delete(key)
                except Exception:
                    logger.exception("Failed deleting corrupted redis key=%s", key)
    elif user_id in memory_store.users:
        return memory_store.users[user_id]

    return {"user_id": user_id, "enabled": False, "selected_model": None, "updated_at": None}


@router.put("/state/selection")
async def put_selection(
    payload: SelectionPayload,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    x_state_service_token: str | None = Header(default=None, alias="X-State-Service-Token"),
) -> dict[str, Any]:
    require_trusted_proxy_token(x_state_service_token)
    user_id = require_user_id(x_user_id)
    value = {
        "user_id": user_id,
        "enabled": payload.enabled,
        "selected_model": payload.selected_model.strip() if payload.selected_model else None,
        "updated_at": now_iso(),
    }

    if redis_client:
        await redis_client.set(selection_key(user_id), json.dumps(value))
        await redis_client.sadd(USERS_KEY, user_id)
    else:
        memory_store.users[user_id] = value

    return value


@router.get("/state/selections")
async def get_selections(
    limit: int = Query(default=10, ge=1, le=100),
    include_self: bool = Query(default=False),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    x_state_service_token: str | None = Header(default=None, alias="X-State-Service-Token"),
) -> dict[str, Any]:
    require_trusted_proxy_token(x_state_service_token)
    current_user = require_user_id(x_user_id)
    items: list[dict[str, Any]] = []

    if redis_client:
        user_ids = await redis_client.smembers(USERS_KEY)
        keys: list[str] = []
        for user_id in user_ids:
            try:
                keys.append(selection_key(user_id))
            except ValueError as exc:
                logger.warning("Skipping invalid user_id from redis set %s: %s", user_id, exc)

        if keys:
            raw_values = await redis_client.mget(keys)
            for key, raw in zip(keys, raw_values):
                if not raw:
                    continue
                try:
                    items.append(json.loads(raw))
                except (json.JSONDecodeError, ValueError) as exc:
                    logger.warning("Skipping corrupted selection JSON for key=%s: %s", key, exc)
    else:
        items = list(memory_store.users.values())

    if not include_self:
        items = [item for item in items if item.get("user_id") != current_user]

    items.sort(key=lambda item: item.get("updated_at") or "", reverse=True)
    return {"items": items[:limit], "total": len(items)}
