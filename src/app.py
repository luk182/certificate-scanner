import logging
from flask import Flask, redirect, url_for, session, render_template
from src.config import settings
from src.extensions import setup_logging
from src.auth.msal_auth import auth_bp
from src.api.certificates import certs_bp
from src.api.dashboard import dashboard_bp
from src.api.settings import settings_bp
from src.api.scan import scan_bp
from src.scanner.scheduler import start_scheduler

logger = logging.getLogger(__name__)


def create_app():
    app = Flask(__name__, template_folder="templates", static_folder="static")
    app.secret_key = settings.SECRET_KEY
    app.config["SESSION_TYPE"] = "filesystem"

    setup_logging(app)

    # Blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(certs_bp, url_prefix="/api/certificates")
    app.register_blueprint(dashboard_bp, url_prefix="/api/dashboard")
    app.register_blueprint(settings_bp, url_prefix="/api/settings")
    app.register_blueprint(scan_bp, url_prefix="/api/scan")

    @app.route("/health")
    def health():
        return {"status": "healthy"}, 200

    @app.route("/")
    def index():
        if not session.get("user"):
            return redirect(url_for("auth.login"))
        return redirect(url_for("dashboard_page"))

    @app.route("/dashboard")
    def dashboard_page():
        if not session.get("user"):
            return redirect(url_for("auth.login"))
        return render_template("dashboard.html", user=session["user"])

    @app.route("/certificates")
    def certificates_page():
        if not session.get("user"):
            return redirect(url_for("auth.login"))
        return render_template("certificates.html", user=session["user"])

    @app.route("/settings")
    def settings_page():
        if not session.get("user"):
            return redirect(url_for("auth.login"))
        return render_template("settings.html", user=session["user"])

    start_scheduler(app)

    logger.info("Certificate Scanner application started")
    return app


app = create_app()

if __name__ == "__main__":
    app.run(debug=(settings.FLASK_ENV == "development"))
