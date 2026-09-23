@echo off
title Zombies Declassified - Kino der Toten installer
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-kino.ps1" %*
echo.
pause
