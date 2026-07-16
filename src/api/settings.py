from flask import Blueprint, jsonify, request, session
from src.services.cosmos_service import cosmos_service
from src.scanner.scheduler import reschedule
import logging

logger = logging.getLogger(__name__)
settings_bp = Blueprint("settings_api", __name__)


@settings_bp.route("/", methods=["GET"])
def get_settings():
    if not session.get("user"):
        return jsonify({"error": "Unauthorized"}), 401
    return jsonify(cosmos_service.get_settings())


@settings_bp.route("/", methods=["POST"])
def save_settings():
    if not session.get("user"):
        return jsonify({"error": "Unauthorized"}), 401
    data = request.json
    data["id"] = "scanner_settings"
    cosmos_service.upsert_settings(data)
    if "frequency" in data:
        reschedule(data["frequency"])
    logger.info(f"Settings updated by {session['user'].get('preferred_username')}")
    return jsonify({"message": "Settings saved"})
