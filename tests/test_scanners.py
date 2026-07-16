import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime, timezone, timedelta
from src.models.certificate import Certificate, ResourceType, CertLocation, CertStatus


def make_cert(days_offset: int) -> Certificate:
    return Certificate(
        cert_name="test.contoso.com",
        resource_type=ResourceType.APIM,
        resource_name="my-apim",
        subscription_name="Production",
        subscription_id="sub-001",
        urls_sni=["test.contoso.com"],
        expiration_date=datetime.now(timezone.utc) + timedelta(days=days_offset),
        cert_location=CertLocation.UPLOADED,
    )


def test_cert_status_healthy():
    cert = make_cert(91)
    assert cert.status == CertStatus.HEALTHY


def test_cert_status_warning():
    cert = make_cert(45)
    assert cert.status == CertStatus.WARNING


def test_cert_status_expired():
    cert = make_cert(-5)
    assert cert.status == CertStatus.EXPIRED


def test_cert_days_remaining():
    cert = make_cert(30)
    assert cert.days_remaining == 30


def test_cert_to_cosmos_sets_id():
    cert = make_cert(100)
    doc = cert.to_cosmos()
    assert doc["id"] is not None
    assert "APIM" in doc["id"]


def test_cert_to_cosmos_includes_status():
    cert = make_cert(50)
    doc = cert.to_cosmos()
    assert doc["status"] == "warning"


def test_cert_with_keyvault():
    cert = Certificate(
        cert_name="kv.contoso.com",
        resource_type=ResourceType.APP_GATEWAY,
        resource_name="my-agw",
        subscription_name="Dev",
        subscription_id="sub-002",
        urls_sni=["kv.contoso.com"],
        expiration_date=datetime.now(timezone.utc) + timedelta(days=200),
        cert_location=CertLocation.KEY_VAULT,
        keyvault_name="my-keyvault",
    )
    assert cert.cert_location == CertLocation.KEY_VAULT
    assert cert.keyvault_name == "my-keyvault"
