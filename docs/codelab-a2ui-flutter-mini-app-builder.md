---
title: "Codelab: Build an AI Mini App Builder in Flutter with a2ui_flutter"
description: "A step-by-step hands-on codelab showing how to render live AI-generated Flutter UIs using a2ui_flutter, register custom interactive components, connect live AI models, and save mini apps to a Private/Public Library."
date: "2026-11-22"
author: "Etornam"
duration: "45 min"
level: "Intermediate"
tags: ["flutter", "codelab", "a2ui_flutter", "generative-ui", "gemini", "dart"]
slug: "codelab-build-ai-mini-app-builder-a2ui-flutter"
coverImage: "./cover-a2ui-studio.jpg"
---

# Codelab: Build an AI Mini App Builder in Flutter with `a2ui_flutter`

**Duration:** ~45 minutes  
**Level:** Intermediate Flutter / Dart  
**Platforms:** Mobile (iOS/Android), Web, and Desktop (macOS/Linux/Windows)

## What You'll Build

In this codelab, you will build a cross-platform Flutter app powered by **[`a2ui_flutter`](https://pub.dev/packages/a2ui_flutter)** where users can:

1. Describe a mini app in a chat interface (e.g., a to-do tracker with a calendar, chat, and local notifications).
2. Watch the AI generate and render a **live, interactive Flutter UI** using the A2UI v1.0 protocol.
3. Iteratively refine the generated mini app across multiple turns.
4. Connect either a **live Gemini API key** (with dynamic online model discovery) or a **locally installed AI CLI** on Desktop.
5. Save finished mini apps into a **Private Vault** or **Public Community Library** and launch them anytime.

## Prerequisites

- **Flutter SDK** `3.38+` installed and on your `PATH` (`flutter --version`)
- An IDE (VS Code, Android Studio, or Antigravity)
- A [Google Gemini API key](https://aistudio.google.com/apikey) — *or* an already signed-in desktop AI CLI (`agy`, `claude`, `codex`, `gemini`, or `ollama`)

---

## Step 1: Create the Flutter Project & Add Dependencies

Create a new multi-platform Flutter project and install `a2ui_flutter`, `a2ui_core`, `json_schema_builder`, `http`, and `shared_preferences`:

```bash
flutter create --platforms ios,android,web,macos a2ui_studio
cd a2ui_studio

flutter pub add a2ui_flutter a2ui_core json_schema_builder http shared_preferences uuid intl
```

> **macOS Desktop Tip:** Open `macos/Runner/DebugProfile.entitlements` and add `<key>com.apple.security.network.client</key><true/>` so outbound HTTP requests to the Gemini API succeed on macOS. If you plan to spawn installed desktop CLIs via `Process.run`, set `com.apple.security.app-sandbox` to `<false/>`.

---

## Step 2: Understand How `a2ui_flutter` Renders Surfaces

Unlike code generators, `a2ui_flutter` renders **declarative A2UI JSON messages** using components registered in your app's catalog. A minimal v1.0 surface requires just two envelopes:

```json
[
  {
    "version": "1.0",
    "createSurface": {
      "surfaceId": "hello_surface",
      "catalogId": "https://a2ui.org/specification/v1_0/basic_catalog.json"
    }
  },
  {
    "version": "1.0",
    "updateComponents": {
      "surfaceId": "hello_surface",
      "components": [
        { "id": "root", "component": "Column", "children": ["greeting"] },
        { "id": "greeting", "component": "Text", "text": "Hello from A2UI!" }
      ]
    }
  }
]
```

Every component references its children by string `id`, starting from `"root"`.

---

## Step 3: Register a Custom Interactive Component Catalog

Create `lib/a2ui/studio_catalog.dart` to define custom mini-app components that the AI can compose alongside `basicCatalog()`. Here is an interactive `TodoBoard` component:

```dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

class StudioCatalog {
  static const String id = 'https://a2ui.studio/catalog/v1';

  static CatalogImplementation create({
    void Function(String title, String body)? onNotify,
  }) {
    return CatalogImplementation(
      id: id,
      protocolVersion: A2uiProtocolVersion.v1_0,
      title: 'A2UI Studio Catalog',
      components: [
        ComponentImplementation(
          name: 'TodoBoard',
          schema: Schema.object(
            properties: {
              'title': CommonSchemasV1.dynamicString,
              'items': Schema.list(items: Schema.object()),
            },
          ),
          builder: (context, node, props, buildChild) {
            final title = props.string('title') ?? 'Tasks';
            final rawItems = props.value('items');
            final starterTitles = <String>[
              if (rawItems is List)
                for (final item in rawItems)
                  if (item is Map && item['title'] != null)
                    item['title'].toString(),
            ];
            return _TodoBoardWidget(
              title: title,
              initialTasks: starterTitles,
              onNotify: onNotify,
            );
          },
        ),
      ],
    );
  }
}

class _TodoBoardWidget extends StatefulWidget {
  const _TodoBoardWidget({
    required this.title,
    required this.initialTasks,
    this.onNotify,
  });

  final String title;
  final List<String> initialTasks;
  final void Function(String title, String body)? onNotify;

  @override
  State<_TodoBoardWidget> createState() => _TodoBoardWidgetState();
}

class _TodoBoardWidgetState extends State<_TodoBoardWidget> {
  late final List<(String title, bool done)> _tasks;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tasks = widget.initialTasks.map((t) => (t, false)).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks.insert(0, (text, false));
      _ctrl.clear();
    });
    widget.onNotify?.call('Task Added', '"$text" scheduled with reminder.');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(hintText: 'Add a task...'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _add, child: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _tasks.length; i++)
              CheckboxListTile(
                value: _tasks[i].$2,
                title: Text(_tasks[i].$1),
                onChanged: (v) => setState(
                  () => _tasks[i] = (_tasks[i].$1, v ?? false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

> **Challenge:** Repeat this pattern to add `CalendarWidget`, `LocalNotificationCard`, `MiniChatPanel`, and `PomodoroTimer` to `StudioCatalog`.

---

## Step 4: Build a Reusable `A2uiSurfaceHost` with Sanitization

LLMs occasionally add extra fields (like `darkTheme`) to `createSurface` envelopes, which `a2ui_core` v1.0's strict validator rejects. Add a small sanitizer and wrap `MessageProcessor` + `A2uiSurface` in `lib/a2ui/a2ui_surface_host.dart`:

```dart
import 'dart:convert';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:flutter/material.dart';
import 'studio_catalog.dart';

class A2uiSurfaceHost extends StatefulWidget {
  const A2uiSurfaceHost({
    super.key,
    required this.messages,
    this.onNotify,
  });

  final List<Map<String, Object?>> messages;
  final void Function(String title, String body)? onNotify;

  @override
  State<A2uiSurfaceHost> createState() => _A2uiSurfaceHostState();
}

class _A2uiSurfaceHostState extends State<A2uiSurfaceHost> {
  MessageProcessor<ComponentImplementation>? _processor;
  SurfaceModel<ComponentImplementation>? _surface;
  String? _error;
  String _signature = '';

  static const _allowedCreateKeys = {
    'surfaceId',
    'catalogId',
    'sendDataModel',
    'components',
    'dataModel',
    'metadata',
  };

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant A2uiSurfaceHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (jsonEncode(widget.messages) != _signature) {
      _rebuild();
    }
  }

  List<Map<String, Object?>> _sanitize(List<Map<String, Object?>> raw) {
    return raw.map((m) {
      if (m['createSurface'] is Map) {
        final src = Map<String, Object?>.from(m['createSurface']! as Map);
        final filtered = {
          for (final e in src.entries)
            if (_allowedCreateKeys.contains(e.key)) e.key: e.value,
        };
        filtered.putIfAbsent('catalogId', () => BasicCatalog.v1_0Id);
        return {'version': '1.0', 'createSurface': filtered};
      }
      return {'version': '1.0', ...m};
    }).toList();
  }

  void _rebuild() {
    _processor?.dispose();
    _surface = null;
    _error = null;
    _signature = jsonEncode(widget.messages);

    final processor = MessageProcessor<ComponentImplementation>(
      catalogs: [
        basicCatalog(),
        StudioCatalog.create(onNotify: widget.onNotify),
      ],
    );

    processor.model.onSurfaceCreated.subscribe((created) {
      if (mounted) setState(() => _surface = created);
    });

    try {
      if (widget.messages.isNotEmpty) {
        processor.processMessages(_sanitize(widget.messages));
      }
    } catch (e) {
      _error = e.toString();
    }
    _processor = processor;
  }

  @override
  void dispose() {
    _processor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Text('A2UI Error: $_error');
    if (_surface == null) {
      return const Center(child: Text('Describe a mini app to begin.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: A2uiSurface(key: ObjectKey(_surface), surface: _surface!),
    );
  }
}
```

---

## Step 5: Fetch Live AI Models Dynamically (No Hardcoded Lists)

Instead of hardcoding model IDs that go stale, query the Gemini `v1beta/models` endpoint directly and filter to models supporting `generateContent`:

```dart
Future<List<String>> fetchLiveGeminiModels(String apiKey) async {
  final uri = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models',
  ).replace(queryParameters: {'key': apiKey.trim(), 'pageSize': '100'});

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('Failed to fetch models (${res.statusCode})');
  }

  final body = jsonDecode(res.body) as Map<String, Object?>;
  final rawModels = body['models'] as List<Object?>? ?? const [];
  final ids = <String>[];

  for (final item in rawModels.whereType<Map>()) {
    final methods = (item['supportedGenerationMethods'] as List? ?? const [])
        .map((e) => e.toString());
    if (!methods.contains('generateContent')) continue;

    final name = item['name']?.toString() ?? '';
    ids.add(name.replaceFirst('models/', ''));
  }
  return ids;
}
```

> **Desktop Bonus (Zero-API-Key CLI Auth):** On macOS/Linux/Windows, you can also detect installed CLIs (`agy`, `claude`, `codex`, `gemini`, `ollama`) via `Process.run('which', [binary])` and invoke them headlessly (`agy --print`, `claude -p`, `codex exec`) using the user's existing CLI login — no API key required! Wrap the `dart:io` implementation behind a conditional export (`export 'cli_stub.dart' if (dart.library.io) 'cli_io.dart';`) so Flutter Web builds cleanly.

---

## Step 6: Prompt the Model & Iterate on A2UI Surfaces

When the user sends a prompt, instruct the model to return strict JSON containing `appTitle`, `assistantReply`, and `a2uiMessages`. For follow-up iterations, include the previous `a2uiMessages` in the prompt so the AI updates the existing mini app instead of starting over:

```dart
final userPrompt = existingMessages.isEmpty
    ? 'Create a mini app with these requirements:\n$prompt'
    : 'Current A2UI JSON:\n${jsonEncode(existingMessages)}\n\n'
      'User iteration request:\n$prompt\n\n'
      'Return the updated full JSON preserving existing components unless asked to remove them.';
```

Parse the response's `a2uiMessages` list and pass it straight to `A2uiSurfaceHost(messages: currentA2uiMessages)` — your UI updates live!

---

## Step 7: Add a Private & Public Mini App Library

Create an immutable `MiniApp` model with a `MiniAppVisibility` enum (`privateVault` vs `publicCommunity`), and serialize the list to `SharedPreferences` (or Firestore for multi-user public sharing):

```dart
enum MiniAppVisibility { privateVault, publicCommunity }

class MiniApp {
  const MiniApp({
    required this.id,
    required this.title,
    required this.description,
    required this.visibility,
    required this.a2uiMessages,
  });

  final String id;
  final String title;
  final String description;
  final MiniAppVisibility visibility;
  final List<Map<String, Object?>> a2uiMessages;
}
```

Add a **Save to Library** button in your chat header and workspace toolbar that opens a dialog letting the user pick **Private** (*only you can see, install, and use*) or **Public** (*others can discover, install, fork, and use*). Clicking **Launch / Use** on any Library card opens a dialog hosting `A2uiSurfaceHost(messages: app.a2uiMessages)`.

---

## Step 8: Make It Responsive Across Mobile, Web & Desktop

Wrap your root shell in a `LayoutBuilder` and adapt navigation strictly by `constraints.maxWidth`:

- `maxWidth >= 1040` → Full persistent sidebar + split-pane chat & live preview
- `maxWidth >= 680` → Compact `NavigationRail`
- `maxWidth < 680` → Bottom `NavigationBar` with single-pane tabbed workspace

Run and test across all targets:

```bash
flutter test
flutter run -d macos
flutter run -d chrome
```

---

## Congratulations!

You've built a live, cross-platform AI Mini App Builder powered by **`a2ui_flutter`**.

### Next Steps & Challenges
- **Add more catalog components**: Try building a `KanbanBoard`, `AudioMemoRecorder`, or `CountdownWidget` in `StudioCatalog`.
- **Cloud Sync for Public Library**: Back `MiniAppVisibility.publicCommunity` with Cloud Firestore so users can publish and fork mini apps in real time.
- **Action Callbacks**: Subscribe to `processor.model.onAction` to wire A2UI `Button` actions to native Flutter features like share sheets, clipboard export, or local SQLite storage.
