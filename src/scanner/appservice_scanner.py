import logging
from azure.mgmt.web import WebSiteManagementClient
from src.scanner.base_scanner import BaseScanner
from src.models.certificate import Certificate, ResourceType, CertLocation

logger = logging.getLogger(__name__)


class AppServiceScanner(BaseScanner):
    def scan(self, subscription_ids: list = None) -> list[Certificate]:
        certs = []
        for sub in self.get_subscriptions(subscription_ids):
            try:
                client = WebSiteManagementClient(self.credential, sub.subscription_id)
                sub_certs = {c.thumbprint: c for c in client.certificates.list()}
                for app in client.web_apps.list():
                    if app.kind and "functionapp" in (app.kind or "").lower():
                        continue
                    for binding in (app.host_name_ssl_states or []):
                        if not (binding.ssl_state and binding.ssl_state.value != "Disabled"):
                            continue
                        cert = sub_certs.get(binding.thumbprint)
                        if not cert:
                            continue
                        location = CertLocation.KEY_VAULT if cert.key_vault_id else CertLocation.UPLOADED
                        kv_name = None
                        if cert.key_vault_id:
                            parts = cert.key_vault_id.split("/")
                            kv_name = parts[parts.index("vaults") + 1] if "vaults" in parts else None
                        certs.append(Certificate(
                            cert_name=cert.subject_name or binding.name,
                            resource_type=ResourceType.APP_SERVICE,
                            resource_name=app.name,
                            subscription_name=sub.display_name,
                            subscription_id=sub.subscription_id,
                            urls_sni=[binding.name],
                            expiration_date=cert.expiration_date,
                            cert_location=location,
                            keyvault_name=kv_name,
                            thumbprint=cert.thumbprint,
                        ))
            except Exception as e:
                logger.error(f"App Service scan failed for subscription {sub.subscription_id}: {e}")
        return certs
