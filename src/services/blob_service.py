import csv
import io
import logging
from datetime import datetime, timezone
from azure.storage.blob import BlobServiceClient
from src.config import settings
from src.extensions import get_azure_credential

logger = logging.getLogger(__name__)


class BlobService:
    def __init__(self):
        credential = get_azure_credential()
        self.client = BlobServiceClient(
            account_url=settings.STORAGE_ACCOUNT_URL,
            credential=credential,
        )
        self.container = settings.STORAGE_CONTAINER

    def export_certificates_csv(self, certificates: list) -> bytes:
        output = io.StringIO()
        fieldnames = [
            "cert_name", "resource_type", "resource_name", "subscription_name",
            "urls_sni", "expiration_date", "cert_location", "keyvault_name",
            "status", "days_remaining",
        ]
        writer = csv.DictWriter(output, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for cert in certificates:
            row = dict(cert)
            row["urls_sni"] = ", ".join(cert.get("urls_sni", []))
            writer.writerow(row)
        data = output.getvalue().encode("utf-8")
        blob_name = f"exports/certificates_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.csv"
        container_client = self.client.get_container_client(self.container)
        container_client.upload_blob(blob_name, data, overwrite=True)
        logger.info(f"Exported certificates to blob: {blob_name}")
        return data


blob_service = BlobService()
