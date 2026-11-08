==================================================
  My-OpenCode-Portable 1.0.0
  OpenCode V2.2.6 — Windows x64 + Linux x64
==================================================

ЭТО ГОТОВЫЙ АРХИВ
  Всё уже внутри: бинарь, конфиг, лаунчеры.
  Git и установка не нужны.

ЗАПУСК
  Windows:
     launch.cmd
  Linux:
     bash launch.sh          (или ./launch.sh)

  Если ./launch.sh пишет Permission denied — запусти через bash.

ПЕРВЫЙ ВХОД
  В TUI:
     /connect -> OpenCode Go -> вставить API key
     /models  -> выбрать модель
  По умолчанию: opencode-go/deepseek-v4.1-flash.
  Ключ хранится в data/opencode/auth.json на SSD.
  Без подписки: бесплатные opencode/...-free.

ГДЕ ДАННЫЕ
  data/   — auth.json, БД сессий, логи
  cache/  — кэш
  state/  — состояние клиента
  tmp/    — временные файлы
  OpenCode пишет данные сюда; git/gh могут
  использовать свои обычные настройки.

ПРОВЕРКА
  Windows: launch.cmd --version
           launch.cmd debug paths
  Linux:   bash launch.sh --version
           bash launch.sh debug paths
  Пути data/cache/state/tmp/db должны быть внутри этой папки.

ОБНОВЛЕНИЕ
  bash scripts/fetch-binary.sh
  bash scripts/fetch-binary.sh 2.2.7
  Скрипт уже в архиве, проверяет SHA-256.
  Автообновление отключено.

  Проверка самого архива из релиза:
     sha256sum -c SHA256SUMS

ЕСЛИ НЕ ЗАПУСКАЕТСЯ
  * Permission denied: bash launch.sh
  * noexec: лаунчер покажет команду remount
  * старый бинарь: запусти scripts/fetch-binary.sh

КОНФИГ
  config/opencode.json — модель и настройки
  config/AGENTS.md     — инструкции агента
  config/cli.json      — TUI
  config/service.json  — приватный сервис, без общего демона

ВЕРСИИ
  Сборка: 1.0.0 (VERSION)
  OpenCode: 2.2.6 (OPENCODE_VERSION)

ЛИЦЕНЗИИ
  Проект: GPL-3.0 (LICENSE, NOTICE)
  OpenCode: MIT (LICENSE-OpenCode)

БЕЗОПАСНОСТЬ
  На SSD лежит исполняемый файл и токен доступа.
  Не запускай с незнакомых машин и не передавай SSD посторонним.
