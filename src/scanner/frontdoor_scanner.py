import logging
from azure.mgmt.frontdoor import FrontDoorManagementClient
from src.scanner.base_scanner import BaseScanner
from src.models.certificate import Certificate, ResourceType, CertLocation

logger = logging.getLogger(__name__)


class FrontDoorScanner(BaseScanner):
    def scan(self, subscription_ids: list = None) -> list[Certificate]:
        certs = []
        for sub in self.get_subscriptions(subscription_ids):
            try:
                client = FrontDoorManagementClient(self.credential, sub.subscription_id)
                for fd in client.front_doors.list():
                    for endpoint in (fd.frontend_endpoints or []):
                        custom_https = endpoint.custom_https_configuration
                        if not custom_https:
                            continue
                        location = (
                            CertLocation.KEY_VAULT
                            if custom_https.certificate_source == "AzureKeyVault"
                            else CertLocation.UPLOADED
                        )
                        kv_name = None
                        if (location == CertLocation.KEY_VAULT
                                and custom_https.key_vault_certificate_source_parameters):
                            kv_id = custom_https.key_vault_certificate_source_parameters.vault.id
                            parts = kv_id.split("/")
                            kv_name = parts[parts.index("vaults") + 1] if "vaults" in parts else None
                        certs.append(Certificate(
                            cert_name=endpoint.host_name or endpoint.name,
                            resource_type=ResourceType.FRONT_DOOR,
                            resource_name=fd.name,
                            subscription_name=sub.display_name,
                            subscription_id=sub.subscription_id,
                            urls_sni=[endpoint.host_name] if endpoint.host_name else [],
                            expiration_date=None,
                            cert_location=location,
                            keyvault_name=kv_name,
                        ))
            except Exception as e:
                logger.error(f"Front Door scan failed for subscription {sub.subscription_id}: {e}")
        return certs
