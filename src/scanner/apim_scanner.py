import logging
from azure.mgmt.apimanagement import ApiManagementClient
from src.scanner.base_scanner import BaseScanner
from src.models.certificate import Certificate, ResourceType, CertLocation

logger = logging.getLogger(__name__)


class APIMScanner(BaseScanner):
    def scan(self, subscription_ids: list = None) -> list[Certificate]:
        certs = []
        for sub in self.get_subscriptions(subscription_ids):
            try:
                client = ApiManagementClient(self.credential, sub.subscription_id)
                for service in client.api_management_service.list():
                    for domain in (service.hostname_configurations or []):
                        if not domain.certificate:
                            continue
                        cert_info = domain.certificate
                        location = CertLocation.KEY_VAULT if domain.key_vault_id else CertLocation.UPLOADED
                        kv_name = None
                        if domain.key_vault_id:
                            parts = domain.key_vault_id.split("/")
                            kv_name = parts[parts.index("vaults") + 1] if "vaults" in parts else None
                        certs.append(Certificate(
                            cert_name=cert_info.subject or domain.host_name,
                            resource_type=ResourceType.APIM,
                            resource_name=service.name,
                            subscription_name=sub.display_name,
                            subscription_id=sub.subscription_id,
                            urls_sni=[domain.host_name],
                            expiration_date=cert_info.expiry,
                            cert_location=location,
                            keyvault_name=kv_name,
                            thumbprint=cert_info.thumbprint,
                        ))
            except Exception as e:
                logger.error(f"APIM scan failed for subscription {sub.subscription_id}: {e}")
        return certs
