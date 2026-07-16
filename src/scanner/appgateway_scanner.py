import logging
import base64
from azure.mgmt.network import NetworkManagementClient
from src.scanner.base_scanner import BaseScanner
from src.models.certificate import Certificate, ResourceType, CertLocation

logger = logging.getLogger(__name__)


def _parse_cert_expiry(public_cert_data_b64: str):
    """Parse expiry date from a base64-encoded DER certificate."""
    try:
        from cryptography import x509
        from cryptography.hazmat.backends import default_backend
        der = base64.b64decode(public_cert_data_b64)
        cert = x509.load_der_x509_certificate(der, default_backend())
        return cert.not_valid_after_utc
    except Exception:
        return None


class AppGatewayScanner(BaseScanner):
    def scan(self, subscription_ids: list = None) -> list[Certificate]:
        certs = []
        for sub in self.get_subscriptions(subscription_ids):
            try:
                client = NetworkManagementClient(self.credential, sub.subscription_id)
                for agw in client.application_gateways.list_all():
                    for ssl_cert in (agw.ssl_certificates or []):
                        location = (
                            CertLocation.KEY_VAULT if ssl_cert.key_vault_secret_id
                            else CertLocation.UPLOADED
                        )
                        kv_name = None
                        if ssl_cert.key_vault_secret_id:
                            parts = ssl_cert.key_vault_secret_id.split("/")
                            kv_name = parts[2].split(".")[0] if len(parts) > 2 else None
                        sni_list = []
                        for listener in (agw.http_listeners or []):
                            if (listener.ssl_certificate
                                    and listener.ssl_certificate.id == ssl_cert.id):
                                if listener.host_name:
                                    sni_list.append(listener.host_name)
                                sni_list.extend(listener.host_names or [])
                        expiry = None
                        if ssl_cert.public_cert_data:
                            expiry = _parse_cert_expiry(ssl_cert.public_cert_data)
                        certs.append(Certificate(
                            cert_name=ssl_cert.name,
                            resource_type=ResourceType.APP_GATEWAY,
                            resource_name=agw.name,
                            subscription_name=sub.display_name,
                            subscription_id=sub.subscription_id,
                            urls_sni=sni_list,
                            expiration_date=expiry,
                            cert_location=location,
                            keyvault_name=kv_name,
                        ))
            except Exception as e:
                logger.error(f"App Gateway scan failed for subscription {sub.subscription_id}: {e}")
        return certs
