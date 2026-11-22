/// Metadata for a live AI model fetched dynamically from the provider API.
class AiModelInfo {
  const AiModelInfo({
    required this.id,
    required this.displayName,
    this.description = '',
    this.inputTokenLimit,
    this.outputTokenLimit,
  });

  /// Short model identifier used in API paths (e.g. `gemini-2.5-flash`).
  final String id;
  final String displayName;
  final String description;
  final int? inputTokenLimit;
  final int? outputTokenLimit;

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'description': description,
    'inputTokenLimit': inputTokenLimit,
    'outputTokenLimit': outputTokenLimit,
  };

  factory AiModelInfo.fromJson(Map<String, Object?> json) {
    return AiModelInfo(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? (json['id'] as String? ?? ''),
      description: json['description'] as String? ?? '',
      inputTokenLimit: (json['inputTokenLimit'] as num?)?.toInt(),
      outputTokenLimit: (json['outputTokenLimit'] as num?)?.toInt(),
    );
  }

  /// Parses a model object from the Gemini `v1beta/models` REST response.
  factory AiModelInfo.fromGeminiApi(Map<String, Object?> json) {
    final rawName = json['name'] as String? ?? '';
    final id = rawName.startsWith('models/')
        ? rawName.substring('models/'.length)
        : rawName;
    return AiModelInfo(
      id: id,
      displayName: (json['displayName'] as String?)?.trim().isNotEmpty == true
          ? json['displayName'] as String
          : id,
      description: json['description'] as String? ?? '',
      inputTokenLimit: (json['inputTokenLimit'] as num?)?.toInt(),
      outputTokenLimit: (json['outputTokenLimit'] as num?)?.toInt(),
    );
  }
}
