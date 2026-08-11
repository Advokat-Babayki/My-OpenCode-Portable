==================================================
  opencode-dev — портативная сборка OpenCode
  (Windows x64 + Linux x64)
==================================================

ЧТО ЭТО
  OpenCode v1.18.16 (CLI, Windows x64 и Linux x64). Всё
  переносимое: конфиг, база сессий и кэш лежат на этой
  флешке. Ничего не устанавливается в систему. Windows и
  Linux пользуются одним конфигом и одной базой сессий.

WINDOWS — ЗАПУСК
  1. Вставь флешку.
  2. Открой Windows Terminal (или PowerShell).
     Если его нет — обычный cmd тоже подойдёт, но для
     красивого интерфейса (TUI) лучше Windows Terminal.
  3. Выполни:
       Z:\OpenCode\launch.cmd
     (буква диска Z может отличаться — подставь свою;
      сама команда сама определит свой путь при любой букве)

  Все данные пишутся в data\ и cache\ на флешке.
  Никаких новых папок в C:\Users\... создаваться не должно.

LINUX — ЗАПУСК
  1. Вставь флешку.
  2. Открой терминал и перейди в папку:
       cd /run/media/<пользователь>/<метка>/OpenCode
     (путь монтирования может отличаться на разных машинах)
  3. Запусти:
       ./launch.sh              (интерфейс TUI)
       ./launch.sh --version    (проверка версии)
       ./launch.sh run "вопрос" (текстовый режим без TUI)

  Если при запуске ошибка «Permission denied» — на флешке
  exFAT, exec-бит не сохранился. launch.sh сам попробует
  запуститься через динамический загрузчик; если не вышло:
       sudo mount -o remount,exec /run/media/<пользователь>/<метка>
  Требования: bash, glibc >= 2.28 (старые дистрибутивы могут
  не подойти), git — только для работы с репозиториями.

ПРОВЕРКА (один раз, перед первым выездом)
  Windows:
     opencode db path  -> путь в data\opencode\ на флешке
     opencode --version -> v1.18.16
     Убедись, что НЕ появились:
       C:\Users\<имя>\.config\opencode
       C:\Users\<имя>\.local
       C:\Users\<имя>\.cache
  Linux:
     ./launch.sh db path  -> путь в data/opencode/ на флешке
     ./launch.sh --version -> v1.18.16
     Убедись, что НЕ появились:
       ~/.config/opencode  ~/.local/share/opencode  ~/.cache/opencode
  Если папки появились — редирект не сработал, доложи.

МОДЕЛИ — БЕЗ КЛЮЧЕЙ, БЕСПЛАТНО
  В opencode встроен провайдер OpenCode Zen с бесплатными
  моделями (формат opencode/<id>). Никаких API-ключей вписывать
  не нужно. По умолчанию стоит opencode/deepseek-v4-flash-free
  — бесплатная модель DeepSeek V4 Flash.
  Другие бесплатные модели открыть через /models в TUI
  (mimo-v2.5-free, nemotron-3-ultra-free, big-pickle и др. —
  список периодически меняется, big-pickle постоянная).

  Если opencode вдруг попросит «подключить провайдера»:
    в TUI набрать /connect -> выбрать OpenCode Zen ->
    войти через GitHub (бесплатно, без ключа).
  Вход сохранится в data/opencode/auth.json на флешке.

  Альтернативы без платного ключа (по желанию):
    * GitHub Copilot Free  — /connect -> GitHub Copilot,
      вход в браузере через аккаунт GitHub.
    * Google Gemini Free   — ключ из aistudio.google.com,
      /connect -> Google.
    * Groq Free            — ключ из console.groq.com.

КОНФИГ
  Настройки в config/opencode.json (модель, отключённые
  lsp/formatter/autoupdate). Ключей там нет.
  Береги флешку: если войдёшь в аккаунт — токен лежит
  в data/opencode/auth.json.

ЕСЛИ TUI РИСУЕТСЯ КРИВО
  Windows: поставь Windows Terminal или используй текстовый
  режим:  launch.cmd run "вопрос"
  Linux: используй текстовый режим:  ./launch.sh run "вопрос"

ПРИМЕЧАНИЯ
  * При первом запуске на Windows может спросить про
    SmartScreen / антивирус на неподписанный exe — нажми
    «Всё равно выполнить».
  * Git нужен только для работы с репозиториями. Без git
    opencode запустится, но git-операции не заработают.
  * Автообновление выключено. Обновлять вручную с
    https://github.com/anomalyco/opencode/releases/latest:
      Windows: opencode-windows-x64.zip -> заменить bin/opencode.exe
      Linux:   opencode-linux-x64.tar.gz -> заменить bin/opencode
  * LSP-серверы и форматтеры отключены (не качаются, не требуются).
