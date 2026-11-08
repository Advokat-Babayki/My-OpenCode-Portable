@echo off
setlocal
set "ROOT=%~dp0"
set "BIN=%ROOT%bin\opencode.exe"

rem Не тащить конфиг, базу, ключи и флаги из родительского OpenCode.
for %%V in (OPENCODE OPENCODE_CONFIG OPENCODE_CONFIG_CONTENT OPENCODE_CONFIG_DIR OPENCODE_DB OPENCODE_MODELS_PATH OPENCODE_MODELS_URL OPENCODE_API_KEY OPENCODE_PASSWORD OPENCODE_SERVER_PASSWORD OPENCODE_SESSION_ID OPENCODE_CLIENT OPENCODE_TERMINAL OPENCODE_WORKTREE_BASE OPENCODE_WORKTREE_PATH OPENCODE_REPO_CLONE_GITHUB_BASE_URL OPENCODE_LOG_LEVEL OPENCODE_DISABLE_AUTOUPDATE OPENCODE_DISABLE_CLAUDE_CODE OPENCODE_DISABLE_CLAUDE_CODE_SKILLS) do set "%%V="

set "OPENCODE_CONFIG_DIR=%ROOT%config"
set "XDG_DATA_HOME=%ROOT%data"
set "XDG_CACHE_HOME=%ROOT%cache"
set "XDG_STATE_HOME=%ROOT%state"
set "TMP=%ROOT%tmp"
set "TEMP=%ROOT%tmp"
set "TMPDIR=%ROOT%tmp"
set "OPENCODE_DISABLE_AUTOUPDATE=true"
set "OPENCODE_DISABLE_CLAUDE_CODE=true"
set "OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=true"

if not exist "%ROOT%data" mkdir "%ROOT%data"
if not exist "%ROOT%cache" mkdir "%ROOT%cache"
if not exist "%ROOT%state" mkdir "%ROOT%state"
if not exist "%ROOT%tmp" mkdir "%ROOT%tmp"

if not exist "%BIN%" (
  echo opencode: bin\opencode.exe not found.
  echo Download it: bash scripts/fetch-binary.sh
  exit /b 1
)

"%BIN%" --version 2>nul | findstr /r /c:" v2\." >nul
if errorlevel 1 (
  echo WARNING: bin\opencode.exe is not OpenCode V2.
  echo Update it: bash scripts/fetch-binary.sh
)

"%BIN%" %*
endlocal
