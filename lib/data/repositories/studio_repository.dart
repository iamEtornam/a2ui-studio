import '../../domain/models/ai_model_info.dart';
import '../../domain/models/chat_session.dart';
import '../../domain/models/mini_app.dart';
import '../../domain/models/studio_settings.dart';
import '../services/storage_service.dart';

/// Single source of truth for live user chat sessions, saved mini apps,
/// studio settings, and dynamically fetched AI models.
class StudioRepository {
  StudioRepository({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  Future<List<ChatSession>> loadSessions() => _storage.loadSessions();

  Future<void> saveSessions(List<ChatSession> sessions) =>
      _storage.saveSessions(sessions);

  Future<List<MiniApp>> loadLibrary() => _storage.loadLibrary();

  Future<void> saveLibrary(List<MiniApp> apps) => _storage.saveLibrary(apps);

  Future<StudioSettings> loadSettings() async {
    return (await _storage.loadSettings()) ?? const StudioSettings();
  }

  Future<void> saveSettings(StudioSettings settings) =>
      _storage.saveSettings(settings);

  Future<List<AiModelInfo>> loadCachedModels() => _storage.loadCachedModels();

  Future<void> saveCachedModels(List<AiModelInfo> models) =>
      _storage.saveCachedModels(models);
}
