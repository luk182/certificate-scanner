import logging
from azure.cosmos import CosmosClient, exceptions
from src.config import settings
from src.extensions import get_azure_credential

logger = logging.getLogger(__name__)


class CosmosService:
    def __init__(self):
        credential = get_azure_credential()
        self.client = CosmosClient(settings.COSMOS_ENDPOINT, credential=credential)
        self.db = self.client.get_database_client(settings.COSMOS_DATABASE)
        self.certs_container = self.db.get_container_client(settings.COSMOS_CONTAINER_CERTS)
        self.settings_container = self.db.get_container_client(settings.COSMOS_CONTAINER_SETTINGS)

    def upsert_certificate(self, cert_dict: dict):
        try:
            self.certs_container.upsert_item(cert_dict)
        except exceptions.CosmosHttpResponseError as e:
            logger.error(f"Failed to upsert certificate: {e}")
            raise

    def get_all_certificates(self) -> list:
        try:
            query = "SELECT * FROM c ORDER BY c.expiration_date ASC"
            return list(self.certs_container.query_items(
                query=query, enable_cross_partition_query=True
            ))
        except exceptions.CosmosHttpResponseError as e:
            logger.error(f"Failed to query certificates: {e}")
            return []

    def get_certificates_by_filter(self, resource_type: str = None, status: str = None) -> list:
        conditions = []
        params = []
        if resource_type:
            conditions.append("c.resource_type = @resource_type")
            params.append({"name": "@resource_type", "value": resource_type})
        if status:
            conditions.append("c.status = @status")
            params.append({"name": "@status", "value": status})
        query = "SELECT * FROM c"
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        query += " ORDER BY c.expiration_date ASC"
        return list(self.certs_container.query_items(
            query=query, parameters=params, enable_cross_partition_query=True
        ))

    def get_settings(self) -> dict:
        try:
            return self.settings_container.read_item(
                "scanner_settings", partition_key="scanner_settings"
            )
        except exceptions.CosmosResourceNotFoundError:
            return {}

    def upsert_settings(self, settings_dict: dict):
        self.settings_container.upsert_item(settings_dict)


cosmos_service = CosmosService()
