import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../data/repositories/studio_repository.dart';
import '../../../data/services/a2ui_ai_service.dart';
import '../../../data/services/local_cli_service.dart';
import '../../../data/services/local_notification_service.dart';
import '../../../domain/models/ai_model_info.dart';
import '../../../domain/models/chat_session.dart';
import '../../../domain/models/installed_cli.dart';
import '../../../domain/models/mini_app.dart';
import '../../../domain/models/studio_settings.dart';

enum StudioSection {
  chatSessions('Chat Sessions', Icons.chat_bubble_outline_rounded),
  studioWorkspace('Studio Workspace', Icons.grid_view_rounded),
  miniAppLibrary('Mini App Library', Icons.layers_outlined),
  devicePreview('Device Preview', Icons.devices_rounded),
  settings('Settings & API Keys', Icons.tune_rounded);

  const StudioSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum LibraryFilter { all, privateVault, publicCommunity }

/// Central ChangeNotifier ViewModel coordinating installed AI CLI discovery,
/// live Gemini API model discovery, multi-chat A2UI generation, and Library state.
class StudioViewModel extends ChangeNotifier {
  StudioViewModel({
    required StudioRepository repository,
    required A2uiAiService aiService,
    required this.notificationService,
    LocalCliService? cliService,
  }) : _repository = repository,
       _aiService = aiService,
       _cliService = cliService ?? LocalCliService();

  final StudioRepository _repository;
  final A2uiAiService _aiService;
  final LocalCliService _cliService;
  final LocalNotificationService notificationService;
  final _uuid = const Uuid();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool get supportsLocalCli => _cliService.isSupported;

  StudioSection _activeSection = StudioSection.chatSessions;
  StudioSection get activeSection => _activeSection;

  List<ChatSession> _sessions = [];
  List<ChatSession> get sessions => List.unmodifiable(_sessions);

  String? _activeSessionId;
  ChatSession? get activeSession {
    if (_sessions.isEmpty) return null;
    return _sessions.firstWhere(
      (s) => s.id == _activeSessionId,
      orElse: () => _sessions.first,
    );
  }

  List<MiniApp> _library = [];
  List<MiniApp> get library => List.unmodifiable(_library);

  StudioSettings _settings = const StudioSettings();
  StudioSettings get settings => _settings;

  // Installed Desktop CLIs
  List<InstalledCliTool> _installedClis = [];
  List<InstalledCliTool> get installedClis => List.unmodifiable(_installedClis);

  bool _isScanningClis = false;
  bool get isScanningClis => _isScanningClis;

  List<AiModelInfo> _cliModels = [];
  List<AiModelInfo> get cliModels => List.unmodifiable(_cliModels);

  bool _isFetchingCliModels = false;
  bool get isFetchingCliModels => _isFetchingCliModels;

  InstalledCliTool? get connectedCli {
    if (!_settings.isUsingInstalledCli) return null;
    for (final cli in _installedClis) {
      if (cli.id == _settings.connectedCliId && cli.isInstalled) {
        return cli;
      }
    }
    if (_settings.connectedCliPath.isNotEmpty) {
      return InstalledCliTool(
        id: _settings.connectedCliId,
        name: _settings.connectedCliName,
        binaryName: _settings.connectedCliId,
        description: '',
        isInstalled: true,
        executablePath: _settings.connectedCliPath,
      );
    }
    return null;
  }

  // Live dynamically fetched Gemini API models (never hardcoded)
  List<AiModelInfo> _availableModels = [];
  List<AiModelInfo> get availableModels => List.unmodifiable(_availableModels);

  bool _isFetchingModels = false;
  bool get isFetchingModels => _isFetchingModels;

  String? _modelsError;
  String? get modelsError => _modelsError;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _lastGenerationError;
  String? get lastGenerationError => _lastGenerationError;

  String _chatSearchQuery = '';
  String get chatSearchQuery => _chatSearchQuery;

