from pydantic import BaseModel, Field


class SelectionPayload(BaseModel):
    enabled: bool = True
    selected_model: str | None = None


class CatalogPayload(BaseModel):
    models: list[str] = Field(default_factory=list)
    status: str = Field(default="live")
