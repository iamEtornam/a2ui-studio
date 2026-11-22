import 'package:flutter/material.dart';
import 'data/repositories/studio_repository.dart';
import 'data/services/a2ui_ai_service.dart';
import 'data/services/local_notification_service.dart';
import 'data/services/storage_service.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/core/widgets/app_shell.dart';
import 'ui/features/studio/studio_view_model.dart';

/// Root application widget for A2UI Studio.
class A2uiStudioApp extends StatefulWidget {
  const A2uiStudioApp({super.key, this.viewModel});

  final StudioViewModel? viewModel;

  @override
  State<A2uiStudioApp> createState() => _A2uiStudioAppState();
}

class _A2uiStudioAppState extends State<A2uiStudioApp> {
  late final StudioViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _ownsViewModel = false;
    } else {
      _viewModel = StudioViewModel(
        repository: StudioRepository(storage: StorageService()),
        aiService: A2uiAiService(),
        notificationService: LocalNotificationService(),
      );
      _ownsViewModel = true;
      _viewModel.initialize();
    }
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.notificationService.dispose();
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return MaterialApp(
          title: 'A2UI Studio — AI Mini App Builder',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _viewModel.settings.themeMode,
          home: _viewModel.isInitialized
              ? AppShell(viewModel: _viewModel)
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }
}
