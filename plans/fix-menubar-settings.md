# План: исправление меню бара и открытия настроек

## Контекст и корневые причины

Проект сейчас собирается как «голый» SPM-исполняемый файл (`swift run`), а не как
полноценный `.app`-бандл. Из-за этого:

1. [`Resources/Info.plist`](../Resources/Info.plist:1) не встраивается в бандл.
2. Нет главного меню приложения (`NSApp.mainMenu`) — [`AppDelegate.swift`](../App/AppDelegate.swift:5) оставляет `applicationDidFinishLaunching` пустым.
3. Кнопка Settings в [`PopoverView.swift`](../MenuBar/PopoverView.swift:101) использует `NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)`, который опирается на responder chain и авто-сгенерированное меню — его нет, поэтому действие молча ничего не делает.

Дополнительно: глобальный хоткей `Cmd+Shift+N` не реализован (зависимость `HotKey` объявлена, но нигде не используется).

---

## План исправлений

### Шаг 1. Создать Xcode-проект (`.xcodeproj`) — основа для бандла

SPM-исполняемый файл принципиально не может дать полноценное macOS-приложение с
меню, бандлом и встроенным `Info.plist`. Нужен Xcode-проект.

- Создать `NvidiaLLM.xcodeproj` (macOS App, SwiftUI lifecycle, Swift 6, macOS 15+).
- Цель `NvidiaLLM` со всеми исходниками из директорий: `App/`, `Models/`, `Services/`,
  `Chat/`, `MenuBar/`, `Settings/`, `Metrics/`, `DesignSystem/`, `Extensions/`.
- Включить `Resources/Info.plist` как Info.plist цели (поле "Info.plist File").
- Включить `Resources/Assets.xcassets` в ресурсы цели.
- Добавить SPM-зависимости: `swift-markdown-ui` (≥2.4.0), `HotKey` (≥0.2.0).
- Оставить [`Package.swift`](../Package.swift:1) для CI/тулинга, но сборку приложения вести через Xcode.

**Почему это важно:** только `.app`-бандл даёт корректное главное меню, встраивание
`Info.plist` и работающую сцену `Settings { ... }`.

### Шаг 2. Установить главное меню приложения в `AppDelegate`

В [`AppDelegate.swift`](../App/AppDelegate.swift:5) реализовать `applicationDidFinishLaunching`,
создающий `NSApp.mainMenu` с минимальной структурой:

- Меню приложения: About, Settings… (`Cmd+,`), Quit (`Cmd+Q`).
- Пункт «Settings…» должен вызывать открытие окна настроек.

Это гарантирует, что:
- Появится верхнее меню приложения (решает «нет меню бара»).
- Появится responder для `showSettingsWindow:` / `Cmd+,`.

### Шаг 3. Надёжно открывать настройки из поповера

В [`PopoverView.swift`](../MenuBar/PopoverView.swift:101) заменить хрупкий
`sendAction` на современный API:

- Использовать `@Environment(\.openSettings)` (macOS 14+, цель — macOS 15).
- Кнопка Settings вызывает `openSettings()`.

Это убирает зависимость от responder chain и селектора `showSettingsWindow:`,
который молча не срабатывает без главного меню.

### Шаг 4. Реализовать глобальный хоткей (опционально, но заявлено в README)

- Импортировать `HotKey` в [`AppDelegate.swift`](../App/AppDelegate.swift:5).
- В `applicationDidFinishLaunching` создать `HotKey` из `AppSettings.shared.globalHotkey`
  (по умолчанию `cmd+shift+n`), который открывает/фокусирует главное окно или поповер.
- Реагировать на изменение настройки (пересоздавать `HotKey`).

### Шаг 5. Проверка

- Сборка через Xcode (`Cmd+B` / `Cmd+R`).
- Появляется иконка CPU в статус-баре → клик → поповер.
- В поповере кнопка Settings открывает окно настроек.
- Верхнее меню приложения содержит пункт Settings (`Cmd+,`).
- (Опц.) `Cmd+Shift+N` открывает окно/поповер.

---

## Затронутые файлы

| Файл | Изменение |
|------|-----------|
| `NvidiaLLM.xcodeproj` (новый) | Создать проект, цель, ресурсы, зависимости |
| [`App/AppDelegate.swift`](../App/AppDelegate.swift:5) | Установить `NSApp.mainMenu`, (опц.) `HotKey` |
| [`MenuBar/PopoverView.swift`](../MenuBar/PopoverView.swift:101) | `openSettings()` вместо `sendAction` |
| [`Package.swift`](../Package.swift:1) | Без изменений (оставить для тулинга) |

## Риски / заметки

- Создание `.xcodeproj` — ручной шаг в Xcode; я могу подготовить структуру и инструкции,
  но сам файл проекта удобнее создать через Xcode UI.
- `@Environment(\.openSettings)` требует macOS 14+ — целевая платформа macOS 15, ОК.
- Если оставить сборку только через SPM, главное меню можно установить вручную в
  `AppDelegate`, но без бандла `Info.plist` и полноценного `.app` часть поведения
  останется ограниченной.
