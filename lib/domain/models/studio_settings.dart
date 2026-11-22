import 'package:flutter/material.dart';
import 'mini_app.dart';

/// Whether live AI generation uses a direct Gemini API key or a locally installed AI CLI.
enum AiBackendMode {
  geminiApi,
  installedCli;

  static AiBackendMode fromString(String value) {
    return value == 'installedCli'
        ? AiBackendMode.installedCli
        : AiBackendMode.geminiApi;
  }
}

/// Persisted studio configuration and live AI provider preferences.
class StudioSettings {
  const StudioSettings({
    this.themeMode = ThemeMode.dark,
    this.backendMode = AiBackendMode.geminiApi,
    this.geminiApiKey = '',
    this.selectedModel = '',
    this.connectedCliId = '',
    this.connectedCliName = '',
    this.connectedCliPath = '',
    this.cliSelectedModel = '',
    this.temperature = 0.2,
    this.maxTokens = 8192,
    this.includeInlineComments = true,
    this.autoFormatOutput = true,
    this.backgroundNotificationDaemon = true,
    this.notificationChannelId = 'a2ui_task_reminders',
    this.defaultVisibility = MiniAppVisibility.privateVault,
  });

  final ThemeMode themeMode;
  final AiBackendMode backendMode;
  final String geminiApiKey;
  final String selectedModel;
  final String connectedCliId;
  final String connectedCliName;
  final String connectedCliPath;
  final String cliSelectedModel;
  final double temperature;
  final int maxTokens;
  final bool includeInlineComments;
  final bool autoFormatOutput;
  final bool backgroundNotificationDaemon;
  final String notificationChannelId;
  final MiniAppVisibility defaultVisibility;

  bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;
  bool get hasSelectedModel => selectedModel.trim().isNotEmpty;
  bool get isUsingInstalledCli =>
      backendMode == AiBackendMode.installedCli &&
      connectedCliId.trim().isNotEmpty;

  bool get isReadyForLiveGeneration =>
      isUsingInstalledCli || (hasGeminiApiKey && hasSelectedModel);

  String get activeEngineLabel {
    if (isUsingInstalledCli) {
      final name = connectedCliName.isNotEmpty
          ? connectedCliName
          : connectedCliId;
      return cliSelectedModel.isNotEmpty ? '$name • $cliSelectedModel' : name;
    }
    if (hasGeminiApiKey && hasSelectedModel) {
      return selectedModel;
    }
    return 'Not Connected';
  }

  StudioSettings copyWith({
    ThemeMode? themeMode,
    AiBackendMode? backendMode,
    String? geminiApiKey,
    String? selectedModel,
    String? connectedCliId,
    String? connectedCliName,
    String? connectedCliPath,
    String? cliSelectedModel,
    double? temperature,
    int? maxTokens,
    bool? includeInlineComments,
    bool? autoFormatOutput,
    bool? backgroundNotificationDaemon,
    String? notificationChannelId,
    MiniAppVisibility? defaultVisibility,
  }) {
    return StudioSettings(
      themeMode: themeMode ?? this.themeMode,
      backendMode: backendMode ?? this.backendMode,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      connectedCliId: connectedCliId ?? this.connectedCliId,
      connectedCliName: connectedCliName ?? this.connectedCliName,
      connectedCliPath: connectedCliPath ?? this.connectedCliPath,
      cliSelectedModel: cliSelectedModel ?? this.cliSelectedModel,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      includeInlineComments:
          includeInlineComments ?? this.includeInlineComments,
      autoFormatOutput: autoFormatOutput ?? this.autoFormatOutput,
      backgroundNotificationDaemon:
          backgroundNotificationDaemon ?? this.backgroundNotificationDaemon,
      notificationChannelId:
          notificationChannelId ?? this.notificationChannelId,
      defaultVisibility: defaultVisibility ?? this.defaultVisibility,
    );
  }

  Map<String, Object?> toJson() => {
    'themeMode': themeMode.name,
    'backendMode': backendMode.name,
    'geminiApiKey': geminiApiKey,
    'selectedModel': selectedModel,
    'connectedCliId': connectedCliId,
    'connectedCliName': connectedCliName,
    'connectedCliPath': connectedCliPath,
    'cliSelectedModel': cliSelectedModel,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'includeInlineComments': includeInlineComments,
    'autoFormatOutput': autoFormatOutput,
    'backgroundNotificationDaemon': backgroundNotificationDaemon,
    'notificationChannelId': notificationChannelId,
    'defaultVisibility': defaultVisibility.name,
  };

  factory StudioSettings.fromJson(Map<String, Object?> json) {
    final modeStr = json['themeMode'] as String? ?? 'dark';
    return StudioSettings(
      themeMode: modeStr == 'light' ? ThemeMode.light : ThemeMode.dark,
      backendMode: AiBackendMode.fromString(
        json['backendMode'] as String? ?? 'geminiApi',
      ),
      geminiApiKey: json['geminiApiKey'] as String? ?? '',
      selectedModel: json['selectedModel'] as String? ?? '',
      connectedCliId: json['connectedCliId'] as String? ?? '',
      connectedCliName: json['connectedCliName'] as String? ?? '',
      connectedCliPath: json['connectedCliPath'] as String? ?? '',
      cliSelectedModel: json['cliSelectedModel'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.2,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 8192,
      includeInlineComments: json['includeInlineComments'] as bool? ?? true,
      autoFormatOutput: json['autoFormatOutput'] as bool? ?? true,
      backgroundNotificationDaemon:
          json['backgroundNotificationDaemon'] as bool? ?? true,
      notificationChannelId:
          json['notificationChannelId'] as String? ?? 'a2ui_task_reminders',
      defaultVisibility: MiniAppVisibility.fromString(
        json['defaultVisibility'] as String? ?? 'privateVault',
      ),
    );
  }
}
