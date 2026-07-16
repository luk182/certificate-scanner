import logging
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

logger = logging.getLogger(__name__)
_scheduler = BackgroundScheduler()


def run_scan():
    from src.services.cosmos_service import cosmos_service
    from src.services.loganalytics_service import loganalytics_service
    from src.scanner.apim_scanner import APIMScanner
    from src.scanner.appgateway_scanner import AppGatewayScanner
    from src.scanner.appservice_scanner import AppServiceScanner
    from src.scanner.functions_scanner import FunctionsScanner
    from src.scanner.logicapps_scanner import LogicAppsScanner
    from src.scanner.frontdoor_scanner import FrontDoorScanner
    from datetime import datetime, timezone

    logger.info("Starting certificate scan")
    stored_settings = cosmos_service.get_settings()
    subscription_ids = stored_settings.get("subscription_ids") or None

    scanners = [
        APIMScanner(),
        AppGatewayScanner(),
        AppServiceScanner(),
        FunctionsScanner(),
        LogicAppsScanner(),
        FrontDoorScanner(),
    ]
    all_certs = []
    for scanner in scanners:
        try:
            found = scanner.scan(subscription_ids)
            all_certs.extend(found)
            logger.info(f"{scanner.__class__.__name__} found {len(found)} certificates")
        except Exception as e:
            logger.error(f"Scanner {scanner.__class__.__name__} failed: {e}")

    for cert in all_certs:
        cosmos_service.upsert_certificate(cert.to_cosmos())

    cert_dicts = [c.to_cosmos() for c in all_certs]
    loganalytics_service.send_certificate_alerts(cert_dicts)

    stored_settings["last_scan"] = datetime.now(timezone.utc).isoformat()
    stored_settings["id"] = "scanner_settings"
    cosmos_service.upsert_settings(stored_settings)
    logger.info(f"Scan complete. {len(all_certs)} total certificates upserted.")


def start_scheduler(app):
    from src.services.cosmos_service import cosmos_service
    stored_settings = cosmos_service.get_settings()
    frequency = stored_settings.get("frequency", "daily")
    _apply_schedule(frequency)
    _scheduler.start()
    logger.info(f"Scheduler started with frequency: {frequency}")


def _apply_schedule(frequency: str):
    _scheduler.remove_all_jobs()
    if frequency == "weekly":
        _scheduler.add_job(run_scan, CronTrigger(day_of_week="mon", hour=2, minute=0), id="cert_scan")
    else:
        _scheduler.add_job(run_scan, CronTrigger(hour=2, minute=0), id="cert_scan")


def reschedule(frequency: str):
    _apply_schedule(frequency)
    logger.info(f"Scheduler rescheduled to: {frequency}")
