@echo off
setlocal
set "ROOT=%~dp0"
set "BIN=%ROOT%bin\opencode.exe"
set "OPENCODE_CONFIG=%ROOT%config\opencode.json"
set "OPENCODE_CONFIG_DIR=%ROOT%config"
set "XDG_DATA_HOME=%ROOT%data"
set "XDG_CACHE_HOME=%ROOT%cache"
set "OPENCODE_DISABLE_AUTOUPDATE=true"
set "OPENCODE_DISABLE_LSP_DOWNLOAD=true"
"%BIN%" %*
endlocal
