import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/ai_model_info.dart';
import '../../domain/models/chat_session.dart';
import '../../domain/models/mini_app.dart';
import '../../domain/models/studio_settings.dart';

/// Persists live chat sessions, mini app library items, settings, and fetched models.
class StorageService {
  static const _sessionsKey = 'a2ui_studio_sessions_live_v2';
  static const _libraryKey = 'a2ui_studio_library_live_v2';
  static const _settingsKey = 'a2ui_studio_settings_live_v2';
  static const _modelsKey = 'a2ui_studio_models_live_v2';

  Future<List<ChatSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<Object?>;
    return list
        .map((e) => ChatSession.fromJson(Map<String, Object?>.from(e! as Map)))
        .toList();
  }

  Future<void> saveSessions(List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encoded);
  }

  Future<List<MiniApp>> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_libraryKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<Object?>;
    return list
        .map((e) => MiniApp.fromJson(Map<String, Object?>.from(e! as Map)))
        .toList();
  }

  Future<void> saveLibrary(List<MiniApp> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(apps.map((a) => a.toJson()).toList());
    await prefs.setString(_libraryKey, encoded);
  }

  Future<StudioSettings?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return null;
    return StudioSettings.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> saveSettings(StudioSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    // Never persist raw API keys to browser localStorage on Web (XSS risk).
    final toStore = kIsWeb ? settings.copyWith(geminiApiKey: '') : settings;
    await prefs.setString(_settingsKey, jsonEncode(toStore.toJson()));
  }

  Future<List<AiModelInfo>> loadCachedModels() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_modelsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<Object?>;
    return list
        .map((e) => AiModelInfo.fromJson(Map<String, Object?>.from(e! as Map)))
        .toList();
  }

  Future<void> saveCachedModels(List<AiModelInfo> models) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(models.map((m) => m.toJson()).toList());
    await prefs.setString(_modelsKey, encoded);
  }
}
