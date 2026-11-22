import 'dart:convert';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/ai_model_info.dart';
import '../../domain/models/chat_session.dart';
import '../../domain/models/installed_cli.dart';
import '../../domain/models/studio_settings.dart';
import '../../ui/core/a2ui/a2ui_sanitizer.dart';
import '../../ui/core/a2ui/studio_catalog.dart';
import 'local_cli_service.dart';

/// Exception thrown when a live AI API or CLI call fails or is unconfigured.
class A2uiApiException implements Exception {
  const A2uiApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Result of a live AI mini-app generation or iteration turn.
class A2uiGenerationResult {
  const A2uiGenerationResult({
    required this.assistantReply,
    required this.appTitle,
    required this.appDescription,
    required this.category,
    required this.tags,
    required this.a2uiMessages,
    required this.telemetrySteps,
    required this.featureHighlights,
    required this.compileDurationMs,
    required this.modelLabel,
  });

  final String assistantReply;
  final String appTitle;
  final String appDescription;
  final String category;
  final List<String> tags;
  final List<Map<String, Object?>> a2uiMessages;
  final List<String> telemetrySteps;
  final List<String> featureHighlights;
  final int compileDurationMs;
  final String modelLabel;
}

/// Live AI client supporting BOTH:
/// 1. Locally installed & already-authenticated AI CLIs (`agy`, `claude`, `codex`, `gemini`, `ollama`)
/// 2. Direct Google Gemini REST API with dynamic online model discovery.
class A2uiAiService {
  A2uiAiService({
    http.Client? httpClient,
    LocalCliService? cliService,
  }) : _httpClient = httpClient ?? http.Client(),
       _cliService = cliService ?? LocalCliService();

  final http.Client _httpClient;
  final LocalCliService _cliService;

  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  /// Fetches the live list of available generative models directly from the Gemini API.
  Future<List<AiModelInfo>> fetchAvailableModels(String apiKey) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const A2uiApiException(
        'Enter your Google Gemini API key to fetch available models.',
      );
    }

    final models = <AiModelInfo>[];
    String? pageToken;

    do {
      final queryParams = <String, String>{
        'pageSize': '100',
        if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
      };
      final uri = Uri.parse('$_baseUrl/models').replace(
        queryParameters: queryParams,
      );

      final response = await _httpClient.get(
        uri,
        headers: {'x-goog-api-key': trimmedKey},
      );
      if (response.statusCode != 200) {
        throw A2uiApiException(_extractApiError(response));
      }

      final body = jsonDecode(response.body) as Map<String, Object?>;
      final rawModels = body['models'] as List<Object?>? ?? const [];

      for (final item in rawModels) {
        if (item is! Map) continue;
        final map = Map<String, Object?>.from(item);
        final methods =
            (map['supportedGenerationMethods'] as List<Object?>? ?? const [])
                .map((e) => e.toString())
                .toList();
        if (!methods.contains('generateContent')) continue;

        final info = AiModelInfo.fromGeminiApi(map);
        if (info.id.isNotEmpty) {
          models.add(info);
        }
      }

      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);

