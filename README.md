# NVIDIA LLM Client for macOS

<p align="center">
  <img src="Resources/Assets.xcassets/AppIcon.appiconset" width="128" height="128" alt="App Icon" />
</p>

A native macOS application for accessing all NVIDIA LLM models via the [`integrate.api.nvidia.com/v1/chat/completions`](https://build.nvidia.com) API. Built with Swift 6 + SwiftUI + SwiftData, strictly following the **macOS Tahoe / Liquid Glass** design code.

---

## Table of Contents

- [Features](#features)
- [Interface Overview](#interface-overview)
- [Requirements](#requirements)
- [Build & Run](#build--run)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Design System](#design-system)
- [Metrics](#metrics)
- [Theme](#theme)
- [Health Check](#health-check)
- [System Prompt](#system-prompt)
- [API](#api)
- [Error Handling](#error-handling)
- [Security](#security)
- [Testing](#testing)
- [Distribution](#distribution)
- [Dependencies](#dependencies)
- [FAQ](#faq)

---

## Features

### Chat
- **Streaming** — token-by-token responses via Server-Sent Events (SSE)
- **Markdown** — rendering via MarkdownUI with code highlighting
- **Editing** — message editing and regeneration
- **Attachments** — drag & drop images, paste from clipboard
- **Multimodal** — text, images (URL/base64), video (URL)

### Menu Bar
- **Popover** — quick access via menu bar icon
- **Global Hotkey** — `Cmd+Shift+N` to toggle popover
- **Quick Model Switcher** — directly in the popover

### Metrics
- **Token Counter** — `prompt_tokens`, `completion_tokens`, `total_tokens` from API `usage`
- **Latency** — Time-to-first-token (TTFT), total response time, tokens/sec
- **Dashboard** — daily charts, per-model breakdown, period summary
- **Badges** — compact indicator under each assistant response
- **Context** — context window fill indicator with overflow warning
- **Export** — CSV and JSON

### Theme
- **System / Light / Dark** — toggle with icons (sun / moon / half-circle)
- **Auto-follow** — "System" automatically matches macOS appearance
- **Persisted** — preference saved between launches

### Health Check
- **Model availability indicator** — ✅ available / ❌ unavailable / 🔒 no key / 🔄 checking
- **Auto-check** — on model load and API key save
- **Minimal request** — `max_tokens: 1` to conserve tokens

### System Prompt
- **Global default** — set in Settings, applied to new conversations
- **Per-conversation override** — editable in chat via collapsible panel
- **Persisted** — in SwiftData, `systemPrompt` field in `Conversation`

### Other
- **Web Search** — research mode via Google Custom Search API
- **History** — SwiftData, search, export to Markdown/JSON/CSV
- **Security** — API keys stored in macOS Keychain
- **All parameters** — temperature, top_p, max_tokens, presence/frequency penalty, stop, seed, thinking_mode

---

## Interface Overview

> The app uses Liquid Glass materials from macOS Tahoe: translucent panels, vibrancy on text, hierarchical SF Symbols.

| Component | Description |
|-----------|-------------|
| Main Window | NavigationSplitView: sidebar + message thread + input |
| Menu Bar Popover | Compact 360px chat with recent messages |
| Settings | 7 tabs: API, Models, Search, Behavior, History, Metrics, About |
| Metrics Dashboard | Summary + charts (Swift Charts) + model breakdown |
| Usage Badge | Glass capsule under response: tokens, time, tokens/sec |
| Context Indicator | Glass capsule: estimated tokens / context limit |
| Model Status | Glass capsule: ✅/❌/🔒/🔄 with colored icon |
| Theme Toggle | Toolbar icon: 🌓/☀️/🌙 |

---

## Requirements

| Component | Version |
|-----------|---------|
| macOS | 15.0+ (Sequoia), 26+ (Tahoe) recommended for Liquid Glass |
| Xcode | 16.0+ |
| Swift | 6.0+ |
| Architecture | Apple Silicon (M1/M2/M3/M4) |
| NVIDIA API | Key from [build.nvidia.com](https://build.nvidia.com) |

---

## Build & Run

### Via Xcode

```bash
# 1. Open the project
open NvidiaLLM.xcodeproj

# 2. Build (Cmd+B)
# 3. Run (Cmd+R)
# 4. Tests (Cmd+U)
```

### Via Command Line

```bash
# Debug build
xcodebuild -scheme NvidiaLLM -configuration Debug build

# Release build
xcodebuild -scheme NvidiaLLM -configuration Release build

# Run
open build/Debug/NvidiaLLM.app

# Tests
xcodebuild -scheme NvidiaLLM test
```

### First Launch

1. The app launches in the **Menu Bar** (CPU icon in the menu bar)
2. Open **Settings** (`Cmd+,`) → **API** tab → enter NVIDIA API Key
3. (Optional) **Search** tab → Google Custom Search API Key + CX
4. **Models** tab → select default model + system prompt
5. Click the model status indicator — it should turn ✅ green
6. Start chatting in the window or via the popover

---

## Architecture

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

### Patterns
- **MVVM** — `@Observable` ViewModels for Chat, Popover, Metrics
- **Service Layer** — separate services for API, metrics, keychain
- **SwiftData** — native persistence, `@Model` classes
- **AsyncStream** — streaming via `AsyncStream<StreamEvent>`
- **Dependency Injection** — services passed through `init`

---

## Project Structure

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
│   ├── ErrorStateView.swift        # Error banner with retry button
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
│   ├── BehaviorSettingsView.swift  # Theme + hotkey + launch + network
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
│   ├── Assets.xcassets/            # App icon, AccentColor
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

**Total: 62 files** across 10 modules.

---

## Design System

### macOS Tahoe / Liquid Glass

The app strictly follows the macOS Tahoe design code:

| Principle | Implementation |
|-----------|----------------|
| **Liquid Glass** | `.glassEffect()` on macOS 26+, fallback `.ultraThinMaterial` |
| **Vibrancy** | `NSVisualEffectView` with `.hudWindow` material |
| **SF Symbols** | All icons are system, `.symbolRenderingMode(.hierarchical)` |
| **Fonts** | System font (SF Pro), `.design(.monospaced)` for numbers |
| **Colors** | Semantic colors (`.primary`, `.secondary`, `.tertiary`), `.accentColor` |
| **Corners** | 10–14pt for cards, 6–8pt for buttons, capsule for badges |
| **Animations** | `.spring(duration: 0.2)` for presses, `.easeOut` for scroll |
| **HIG** | System button styles, proper keyboard navigation, accessibility |

### Glass Components

```swift
// Glass background for panels
.glassBackground(cornerRadius: 14)

// Glass capsule for badges
.glassCapsuleBackground()

// Glass window background
.glassWindowBackground()

// Glass button
.buttonStyle(GlassButtonStyle(prominence: .prominent))
```

### SF Symbols

All icons use hierarchical rendering mode for depth:

```swift
Image(systemName: "cpu")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.nvidiaGreen)
```

---

## Metrics

### What is Collected

| Metric | Source | When |
|--------|--------|------|
| `prompt_tokens` | API `usage` | After each request |
| `completion_tokens` | API `usage` | After each request |
| `total_tokens` | API `usage` | After each request |
| TTFT (ms) | `LatencyTracker` | Time to first token |
| Response time (ms) | `LatencyTracker` | Total generation time |
| Tokens/sec | Calculated | `completion_tokens / generation_time` |

### Where to View

1. **In chat** — `UsageBadgeView` under each assistant response
   - Compact: `↑10 ↓20 · 1.2s`
   - Expanded: input/output/total/model
2. **Dashboard** — Metrics tab in the main window
   - 6 cards: Requests, Total Tokens, Prompt, Completion, Avg TTFT, Avg Response
   - Daily token usage chart (Swift Charts)
   - Top models by tokens
   - Latency statistics
3. **Export** — Settings → Metrics → CSV/JSON

### Context

`ContextIndicatorView` in the input panel shows:
- Estimated tokens for the current context (pre-send)
- Context window fill (`context_length` from model metadata)
- Colored progress bar: 🟢 <60% / 🟡 <80% / 🔴 >80%
- Warning when approaching the limit

---

## Theme

### Modes

| Mode | Icon | Description |
|------|------|-------------|
| System | `circle.lefthalf.filled` | Follows macOS |
| Light | `sun.max.fill` | Light |
| Dark | `moon.stars.fill` | Dark |

### Controls

- **Toolbar** — `ThemeToggleView` button in the top-right corner
  - Click cycles: system → light → dark → system
  - Right-click opens a menu for direct selection
- **Settings** → Behavior → Appearance — segmented picker

### Implementation

```swift
// ThemeManager — @Observable, persisted in UserDefaults
@Observable final class ThemeManager {
    var appearance: AppearanceMode  // system / light / dark
}

// Applied in App
.preferredColorScheme(theme.appearance.colorScheme)
```

---

## Health Check

### How it Works

`HealthCheckService` sends a minimal request to the API:

```json
{
  "model": "nvidia/llama-3.1-nemotron-70b-instruct",
  "messages": [{"role": "user", "content": "Hi"}],
  "max_tokens": 1,
  "stream": false
}
```

### Statuses

| Status | Icon | Color | Condition |
|--------|------|-------|-----------|
| Unknown | `questionmark.circle` | gray | Not checked |
| Checking | `arrow.triangle.2.circlepath` | blue | In progress (rotating) |
| Available | `checkmark.circle.fill` | green | HTTP 200 or 429 |
| Unavailable | `xmark.circle.fill` | red | 401/403/404/5xx/network |
| No API key | `lock.circle` | orange | Key not set |

### Where Displayed

`ModelStatusIndicatorView` — glass capsule next to the model selector in the input panel. Click triggers a re-check.

---

## System Prompt

### Levels

1. **Global default** — Settings → Models → Default System Prompt
   - Applied to all new conversations
   - Stored in `AppSettings.defaultSystemPrompt`
2. **Per-conversation** — collapsible panel in the input area (`gearshape` icon)
   - Overrides the global default
   - Stored in `Conversation.systemPrompt`

### Sending

The system prompt is sent as the first message with `role: "system"`:

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
// Request with include_usage to get token counts in the final chunk
{
  "model": "...",
  "messages": [...],
  "stream": true,
  "stream_options": {"include_usage": true}
}

// The final SSE chunk contains usage:
data: {"choices":[],"usage":{"prompt_tokens":10,"completion_tokens":20,"total_tokens":30}}
data: [DONE]
```

### Parameters

| Parameter | Type | Default |
|-----------|------|---------|
| `temperature` | Double | 0.7 |
| `top_p` | Double | 0.95 |
| `max_tokens` | Int | 1024 |
| `presence_penalty` | Double | 0 |
| `frequency_penalty` | Double | 0 |
| `stop` | [String] | nil |
| `seed` | Int | nil |
| `chat_template_kwargs.thinking_mode` | String | "off" |

---

## Error Handling

### Retry with Exponential Backoff

- **3 attempts** max with exponential backoff (1s → 2s → 4s)
- **Retries for:** 429 (rate limited), 5xx (server errors), timeout, network connection lost, no internet
- **Respects `Retry-After` header** from the server
- **Does not retry:** 401/403 (auth), 404 (not found), 400 (bad request), decoding errors

### Configurable Timeouts

Settings → Behavior → Network:

| Parameter | Default | Range | Meaning |
|-----------|---------|-------|---------|
| Request timeout | 30s | 10–120s | Time without data before timeout |
| Resource timeout | 120s | 30–600s | Total time including retries |
| Max retries | 3 | 0–10 | Retry attempts for transient errors |

### Error State View

`ErrorStateView` — glass background with:
- Hierarchical SF Symbol `exclamationmark.triangle.fill`
- **Retry button** — re-sends the last request
- **Dismiss button** (X) — clears the error

### Error Map

| Error | What happens | Retry? |
|-------|-------------|--------|
| No API key | "Set API key in Settings" | ❌ |
| Invalid URL | "API URL is invalid" | ❌ |
| 401/403 Auth | "Auth failed" | ❌ |
| 404 Not found | "Model not found" | ❌ |
| 429 Rate limited | Waits `Retry-After` or backoff | ✅ 3 times |
| 5xx Server error | Exponential backoff | ✅ 3 times |
| Timeout | Exponential backoff | ✅ 3 times |
| Network lost | Exponential backoff | ✅ 3 times |
| No internet | Exponential backoff | ✅ 3 times |
| Decoding error | "Failed to decode" | ❌ |
| Stream error | "Streaming error: ..." | ❌ |

---

## Security

| Data | Storage |
|------|---------|
| NVIDIA API Key | macOS Keychain (`SecItem`) |
| Google Search API Key | macOS Keychain |
| Google Search CX | macOS Keychain |
| Conversations | SwiftData (SQLite, local) |
| Usage Records | SwiftData (SQLite, local) |
| Settings | UserDefaults |

API keys are **never** stored in UserDefaults or plain text.

---

## Testing

```bash
# Run all tests
xcodebuild -scheme NvidiaLLM test

# Or via Xcode: Cmd+U
```

### Coverage

| Test File | Tests | What it Covers |
|-----------|-------|----------------|
| `StreamingParserTests` | 7 | SSE parsing: delta, usage, [DONE], errors |
| `TokenEstimatorTests` | 8 | Token estimation: EN/Cyrillic, context, limits |
| `MetricsStoreTests` | 5 | CRUD, aggregation, breakdown, CSV export |
| `NVIDIAAPIServiceTests` | 3 | Missing key, invalid URL, stream error |
| `ModelsFetcherTests` | 3 | Fetch, displayName |
| `ChatViewModelTests` | 5 | CRUD conversations, send without key, context |
| `HealthCheckServiceTests` | 9 | Health check statuses, theme cycle |

**Total: 40 tests.**

---

## Distribution

### Manual Build

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

### Code Signing and Notarization

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

### CI/CD (optional)

- **GitHub Actions** / **Xcode Cloud** — build + test on every PR
- Automatic archive + notarization for release tags

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) | 2.4+ | Markdown rendering |
| [HotKey](https://github.com/soffes/HotKey) | 0.2+ | Global keyboard shortcuts |

Minimal external dependencies — everything else is native (SwiftUI, SwiftData, Swift Charts, Security, AppKit).

---

## FAQ

### Where do I get an NVIDIA API Key?
On [build.nvidia.com](https://build.nvidia.com) — log in with an NVIDIA Developer account, select a model, click "Get API Key".

### Why is there no cost estimation?
NVIDIA NIM pricing changes over time and is not exposed via the API. We only show tokens and latency, which come directly from the API response and are guaranteed to be accurate.

### Does it work on Intel Macs?
No. The app targets Apple Silicon (M1+). Minimum macOS 15.

### Can I use a different API endpoint?
Yes — Settings → API → Endpoint. Any OpenAI-compatible endpoint works.

### Where is data stored?
`~/Library/Application Support/com.nvidia-llm.app/` — SwiftData SQLite database.

### How do I export history?
Settings → History → Export as Markdown / JSON.

### How do I export metrics?
Settings → Metrics → Export as CSV / JSON.

---

## License

Private project. All rights reserved.
