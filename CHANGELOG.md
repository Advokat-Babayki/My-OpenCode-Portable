# Changelog

## 1.0.0 — 2026-11-09

- Portable OpenCode V2.2.6 for Windows x64 and Linux x64.
- Personal config: `config/opencode.json`, `config/AGENTS.md`, `config/cli.json`.
- OpenCode Go (`opencode-go/deepseek-v4.1-flash`) by default; free OpenCode Zen
  model for session titles.
- Isolated `data`, `cache`, `state` and `tmp`; private service, no shared daemon.
- Inherited host `OPENCODE_*` variables are cleared at launch.
- SHA-256 verification for downloaded binaries; atomic binary replacement.
- Release bundles include the update script, version files and third-party notices.
- Static smoke tests and launcher tests.
