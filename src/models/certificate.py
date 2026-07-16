from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone
from enum import Enum


class ResourceType(str, Enum):
    APIM = "APIM"
    APP_GATEWAY = "App Gateway"
    APP_SERVICE = "App Service"
    FUNCTIONS = "Functions"
    LOGIC_APPS = "Logic Apps"
    FRONT_DOOR = "Front Door"


class CertLocation(str, Enum):
    KEY_VAULT = "Key Vault"
    UPLOADED = "Uploaded"
    MANAGED = "Managed"


class CertStatus(str, Enum):
    HEALTHY = "healthy"
    WARNING = "warning"
    EXPIRED = "expired"


class Certificate(BaseModel):
    id: Optional[str] = None
    cert_name: str
    resource_type: ResourceType
    resource_name: str
    subscription_name: str
    subscription_id: str
    urls_sni: list[str] = []
    expiration_date: Optional[datetime] = None
    cert_location: CertLocation
    keyvault_name: Optional[str] = None
    thumbprint: Optional[str] = None
    scanned_at: datetime = None

    def model_post_init(self, __context):
        if self.scanned_at is None:
            self.scanned_at = datetime.now(timezone.utc)

    @property
    def status(self) -> CertStatus:
        if not self.expiration_date:
            return CertStatus.HEALTHY
        now = datetime.now(timezone.utc)
        exp = self.expiration_date
        if exp.tzinfo is None:
            exp = exp.replace(tzinfo=timezone.utc)
        days_remaining = (exp - now).days
        if days_remaining < 0:
            return CertStatus.EXPIRED
        if days_remaining <= 90:
            return CertStatus.WARNING
        return CertStatus.HEALTHY

    @property
    def days_remaining(self) -> Optional[int]:
        if not self.expiration_date:
            return None
        now = datetime.now(timezone.utc)
        exp = self.expiration_date
        if exp.tzinfo is None:
            exp = exp.replace(tzinfo=timezone.utc)
        return (exp - now).days

    def to_cosmos(self) -> dict:
        data = self.model_dump(mode="json")
        data["id"] = (
            self.id
            or f"{self.resource_type}-{self.resource_name}-{self.cert_name}".replace(" ", "_")
        )
        data["status"] = self.status.value
        data["days_remaining"] = self.days_remaining
        return data
