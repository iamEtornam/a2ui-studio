# A2UI Studio — AI Mini App Builder for Flutter

A cross-platform **Flutter** studio (Mobile, Web, and Desktop) powered by **[`a2ui_flutter`](https://pub.dev/packages/a2ui_flutter)** (`v0.4.0`) and **[`a2ui_core`](https://pub.dev/packages/a2ui_core)** (`v0.8.0`) that lets you describe, iteratively refine, preview, save, and share interactive mini apps generated live by AI.

---

## Key Features

- **Multi-Chat Mini App Builder**: Create, filter, pin, switch between, and delete multiple chat sessions. Describe any mini app in natural language (e.g., *"Create a mini app to track my to-dos with a calendar, embedded chat, and local notifications"*) and iterate conversationally until it's ready.
- **Live `a2ui_flutter` v1.0 Rendering**: Renders real, safe, declarative A2UI v1.0 surfaces as native Flutter widgets combining `basicCatalog()` with a custom interactive `StudioCatalog`:
  - `MiniAppHeader` — Branded app bar with status badge & notification trigger
  - `CalendarWidget` — Interactive monthly schedule calendar with event markers
  - `TodoBoard` — Add, complete, delete, and drag-to-reorder task board
  - `MiniChatPanel` — Live AI-powered embedded assistant chat inside your mini app
  - `LocalNotificationCard` — Instant & scheduled local notification alerts
  - `MetricChartCard` — KPI summary with sparkline chart
  - `PomodoroTimer` — Working focus countdown timer with completion alert
  - `HabitHeatmap` — Interactive daily habit streak grid
- **Zero-API-Key Installed CLI Auth (Desktop)**: Automatically scans your machine for already-installed AI CLIs — **Antigravity CLI (`agy`)**, **Claude Code CLI (`claude`)**, **Codex CLI (`codex`)**, **Gemini CLI (`gemini`)**, and **Ollama (`ollama`)**. Click **Connect** to reuse your CLI's existing authentication with zero API key setup, including live model discovery (`agy models` / `ollama list`).
- **Dynamic Online Gemini Model Discovery**: Optionally connect a Google Gemini API key to fetch the latest available generative models directly from `generativelanguage.googleapis.com/v1beta/models` — no hardcoded model list.
- **Private & Public Mini App Library**: Click **Save to Library** when you're happy with your mini app. Choose:
  - **Private Vault** — Only you can see, install, and use it.
  - **Public Community** — Discoverable, installable, and forkable by others.
  - Launch any saved mini app live, toggle Private/Public visibility anytime, or **Fork** it into a new chat session to iterate further.
- **Studio Workspace & Multi-Platform Device Preview**: Inspect the live A2UI Widget Tree, raw A2UI v1.0 JSON schema, and Properties; test your mini app simultaneously in synchronized Mobile (`iPhone 16 Pro`) and Desktop/Web viewports with a live Telemetry & Diagnostics console.
- **Adaptive Responsive UI & Dual Themes**: Automatically adapts across Desktop (`>= 1040px` sidebar), Tablet (`680px–1039px` rail), and Mobile (`< 680px` bottom navigation bar), with **Obsidian Kinetic (Dark)** and **Lumen Kinetic (Light)** themes.

---

## Architecture

```text
lib/
├── main.dart
├── app.dart
├── domain/models/
│   ├── ai_model_info.dart           # Dynamically fetched AI model metadata
│   ├── chat_session.dart            # Multi-chat sessions, turns, telemetry, A2UI JSON
│   ├── installed_cli.dart           # Discovered local AI CLI metadata
│   ├── mini_app.dart                # Library mini app (Private/Public visibility)
│   └── studio_settings.dart         # Active backend (CLI or API), theme, preferences
├── data/
│   ├── services/
│   │   ├── a2ui_ai_service.dart     # Live Gemini REST API + Installed CLI orchestration
│   │   ├── local_cli_service.dart   # Cross-platform CLI discovery & execution (IO/Web)
│   │   ├── local_notification_service.dart # Cross-platform notification HUD & scheduler
│   │   └── storage_service.dart     # Local SharedPreferences persistence
│   └── repositories/
│       └── studio_repository.dart   # Single source of truth for sessions, library & settings
└── ui/
    ├── core/
    │   ├── a2ui/
    │   │   ├── a2ui_sanitizer.dart  # Strict A2UI v1.0 envelope sanitizer
    │   │   ├── a2ui_surface_host.dart # Reusable live A2uiSurface host
    │   │   └── studio_catalog.dart  # Custom interactive A2UI v1.0 component catalog
    │   ├── theme/                   # Obsidian Kinetic (Dark) & Lumen Kinetic (Light)
    │   └── widgets/                 # Adaptive AppShell, Save Dialog, Live Runner, Toast HUD
    └── features/
        ├── chat_sessions/           # Multi-chat builder hub
        ├── workspace/               # Split-pane Studio Workspace & A2UI Inspector
        ├── library/                 # Private Vault & Public Community Mini App Library
        ├── device_preview/          # Synchronized Mobile + Desktop/Web Simulator
        ├── settings/                # Installed CLIs, Gemini API key, Models & Appearance
        └── studio/                  # StudioViewModel (ChangeNotifier)
```

---

## Prerequisites

- **Flutter SDK** `3.38+` (tested on Flutter `3.50.1` / Dart `3.14.0`)
- Platform toolchains for your target(s):
  - **macOS Desktop**: Xcode + CocoaPods
  - **Web**: Chrome
  - **iOS / Android**: Xcode / Android Studio
- **AI Backend** (choose one):
  - **Desktop (Zero API Key)**: Any signed-in local CLI (`agy`, `claude`, `codex`, `gemini`, or `ollama`)
  - **All Platforms**: A [Google Gemini API key](https://aistudio.google.com/apikey)

---

## Setup & Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/iamEtornam/a2ui-studio.git
   cd a2ui-studio
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # macOS Desktop (supports Installed AI CLI auto-discovery)
   flutter run -d macos

   # Web
   flutter run -d chrome

   # iOS / Android
   flutter run
   ```

4. **Connect an AI Provider**
   - Open **Settings & API Keys** inside the app.
   - **Option A (Desktop — No API Key Required)**: Under **Installed AI CLIs**, click **Connect** next to any detected CLI (`Antigravity CLI`, `Claude Code CLI`, `Codex CLI`, `Gemini CLI`, or `Ollama CLI`). For `agy` and `ollama`, select your preferred model from the live-fetched dropdown.
   - **Option B (Any Platform — Gemini API Key)**: Paste your `GEMINI_API_KEY` and click **Save & Fetch Models** to dynamically pull the latest generative models from Google's API.

---

## Running Tests & Builds

```bash
# Run unit & widget tests
flutter test

# Build for Web (supports Wasm)
flutter build web

# Build for macOS Desktop
flutter build macos
```

---

## Security & Distribution Notes

- **API Key Handling**: Gemini API requests send your key via the `x-goog-api-key` HTTP header (never in URL query parameters). On Web builds, API keys are kept in memory for the active session and are never written to `localStorage`.
- **Installed CLI Allowlist**: On Desktop, `LocalCliService` only executes binaries from a fixed allowlist (`agy`, `claude`, `codex`, `gemini`, `ollama`) freshly resolved from system directories, validates model identifiers against a strict regex, and enforces execution timeouts.
- **A2UI Sandbox**: Surfaces run strictly on A2UI protocol `v1.0` with `openUrl` disabled and component/envelope sanitization via `A2uiSanitizer`.
- **macOS Distribution**: `macos/Runner/Release.entitlements` sets `com.apple.security.app-sandbox = false` so direct-distributed developer builds can invoke locally installed AI CLIs. Re-enable `com.apple.security.app-sandbox = true` if submitting to the Mac App Store (CLI execution will be disabled in sandboxed builds).

---

## License

Private repository — all rights reserved.
