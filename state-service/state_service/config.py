import os

REDIS_URL = os.getenv("REDIS_URL", "").strip()
STATE_KEY_PREFIX = os.getenv("STATE_KEY_PREFIX", "aigw:state")

CATALOG_KEY = f"{STATE_KEY_PREFIX}:catalog"
USERS_KEY = f"{STATE_KEY_PREFIX}:users"


def selection_key(user_id: str) -> str:
    return f"{STATE_KEY_PREFIX}:selection:{user_id}"
