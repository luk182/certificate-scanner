import logging
from abc import ABC, abstractmethod
from azure.mgmt.resource import SubscriptionClient
from src.extensions import get_azure_credential
from src.models.certificate import Certificate

logger = logging.getLogger(__name__)


class BaseScanner(ABC):
    def __init__(self):
        self.credential = get_azure_credential()

    def get_subscriptions(self, subscription_ids: list = None) -> list:
        sub_client = SubscriptionClient(self.credential)
        all_subs = list(sub_client.subscriptions.list())
        if subscription_ids:
            return [s for s in all_subs if s.subscription_id in subscription_ids]
        return all_subs

    @abstractmethod
    def scan(self, subscription_ids: list = None) -> list[Certificate]:
        pass
