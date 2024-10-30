@echo off
poetry run uvicorn "aroiwa.main:create_app" --reload