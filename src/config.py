from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # Azure AD
    AZURE_TENANT_ID: str
    AZURE_CLIENT_ID: str
    AZURE_CLIENT_SECRET: Optional[str] = None  # Not needed with Managed Identity in prod

    # App
    SECRET_KEY: str
    FLASK_ENV: str = "production"

    # CosmosDB
    COSMOS_ENDPOINT: str
    COSMOS_DATABASE: str = "certificate-scanner"
    COSMOS_CONTAINER_CERTS: str = "certificates"
    COSMOS_CONTAINER_SETTINGS: str = "settings"

    # Storage
    STORAGE_ACCOUNT_URL: str
    STORAGE_CONTAINER: str = "exports"

    # Application Insights
    APPINSIGHTS_CONNECTION_STRING: str

    # Log Analytics
    LOG_ANALYTICS_WORKSPACE_ID: str
    LOG_ANALYTICS_DCE_ENDPOINT: str
    LOG_ANALYTICS_DCR_IMMUTABLE_ID: str
    LOG_ANALYTICS_STREAM_NAME: str = "Custom-CertificateAlerts_CL"

    class Config:
        env_file = ".env"


settings = Settings()
