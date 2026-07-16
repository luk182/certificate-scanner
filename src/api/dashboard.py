from flask import Blueprint, jsonify, session
from src.services.cosmos_service import cosmos_service
from src.models.certificate import ResourceType
import logging

logger = logging.getLogger(__name__)
dashboard_bp = Blueprint("dashboard", __name__)


@dashboard_bp.route("/", methods=["GET"])
def get_dashboard():
    if not session.get("user"):
        return jsonify({"error": "Unauthorized"}), 401
    certs = cosmos_service.get_all_certificates()

    def count_status(cert_list):
        return {
            "healthy": sum(1 for c in cert_list if c.get("status") == "healthy"),
            "warning": sum(1 for c in cert_list if c.get("status") == "warning"),
            "expired": sum(1 for c in cert_list if c.get("status") == "expired"),
        }

    result = {}
    for rt in ResourceType:
        filtered = [c for c in certs if c.get("resource_type") == rt.value]
        result[rt.value] = count_status(filtered)

    result["All"] = count_status(certs)
    return jsonify(result)
