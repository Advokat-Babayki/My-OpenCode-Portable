# opencode-dev — портативный OpenCode (Windows + Linux)

Переносимая сборка [OpenCode](https://github.com/anomalyco/opencode) v1.18.16
(CLI, single-binary, Bun). Запускается прямо с флешки **без установки в систему**:
конфиг, база сессий и кэш лежат рядом с бинарём. Ничего не пишется в
`~/.config`, `~/.local/share`, `~/.cache` / `%USERPROFILE%`.

Windows и Linux пользуются **одним конфигом и одной базой сессий** — переключился
на другую ОС, сессии на месте.

## Возможности

- ⚡ **Без установки** — один бинарь, конфиг, база и кэш в одной папке
- 🔑 **Без API-ключей** — встроенный провайдер OpenCode Zen с бесплатными моделями
  (по умолчанию `opencode/deepseek-v4-flash-free`; список бесплатных — через `/models`)
- 🚫 Автообновление, LSP-серверы и форматтеры отключены — ничего не качается на клиенте
- 🧭 Работает при любом пути/букве диска — пути в лаунчерах строятся относительно себя
- 🖥️ Windows (`launch.cmd`) и Linux (`launch.sh`, с fallback для exFAT)

## Структура

```
opencode-dev/
├── bin/
│   ├── opencode.exe        # Windows x64
│   └── opencode            # Linux x64
├── config/
│   ├── opencode.json       # настройки и модель
│   └── agents/ commands/ modes/ plugins/ skills/ themes/ tools/
├── data/                   # XDG_DATA_HOME → auth.json, БД сессий
├── cache/                  # XDG_CACHE_HOME
├── launch.cmd              # Windows
├── launch.sh               # Linux
└── README.md
```

## Запуск

**Windows:**

```
Z:\opencode-dev\launch.cmd
```

**Linux:**

```bash
cd /path/to/opencode-dev
./launch.sh               # TUI
./launch.sh run "запрос"  # текстовый режим без TUI
```

Запускайте из папки проекта — opencode подхватит контекст проекта.

Если на Linux ошибка `Permission denied` (флешка exFAT, exec-бит не сохранился):
`launch.sh` сам попробует запуститься через динамический загрузчик. Крайний случай:

```bash
sudo mount -o remount,exec /path/to/mountpoint
```

## Проверка, что система не засоряется

```bash
./launch.sh db path      # → должно указать на data/opencode/ рядом с лаунчером
./launch.sh --version    # → v1.18.16
```

Убедитесь, что **не** появилось `~/.config/opencode`, `~/.local/share/opencode`,
`~/.cache/opencode` (Windows: `C:\Users\<имя>\.config\opencode` и т.д.).
Если появилось — редирект не сработал.

## Бесплатные модели (без ключей)

Встроенный провайдер **OpenCode Zen** (формат `opencode/<id>`):

- `opencode/deepseek-v4-flash-free` — бесплатно (по умолчанию)
- `opencode/big-pickle` — всегда бесплатно
- `opencode/mimo-v2.5-free`, `opencode/nemotron-3-ultra-free`, и др. — ротируется

Полный список — через `/models` в TUI. Если opencode попросит подключить
провайдера: `/connect` → OpenCode Zen → вход через GitHub (бесплатно, без ключа).
Токены сохраняются в `data/opencode/auth.json` (на флешке).

Альтернативы без платного ключа: GitHub Copilot Free, Google Gemini Free, Groq Free.

## Обновление

Автообновление отключено. Обновить вручную — заменить бинарь из официального
релиза [anomalyco/opencode](https://github.com/anomalyco/opencode/releases/latest):

- Windows: `opencode-windows-x64.zip` → `bin/opencode.exe`
- Linux: `opencode-linux-x64.tar.gz` → `bin/opencode`

## Сборка релизных архивов

Архивы собираются скриптом `scripts/make-portable.sh` — он скачивает официальные
бинари с GitHub Releases указанной версии и собирает переносимые бандлы:

```bash
bash scripts/make-portable.sh 1.18.16
```

Результат в `release/`:
- `opencode-portable-windows-x64.zip`
- `opencode-portable-linux-x64.tar.gz`

В CI (GitHub Actions) то же самое делает `.github/workflows/release.yml` — при
пуше тега `v*` он собирает архивы и прикрепляет их к релизу автоматически.

## Требования

- **Windows**: 64-бит; git — только для работы с репозиториями; для TUI лучше
  Windows Terminal (старый `cmd` рисует TUI криво — тогда используйте `run`)
- **Linux**: bash, glibc ≥ 2.28 (для Alpine/не-glibc есть вариант `-musl`),
  git — только для работы с репозиториями

## Лицензия

MIT — см. [LICENSE](LICENSE). OpenCode распространяется под собственной лицензией;
бинарные файлы принадлежат их авторам.
