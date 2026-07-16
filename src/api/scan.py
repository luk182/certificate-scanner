from flask import Blueprint, jsonify, session
from src.scanner.scheduler import run_scan
import threading
import logging

logger = logging.getLogger(__name__)
scan_bp = Blueprint("scan", __name__)


@scan_bp.route("/run", methods=["POST"])
def trigger_scan():
    if not session.get("user"):
        return jsonify({"error": "Unauthorized"}), 401
    thread = threading.Thread(target=run_scan, daemon=True)
    thread.start()
    logger.info(f"Manual scan triggered by {session['user'].get('preferred_username')}")
    return jsonify({"message": "Scan started"}), 202