  LibraryFilter _libraryFilter = LibraryFilter.all;
  LibraryFilter get libraryFilter => _libraryFilter;

  String _librarySearchQuery = '';
  String get librarySearchQuery => _librarySearchQuery;

  String _libraryCategory = 'All Categories';
  String get libraryCategory => _libraryCategory;

  final List<String> _telemetryLogs = [
    '[a2ui_flutter] Engine v0.4.0 initialized (Protocol v1.0).',
    '[StudioCatalog] Registered 8 live interactive A2UI components.',
  ];
  List<String> get telemetryLogs => List.unmodifiable(_telemetryLogs);

  Future<void> initialize() async {
    _sessions = await _repository.loadSessions();
    _library = await _repository.loadLibrary();
    _settings = await _repository.loadSettings();
    _availableModels = await _repository.loadCachedModels();

    if (_sessions.isNotEmpty) {
      _activeSessionId = _sessions.first.id;
    }
    _isInitialized = true;
    notifyListeners();

    if (_cliService.isSupported) {
      await scanInstalledClis();
      final cli = connectedCli;
      if (cli != null && cli.supportsDynamicModels) {
        await _loadModelsForCli(cli);
      }
    }

    if (_settings.hasGeminiApiKey) {
      await fetchLiveModels();
    }
  }

  void setSection(StudioSection section) {
    if (_activeSection == section) return;
    _activeSection = section;
    notifyListeners();
  }

  void clearGenerationError() {
    if (_lastGenerationError == null) return;
    _lastGenerationError = null;
    notifyListeners();
  }

  void addTelemetry(String message) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    _telemetryLogs.insert(0, '[$ts] $message');
    if (_telemetryLogs.length > 80) {
      _telemetryLogs.removeLast();
    }
    notifyListeners();
  }

  void triggerLocalNotification({
    required String title,
    required String body,
    bool scheduled = false,
  }) {
    final appName = activeSession?.currentAppTitle ?? 'A2UI Studio';
    if (scheduled) {
      notificationService.scheduleReminder(
        title: title,
        body: body,
        channelId: _settings.notificationChannelId,
        appName: appName,
      );
      addTelemetry('[LocalNotif] Scheduled 4s reminder: "$title".');
    } else {
      notificationService.triggerNotification(
        title: title,
        body: body,
        channelId: _settings.notificationChannelId,
        appName: appName,
      );
      addTelemetry('[LocalNotif] Triggered alert: "$title".');
    }
  }

  // ---- Installed AI CLI Auto-Discovery & Connection ----

  Future<void> scanInstalledClis() async {
    if (!_cliService.isSupported) return;
    _isScanningClis = true;
    notifyListeners();
    addTelemetry('[CLI Discovery] Scanning system for installed AI CLIs...');
    try {
      _installedClis = await _cliService.discoverInstalledClis();
      final found = _installedClis.where((c) => c.isInstalled).toList();
      addTelemetry(
        '[CLI Discovery] Found ${found.length} installed CLI(s): '
        '${found.map((c) => c.binaryName).join(", ")}',
      );
    } catch (e) {
      addTelemetry('[CLI Discovery Error] $e');
    } finally {
      _isScanningClis = false;
      notifyListeners();
    }
  }

  /// Connects the studio to a locally installed AI CLI (uses the CLI's own auth).
  Future<void> connectInstalledCli(InstalledCliTool cli) async {
    if (!cli.isInstalled || cli.executablePath == null) return;

    _settings = _settings.copyWith(
      backendMode: AiBackendMode.installedCli,
      connectedCliId: cli.id,
      connectedCliName: cli.name,
      connectedCliPath: cli.executablePath!,
      cliSelectedModel: '',
    );
    await _repository.saveSettings(_settings);
    _cliModels = [];
    notifyListeners();
    addTelemetry('[CLI Auth] Connected to ${cli.name} (${cli.executablePath}).');

    if (cli.supportsDynamicModels) {
      await _loadModelsForCli(cli);
    }
  }

