from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class DatabaseSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="DB_")

    user: SecretStr = SecretStr("sandbox")
    password: SecretStr = SecretStr("sandbox")
    host: SecretStr = SecretStr("localhost")
    port: SecretStr = SecretStr("3306")
    database_name: str = "sandbox"
