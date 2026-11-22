import 'dart:convert';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_studio/app.dart';
import 'package:a2ui_studio/data/repositories/studio_repository.dart';
import 'package:a2ui_studio/data/services/a2ui_ai_service.dart';
import 'package:a2ui_studio/data/services/local_cli_service.dart';
import 'package:a2ui_studio/data/services/local_notification_service.dart';
import 'package:a2ui_studio/data/services/storage_service.dart';
import 'package:a2ui_studio/domain/models/ai_model_info.dart';
import 'package:a2ui_studio/domain/models/installed_cli.dart';
import 'package:a2ui_studio/domain/models/mini_app.dart';
import 'package:a2ui_studio/ui/core/a2ui/studio_catalog.dart';
import 'package:a2ui_studio/ui/features/studio/studio_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCliService extends LocalCliService {
  @override
  bool get isSupported => true;

  @override
  Future<List<InstalledCliTool>> discoverInstalledClis() async => const [
    InstalledCliTool(
      id: 'agy',
      name: 'Antigravity CLI',
      binaryName: 'agy',
      description: 'Test Antigravity CLI',
      isInstalled: true,
      executablePath: '/usr/local/bin/agy',
      version: '1.5.5',
      supportsDynamicModels: true,
    ),
  ];

  @override
  Future<List<AiModelInfo>> fetchModelsForCli(InstalledCliTool cli) async =>
      const [
        AiModelInfo(
          id: 'gemini-4-neon-medium',
          displayName: 'Gemini 4 Neon (Medium)',
        ),
      ];

  @override
  Future<String> runPrompt({
    required InstalledCliTool cli,
    required String prompt,
    String? model,
  }) async => '{}';
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  MockClient createMockGeminiClient() {
    return MockClient((request) async {
      if (request.url.path.endsWith('/models')) {
        return http.Response(
          jsonEncode({
            'models': [
              {
                'name': 'models/gemini-2.5-pro',
                'displayName': 'Gemini 2.5 Pro',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/gemini-2.5-flash',
                'displayName': 'Gemini 2.5 Flash',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/text-embedding-004',
                'displayName': 'Text Embedding',
                'supportedGenerationMethods': ['embedContent'],
              },
            ],
          }),
          200,
        );
      }

      if (request.url.path.endsWith(':generateContent')) {
        final a2uiPayload = {
          'appTitle': 'TaskPulse',
          'appDescription': 'To-do tracker with calendar, chat, and local alerts.',
          'category': 'Productivity & Utilities',
          'tags': ['todo', 'calendar', 'chat', 'notifications'],
          'assistantReply': 'Built TaskPulse with live Gemini API.',
          'featureHighlights': ['TodoBoard', 'CalendarWidget', 'MiniChatPanel'],
          'a2uiMessages': [
            {
              'version': '1.0',
              'createSurface': {
                'surfaceId': 'live_surface_1',
                'catalogId': BasicCatalog.v1_0Id,
              },
            },
            {
              'version': '1.0',
              'updateComponents': {
                'surfaceId': 'live_surface_1',
                'components': [
                  {
                    'id': 'root',
                    'component': 'Column',
                    'children': ['header', 'todo', 'calendar'],
                  },
                  {
                    'id': 'header',
                    'component': 'MiniAppHeader',
                    'catalogId': StudioCatalog.id,
                    'title': 'TaskPulse',
                  },
                  {
                    'id': 'todo',
                    'component': 'TodoBoard',
                    'catalogId': StudioCatalog.id,
                    'title': 'Tasks',
                    'items': [],
                  },
                  {
                    'id': 'calendar',
                    'component': 'CalendarWidget',
                    'catalogId': StudioCatalog.id,
                    'title': 'Calendar',
                  },
                ],
              },
            },
          ],
        };

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': jsonEncode(a2uiPayload)},
                  ],
                },
              },
            ],
          }),
          200,
        );
      }

      return http.Response('Not found', 404);
    });
  }

  test(
    'Zero dummy data on fresh launch; dynamic model fetch, live generation, and Library save work',
    () async {
      final fakeCli = _FakeCliService();
      final vm = StudioViewModel(
        repository: StudioRepository(storage: StorageService()),
        aiService: A2uiAiService(
          httpClient: createMockGeminiClient(),
          cliService: fakeCli,
        ),
        notificationService: LocalNotificationService(),
        cliService: fakeCli,
      );
      await vm.initialize();

      // 1. Fresh launch has ZERO dummy data
      expect(vm.sessions, isEmpty);
      expect(vm.library, isEmpty);
      expect(vm.availableModels, isEmpty);
      expect(vm.settings.isReadyForLiveGeneration, isFalse);

      // 2. Fetch live models dynamically from API (embedding-only model excluded)
      final ok = await vm.fetchLiveModels(apiKeyOverride: 'test-key-123');
      expect(ok, isTrue);
      expect(vm.availableModels.length, 2);
      expect(
        vm.availableModels.map((m) => m.id),
        containsAll(['gemini-2.5-pro', 'gemini-2.5-flash']),
      );
      expect(vm.settings.isReadyForLiveGeneration, isTrue);

      // 3. Generate live A2UI mini app
      await vm.sendPrompt(
        'Create a mini app that I can use to track my to-dos with calendar and chat.',
      );
      expect(vm.activeSession, isNotNull);
      expect(vm.activeSession!.hasGeneratedUi, isTrue);
      expect(vm.activeSession!.currentAppTitle, 'TaskPulse');

      // 4. Save to Library as Private, then toggle to Public
      final saved = vm.saveCurrentMiniAppToLibrary(
        title: 'TaskPulse',
        description: 'Live generated to-do mini app.',
        category: 'Productivity & Utilities',
        visibility: MiniAppVisibility.privateVault,
        tags: ['todo', 'calendar'],
      );
      expect(saved.isPrivate, isTrue);

      vm.toggleMiniAppVisibility(saved.id);
      vm.setLibraryFilter(LibraryFilter.publicCommunity);
      expect(vm.filteredLibrary.any((a) => a.id == saved.id), isTrue);

      vm.notificationService.dispose();
      vm.dispose();
    },
  );

  testWidgets('A2uiStudioApp prompts to connect Gemini API key when unconfigured', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 840);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeCli = _FakeCliService();
    final vm = StudioViewModel(
      repository: StudioRepository(storage: StorageService()),
      aiService: A2uiAiService(
        httpClient: createMockGeminiClient(),
        cliService: fakeCli,
      ),
      notificationService: LocalNotificationService(),
      cliService: fakeCli,
    );
    await vm.initialize();

    await tester.pumpWidget(A2uiStudioApp(viewModel: vm));
    await tester.pumpAndSettle();

    expect(find.text('A2UI Studio'), findsOneWidget);
    expect(find.text('Connect CLI or API Key'), findsOneWidget);

    vm.notificationService.dispose();
    vm.dispose();
  });
}
