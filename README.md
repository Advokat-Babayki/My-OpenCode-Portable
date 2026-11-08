# My-OpenCode-Portable — портативный OpenCode V2 (Windows + Linux)

Личная переносимая сборка [OpenCode](https://opencode.ai) V2: бинарь, конфиг, база
сессий, кэш, состояние и временные файлы лежат рядом с лаунчером. Запускается с
внешнего SSD/флешки без установки в систему. Ничего не пишется в `~/.config`,
`~/.local/share`, `~/.local/state`, `~/.cache` / `%USERPROFILE%`.

Windows и Linux используют один конфиг и одну базу сессий.

## Что внутри

- **OpenCode V2** (CLI, single-binary, Bun). Проверено на `2.2.6`.
- `config/opencode.json` — модель OpenCode Go, отключены автообновление и форматтеры,
  включён todo-инструмент.
- `config/AGENTS.md` — персональные инструкции агента.
- `config/cli.json` — настройки TUI.
- `config/service.json` — фоновый сервис OpenCode отключён, чтобы портативная копия
  не подключалась к системному сервису и не писала в домашнюю папку.
- `bin/` — бинарь OpenCode (в git не хранится).
- `data/` — входы в провайдеры (`auth.json`), база сессий.
- `cache/`, `state/`, `tmp/` — кэш, состояние клиента и временные файлы.

## Структура

```
My-OpenCode-Portable/
├── bin/
│   ├── opencode.exe        # Windows x64
│   └── opencode            # Linux x64
├── config/
│   ├── opencode.json       # настройки и модель
│   ├── AGENTS.md           # инструкции агента
│   ├── cli.json            # настройки TUI
│   ├── service.json        # общий сервис отключён
│   └── agents/ commands/ plugins/ skills/
├── data/                   # auth.json, БД сессий
├── cache/
├── state/
├── tmp/
├── launch.cmd              # Windows
├── launch.sh               # Linux
└── README.md
```

`bin/`, `data/`, `cache/`, `state/`, `tmp/` и `release/` в git не попадают.

## Установка на SSD

```bash
git clone git@github.com:Advokat-Babayki/My-OpenCode-Portable.git
cd My-OpenCode-Portable
bash scripts/fetch-binary.sh
./launch.sh
```

`fetch-binary.sh` скачивает официальный бинарь OpenCode V2 для текущей платформы
(Linux/macOS/Windows через Git Bash). Можно указать версию явно:
`bash scripts/fetch-binary.sh 2.2.6`.

Если в `bin/` остался бинарь от старой сборки — замени его тем же скриптом.

**Windows:** проще взять готовый архив `opencode-portable-windows-x64.zip` из
[релизов](https://github.com/Advokat-Babayki/My-OpenCode-Portable/releases) или
выполнить `bash scripts/fetch-binary.sh` в Git Bash.

## Запуск

**Windows:**

```
Z:\My-OpenCode-Portable\launch.cmd
```

**Linux:**

```bash
./launch.sh               # TUI
./launch.sh run "запрос"  # текстовый режим
```

Запускайте из папки проекта — OpenCode подхватит контекст проекта.

Если на Linux ошибка `Permission denied` (exFAT, exec-бит не сохранился):
`launch.sh` сам попробует запуститься через динамический загрузчик. Крайний случай:

```bash
sudo mount -o remount,exec /path/to/mountpoint
```

## Модели и OpenCode Go

По умолчанию стоит `opencode-go/deepseek-v4.1-flash`. Ключей в репозитории нет.

1. Запусти TUI.
2. `/connect` → **OpenCode Go** → вставь свой API key.
3. `/models` → выбери модель.

Ключ сохранится в `data/opencode/auth.json` на флешке, не в git.

Без подписки можно пользоваться бесплатными моделями OpenCode Zen:
`/models` → `opencode/deepseek-v4.1-flash-free` и другие. Для генерации заголовков
сессий в конфиге уже стоит бесплатная модель.

## Проверка, что система не засоряется

```bash
./launch.sh --version
./launch.sh debug paths
```

Пути `data`, `cache`, `state`, `tmp`, `db` должны указывать внутрь папки сборки.
Убедись, что **не** появилось `~/.config/opencode`, `~/.local/share/opencode`,
`~/.local/state/opencode`, `~/.cache/opencode` (Windows: `C:\Users\<имя>\.config\opencode`
и т.д.). Если появилось — редирект не сработал.

## Обновление OpenCode

```bash
bash scripts/fetch-binary.sh          # последний V2
bash scripts/fetch-binary.sh 2.2.7    # конкретная версия
```

Автообновление отключено: бинарь меняется только вручную.

## Сборка релизных архивов

```bash
bash scripts/make-portable.sh 2.2.6
```

Скрипт скачивает официальные бинари Windows x64 и Linux x64 и собирает:

- `release/opencode-portable-windows-x64.zip`
- `release/opencode-portable-linux-x64.tar.gz`

В CI то же самое делает `.github/workflows/release.yml` при пуше тега `v*`.
Версия V2 определяется автоматически (GitHub API отдаёт V1 как «latest», поэтому
скрипты явно выбирают последний тег `v2.*`).

## Требования

- **Windows**: 10/11 x64; для TUI лучше Windows Terminal; git — только для работы
  с репозиториями.
- **Linux**: bash, glibc ≥ 2.28 (для Alpine/не-glibc есть вариант `-musl`),
  git — только для работы с репозиториями.

## Лицензия

GPL-3.0 — см. [LICENSE](LICENSE). OpenCode распространяется под собственной
лицензией; бинарные файлы принадлежат их авторам.
