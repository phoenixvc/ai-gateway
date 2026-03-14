import os

REDIS_URL = os.getenv("REDIS_URL", "").strip()
STATE_KEY_PREFIX = os.getenv("STATE_KEY_PREFIX", "aigw:state")
STATE_SERVICE_SHARED_TOKEN = os.getenv("STATE_SERVICE_SHARED_TOKEN", "").strip()

CATALOG_KEY = f"{STATE_KEY_PREFIX}:catalog"
USERS_KEY = f"{STATE_KEY_PREFIX}:users"


def selection_key(user_id: str) -> str:
    if not user_id or not user_id.strip():
        raise ValueError("user_id must be a non-empty string")

    normalized_user_id = user_id.strip()
    if ":" in normalized_user_id or any(char.isspace() for char in normalized_user_id):
        raise ValueError("user_id must not contain ':' or whitespace")

    return f"{STATE_KEY_PREFIX}:selection:{normalized_user_id}"
