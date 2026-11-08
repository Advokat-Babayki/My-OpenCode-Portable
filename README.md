# My-OpenCode-Portable 1.0.0 — портативный OpenCode V2 (Windows + Linux)

Личная переносимая сборка [OpenCode](https://opencode.ai) V2: бинарь, конфиг, база
сессий, кэш, состояние и временные файлы лежат рядом с лаунчером. Запускается с
внешнего SSD/флешки без установки в систему. OpenCode не пишет свои файлы в
`~/.config`, `~/.local/share`, `~/.local/state`, `~/.cache` / `%USERPROFILE%`.

Это не песочница: агент и запущенные им команды работают с твоими правами и могут
читать системные настройки (git, ssh, gh). Портативность относится к данным OpenCode,
а не к изоляции процессов.

## Версии

- Сборка: **1.0.0** — файл `VERSION`
- OpenCode: **2.2.6** — файл `OPENCODE_VERSION`

## Что внутри

- `config/opencode.json` — модель OpenCode Go, отключены автообновление, форматтеры и LSP,
  включён todo-инструмент.
- `config/AGENTS.md` — персональные инструкции агента.
- `config/cli.json` — настройки TUI.
- `config/service.json` — общий фоновый сервис OpenCode отключён; каждая сессия
  запускает приватный сервер и не цепляется к системному.
- `config/agents/`, `commands/`, `plugins/`, `skills/` — место для своих агентов,
  команд, плагинов и навыков (создаются сборкой или при необходимости вручную).
- `bin/` — бинарь OpenCode (в git не хранится; в релизных архивах есть).
- `data/opencode/` — `auth.json`, база сессий и логи.
- `cache/`, `state/`, `tmp/` — кэш, состояние клиента и временные файлы.
- `scripts/fetch-binary.sh` — скачивание и обновление бинаря (входит в релизные архивы).
- `scripts/smoke-test.sh` — проверки конфига и лаунчера.

## Структура

```
My-OpenCode-Portable/
├── bin/opencode(.exe)      # бинарь (не в git)
├── config/
│   ├── opencode.json
│   ├── AGENTS.md
│   ├── cli.json
│   ├── service.json
│   └── agents/ commands/ plugins/ skills/
├── data/                   # auth.json, БД сессий, логи
├── cache/
├── state/
├── tmp/
├── scripts/                # fetch-binary.sh, lib.sh, smoke-test.sh
├── launch.cmd              # Windows
├── launch.sh               # Linux
├── VERSION
├── OPENCODE_VERSION
├── CHANGELOG.md
├── NOTICE
├── LICENSE                 # GPL-3.0
└── LICENSE-OpenCode        # MIT
```

`bin/`, `data/`, `cache/`, `state/`, `tmp/` и `release/` в git не попадают.

## Установка из релиза

1. Скачай архив со страницы [releases/latest](https://github.com/Advokat-Babayki/My-OpenCode-Portable/releases/latest):
   `opencode-portable-windows-x64.zip` или `opencode-portable-linux-x64.tar.gz`.
2. Распакуй — внутри будет папка `opencode-portable-windows-x64` или
   `opencode-portable-linux-x64`.
3. Запусти:
   - Windows: `launch.cmd`
   - Linux: `bash launch.sh` (или `./launch.sh`)
4. В TUI: `/connect` → **OpenCode Go** → вставь свой API key.

Git для готового архива не нужен.

## Установка из исходников

```bash
git clone https://github.com/Advokat-Babayki/My-OpenCode-Portable.git
cd My-OpenCode-Portable
bash scripts/fetch-binary.sh
./launch.sh
```

`fetch-binary.sh` скачивает официальный бинарь OpenCode V2 для текущей платформы
(Linux x64/arm64, macOS, Windows x64/arm64 через Git Bash), проверяет SHA-256 и
кладёт его в `bin/`. На Linux автоматически выбирается musl-вариант, если система
на musl (Alpine).

Если в `bin/` остался бинарь от старой сборки — просто запусти скрипт ещё раз.

## Запуск

**Windows:**

```
Z:\opencode-portable-windows-x64\launch.cmd
```

**Linux:**

```bash
bash launch.sh               # TUI
bash launch.sh run "запрос"  # текстовый режим
```

Запускай из папки проекта — OpenCode подхватит контекст проекта.

## Модели и OpenCode Go

По умолчанию стоит `opencode-go/deepseek-v4.1-flash`. Ключей в репозитории нет.

1. Запусти TUI.
2. `/connect` → **OpenCode Go** → вставь API key.
3. `/models` → выбери модель.

Ключ сохранится в `data/opencode/auth.json` на флешке, не в git.

Без подписки доступны бесплатные модели OpenCode Zen: `/models` →
`opencode/deepseek-v4.1-flash-free` и другие. Для заголовков сессий в конфиге уже
стоит бесплатная модель.

## Проверка портативности

```bash
bash launch.sh --version
bash launch.sh debug paths
```

Пути `data`, `cache`, `state`, `tmp`, `db` должны указывать внутрь папки сборки.
Не должно появиться `~/.config/opencode`, `~/.local/share/opencode`,
`~/.local/state/opencode`, `~/.cache/opencode`.

Лаунчер очищает унаследованные `OPENCODE_*` (конфиг, БД, ключи, пути к моделям),
чтобы родительский OpenCode не менял поведение портативной копии. Дочерние
инструменты вроде `git` и `gh` по-прежнему могут читать свои обычные настройки.

## Обновление OpenCode

```bash
bash scripts/fetch-binary.sh          # последняя V2
bash scripts/fetch-binary.sh 2.2.7    # конкретная версия
```

Скрипт входит в релизные архивы. Автообновление отключено: бинарь меняется только
вручную.

## Сборка релизных архивов

```bash
bash scripts/make-portable.sh 2.2.6
```

Если версия не указана, берётся `OPENCODE_VERSION`, иначе последняя V2. Скрипт
скачивает официальные бинари, проверяет SHA-256, собирает архивы с верхней папкой
и кладёт их в `release/`:

- `release/opencode-portable-windows-x64.zip`
- `release/opencode-portable-linux-x64.tar.gz`
- `release/SHA256SUMS`

В CI это делает `.github/workflows/release.yml` при пуше тега `v*`. Версия проекта
и версия OpenCode разделены: тег `v1.0.0` выпускает сборку 1.0.0 с OpenCode из
`OPENCODE_VERSION`.

## Тесты

```bash
bash scripts/smoke-test.sh --static   # синтаксис, JSON, лаунчер на фейковом бинаре
bash scripts/smoke-test.sh            # + реальный bin/opencode и debug paths
```

## Требования

- **Windows**: 10/11 x64; для TUI лучше Windows Terminal. Для скачивания бинаря
  нужен Git Bash + `curl`, `unzip` или `python3`.
- **Linux**: bash, `curl`, `tar`; glibc ≥ 2.28 или musl (Alpine). Для сборки —
  `unzip` или `python3`, `zip` или `python3`.
- Для проверки SHA-256: `sha256sum`, `shasum` или `openssl`.
- **macOS**: `fetch-binary.sh` умеет скачать бинарь, но готовые архивы выпускаются
  только для Windows и Linux x64.
- **git**: нужен для клонирования и обновления исходников; для запуска готового
  архива не нужен.

## exFAT и noexec

Если `./launch.sh` не запускается из-за потерянного exec-бита:

```bash
bash launch.sh
```

Если система говорит, что диск смонтирован с `noexec`, лаунчер выведет точную
команду remount. Обычно:

```bash
sudo mount -o remount,exec /path/to/mountpoint
```

## Безопасность

- Бинари скачиваются с официальных релизов `anomalyco/opencode` и проверяются по
  SHA-256 из `SHA256SUMS`. В релизе рядом с архивами лежит свой `SHA256SUMS`;
  проверка: `sha256sum -c SHA256SUMS`.
- Windows может показать SmartScreen на неподписанный `opencode.exe` — это
  ожидаемо.
- На SSD лежит исполняемый файл и, после `/connect`, токен доступа. Не запускай
  сборку с незнакомых машин и не передавай SSD посторонним.
- Секреты в репозиторий не коммитятся; `config/auth.json`, `.env*` и
  `*.local.json` игнорируются.

## Лицензии

- Проект: GPL-3.0 — см. [LICENSE](LICENSE) и [NOTICE](NOTICE).
- OpenCode: MIT — см. [LICENSE-OpenCode](LICENSE-OpenCode).
