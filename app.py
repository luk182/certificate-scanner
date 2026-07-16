# Entry point for local development.
# Production uses: gunicorn "src.app:app" (see startup.sh)
from src.app import app

if __name__ == "__main__":
    app.run(debug=True)
