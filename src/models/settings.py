from pydantic import BaseModel
from typing import List, Optional
from enum import Enum


class ScanFrequency(str, Enum):
    DAILY = "daily"
    WEEKLY = "weekly"


class ScanScope(str, Enum):
    SUBSCRIPTIONS = "subscriptions"
    MANAGEMENT_GROUPS = "management_groups"


class ScannerSettings(BaseModel):
    id: str = "scanner_settings"
    scope_type: ScanScope = ScanScope.SUBSCRIPTIONS
    subscription_ids: List[str] = []
    management_group_ids: List[str] = []
    frequency: ScanFrequency = ScanFrequency.DAILY
    last_scan: Optional[str] = None
    next_scan: Optional[str] = None
