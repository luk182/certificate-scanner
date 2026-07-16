from flask import Blueprint, jsonify, request, session, send_file
from src.services.cosmos_service import cosmos_service
from src.services.blob_service import blob_service
import io
import logging

logger = logging.getLogger(__name__)
certs_bp = Blueprint("certs", __name__)


@certs_bp.route("/", methods=["GET"])
def get_certificates():
    if not session.get("user"):
        return jsonify({"error": "Unauthorized"}), 401
    resource_type = request.args.get("resource_type")
    status = request.args.get("status")
    certs = cosmos_service.get_certificates_by_filter(resource_type, status)
    return jsonify(certs)


@certs_bp.route("/export", methods=["GET"])
def export_csv():
    if not session.get("user"):
        return jsonify({"error": "Unauthorized"}), 401
    certs = cosmos_service.get_all_certificates()
    csv_data = blob_service.export_certificates_csv(certs)
    return send_file(
        io.BytesIO(csv_data),
        mimetype="text/csv",
        as_attachment=True,
        download_name="certificates.csv",
    )
