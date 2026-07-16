#!/bin/bash
set -e
gunicorn --bind=0.0.0.0:8000 --workers=2 --threads=4 --timeout=120 "src.app:app"
