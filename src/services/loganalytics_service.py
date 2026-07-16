import logging
from datetime import datetime, timezone
from azure.monitor.ingestion import LogsIngestionClient
from src.config import settings
from src.extensions import get_azure_credential

logger = logging.getLogger(__name__)


class LogAnalyticsService:
    def __init__(self):
        credential = get_azure_credential()
        self.client = LogsIngestionClient(
            endpoint=settings.LOG_ANALYTICS_DCE_ENDPOINT,
            credential=credential,
        )

    def send_certificate_alerts(self, certificates: list):
        """Send red/yellow certificates to the Log Analytics custom table."""
        alerts = []
        for cert in certificates:
            if cert.get("status") in ("expired", "warning"):
                alerts.append({
                    "TimeGenerated": datetime.now(timezone.utc).isoformat(),
                    "CertName": cert.get("cert_name"),
                    "SNURL": ", ".join(cert.get("urls_sni", [])),
                    "Resource": cert.get("resource_name"),
                    "ResourceType": cert.get("resource_type"),
                    "ExpirationDate": cert.get("expiration_date"),
                    "Status": cert.get("status"),
                    "DaysRemaining": cert.get("days_remaining"),
                })
        if alerts:
            try:
                self.client.upload(
                    rule_id=settings.LOG_ANALYTICS_DCR_IMMUTABLE_ID,
                    stream_name=settings.LOG_ANALYTICS_STREAM_NAME,
                    logs=alerts,
                )
                logger.info(f"Sent {len(alerts)} certificate alerts to Log Analytics")
            except Exception as e:
                logger.error(f"Failed to send alerts to Log Analytics: {e}")


loganalytics_service = LogAnalyticsService()