  Future<void> _loadModelsForCli(InstalledCliTool cli) async {
    _isFetchingCliModels = true;
    notifyListeners();
    try {
      final fetched = await _cliService.fetchModelsForCli(cli);
      _cliModels = fetched;
      if (fetched.isNotEmpty) {
        final stillValid = fetched.any(
          (m) => m.id == _settings.cliSelectedModel,
        );
        if (!stillValid) {
          _settings = _settings.copyWith(cliSelectedModel: fetched.first.id);
          await _repository.saveSettings(_settings);
        }
        addTelemetry(
          '[CLI Models] Loaded ${fetched.length} live model(s) from ${cli.name}.',
        );
      }
    } catch (e) {
      addTelemetry('[CLI Models Error] $e');
    } finally {
      _isFetchingCliModels = false;
      notifyListeners();
    }
  }

  Future<void> disconnectInstalledCli() async {
    _settings = _settings.copyWith(
      backendMode: AiBackendMode.geminiApi,
      connectedCliId: '',
      connectedCliName: '',
      connectedCliPath: '',
      cliSelectedModel: '',
    );
    _cliModels = [];
    await _repository.saveSettings(_settings);
    addTelemetry('[CLI Auth] Disconnected local CLI.');
    notifyListeners();
  }

  // ---- Dynamic Live Gemini API Model Discovery ----

  Future<bool> fetchLiveModels({String? apiKeyOverride}) async {
    final key = (apiKeyOverride ?? _settings.geminiApiKey).trim();
    if (key.isEmpty) {
      _modelsError = 'Enter your Gemini API key first to load live models.';
      notifyListeners();
      return false;
    }

    if (apiKeyOverride != null) {
      _settings = _settings.copyWith(
        geminiApiKey: key,
        backendMode: AiBackendMode.geminiApi,
      );
      await _repository.saveSettings(_settings);
    }

    _isFetchingModels = true;
    _modelsError = null;
    notifyListeners();
    addTelemetry('[Models API] Fetching live Gemini model list...');

    try {
      final fetched = await _aiService.fetchAvailableModels(key);
      _availableModels = fetched;
      await _repository.saveCachedModels(fetched);

      final stillExists = fetched.any((m) => m.id == _settings.selectedModel);
      if (!stillExists && fetched.isNotEmpty) {
        final preferred = fetched.firstWhere(
          (m) => m.id.contains('flash') && !m.id.contains('lite'),
          orElse: () => fetched.first,
        );
        _settings = _settings.copyWith(selectedModel: preferred.id);
        await _repository.saveSettings(_settings);
      }

      addTelemetry(
        '[Models API] Loaded ${fetched.length} live models. Active: ${_settings.selectedModel}',
      );
      return true;
    } catch (e) {
      _modelsError = e.toString();
      addTelemetry('[Models API Error] $e');
      return false;
    } finally {
      _isFetchingModels = false;
      notifyListeners();
    }
  }

  /// Sends a live chat message from an embedded MiniChatPanel inside a generated mini app.
  Future<String> sendMiniAppChat(String message, String appContext) async {
    addTelemetry('[MiniChatPanel] Calling ${_settings.activeEngineLabel}...');
    final reply = await _aiService.sendMiniAppChatMessage(
      message: message,
      appContext: appContext,
      settings: _settings,
      connectedCli: connectedCli,
    );
    addTelemetry('[MiniChatPanel] Received live reply.');
    return reply;
  }

  // ---- Chat Sessions ----

  void setChatSearchQuery(String query) {
    _chatSearchQuery = query;
    notifyListeners();
  }

