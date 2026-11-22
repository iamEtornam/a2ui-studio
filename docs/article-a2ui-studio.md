---
title: "Building A2UI Studio: A Cross-Platform AI Mini App Builder with Flutter and a2ui_flutter"
description: "How I built a Mobile, Web, and Desktop Flutter studio that turns natural-language prompts into live native Flutter mini apps using A2UI v1.0, dynamic model discovery, and zero-API-key local CLI authentication."
date: "2026-11-22"
author: "Etornam"
tags: ["flutter", "a2ui", "ai", "dart", "generative-ui", "desktop", "mobile", "web"]
slug: "building-a2ui-studio-with-flutter"
coverImage: "./cover-a2ui-studio.jpg"
---

# Building A2UI Studio: A Cross-Platform AI Mini App Builder with Flutter and `a2ui_flutter`

Most AI coding demos stop at generating static HTML or dumping a block of code you still have to copy, paste, debug, and compile. What if you could describe a mini app in a chat window — *"Create a mini app to track my to-dos with a calendar, an embedded chat, and local notifications"* — watch it render as **real, interactive native Flutter widgets** in seconds, iterate on it conversationally, and save it to your own **Private Vault** or **Public Community Library**?

That's the idea behind **A2UI Studio** — a cross-platform Flutter app (iOS, Android, Web, and macOS Desktop) built on Google's **[`a2ui_flutter`](https://pub.dev/packages/a2ui_flutter)** and **[`a2ui_core`](https://pub.dev/packages/a2ui_core)** packages.

---

## Why A2UI Instead of `eval()` or Code Generation?

Traditional "AI UI builders" either stream raw HTML/JS into a WebView or generate Dart source files that require a full rebuild. **A2UI (Agent-to-User Interface)** takes a safer, cleaner approach:

1. **Declarative JSON Protocol (`v1.0`)**: The LLM never executes arbitrary code. Instead, it emits structured JSON envelopes (`createSurface`, `updateComponents`, `updateDataModel`).
2. **Pre-Approved Native Component Catalogs**: Your Flutter app registers a `CatalogImplementation` defining the exact widgets the AI is allowed to compose, along with JSON Schemas describing their properties.
3. **Instant Native Rendering**: `a2ui_core`'s `MessageProcessor` validates incoming messages and drives `a2ui_flutter`'s `A2uiSurface` widget — giving you 60/120fps native Flutter rendering on Mobile, Web, and Desktop without recompiling.

---

## Extending `basicCatalog()` with a Custom `StudioCatalog`

`a2ui_flutter` ships with `basicCatalog()` (`Column`, `Row`, `Card`, `Text`, `Button`, `TextField`, `CheckBox`, `Slider`, `DateTimeInput`, `Tabs`, and more). To make generated mini apps genuinely useful out of the box, A2UI Studio registers a custom v1.0 catalog (`https://a2ui.studio/catalog/v1`) right alongside `basicCatalog()`:

- **`MiniAppHeader`** — Branded header with live status pill and a notification trigger button.
- **`CalendarWidget`** — Interactive monthly calendar with selectable days and event indicator dots.
- **`TodoBoard`** — Interactive task list with add-task input, completion checkboxes, priority tags, delete, and drag-to-reorder (`ReorderableListView`).
- **`MiniChatPanel`** — An embedded AI assistant chat inside the generated mini app itself, wired directly to the live AI backend.
- **`LocalNotificationCard`** — Toggleable reminder channel with instant test alerts and scheduled local notifications.
- **`PomodoroTimer`**, **`HabitHeatmap`**, and **`MetricChartCard`** — Ready-to-compose productivity, habit, and analytics widgets.

Each component is declared with a `ComponentImplementation` and `json_schema_builder` schema, then passed into `MessageProcessor`:

```dart
final processor = MessageProcessor<ComponentImplementation>(
  catalogs: [
    basicCatalog(),
    StudioCatalog.create(
      onNotify: onNotify,
      onTelemetry: onTelemetry,
      onMiniChat: onMiniChat,
    ),
  ],
);
```

---

## Real-World Lesson: Sanitizing LLM Output for Strict A2UI Validation

When running against real LLMs, you quickly learn that models love to be "helpful" in ways strict schema validators reject. For example, mentioning `darkTheme` in a prompt can cause a model to emit `"darkTheme": true` directly inside `createSurface` — triggering:

```text
A2uiValidationError [VALIDATION_FAILED]:
Unknown field 'createSurface.darkTheme'. Expected only:
surfaceId, catalogId, sendDataModel, components, dataModel, metadata.
```

To make A2UI Studio resilient across every LLM provider, I added a lightweight **`A2uiSanitizer`** layer that runs right before `processor.processMessages(...)`:

- Strips any unexpected keys outside the strict v1.0 allowlist on `createSurface`, `updateComponents`, and `updateDataModel`.
- Ensures `version` is always `"1.0"` and `catalogId` defaults to `BasicCatalog.v1_0Id`.
- Automatically attaches `StudioCatalog.id` to any custom studio component name in case a model omits `catalogId`.

That single 90-line sanitizer turned occasional brittle JSON outputs into rock-solid, zero-crash rendering.

---

## Zero-API-Key Desktop Auth via Installed AI CLIs

One friction point with developer AI tools is constantly hunting down and pasting API keys — even when you're already signed into **Antigravity CLI (`agy`)**, **Claude Code (`claude`)**, **Codex CLI (`codex`)**, **Gemini CLI (`gemini`)**, or **Ollama (`ollama`)** on your laptop.

On Desktop, A2UI Studio automatically scans your `PATH` and common binary directories (`~/.local/bin`, `/opt/homebrew/bin`, `/usr/local/bin`, etc.) to detect installed CLIs and their versions:

- Click **Connect** next to any detected CLI, and A2UI Studio routes prompts directly through that CLI's headless mode (`agy --print`, `claude -p`, `codex exec`, `gemini -p`, `ollama run`) using your existing authentication.
- For CLIs that expose a live model list (`agy models`, `ollama list`), A2UI Studio dynamically populates the model dropdown — zero hardcoded model lists.
- Because Flutter targets Web and Mobile too, the CLI service uses Dart conditional exports (`local_cli_service_stub.dart` if Web, `local_cli_service_io.dart` if `dart.library.io`), so Web and Mobile builds compile cleanly with zero `dart:io` leakage.

### Dynamic Online Model Discovery for Gemini API

On Web, Mobile, or whenever you prefer direct HTTP calls, pasting a Gemini API key triggers a live call to `GET https://generativelanguage.googleapis.com/v1beta/models` (paginated and filtered to `generateContent`-capable models). Whenever Google ships a new model, it appears automatically in the dropdown the next time you hit **Fetch Models**.

---

## From Chat Iteration to a Private/Public Mini App Library

The core user loop in A2UI Studio follows four crisp steps:

1. **Multi-Chat Sessions**: Spin up separate conversations for different mini apps (`To-Do Tracker`, `Pomodoro Studio`, `Habit Tracker`). Each session maintains its own message history, telemetry steps, and evolving A2UI v1.0 surface.
2. **Iterative Refinement**: Ask follow-up changes either in chat or in the split-pane **Studio Workspace** (*"Add a Pomodoro focus timer"*). The current A2UI JSON is passed back as context so iterations preserve existing components while adding or modifying what you asked for.
3. **Inspect & Preview Across Viewports**: Inspect the live **A2UI Widget Tree** and raw **A2UI JSON**, morph the preview across **Mobile / Tablet / Desktop / Web Canvas**, or open **Device Preview** to test synchronized iPhone + macOS/Web frames alongside a real-time Telemetry console.
4. **Save to Library (Private Vault vs. Public Community)**: Click **Save to Library** to name, tag, categorize, and choose visibility:
   - **Private Vault**: Only you can see, install, and run it.
   - **Public Community**: Others can discover, install, run, and **Fork** it into their own chat session to remix.

---

## Adaptive Multi-Platform UI & Dual Themes

Using `LayoutBuilder` breakpoints (never device-type checks), A2UI Studio adapts seamlessly to any window size:

- **Desktop (`>= 1040px`)**: Full sidebar navigation, split-pane Chat & Studio Workspace, and side-by-side Device Preview.
- **Tablet (`680px–1039px`)**: Compact `NavigationRail` with collapsible panes.
- **Mobile (`< 680px`)**: Clean bottom `NavigationBar`, single-pane tabbed workspace, and swipe-friendly conversation switcher.

Both **Obsidian Kinetic (Dark)** and **Lumen Kinetic (Light)** themes are implemented via a custom `ThemeExtension<StudioColors>`, ensuring crisp WCAG-compliant contrast across every card, code well, chip, and button.

---

## What's Next?

With the foundation in place, the next frontier is syncing **Public Community** mini apps to a live backend (Cloud Firestore or Supabase), supporting A2UI `callAgentFunction` tool callbacks so mini apps can read/write real user data, and exporting any mini app as a standalone Flutter package.

If you want to build your own `a2ui_flutter` mini-app builder from scratch, check out the companion step-by-step **Codelab** right here on [etornam.dev](https://etornam.dev)!
