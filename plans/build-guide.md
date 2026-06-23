# Как собрать и запустить NVIDIA LLM Client

> ⚠️ Это macOS-приложение (AppKit/SwiftUI/SwiftData). Его **нельзя** собрать или
> запустить на Windows. Нужен Mac с macOS 15.0+ (Sequoia) и Xcode 16.0+.
>
> ✅ Тестовая сборка выполняется на **macOS Tahoe 26.5.1** с Xcode 26. Приложение
> использует Liquid Glass на macOS 26+ (см. [`GlassWindowModifier`](../DesignSystem/GlassWindowModifier.swift:10)).

Проект «запакован» для автоматической установки: есть XcodeGen-спецификация
([`project.yml`](../project.yml:1)), скрипт одной команды
([`scripts/setup.sh`](../scripts/setup.sh:1)) и CI-сборка
([`.github/workflows/build.yml`](../.github/workflows/build.yml:1)).

---

## Вариант 0. Скачать готовый .app из GitHub Actions (без локальной сборки)

Если не хочется ничего ставить локально — CI соберёт приложение за вас:

1. Откройте репозиторий на GitHub → вкладка **Actions**.
2. Запустите workflow **Build** вручную (кнопка **Run workflow**) или он сработает
   автоматически при пуше в `main`.
3. Когда сборка завершится — откройте её → прокрутите вниз до **Artifacts** →
   скачайте `NvidiaLLM-app`.
4. Распакуйте `NvidiaLLM.zip` → перетащите `NvidiaLLM.app` в `/Applications`.
5. При первом запуске: ПКМ → **Open** (обход Gatekeeper, т.к. сборка без
   подписи разработчика).

> Сборка без подписи (`CODE_SIGN_IDENTITY="-"`), поэтому macOS покажет
> предупреждение — это нормально для личного использования.

---

## Вариант A. Одна команда через setup.sh (рекомендуется)

Скрипт [`scripts/setup.sh`](../scripts/setup.sh:1) делает всё автоматически:
ставит XcodeGen, генерирует `.xcodeproj` из [`project.yml`](../project.yml:1),
открывает проект в Xcode.

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Затем в Xcode: `Cmd+R` (сборка и запуск).

---

## Вариант B. Вручную через XcodeGen

Если хотите контролировать процесс:

```bash
# 1. Установить XcodeGen (один раз)
brew install xcodegen

# 2. Сгенерировать проект
xcodegen generate

# 3. Открыть в Xcode
open NvidiaLLM.xcodeproj

# 4. Собрать и запустить: Cmd+R
```

[`project.yml`](../project.yml:1) уже описывает цель `NvidiaLLM` со всеми
исходниками, встроенным [`Resources/Info.plist`](../Resources/Info.plist:1),
`Assets.xcassets` и SPM-зависимостями (`swift-markdown-ui`, `HotKey`).

---

## Вариант C. Через командную строку (xcodebuild)

После генерации проекта (Вариант A или B):

```bash
# Debug-сборка
xcodebuild -project NvidiaLLM.xcodeproj -scheme NvidiaLLM -configuration Debug build

# Запуск
open build/Debug/NvidiaLLM.app

# Release-сборка
xcodebuild -project NvidiaLLM.xcodeproj -scheme NvidiaLLM -configuration Release build

# Тесты
xcodebuild -project NvidiaLLM.xcodeproj -scheme NvidiaLLM test
```

---

## Вариант D. Только через SPM (ограниченный)

Можно собрать как SPM-исполняемый файл, но **без** `.app`-бандла часть функций
(встраивание `Info.plist`, иконка приложения) будет ограничена. Главное меню
теперь устанавливается вручную в [`AppDelegate`](../App/AppDelegate.swift:41),
поэтому базовая работа возможна:

```bash
swift build
swift run NvidiaLLM
```

> Минус: нет `.app`-бандла, `Info.plist` не применяется, нет иконки приложения.
> Для полноценной работы используйте Вариант A.

---

## Первый запуск

1. Приложение запускается — в строке меню появляется иконка **CPU**.
2. Верхнее меню приложения: **NVIDIA LLM → Settings…** (`Cmd+,`) → вкладка **API**
   → введите NVIDIA API Key (получить на [build.nvidia.com](https://build.nvidia.com)).
3. (Опц.) Вкладка **Search** → Google Custom Search API Key + CX.
4. Вкладка **Models** → выберите модель + системный промпт.
5. Кликните индикатор статуса модели — должен стать ✅ зелёным.
6. Начните чат в окне или через поповер (иконка CPU в строке меню).
7. `Cmd+Shift+N` — глобальный хоткей для активации окна.

---

## Проверка исправлений

| Что проверить | Как | Ожидаемый результат |
|---------------|-----|---------------------|
| Главное меню | Запустите приложение, посмотрите на верхнюю строку меню | Есть меню «NVIDIA LLM» с пунктами About / Settings… / Quit |
| Настройки из бара | Кликните иконку CPU → кнопку «Settings» | Открывается окно настроек |
| `Cmd+,` | Нажмите в приложении | Открываются настройки |
| Глобальный хоткей | Нажмите `Cmd+Shift+N` из любого приложения | Активируется главное окно |

---

## Требования

| Компонент | Версия |
|-----------|--------|
| macOS | 15.0+ (Sequoia); **26.5.1 (Tahoe)** — тестовая платформа, для Liquid Glass |
| Xcode | 16.0+; **26** — для сборки на Tahoe |
| Swift | 6.0+ |
| Архитектура | Apple Silicon (M1/M2/M3/M4) |
| NVIDIA API | Ключ с [build.nvidia.com](https://build.nvidia.com) |

> На macOS Tahoe 26+ приложение использует нативный Liquid Glass-материал
> (`.ultraThinMaterial`); на более ранних версиях — fallback на
> `NSVisualEffectView` (см. [`GlassWindowModifier.swift`](../DesignSystem/GlassWindowModifier.swift:10)).
