@echo off
setlocal
set "ROOT=%~dp0"
set "BIN=%ROOT%bin\opencode.exe"
set "OPENCODE_CONFIG_DIR=%ROOT%config"
set "XDG_DATA_HOME=%ROOT%data"
set "XDG_CACHE_HOME=%ROOT%cache"
set "XDG_STATE_HOME=%ROOT%state"
set "TMP=%ROOT%tmp"
set "TEMP=%ROOT%tmp"
set "OPENCODE_DISABLE_AUTOUPDATE=true"

if not exist "%ROOT%data" mkdir "%ROOT%data"
if not exist "%ROOT%cache" mkdir "%ROOT%cache"
if not exist "%ROOT%state" mkdir "%ROOT%state"
if not exist "%ROOT%tmp" mkdir "%ROOT%tmp"

if not exist "%BIN%" (
  echo opencode: bin\opencode.exe not found.
  echo Download it: bash scripts/fetch-binary.sh
  exit /b 1
)

"%BIN%" %*
endlocal
