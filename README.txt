==================================================
  My-OpenCode-Portable — портативный OpenCode V2
  (Windows x64 + Linux x64)
==================================================

ЧТО ЭТО
  OpenCode V2 (CLI, Windows x64 и Linux x64). Всё
  переносимо: конфиг, база сессий, кэш, состояние и
  временные файлы лежат в этой папке. Ничего не
  устанавливается в систему. Windows и Linux
  пользуются одним конфигом и одной базой сессий.
  Проверено на 2.2.6.

УСТАНОВКА
  Склонируй репозиторий на SSD, затем в терминале:
     bash scripts/fetch-binary.sh
  Скрипт скачает официальный бинарь V2 для текущей
  системы. Если bin/ остался от старой версии —
  запусти его же, он заменит бинарь.
  Windows: можно взять готовый zip из релизов или
  выполнить команду в Git Bash.

WINDOWS — ЗАПУСК
  1. Вставь SSD.
  2. Открой Windows Terminal (или PowerShell).
  3. Выполни:
       Z:\My-OpenCode-Portable\launch.cmd
     (буква диска Z может отличаться; лаунчер сам
      определит свой путь при любой букве)
  Все данные пишутся в data\, cache\, state\, tmp\
  рядом с лаунчером.

LINUX — ЗАПУСК
  1. Вставь SSD.
  2. cd /run/media/<пользователь>/<метка>/My-OpenCode-Portable
  3. ./launch.sh
     ./launch.sh --version
     ./launch.sh run "вопрос"

  Permission denied на exFAT: launch.sh сам попробует
  динамический загрузчик; если не вышло:
     sudo mount -o remount,exec /run/media/...

ПРОВЕРКА
  Windows:
     launch.cmd --version
     launch.cmd debug paths
  Linux:
     ./launch.sh --version
     ./launch.sh debug paths
  Пути data/cache/state/tmp/db должны быть внутри
  папки сборки. Не должно появиться:
     C:\Users\<имя>\.config\opencode
     C:\Users\<имя>\.local
     C:\Users\<имя>\.cache
     ~/.config/opencode
     ~/.local/share/opencode
     ~/.local/state/opencode
     ~/.cache/opencode

МОДЕЛИ — OPENCODE GO
  По умолчанию: opencode-go/deepseek-v4.1-flash.
  Ключей в репозитории нет.
     /connect -> OpenCode Go -> вставить API key
     /models  -> выбрать модель
  Ключ сохраняется в data\opencode\auth.json на SSD.
  Без подписки: бесплатные модели opencode/...-free
  через /models.

КОНФИГ
  config/opencode.json — модель, отключены
  автообновление и форматтеры, включён todo.
  config/AGENTS.md — персональные инструкции агента.
  config/cli.json — настройки TUI.
  config/service.json — общий сервис отключён, чтобы
  сборка не подключалась к системному сервису.
  Береги SSD: если войдёшь в аккаунт, токен лежит
  в data\opencode\auth.json.

ОБНОВЛЕНИЕ
  Автообновление выключено. Вручную:
     bash scripts/fetch-binary.sh
     bash scripts/fetch-binary.sh 2.2.7
  Или замени bin\opencode.exe / bin/opencode из
  https://github.com/anomalyco/opencode/releases
  (теги v2.*, не v1.*).

ЕСЛИ TUI РИСУЕТСЯ КРИВО
  Windows: Windows Terminal или
     launch.cmd run "вопрос"
  Linux:
     ./launch.sh run "вопрос"

ПРИМЕЧАНИЯ
  * SmartScreen/антивирус на неподписанный exe —
    «Всё равно выполнить».
  * Git нужен только для работы с репозиториями.
  * LSP в V2 не запускается; форматтеры отключены.
