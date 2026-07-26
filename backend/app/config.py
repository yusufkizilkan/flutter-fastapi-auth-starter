from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """All buyer-facing knobs live here / in .env — change once, not everywhere."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Auth Starter"
    database_url: str = "postgresql://postgres:postgres@db:5432/auth_starter"
    secret_key: str = "dev-only-change-me"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7
    google_client_id: str = ""
    cors_origins: str = "*"
    algorithm: str = "HS256"


@lru_cache
def get_settings() -> Settings:
    return Settings()