  List<ChatSession> get filteredSessions {
    final q = _chatSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return _sessions;
    return _sessions.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.currentAppTitle.toLowerCase().contains(q) ||
          s.lastMessagePreview.toLowerCase().contains(q);
    }).toList();
  }

  ChatSession createNewChat({String? initialTitle}) {
    final now = DateTime.now();
    final session = ChatSession(
      id: 'session_${_uuid.v4().substring(0, 8)}',
      title: initialTitle ?? 'New Mini App Chat',
      messages: const [],
      createdAt: now,
      updatedAt: now,
      modelName: _settings.activeEngineLabel,
    );
    _sessions = [session, ..._sessions];
    _activeSessionId = session.id;
    _activeSection = StudioSection.chatSessions;
    _repository.saveSessions(_sessions);
    addTelemetry('[ChatSessions] Created new session "${session.id}".');
    notifyListeners();
    return session;
  }

  void selectSession(String sessionId) {
    _activeSessionId = sessionId;
    notifyListeners();
  }

  void deleteSession(String sessionId) {
    _sessions = _sessions.where((s) => s.id != sessionId).toList();
    if (_activeSessionId == sessionId) {
      _activeSessionId = _sessions.isNotEmpty ? _sessions.first.id : null;
    }
    _repository.saveSessions(_sessions);
    notifyListeners();
  }

  void togglePinSession(String sessionId) {
    _sessions = _sessions
        .map((s) => s.id == sessionId ? s.copyWith(isPinned: !s.isPinned) : s)
        .toList();
    _repository.saveSessions(_sessions);
    notifyListeners();
  }

  void updateModifiers(EngineModifiers modifiers) {
    final current = activeSession;
    if (current == null) return;
    _replaceSession(current.copyWith(modifiers: modifiers));
    addTelemetry(
      '[StudioWorkspace] Updated runtime modifiers (notifs=${modifiers.localNotifications}, dark=${modifiers.m3DarkTheme}).',
    );
  }

  Future<void> sendPrompt(String rawPrompt) async {
    final prompt = rawPrompt.trim();
    if (prompt.isEmpty || _isGenerating) return;

    if (!_settings.isReadyForLiveGeneration) {
      _lastGenerationError =
          'Connect an installed AI CLI or Gemini API key in Settings & API Keys first.';
      notifyListeners();
      return;
    }

    _lastGenerationError = null;
    var session = activeSession ?? createNewChat();
    final now = DateTime.now();
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: ChatMessageRole.user,
      text: prompt,
      timestamp: now,
    );

    final updatedTitle = session.messages.isEmpty
        ? _shortChatTitle(prompt)
        : session.title;

    session = session.copyWith(
      title: updatedTitle,
      messages: [...session.messages, userMsg],
      modelName: _settings.activeEngineLabel,
      updatedAt: now,
    );
    _replaceSession(session);

    _isGenerating = true;
    notifyListeners();
    addTelemetry(
      '[A2UI Engine] Sending live prompt to ${_settings.activeEngineLabel}...',
    );

    try {
      final result = await _aiService.generateOrIterate(
        prompt: prompt,
        settings: _settings,
        modifiers: session.modifiers,
        existingMessages: session.currentA2uiMessages,
        currentAppTitle: session.currentAppTitle,
        connectedCli: connectedCli,
      );

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        role: ChatMessageRole.assistant,
        text: result.assistantReply,
        timestamp: DateTime.now(),
        a2uiMessages: result.a2uiMessages,
        generatedAppTitle: result.appTitle,
        generatedSummary: result.appDescription,
        telemetrySteps: result.telemetrySteps,
        featureHighlights: result.featureHighlights,
        compileDurationMs: result.compileDurationMs,
        modelLabel: result.modelLabel,
      );

      final updated = session.copyWith(
        messages: [...session.messages, aiMsg],
        currentA2uiMessages: result.a2uiMessages,
        currentAppTitle: result.appTitle,
        currentAppDescription: result.appDescription,
        currentCategory: result.category,
        currentTags: result.tags,
        iterationCount: session.iterationCount + 1,
        modelName: result.modelLabel,
        updatedAt: DateTime.now(),
      );
      _replaceSession(updated);
      addTelemetry(
        '[a2ui_flutter] Compiled "${result.appTitle}" in ${result.compileDurationMs}ms.',
      );
    } catch (e) {
      _lastGenerationError = e.toString();
      addTelemetry('[A2UI Error] $e');
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        role: ChatMessageRole.assistant,
        text: 'Live generation failed: $e',
        timestamp: DateTime.now(),
        modelLabel: _settings.activeEngineLabel,
      );
      _replaceSession(
        session.copyWith(
          messages: [...session.messages, errorMsg],
          updatedAt: DateTime.now(),
        ),
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _replaceSession(ChatSession updated) {
    _sessions = _sessions
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    _repository.saveSessions(_sessions);
    notifyListeners();
  }

  String _shortChatTitle(String prompt) {
    final cleaned = prompt.trim();
    if (cleaned.length <= 34) return cleaned;
    return '${cleaned.substring(0, 34)}...';
  }

  // ---- Mini App Library (Private & Public) ----

  void setLibraryFilter(LibraryFilter filter) {
    _libraryFilter = filter;
    notifyListeners();
  }

  void setLibrarySearchQuery(String q) {
    _librarySearchQuery = q;
    notifyListeners();
  }

  void setLibraryCategory(String category) {
    _libraryCategory = category;
    notifyListeners();
  }

  List<String> get availableCategories {
    final cats = <String>{
      'All Categories',
      'Productivity & Utilities',
      'Health & Habits',
      'Finance & Analytics',
      'Team & Collaboration',
      'Developer Tools',
    };
    for (final app in _library) {
      cats.add(app.category);
    }
    return cats.toList();
  }

  List<MiniApp> get filteredLibrary {
    return _library.where((app) {
      if (_libraryFilter == LibraryFilter.privateVault && !app.isPrivate) {
        return false;
      }
      if (_libraryFilter == LibraryFilter.publicCommunity && !app.isPublic) {
        return false;
      }
      if (_libraryCategory != 'All Categories' &&
          app.category != _libraryCategory) {
        return false;
      }
      final q = _librarySearchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final match =
            app.title.toLowerCase().contains(q) ||
            app.description.toLowerCase().contains(q) ||
            app.authorName.toLowerCase().contains(q) ||
            app.tags.any((t) => t.toLowerCase().contains(q));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  int get installedAppsCount => _library.where((a) => a.isInstalled).length;
  int get privateAppsCount => _library.where((a) => a.isPrivate).length;
  int get publicAppsCount => _library.where((a) => a.isPublic).length;
  int get activeNotifAppsCount =>
      _library.where((a) => a.hasLocalNotifications && a.isInstalled).length +
      notificationService.activeScheduledCount;

  MiniApp saveCurrentMiniAppToLibrary({
    required String title,
    required String description,
    required String category,
    required MiniAppVisibility visibility,
    required List<String> tags,
  }) {
    final session = activeSession;
    final now = DateTime.now();
    final a2uiMessages = session?.currentA2uiMessages ?? const [];
    final hasNotif = a2uiMessages.any(
      (m) => m.toString().contains('LocalNotificationCard'),
    );

    final newApp = MiniApp(
      id: 'app_${_uuid.v4().substring(0, 8)}',
      title: title.trim().isEmpty ? 'Untitled Mini App' : title.trim(),
      description: description.trim(),
      category: category,
      visibility: visibility,
      tags: tags.isEmpty ? const ['flutter', 'a2ui'] : tags,
      a2uiMessages: a2uiMessages,
      authorName: visibility == MiniAppVisibility.publicCommunity
          ? 'You (Public)'
          : 'You (Private)',
      isOwnedByCurrentUser: true,
      createdAt: now,
      updatedAt: now,
      version: 'v1.${session?.iterationCount ?? 0}',
      installCount: 1,
      likeCount: 0,
      isInstalled: true,
      hasLocalNotifications: hasNotif,
      sourceSessionId: session?.id,
    );

    _library = [newApp, ..._library];
    _repository.saveLibrary(_library);

    if (session != null) {
      _replaceSession(
        session.copyWith(
          currentAppTitle: newApp.title,
          currentAppDescription: newApp.description,
          currentCategory: newApp.category,
          currentTags: newApp.tags,
          savedMiniAppId: newApp.id,
        ),
      );
    }

    addTelemetry(
      '[Library] Saved "${newApp.title}" (${visibility.badgeLabel}).',
    );
    notifyListeners();
    return newApp;
  }

  void toggleMiniAppVisibility(String appId) {
    _library = _library.map((app) {
      if (app.id != appId || !app.isOwnedByCurrentUser) return app;
      final next = app.isPrivate
          ? MiniAppVisibility.publicCommunity
          : MiniAppVisibility.privateVault;
      addTelemetry(
        '[Library] Changed "${app.title}" visibility -> ${next.badgeLabel}.',
      );
      return app.copyWith(
        visibility: next,
        authorName: next == MiniAppVisibility.publicCommunity
            ? 'You (Public)'
            : 'You (Private)',
        updatedAt: DateTime.now(),
      );
    }).toList();
    _repository.saveLibrary(_library);
    notifyListeners();
  }

  void installMiniApp(String appId) {
    _library = _library.map((app) {
      if (app.id != appId) return app;
      if (app.isInstalled) return app;
      addTelemetry('[Library] Installed "${app.title}" to local workspace.');
      return app.copyWith(
        isInstalled: true,
        installCount: app.installCount + 1,
      );
    }).toList();
    _repository.saveLibrary(_library);
    notifyListeners();
  }

  void toggleLikeMiniApp(String appId) {
    _library = _library.map((app) {
      if (app.id != appId) return app;
      final liked = !app.isLiked;
      return app.copyWith(
        isLiked: liked,
        likeCount:
            liked ? app.likeCount + 1 : (app.likeCount - 1).clamp(0, 999999),
      );
    }).toList();
    _repository.saveLibrary(_library);
    notifyListeners();
  }

  void deleteMiniApp(String appId) {
    _library = _library.where((a) => a.id != appId).toList();
    _repository.saveLibrary(_library);
    notifyListeners();
  }

  void forkMiniAppToChat(MiniApp app) {
    final now = DateTime.now();
    final session = ChatSession(
      id: 'session_${_uuid.v4().substring(0, 8)}',
      title: 'Fork: ${app.title}',
      createdAt: now,
      updatedAt: now,
      currentA2uiMessages: app.a2uiMessages,
      currentAppTitle: '${app.title} (Remix)',
      currentAppDescription: app.description,
      currentCategory: app.category,
      currentTags: app.tags,
      iterationCount: 1,
      modelName: _settings.activeEngineLabel,
      messages: [
        ChatMessage(
          id: _uuid.v4(),
          role: ChatMessageRole.assistant,
          text:
              'Forked "${app.title}" into your workspace! Tell me what you would like to change or add.',
          timestamp: now,
          a2uiMessages: app.a2uiMessages,
          generatedAppTitle: '${app.title} (Remix)',
          telemetrySteps: const [
            'Cloned A2UI v1.0 manifest from Library',
            'Ready for live iterative AI refinement',
          ],
          compileDurationMs: 0,
          modelLabel: _settings.activeEngineLabel,
        ),
      ],
    );
    _sessions = [session, ..._sessions];
    _activeSessionId = session.id;
    _activeSection = StudioSection.studioWorkspace;
    _repository.saveSessions(_sessions);
    addTelemetry('[Library] Forked "${app.title}" into Studio Workspace.');
    notifyListeners();
  }

  // ---- Settings & Theme ----

  void updateSettings(StudioSettings updated) {
    _settings = updated;
    _repository.saveSettings(updated);
    notifyListeners();
  }

  void toggleThemeMode() {
    final next = _settings.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    updateSettings(_settings.copyWith(themeMode: next));
  }
}
