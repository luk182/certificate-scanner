import pytest
import json
from unittest.mock import patch, MagicMock


@pytest.fixture
def client():
    with patch("src.config.Settings", autospec=True):
        with patch("src.extensions.get_azure_credential", return_value=MagicMock()):
            with patch("src.services.cosmos_service.CosmosService.__init__", return_value=None):
                with patch("src.services.loganalytics_service.LogAnalyticsService.__init__", return_value=None):
                    with patch("src.services.blob_service.BlobService.__init__", return_value=None):
                        with patch("src.scanner.scheduler.start_scheduler"):
                            from src.app import create_app
                            app = create_app()
                            app.config["TESTING"] = True
                            app.config["SECRET_KEY"] = "test-secret"
                            with app.test_client() as c:
                                yield c


def test_health_endpoint(client):
    res = client.get("/health")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["status"] == "healthy"


def test_unauthenticated_certificates(client):
    res = client.get("/api/certificates/")
    assert res.status_code == 401


def test_unauthenticated_dashboard(client):
    res = client.get("/api/dashboard/")
    assert res.status_code == 401


def test_unauthenticated_scan(client):
    res = client.post("/api/scan/run")
    assert res.status_code == 401


def test_unauthenticated_settings(client):
    res = client.get("/api/settings/")
    assert res.status_code == 401
