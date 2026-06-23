# Как собрать и запустить NVIDIA LLM Client

> ⚠️ Это macOS-приложение (AppKit/SwiftUI/SwiftData). Его **нельзя** собрать или
> запустить на Windows. Нужен Mac с macOS 15.0+ (Sequoia) и Xcode 16.0+.

---

## Вариант A. Через Xcode (рекомендуется)

### Шаг 1. Создать Xcode-проект (один раз)

В репозитории сейчас нет `.xcodeproj` — только `Package.swift`. Чтобы получить
полноценный `.app`-бандл с меню и встроенным `Info.plist`, создайте проект:

1. Откройте Xcode → **File → New → Project**.
2. Выберите **macOS → App**.
3. Настройки:
   - Product Name: `NvidiaLLM`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** (если спросит)
   - Include Tests: ✅
4. Сохраните проект **в корень репозитория** (`nvidia-models-macos-app/`).
   - Xcode создаст `NvidiaLLM.xcodeproj` и папку `NvidiaLLM/` с шаблонными файлами.
   - **Удалите шаблонные файлы** (`NvidiaLLMApp.swift`, `ContentView.swift`,
     `Assets.xcassets`, `*.entitlements` — кроме entitlements, если нужен
     Keychain/сеть), чтобы не было конфликтов с существующими исходниками.

### Шаг 2. Добавить исходники в цель

1. В навигаторе проекта (слева) удалите авто-созданную группу `NvidiaLLM`.
2. Перетащите в проект (или **File → Add Files to "NvidiaLLM"**) все папки:
   - `App/`, `Models/`, `Services/`, `Chat/`, `MenuBar/`, `Settings/`,
     `Metrics/`, `DesignSystem/`, `Extensions/`
   - Поставьте галочки: **Copy items if needed = OFF** (файлы уже в репо),
     **Add to target: NvidiaLLM = ON**.
3. Добавьте ресурсы:
   - `Resources/Info.plist` → в настройках цели **General → Identity →
     Info.plist File** укажите `Resources/Info.plist`.
   - `Resources/Assets.xcassets` → добавьте в цель как ресурс.

### Шаг 3. Добавить SPM-зависимости

1. **File → Add Package Dependencies…**
2. Вставьте `https://github.com/gonzalezreal/swift-markdown-ui` → **Add Package** →
   выберите библиотеку **MarkdownUI** → добавить к цели `NvidiaLLM`.
3. Повторите для `https://github.com/soffes/HotKey` → **HotKey** → к цели `NvidiaLLM`.

### Шаг 4. Настроить Signing

1. **Signing & Capabilities** цели:
   - Team: ваш Apple ID (можно бесплатный).
   - Bundle Identifier: `com.nvidia-llm.app` (как в `Info.plist`).
   - Signing Certificate: Apple Development.

### Шаг 5. Собрать и запустить

- `Cmd+B` — сборка.
- `Cmd+R` — запуск.
- `Cmd+U` — тесты.

---

## Вариант B. Через командную строку (xcodebuild)

После создания `.xcodeproj` (Вариант A, шаги 1–4):

```bash
# Debug-сборка
xcodebuild -scheme NvidiaLLM -configuration Debug build

# Запуск
open build/Debug/NvidiaLLM.app

# Release-сборка
xcodebuild -scheme NvidiaLLM -configuration Release build

# Тесты
xcodebuild -scheme NvidiaLLM test
```

---

## Вариант C. Только через SPM (ограниченный)

Можно собрать как SPM-исполняемый файл, но **без** `.app`-бандла часть функций
(встраивание `Info.plist`, полноценное меню) будет ограничена. Тем не менее
главное меню теперь устанавливается вручную в `AppDelegate`, поэтому базовая
работа возможна:

```bash
# Установить зависимости и собрать
swift build

# Запустить (macOS)
swift run NvidiaLLM
```

> Минус: нет `.app`-бандла, `Info.plist` не применяется, иконка приложения
> отсутствует. Для полноценной работы используйте Вариант A.

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
| Настройки из бара | Кликните иконку CPU → кнопка «Settings» | Открывается окно настроек |
| `Cmd+,` | Нажмите в приложении | Открываются настройки |
| Глобальный хоткей | Нажмите `Cmd+Shift+N` из любого приложения | Активируется главное окно |

---

## Требования

| Компонент | Версия |
|-----------|--------|
| macOS | 15.0+ (Sequoia); 26+ (Tahoe) для Liquid Glass |
| Xcode | 16.0+ |
| Swift | 6.0+ |
| Архитектура | Apple Silicon (M1/M2/M3/M4) |
| NVIDIA API | Ключ с [build.nvidia.com](https://build.nvidia.com) |
