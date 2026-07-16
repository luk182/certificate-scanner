from azure.identity import ManagedIdentityCredential, DefaultAzureCredential
from opencensus.ext.azure.log_exporter import AzureLogHandler
import logging
import os


def get_azure_credential():
    if os.getenv("FLASK_ENV") == "development":
        return DefaultAzureCredential()
    return ManagedIdentityCredential()


def setup_logging(app):
    from src.config import settings
    handler = AzureLogHandler(connection_string=settings.APPINSIGHTS_CONNECTION_STRING)
    handler.setLevel(logging.WARNING)
    app.logger.addHandler(handler)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s %(message)s"
    )
