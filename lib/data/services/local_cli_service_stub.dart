import '../../domain/models/ai_model_info.dart';
import '../../domain/models/installed_cli.dart';

/// Web/non-IO stub for local CLI discovery and execution.
class LocalCliService {
  bool get isSupported => false;

  Future<List<InstalledCliTool>> discoverInstalledClis() async => const [];

  Future<List<AiModelInfo>> fetchModelsForCli(InstalledCliTool cli) async =>
      const [];

  Future<String> runPrompt({
    required InstalledCliTool cli,
    required String prompt,
    String? model,
  }) async {
    throw UnsupportedError(
      'Installed AI CLI execution is only available on Desktop (macOS, Linux, Windows).',
    );
  }
}