    models.sort((a, b) => b.id.compareTo(a.id));
    if (models.isEmpty) {
      throw const A2uiApiException(
        'No content-generation models were returned for this API key.',
      );
    }
    return models;
  }

  /// Generates or iteratively refines an A2UI v1.0 mini app via the active live backend.
  Future<A2uiGenerationResult> generateOrIterate({
    required String prompt,
    required StudioSettings settings,
    required EngineModifiers modifiers,
    List<Map<String, Object?>> existingMessages = const [],
    String? currentAppTitle,
    InstalledCliTool? connectedCli,
  }) async {
    final stopwatch = Stopwatch()..start();
    final surfaceId = 'mini_app_${DateTime.now().millisecondsSinceEpoch}';
    final systemPrompt = _buildSystemPrompt(surfaceId, modifiers);
    final userContent = existingMessages.isEmpty
        ? 'Create a mini app with these requirements:\n$prompt'
        : 'Current app title: ${currentAppTitle ?? "Mini App"}\n'
              'Current A2UI JSON:\n${jsonEncode(existingMessages)}\n\n'
              'User iteration request:\n$prompt\n\n'
              'Return the complete updated JSON preserving existing components unless the user asks to remove or replace them.';

    if (settings.isUsingInstalledCli) {
      final cli =
          connectedCli ??
          InstalledCliTool(
            id: settings.connectedCliId,
            name: settings.connectedCliName.isNotEmpty
                ? settings.connectedCliName
                : settings.connectedCliId,
            binaryName: settings.connectedCliId,
            description: '',
            isInstalled: true,
            executablePath: settings.connectedCliPath,
          );

      final combinedPrompt =
          '$systemPrompt\n\n--- USER REQUEST ---\n$userContent\n\n'
          'IMPORTANT: Output ONLY the raw valid JSON object and nothing else.';

      final rawText = await _cliService.runPrompt(
        cli: cli,
        prompt: combinedPrompt,
        model: settings.cliSelectedModel,
      );

      return _parseGenerationJson(
        rawText: rawText,
        currentAppTitle: currentAppTitle,
        stopwatch: stopwatch,
        sourceLabel: settings.activeEngineLabel,
        transportStep: 'Executed via local ${cli.name} (CLI auth)',
      );
    }

    if (!settings.hasGeminiApiKey) {
      throw const A2uiApiException(
        'Not connected. Connect an installed AI CLI or enter a Gemini API key in Settings & API Keys.',
      );
    }
    if (!settings.hasSelectedModel) {
      throw const A2uiApiException(
        'No model selected. Open Settings & API Keys to fetch and choose a live model.',
      );
    }

    final uri = Uri.parse(
      '$_baseUrl/models/${settings.selectedModel}:generateContent',
    );

    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': settings.geminiApiKey.trim(),
      },
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userContent},
            ],
          },
        ],
        'generationConfig': {
          'temperature': settings.temperature,
          'maxOutputTokens': settings.maxTokens,
          'responseMimeType': 'application/json',
        },
      }),
    );

    if (response.statusCode != 200) {
      throw A2uiApiException(_extractApiError(response));
    }

    final body = jsonDecode(response.body) as Map<String, Object?>;
    final candidates = body['candidates'] as List<Object?>?;
    if (candidates == null || candidates.isEmpty) {
      throw const A2uiApiException('Model returned an empty response.');
    }
    final content =
        (candidates.first as Map)['content'] as Map<String, Object?>?;
    final parts = content?['parts'] as List<Object?>?;
    final rawText = (parts?.first as Map?)?['text'] as String?;
    if (rawText == null || rawText.trim().isEmpty) {
      throw const A2uiApiException('Model returned no text payload.');
    }

    return _parseGenerationJson(
      rawText: rawText,
      currentAppTitle: currentAppTitle,
      stopwatch: stopwatch,
      sourceLabel: settings.selectedModel,
      transportStep: 'Called live Gemini API (${settings.selectedModel})',
    );
  }

  /// Sends a live chat message from an embedded [MiniChatPanel] inside a generated mini app.
  Future<String> sendMiniAppChatMessage({
    required String message,
    required String appContext,
    required StudioSettings settings,
    InstalledCliTool? connectedCli,
  }) async {
    if (!settings.isReadyForLiveGeneration) {
      throw const A2uiApiException(
        'Connect an installed AI CLI or Gemini API key in Settings to chat.',
      );
    }

    if (settings.isUsingInstalledCli) {
      final cli =
          connectedCli ??
          InstalledCliTool(
            id: settings.connectedCliId,
            name: settings.connectedCliName,
            binaryName: settings.connectedCliId,
            description: '',
            isInstalled: true,
            executablePath: settings.connectedCliPath,
          );
      return _cliService.runPrompt(
        cli: cli,
        prompt:
            'You are the concise in-app AI assistant inside the "$appContext" mini app. '
            'Answer helpfully in 1-3 short sentences.\n\nUser: $message',
        model: settings.cliSelectedModel,
      );
    }

    final uri = Uri.parse(
      '$_baseUrl/models/${settings.selectedModel}:generateContent',
    );

    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': settings.geminiApiKey.trim(),
      },
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {
              'text':
                  'You are the concise in-app AI assistant inside the "$appContext" mini app. '
                  'Answer helpfully in 1-3 short sentences.',
            },
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': message},
            ],
          },
        ],
        'generationConfig': {
          'temperature': settings.temperature,
          'maxOutputTokens': 512,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw A2uiApiException(_extractApiError(response));
    }

    final body = jsonDecode(response.body) as Map<String, Object?>;
    final candidates = body['candidates'] as List<Object?>?;
    final content =
        (candidates?.firstOrNull as Map?)?['content'] as Map<String, Object?>?;
    final parts = content?['parts'] as List<Object?>?;
    final reply = (parts?.firstOrNull as Map?)?['text'] as String?;
    return reply?.trim().isNotEmpty == true
        ? reply!.trim()
        : 'No response returned by model.';
  }

  String _buildSystemPrompt(String surfaceId, EngineModifiers modifiers) {
    return '''
You are A2UI Studio Engine. You generate real, interactive Flutter mini apps using A2UI protocol v1.0.
Respond with ONLY a valid JSON object (no markdown fences, no commentary) matching this exact structure:
{
  "appTitle": "Short descriptive app title",
  "appDescription": "Concise 1-2 sentence description",
  "category": "Productivity & Utilities | Health & Habits | Finance & Analytics | Team & Collaboration | Developer Tools",
  "tags": ["tag1", "tag2"],
  "assistantReply": "Helpful explanation of what you built or changed",
  "featureHighlights": ["Component — short note"],
  "a2uiMessages": [
    {
      "version": "1.0",
      "createSurface": {
        "surfaceId": "$surfaceId",
        "catalogId": "${BasicCatalog.v1_0Id}"
      }
    },
    {
      "version": "1.0",
      "updateComponents": {
        "surfaceId": "$surfaceId",
        "components": [
          {
            "id": "root",
            "component": "Column",
            "children": ["header", "..."]
          }
        ]
      }
    }
  ]
}

Rules for a2uiMessages:
1. Every component in "root.children" MUST exist in "components" with a matching unique "id".
2. All custom components MUST include "catalogId": "${StudioCatalog.id}":
   - MiniAppHeader: {"id", "component": "MiniAppHeader", "catalogId": "${StudioCatalog.id}", "title": string, "subtitle": string, "badge": string, "showNotificationBell": bool}
   - CalendarWidget: {"id", "component": "CalendarWidget", "catalogId": "${StudioCatalog.id}", "title": string, "highlightDays": int[]}
   - TodoBoard: {"id", "component": "TodoBoard", "catalogId": "${StudioCatalog.id}", "title": string, "reorderable": bool, "items": [{"id": string, "title": string, "due": string, "priority": "High"|"Medium"|"Low", "done": bool}]}
   - MiniChatPanel: {"id", "component": "MiniChatPanel", "catalogId": "${StudioCatalog.id}", "title": string, "welcomeMessage": string, "placeholder": string}
   - LocalNotificationCard: {"id", "component": "LocalNotificationCard", "catalogId": "${StudioCatalog.id}", "title": string, "subtitle": string, "channelId": string, "enabled": bool}
   - MetricChartCard: {"id", "component": "MetricChartCard", "catalogId": "${StudioCatalog.id}", "label": string, "value": string, "delta": string, "points": number[]}
   - PomodoroTimer: {"id", "component": "PomodoroTimer", "catalogId": "${StudioCatalog.id}", "title": string, "focusMinutes": number}
   - HabitHeatmap: {"id", "component": "HabitHeatmap", "catalogId": "${StudioCatalog.id}", "title": string, "streakDays": number}
3. Standard basicCatalog components (no catalogId needed):
   - Column: {"id", "component": "Column", "children": string[]}
   - Row: {"id", "component": "Row", "children": string[]}
   - Card: {"id", "component": "Card", "child": string}
   - Text: {"id", "component": "Text", "text": string}
   - Button: {"id", "component": "Button", "child": string, "action": {"event": {"name": string}}}
   - Divider: {"id", "component": "Divider"}
4. For TodoBoard, leave "items": [] unless the user specifically asks for starter items.
5. NEVER add extra keys to "createSurface" (ONLY "surfaceId" and "catalogId" are allowed — do NOT put darkTheme, theme, or title inside createSurface).
6. User preferences: localNotifications=${modifiers.localNotifications}, hapticFeedback=${modifiers.hapticFeedback}.
''';
  }

  A2uiGenerationResult _parseGenerationJson({
    required String rawText,
    required String? currentAppTitle,
    required Stopwatch stopwatch,
    required String sourceLabel,
    required String transportStep,
  }) {
    final jsonBlock = _extractJsonObject(rawText);
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonBlock);
    } catch (e) {
      throw A2uiApiException('Model returned invalid JSON: $e');
    }
    if (decoded is! Map) {
      throw const A2uiApiException('Expected a JSON object from the model.');
    }

    final parsed = Map<String, Object?>.from(decoded);
    final rawMessages = A2uiSanitizer.sanitize(
      (parsed['a2uiMessages'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, Object?>.from(e))
          .toList(),
    );
    if (rawMessages.isEmpty) {
      throw const A2uiApiException(
        'Model response did not contain any valid a2uiMessages.',
      );
    }

    stopwatch.stop();
    final compCount = _countComponents(rawMessages);
    return A2uiGenerationResult(
      assistantReply:
          parsed['assistantReply'] as String? ??
          'Generated your A2UI mini app surface.',
      appTitle: parsed['appTitle'] as String? ?? (currentAppTitle ?? 'Mini App'),
      appDescription:
          parsed['appDescription'] as String? ??
          'AI-generated Flutter mini app powered by a2ui_flutter.',
      category: parsed['category'] as String? ?? 'Productivity & Utilities',
      tags: (parsed['tags'] as List<Object?>? ?? const ['flutter', 'a2ui'])
          .map((e) => e.toString())
          .toList(),
      a2uiMessages: rawMessages,
      telemetrySteps: [
        transportStep,
        'Validated A2UI v1.0 schema ($compCount components)',
        'Compiled live Flutter A2uiSurface in ${stopwatch.elapsedMilliseconds}ms',
      ],
      featureHighlights:
          (parsed['featureHighlights'] as List<Object?>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      compileDurationMs: stopwatch.elapsedMilliseconds,
      modelLabel: sourceLabel,
    );
  }

  /// Extracts the outermost JSON object from raw model/CLI output.
  String _extractJsonObject(String raw) {
    final stripped = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final start = stripped.indexOf('{');
    final end = stripped.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return stripped.substring(start, end + 1);
    }
    return stripped;
  }

  int _countComponents(List<Map<String, Object?>> messages) {
    var count = 0;
    for (final m in messages) {
      final update = m['updateComponents'];
      if (update is Map && update['components'] is List) {
        count += (update['components'] as List).length;
      }
    }
    return count;
  }

  String _extractApiError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is Map) {
        final err = body['error'] as Map;
        final msg = err['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          return 'API Error (${response.statusCode}): $msg';
        }
      }
    } catch (_) {}
    return 'API request failed with status ${response.statusCode}.';
  }
}
