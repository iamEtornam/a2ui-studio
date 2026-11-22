import 'dart:convert';

/// Visibility level of a saved mini app in the library.
enum MiniAppVisibility {
  privateVault,
  publicCommunity;

  String get label => switch (this) {
    MiniAppVisibility.privateVault => 'Private',
    MiniAppVisibility.publicCommunity => 'Public',
  };

  String get badgeLabel => switch (this) {
    MiniAppVisibility.privateVault => 'Private Vault',
    MiniAppVisibility.publicCommunity => 'Public',
  };

  static MiniAppVisibility fromString(String value) {
    return value == 'publicCommunity' || value == 'public'
        ? MiniAppVisibility.publicCommunity
        : MiniAppVisibility.privateVault;
  }
}

/// Represents a saved A2UI mini app stored in the user's library or community registry.
class MiniApp {
  const MiniApp({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.visibility,
    required this.tags,
    required this.a2uiMessages,
    required this.authorName,
    required this.isOwnedByCurrentUser,
    required this.createdAt,
    required this.updatedAt,
    this.version = 'v1.0',
    this.installCount = 1,
    this.likeCount = 0,
    this.isInstalled = true,
    this.isLiked = false,
    this.hasLocalNotifications = false,
    this.accentHex = '#6366F1',
    this.sourceSessionId,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final MiniAppVisibility visibility;
  final List<String> tags;

  /// Raw A2UI v1.0 JSON message envelopes (`createSurface`, `updateComponents`, `updateDataModel`).
  final List<Map<String, Object?>> a2uiMessages;
  final String authorName;
  final bool isOwnedByCurrentUser;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String version;
  final int installCount;
  final int likeCount;
  final bool isInstalled;
  final bool isLiked;
  final bool hasLocalNotifications;
  final String accentHex;
  final String? sourceSessionId;

  bool get isPublic => visibility == MiniAppVisibility.publicCommunity;
  bool get isPrivate => visibility == MiniAppVisibility.privateVault;

  MiniApp copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    MiniAppVisibility? visibility,
    List<String>? tags,
    List<Map<String, Object?>>? a2uiMessages,
    String? authorName,
    bool? isOwnedByCurrentUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? version,
    int? installCount,
    int? likeCount,
    bool? isInstalled,
    bool? isLiked,
    bool? hasLocalNotifications,
    String? accentHex,
    String? sourceSessionId,
  }) {
    return MiniApp(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      visibility: visibility ?? this.visibility,
      tags: tags ?? this.tags,
      a2uiMessages: a2uiMessages ?? this.a2uiMessages,
      authorName: authorName ?? this.authorName,
      isOwnedByCurrentUser: isOwnedByCurrentUser ?? this.isOwnedByCurrentUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      installCount: installCount ?? this.installCount,
      likeCount: likeCount ?? this.likeCount,
      isInstalled: isInstalled ?? this.isInstalled,
      isLiked: isLiked ?? this.isLiked,
      hasLocalNotifications:
          hasLocalNotifications ?? this.hasLocalNotifications,
      accentHex: accentHex ?? this.accentHex,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'visibility': visibility.name,
    'tags': tags,
    'a2uiMessages': a2uiMessages,
    'authorName': authorName,
    'isOwnedByCurrentUser': isOwnedByCurrentUser,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'version': version,
    'installCount': installCount,
    'likeCount': likeCount,
    'isInstalled': isInstalled,
    'isLiked': isLiked,
    'hasLocalNotifications': hasLocalNotifications,
    'accentHex': accentHex,
    'sourceSessionId': sourceSessionId,
  };

  factory MiniApp.fromJson(Map<String, Object?> json) {
    final rawMessages = (json['a2uiMessages'] as List<Object?>? ?? const [])
        .map((e) => Map<String, Object?>.from(e! as Map))
        .toList();
    return MiniApp(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Productivity & Utilities',
      visibility: MiniAppVisibility.fromString(
        json['visibility'] as String? ?? 'privateVault',
      ),
      tags: (json['tags'] as List<Object?>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      a2uiMessages: rawMessages,
      authorName: json['authorName'] as String? ?? 'You',
      isOwnedByCurrentUser: json['isOwnedByCurrentUser'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      version: json['version'] as String? ?? 'v1.0',
      installCount: (json['installCount'] as num?)?.toInt() ?? 1,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isInstalled: json['isInstalled'] as bool? ?? true,
      isLiked: json['isLiked'] as bool? ?? false,
      hasLocalNotifications: json['hasLocalNotifications'] as bool? ?? false,
      accentHex: json['accentHex'] as String? ?? '#6366F1',
      sourceSessionId: json['sourceSessionId'] as String?,
    );
  }

  String toPrettyA2uiJson() =>
      const JsonEncoder.withIndent('  ').convert(a2uiMessages);
}
