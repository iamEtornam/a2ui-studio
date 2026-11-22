import 'dart:convert';

enum ChatMessageRole { user, assistant }

/// A single turn in a mini-app builder chat session.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.telemetrySteps = const [],
    this.a2uiMessages,
    this.generatedAppTitle,
    this.generatedSummary,
    this.featureHighlights = const [],
    this.compileDurationMs,
    this.modelLabel,
  });

  final String id;
  final ChatMessageRole role;
  final String text;
  final DateTime timestamp;
  final List<String> telemetrySteps;
  final List<Map<String, Object?>>? a2uiMessages;
  final String? generatedAppTitle;
  final String? generatedSummary;
  final List<String> featureHighlights;
  final int? compileDurationMs;
  final String? modelLabel;

  bool get hasSurface => a2uiMessages != null && a2uiMessages!.isNotEmpty;

  Map<String, Object?> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'telemetrySteps': telemetrySteps,
    'a2uiMessages': a2uiMessages,
    'generatedAppTitle': generatedAppTitle,
    'generatedSummary': generatedSummary,
    'featureHighlights': featureHighlights,
    'compileDurationMs': compileDurationMs,
    'modelLabel': modelLabel,
  };

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    final rawMessages = json['a2uiMessages'] as List<Object?>?;
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] == 'assistant'
          ? ChatMessageRole.assistant
          : ChatMessageRole.user,
      text: json['text'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      telemetrySteps: (json['telemetrySteps'] as List<Object?>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      a2uiMessages: rawMessages
          ?.map((e) => Map<String, Object?>.from(e! as Map))
          .toList(),
      generatedAppTitle: json['generatedAppTitle'] as String?,
      generatedSummary: json['generatedSummary'] as String?,
      featureHighlights:
          (json['featureHighlights'] as List<Object?>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      compileDurationMs: (json['compileDurationMs'] as num?)?.toInt(),
      modelLabel: json['modelLabel'] as String?,
    );
  }
}

/// Engine modifier flags toggled in the Studio Workspace.
class EngineModifiers {
  const EngineModifiers({
    this.m3DarkTheme = true,
    this.hapticFeedback = true,
    this.localNotifications = true,
    this.mockDemoData = true,
  });

  final bool m3DarkTheme;
  final bool hapticFeedback;
  final bool localNotifications;
  final bool mockDemoData;

  EngineModifiers copyWith({
    bool? m3DarkTheme,
    bool? hapticFeedback,
    bool? localNotifications,
    bool? mockDemoData,
  }) {
    return EngineModifiers(
      m3DarkTheme: m3DarkTheme ?? this.m3DarkTheme,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      localNotifications: localNotifications ?? this.localNotifications,
      mockDemoData: mockDemoData ?? this.mockDemoData,
    );
  }

  Map<String, Object?> toJson() => {
    'm3DarkTheme': m3DarkTheme,
    'hapticFeedback': hapticFeedback,
    'localNotifications': localNotifications,
    'mockDemoData': mockDemoData,
  };

  factory EngineModifiers.fromJson(Map<String, Object?>? json) {
    if (json == null) return const EngineModifiers();
    return EngineModifiers(
      m3DarkTheme: json['m3DarkTheme'] as bool? ?? true,
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
      localNotifications: json['localNotifications'] as bool? ?? true,
      mockDemoData: json['mockDemoData'] as bool? ?? true,
    );
  }
}

/// Represents a chat conversation where the user specifies and iterates on a mini app.
class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.currentA2uiMessages = const [],
    this.currentAppTitle = 'Untitled Mini App',
    this.currentAppDescription = '',
    this.currentCategory = 'Productivity & Utilities',
    this.currentTags = const ['flutter', 'a2ui'],
    this.iterationCount = 0,
    this.isPinned = false,
    this.modelName = 'Gemini 2.5 Flash',
    this.modifiers = const EngineModifiers(),
    this.savedMiniAppId,
  });

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, Object?>> currentA2uiMessages;
  final String currentAppTitle;
  final String currentAppDescription;
  final String currentCategory;
  final List<String> currentTags;
  final int iterationCount;
  final bool isPinned;
  final String modelName;
  final EngineModifiers modifiers;
  final String? savedMiniAppId;

  bool get hasGeneratedUi => currentA2uiMessages.isNotEmpty;

  String get lastMessagePreview {
    if (messages.isEmpty) return 'Start describing your mini app...';
    return messages.last.text;
  }

  String toPrettyA2uiJson() =>
      const JsonEncoder.withIndent('  ').convert(currentA2uiMessages);

  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Map<String, Object?>>? currentA2uiMessages,
    String? currentAppTitle,
    String? currentAppDescription,
    String? currentCategory,
    List<String>? currentTags,
    int? iterationCount,
    bool? isPinned,
    String? modelName,
    EngineModifiers? modifiers,
    String? savedMiniAppId,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentA2uiMessages: currentA2uiMessages ?? this.currentA2uiMessages,
      currentAppTitle: currentAppTitle ?? this.currentAppTitle,
      currentAppDescription:
          currentAppDescription ?? this.currentAppDescription,
      currentCategory: currentCategory ?? this.currentCategory,
      currentTags: currentTags ?? this.currentTags,
      iterationCount: iterationCount ?? this.iterationCount,
      isPinned: isPinned ?? this.isPinned,
      modelName: modelName ?? this.modelName,
      modifiers: modifiers ?? this.modifiers,
      savedMiniAppId: savedMiniAppId ?? this.savedMiniAppId,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'currentA2uiMessages': currentA2uiMessages,
    'currentAppTitle': currentAppTitle,
    'currentAppDescription': currentAppDescription,
    'currentCategory': currentCategory,
    'currentTags': currentTags,
    'iterationCount': iterationCount,
    'isPinned': isPinned,
    'modelName': modelName,
    'modifiers': modifiers.toJson(),
    'savedMiniAppId': savedMiniAppId,
  };

  factory ChatSession.fromJson(Map<String, Object?> json) {
    final rawMsgs = (json['messages'] as List<Object?>? ?? const [])
        .map((e) => ChatMessage.fromJson(Map<String, Object?>.from(e! as Map)))
        .toList();
    final rawA2ui = (json['currentA2uiMessages'] as List<Object?>? ?? const [])
        .map((e) => Map<String, Object?>.from(e! as Map))
        .toList();
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'New Chat',
      messages: rawMsgs,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      currentA2uiMessages: rawA2ui,
      currentAppTitle: json['currentAppTitle'] as String? ?? 'Untitled Mini App',
      currentAppDescription: json['currentAppDescription'] as String? ?? '',
      currentCategory:
          json['currentCategory'] as String? ?? 'Productivity & Utilities',
      currentTags: (json['currentTags'] as List<Object?>? ?? const ['a2ui'])
          .map((e) => e.toString())
          .toList(),
      iterationCount: (json['iterationCount'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      modelName: json['modelName'] as String? ?? 'Gemini 2.5 Flash',
      modifiers: EngineModifiers.fromJson(
        json['modifiers'] is Map
            ? Map<String, Object?>.from(json['modifiers']! as Map)
            : null,
      ),
      savedMiniAppId: json['savedMiniAppId'] as String?,
    );
  }
}
