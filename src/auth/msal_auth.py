import msal
import uuid
import logging
from flask import Blueprint, redirect, request, session, url_for, render_template
from src.config import settings

logger = logging.getLogger(__name__)
auth_bp = Blueprint("auth", __name__)

AUTHORITY = f"https://login.microsoftonline.com/{settings.AZURE_TENANT_ID}"
SCOPES = ["User.Read"]
REDIRECT_PATH = "/auth/callback"


def _build_msal_app(cache=None):
    return msal.ConfidentialClientApplication(
        settings.AZURE_CLIENT_ID,
        authority=AUTHORITY,
        client_credential=settings.AZURE_CLIENT_SECRET,
        token_cache=cache,
    )


@auth_bp.route("/login")
def login():
    session["state"] = str(uuid.uuid4())
    auth_url = _build_msal_app().get_authorization_request_url(
        SCOPES,
        state=session["state"],
        redirect_uri=url_for("auth.callback", _external=True),
    )
    return render_template("login.html", auth_url=auth_url)


@auth_bp.route(REDIRECT_PATH)
def callback():
    if request.args.get("state") != session.get("state"):
        return redirect(url_for("auth.login"))
    if "error" in request.args:
        logger.error(f"Auth error: {request.args.get('error_description')}")
        return render_template("login.html", error=request.args.get("error_description"))
    result = _build_msal_app().acquire_token_by_authorization_code(
        request.args["code"],
        scopes=SCOPES,
        redirect_uri=url_for("auth.callback", _external=True),
    )
    if "error" in result:
        return render_template("login.html", error=result.get("error_description"))
    session["user"] = result.get("id_token_claims")
    logger.info(f"User logged in: {session['user'].get('preferred_username')}")
    return redirect(url_for("dashboard_page"))


@auth_bp.route("/logout")
def logout():
    session.clear()
    return redirect(
        f"{AUTHORITY}/oauth2/v2.0/logout"
        f"?post_logout_redirect_uri={url_for('auth.login', _external=True)}"
    )
