# NVIDIA LLM Client for macOS

<p align="center">
  <img src="Resources/Assets.xcassets/AppIcon.appiconset" width="128" height="128" alt="App Icon" />
</p>

Нативное macOS-приложение для работы со всеми моделями NVIDIA через API [`integrate.api.nvidia.com/v1/chat/completions`](https://build.nvidia.com). Построено на Swift 6 + SwiftUI + SwiftData с строгим соответствием дизайн-коду **macOS Tahoe / Liquid Glass**.

---

## Содержание

- [Возможности](#возможности)
- [Скриншоты интерфейса](#скриншоты-интерфейса)
- [Требования](#требования)
- [Сборка и запуск](#сборка-и-запуск)
- [Архитектура](#архитектура)
- [Структура проекта](#структура-проекта)
- [Дизайн-система](#дизайн-система)
- [Метрики](#метрики)
- [Тема оформления](#тема-оформления)
- [Health Check](#health-check)
- [Системный промт](#системный-промт)
- [API](#api)
- [Безопасность](#безопасность)
- [Тестирование](#тестирование)
- [Распространение](#распространение)
- [Зависимости](#зависимости)
- [FAQ](#faq)

---

## Возможности

### Чат
- **Streaming** — ответы token-by-token через Server-Sent Events (SSE)
- **Markdown** — рендеринг через MarkdownUI с подсветкой кода
- **Редактирование** — редактирование и регенерация сообщений
- **Вложения** — drag & drop изображений, вставка из буфера
- **Мультимодал** — текст, изображения (URL/base64), видео (URL)

### Menu Bar
- **Popover** — быстрый доступ через иконку в строке меню
- **Глобальный хоткей** — `Cmd+Shift+N` для переключения popover
- **Быстрый переключатель моделей** — прямо в popover

### Метрики
- **Счётчик токенов** — `prompt_tokens`, `completion_tokens`, `total_tokens` из API `usage`
- **Latency** — Time-to-first-token (TTFT), общее время ответа, tokens/sec
- **Дашборд** — графики по дням, breakdown по моделям, сводка за период
- **Бейджи** — компактный индикатор под каждым ответом ассистента
- **Контекст** — индикатор заполнения контекстного окна с предупреждением
- **Экспорт** — CSV и JSON

### Тема оформления
- **System / Light / Dark** — переключатель с иконками (sun / moon / half-circle)
- **Авто-следование** — "System" автоматически подстраивается под macOS
- **Persisted** — настройка сохраняется между запусками

### Health Check
- **Индикатор доступности модели** — ✅ available / ❌ unavailable / 🔒 no key / 🔄 checking
- **Авто-проверка** — при загрузке моделей и сохранении API-ключа
- **Минимальный запрос** — `max_tokens: 1` для экономии токенов

### Системный промт
- **Global default** — задаётся в Settings, применяется к новым разговорам
- **Per-conversation override** — редактируется в чате через collapsible-панель
- **Сохранение** — в SwiftData, поле `systemPrompt` в `Conversation`

### Прочее
- **Web Search** — research mode через Google Custom Search API
- **История** — SwiftData, поиск, экспорт Markdown/JSON/CSV
- **Безопасность** — API-ключи в macOS Keychain
- **Все параметры** — temperature, top_p, max_tokens, presence/frequency penalty, stop, seed, thinking_mode

---

## Скриншоты интерфейса

> Приложение использует Liquid Glass материалы macOS Tahoe: полупрозрачные панели, vibrancy на тексте, hierarchical SF Symbols.

| Компонент | Описание |
|-----------|----------|
| Main Window | NavigationSplitView: sidebar + message thread + input |
| Menu Bar Popover | Компактный чат 360px с последними сообщениями |
| Settings | 7 вкладок: API, Models, Search, Behavior, History, Metrics, About |
| Metrics Dashboard | Сводка + графики (Swift Charts) + breakdown |
| Usage Badge | Glass capsule под ответом: токены, время, tokens/sec |
| Context Indicator | Glass capsule: estimated tokens / context limit |
| Model Status | Glass capsule: ✅/❌/🔒/🔄 с цветной иконкой |
| Theme Toggle | Иконка в toolbar: 🌓/☀️/🌙 |

---

## Требования

| Компонент | Версия |
|-----------|--------|
| macOS | 15.0+ (Sequoia), рекомендуется 26+ (Tahoe) для Liquid Glass |
| Xcode | 16.0+ |
| Swift | 6.0+ |
| Архитектура | Apple Silicon (M1/M2/M3/M4) |
| NVIDIA API | Ключ с [build.nvidia.com](https://build.nvidia.com) |

---

## Сборка и запуск

### Через Xcode

```bash
# 1. Открыть проект
open NvidiaLLM.xcodeproj

# 2. Сборка (Cmd+B)
# 3. Запуск (Cmd+R)
# 4. Тесты (Cmd+U)
```

### Через командную строку

```bash
# Debug-сборка
xcodebuild -scheme NvidiaLLM -configuration Debug build

# Release-сборка
xcodebuild -scheme NvidiaLLM -configuration Release build

# Запуск
open build/Debug/NvidiaLLM.app

# Тесты
xcodebuild -scheme NvidiaLLM test
```

### Первый запуск

1. Приложение запускается в **Menu Bar** (иконка CPU в строке меню)
2. Открыть **Settings** (`Cmd+,`) → вкладка **API** → ввести NVIDIA API Key
3. (Опционально) Вкладка **Search** → Google Custom Search API Key + CX
4. Вкладка **Models** → выбрать модель по умолчанию + системный промт
5. Нажать на индикатор статуса модели — должен загореться ✅ зелёным
6. Начать диалог в окне или через popover

---

## Архитектура

```
┌─────────────────────────────────────────────────────────┐
│                    macOS App (SwiftUI)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │ Menu Bar │  │   Chat   │  │ Settings │  │  Metrics │ │
│  │  Popover │  │  Window  │  │  Window  │  │ Dashboard│ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘ │
│       │              │              │              │       │
│  ┌────┴──────────────┴──────────────┴──────────────┴────┐ │
│  │                  Services Layer                       │ │
│  │  NVIDIAAPI │ ModelsFetcher │ GoogleSearch │ Keychain │ │
│  │  MetricsStore │ TokenEstimator │ LatencyTracker      │ │
│  │  HealthCheck │ StreamingParser                       │ │
│  └──────────────────────┬────────────────────────────────┘ │
│                         │                                  │
│  ┌──────────────────────┴────────────────────────────────┐ │
│  │              Storage (SwiftData + UserDefaults)        │ │
│  │  Conversation │ Message │ UsageRecord │ AppSettings   │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Паттерны
- **MVVM** — `@Observable` ViewModels для Chat, Popover, Metrics
- **Service Layer** — отдельные сервисы для API, метрик, keychain
- **SwiftData** — нативная персистентность, `@Model` классы
- **AsyncStream** — streaming через `AsyncStream<StreamEvent>`
- **Dependency Injection** — сервисы передаются через `init`

---

## Структура проекта

```
NvidiaLLM/
├── App/
│   ├── NvidiaLLMApp.swift          # @main, ModelContainer, scenes
│   ├── ContentView.swift           # TabView: Chat + Metrics + ThemeToggle
│   └── AppDelegate.swift           # NSApplicationDelegate
│
├── Models/
│   ├── Conversation.swift          # @Model: title, systemPrompt, messages
│   ├── Message.swift               # @Model: role, content, tokens, latency
│   ├── UsageRecord.swift           # @Model: per-request metrics
│   ├── NvidiaModel.swift           # Model metadata + context_length
│   ├── SamplingParams.swift        # temperature, top_p, max_tokens, etc.
│   ├── APIModels.swift             # Request/Response DTOs
│   ├── SSEChunk.swift              # SSE streaming chunk model
│   └── AppSettings.swift           # @Observable UserDefaults wrapper
│
├── Services/
│   ├── NVIDIAAPIService.swift      # Streaming + non-streaming API client
│   ├── StreamingParser.swift       # SSE line parser → SSEChunk
│   ├── ModelsFetcher.swift         # GET /v1/models
│   ├── GoogleSearchService.swift   # Google Custom Search API
│   ├── KeychainManager.swift       # SecItem wrapper
│   ├── MetricsStore.swift          # SwiftData metrics CRUD + aggregation
│   ├── TokenEstimator.swift        # Pre-send context estimation
│   ├── LatencyTracker.swift        # TTFT + response time
│   ├── HealthCheckService.swift    # Model availability check
│   └── APIError.swift              # Error enum with LocalizedError
│
├── Chat/
│   ├── MainChatView.swift          # NavigationSplitView
│   ├── ChatSidebar.swift           # Conversation list + search
│   ├── MessageThreadView.swift     # Scrollable message list
│   ├── MessageBubbleView.swift     # Single message with glass bg
│   ├── ChatInputView.swift         # Input + toolbar + sliders
│   ├── StreamingTextView.swift     # Token-by-token with cursor
│   ├── UsageBadgeView.swift        # Token/latency badge per message
│   ├── ContextIndicatorView.swift  # Context window fill indicator
│   ├── ModelStatusIndicatorView.swift # Health check status badge
│   └── ChatViewModel.swift         # @Observable VM
│
├── MenuBar/
│   ├── MenuBarController.swift     # MenuBarExtra scene
│   ├── PopoverView.swift           # Quick chat popover
│   └── PopoverViewModel.swift      # @Observable VM
│
├── Settings/
│   ├── SettingsView.swift          # TabView scene
│   ├── APISettingsView.swift       # API key (Keychain) + endpoint
│   ├── ModelSettingsView.swift     # Default model + system prompt + params
│   ├── SearchSettingsView.swift    # Google Custom Search config
│   ├── BehaviorSettingsView.swift  # Theme + hotkey + launch + popover
│   ├── HistorySettingsView.swift   # Export + retention + clear
│   ├── MetricsSettingsView.swift   # Retention + export + clear
│   └── AboutView.swift             # Version + links
│
├── Metrics/
│   ├── MetricsView.swift           # Dashboard with period selector
│   ├── MetricsSummaryView.swift    # 6 metric cards (glass)
│   ├── TokenUsageChartView.swift   # Swift Charts bar chart
│   ├── ModelBreakdownView.swift    # Per-model horizontal bars
│   └── MetricsViewModel.swift      # @Observable aggregation
│
├── DesignSystem/
│   ├── VisualEffectView.swift      # NSVisualEffectView wrapper
│   ├── GlassWindowModifier.swift   # .glassWindowBackground()
│   ├── GlassButtonStyle.swift      # ButtonStyle with glass
│   ├── GlassTextFieldStyle.swift   # TextFieldStyle
│   ├── GlassSliderStyle.swift      # Slider + label + value
│   ├── ThemeManager.swift          # AppearanceMode + ThemeManager
│   └── ThemeToggleView.swift       # Sun/moon/system toggle
│
├── Extensions/
│   ├── View+Extensions.swift       # glassBackground, glassCapsuleBackground
│   ├── Color+Extensions.swift      # nvidiaGreen, userBubble, assistantBubble
│   └── Date+Extensions.swift       # relativeTime, shortFormatted, daysAgo
│
├── Resources/
│   ├── Assets.xcassets/            # App icon, colors
│   └── Info.plist                  # Bundle config, ATS, macOS 15+
│
├── Tests/
│   ├── StreamingParserTests.swift      # SSE parsing (7 tests)
│   ├── TokenEstimatorTests.swift       # Token estimation (8 tests)
│   ├── MetricsStoreTests.swift         # Metrics CRUD + aggregation (5 tests)
│   ├── NVIDIAAPIServiceTests.swift     # API error handling (3 tests)
│   ├── ModelsFetcherTests.swift        # Model fetching (3 tests)
│   ├── ChatViewModelTests.swift        # VM operations (5 tests)
│   └── HealthCheckServiceTests.swift   # Health check + theme (9 tests)
│
├── Package.swift                   # SPM manifest
└── README.md                       # This file
```

**Итого: 55 файлов** в 10 модулях.

---

## Дизайн-система

### macOS Tahoe / Liquid Glass

Приложение строго следует дизайн-коду macOS Tahoe:

| Принцип | Реализация |
|---------|------------|
| **Liquid Glass** | `.glassEffect()` на macOS 26+, fallback `.ultraThinMaterial` |
| **Vibrancy** | `NSVisualEffectView` с `.hudWindow` material |
| **SF Symbols** | Все иконки — системные, `.symbolRenderingMode(.hierarchical)` |
| **Шрифты** | System font (SF Pro), `.design(.monospaced)` для чисел |
| **Цвета** | Semantic colors (`.primary`, `.secondary`, `.tertiary`), `.accentColor` |
| **Скругления** | 10–14pt для карточек, 6–8pt для кнопок, capsule для бейджей |
| **Анимации** | `.spring(duration: 0.2)` для нажатий, `.easeOut` для скролла |
| **HIG** | System button styles, proper keyboard navigation, accessibility |

### Glass-компоненты

```swift
// Glass background для панелей
.glassBackground(cornerRadius: 14)

// Glass capsule для бейджей
.glassCapsuleBackground()

// Glass window background
.glassWindowBackground()

// Glass button
.buttonStyle(GlassButtonStyle(prominence: .prominent))
```

### SF Symbols

Все иконки используют hierarchical rendering mode для глубины:

```swift
Image(systemName: "cpu")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.nvidiaGreen)
```

---

## Метрики

### Что собирается

| Метрика | Источник | Когда |
|---------|----------|-------|
| `prompt_tokens` | API `usage` | После каждого запроса |
| `completion_tokens` | API `usage` | После каждого запроса |
| `total_tokens` | API `usage` | После каждого запроса |
| TTFT (ms) | `LatencyTracker` | Время до первого токена |
| Response time (ms) | `LatencyTracker` | Полное время генерации |
| Tokens/sec | Расчёт | `completion_tokens / generation_time` |

### Где смотреть

1. **В чате** — `UsageBadgeView` под каждым ответом ассистента
   - Компактно: `↑10 ↓20 · 1.2s`
   - Раскрывается: input/output/total/model
2. **Дашборд** — вкладка Metrics в главном окне
   - 6 карточек: Requests, Total Tokens, Prompt, Completion, Avg TTFT, Avg Response
   - График ежедневного использования (Swift Charts)
   - Top моделей по токенам
   - Latency-статистика
3. **Экспорт** — Settings → Metrics → CSV/JSON

### Контекст

`ContextIndicatorView` в панели ввода показывает:
- Оценку токенов текущего контекста (pre-send)
- Заполнение контекстного окна модели (`context_length`)
- Цветной прогресс-бар: 🟢 <60% / 🟡 <80% / 🔴 >80%
- Предупреждение при приближении к лимиту

---

## Тема оформления

### Режимы

| Режим | Иконка | Описание |
|-------|--------|----------|
| System | `circle.lefthalf.filled` | Следует за macOS |
| Light | `sun.max.fill` | Светлая |
| Dark | `moon.stars.fill` | Тёмная |

### Управление

- **Toolbar** — кнопка `ThemeToggleView` в правом верхнем углу
  - Клик циклит: system → light → dark → system
  - Правый клилк — меню для прямого выбора
- **Settings** → Behavior → Appearance — segmented picker

### Реализация

```swift
// ThemeManager — @Observable, persisted в UserDefaults
@Observable final class ThemeManager {
    var appearance: AppearanceMode  // system / light / dark
}

// Применение в App
.preferredColorScheme(theme.appearance.colorScheme)
```

---

## Health Check

### Как работает

`HealthCheckService` отправляет минимальный запрос к API:

```json
{
  "model": "nvidia/llama-3.1-nemotron-70b-instruct",
  "messages": [{"role": "user", "content": "Hi"}],
  "max_tokens": 1,
  "stream": false
}
```

### Статусы

| Статус | Иконка | Цвет | Условие |
|--------|--------|------|---------|
| Unknown | `questionmark.circle` | серый | Не проверялась |
| Checking | `arrow.triangle.2.circlepath` | синий | Идёт проверка (вращается) |
| Available | `checkmark.circle.fill` | зелёный | HTTP 200 или 429 |
| Unavailable | `xmark.circle.fill` | красный | 401/403/404/5xx/ network |
| No API key | `lock.circle` | оранжевый | Ключ не задан |

### Где отображается

`ModelStatusIndicatorView` — glass capsule рядом с переключателем моделей в панели ввода. Клик запускает повторную проверку.

---

## Системный промт

### Уровни

1. **Global default** — Settings → Models → Default System Prompt
   - Применяется ко всем новым разговорам
   - Сохраняется в `AppSettings.defaultSystemPrompt`
2. **Per-conversation** — collapsible-панель в панели ввода (иконка `gearshape`)
   - Переопределяет global default
   - Сохраняется в `Conversation.systemPrompt`

### Отправка

Системный промт отправляется как первое сообщение с `role: "system"`:

```json
{
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello"}
  ]
}
```

---

## API

### Endpoint

```
POST https://integrate.api.nvidia.com/v1/chat/completions
GET  https://integrate.api.nvidia.com/v1/models
```

### Streaming

```swift
// Запрос с include_usage для получения токенов в финальном чанке
{
  "model": "...",
  "messages": [...],
  "stream": true,
  "stream_options": {"include_usage": true}
}

// Финальный SSE-чанк содержит usage:
data: {"choices":[],"usage":{"prompt_tokens":10,"completion_tokens":20,"total_tokens":30}}
data: [DONE]
```

### Параметры

| Параметр | Тип | Default |
|----------|-----|---------|
| `temperature` | Double | 0.7 |
| `top_p` | Double | 0.95 |
| `max_tokens` | Int | 1024 |
| `presence_penalty` | Double | 0 |
| `frequency_penalty` | Double | 0 |
| `stop` | [String] | nil |
| `seed` | Int | nil |
| `chat_template_kwargs.thinking_mode` | String | "off" |

---

## Безопасность

| Данные | Хранилище |
|--------|-----------|
| NVIDIA API Key | macOS Keychain (`SecItem`) |
| Google Search API Key | macOS Keychain |
| Google Search CX | macOS Keychain |
| Conversations | SwiftData (SQLite, локально) |
| Usage Records | SwiftData (SQLite, локально) |
| Settings | UserDefaults |

API-ключи **никогда** не сохраняются в UserDefaults или plain text.

---

## Тестирование

```bash
# Запуск всех тестов
xcodebuild -scheme NvidiaLLM test

# Или через Xcode: Cmd+U
```

### Покрытие

| Тест-файл | Тестов | Что покрывает |
|-----------|--------|---------------|
| `StreamingParserTests` | 7 | SSE-парсинг: delta, usage, [DONE], ошибки |
| `TokenEstimatorTests` | 8 | Оценка токенов: EN/Cyrillic, context, limits |
| `MetricsStoreTests` | 5 | CRUD, aggregation, breakdown, CSV export |
| `NVIDIAAPIServiceTests` | 3 | Missing key, invalid URL, stream error |
| `ModelsFetcherTests` | 3 | Fetch, displayName |
| `ChatViewModelTests` | 5 | CRUD conversations, send without key, context |
| `HealthCheckServiceTests` | 9 | Health check statuses, theme cycle |

**Итого: 40 тестов.**

---

## Распространение

### Ручная сборка

```bash
# Archive
xcodebuild -scheme NvidiaLLM -configuration Release archive \
  -archivePath build/NvidiaLLM.xcarchive

# Export .app
xcodebuild -exportArchive \
  -archivePath build/NvidiaLLM.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist
```

### Подпись и Notarization

```bash
# Codesign
codesign --deep --force --verify --verbose=4 \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  build/NvidiaLLM.app

# Notarize
xcrun notarytool submit build/NvidiaLLM.zip \
  --apple-id "you@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# Staple
xcrun stapler staple build/NvidiaLLM.app
```

### CI/CD (опционально)

- **GitHub Actions** / **Xcode Cloud** — build + test на каждый PR
- Автоматический archive + notarization для release-тегов

---

## Зависимости

| Пакет | Версия | Назначение |
|-------|--------|------------|
| [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) | 2.4+ | Рендеринг Markdown |
| [HotKey](https://github.com/soffes/HotKey) | 0.2+ | Глобальные горячие клавиши |

Минимум внешних зависимостей — всё остальное нативное (SwiftUI, SwiftData, Swift Charts, Security, AppKit).

---

## FAQ

### Где получить NVIDIA API Key?
На [build.nvidia.com](https://build.nvidia.com) — войти через NVIDIA Developer аккаунт, выбрать модель, нажать "Get API Key".

### Почему нет оценки стоимости?
NVIDIA NIM pricing меняется со временем и не доступен через API. Мы показываем только токены и latency, которые приходят напрямую из ответа API и гарантированно точны.

### Работает ли на Intel Mac?
Нет. Приложение targeting Apple Silicon (M1+). Минимум macOS 15.

### Можно ли использовать другой API endpoint?
Да — Settings → API → Endpoint. Любой OpenAI-compatible endpoint работает.

### Где хранятся данные?
`~/Library/Application Support/com.nvidia-llm.app/` — SwiftData SQLite база.

### Как экспортировать историю?
Settings → History → Export as Markdown / JSON.

### Как экспортировать метрики?
Settings → Metrics → Export as CSV / JSON.

---

## Лицензия

Private project. All rights reserved.
