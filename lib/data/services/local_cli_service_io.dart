import 'dart:io';
import '../../domain/models/ai_model_info.dart';
import '../../domain/models/installed_cli.dart';

/// Desktop IO implementation that scans for installed AI CLIs (`agy`, `claude`,
/// `codex`, `gemini`, `ollama`), queries their live models, and executes prompts
/// using each CLI's existing local authentication.
class LocalCliService {
  bool get isSupported =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  static const _catalog = [
    InstalledCliTool(
      id: 'agy',
      name: 'Antigravity CLI',
      binaryName: 'agy',
      description:
          'Uses your signed-in Antigravity CLI session & live model catalog.',
      isInstalled: false,
      supportsDynamicModels: true,
    ),
    InstalledCliTool(
      id: 'claude',
      name: 'Claude Code CLI',
      binaryName: 'claude',
      description: 'Uses your authenticated Claude Code CLI (`claude -p`).',
      isInstalled: false,
    ),
    InstalledCliTool(
      id: 'codex',
      name: 'Codex CLI',
      binaryName: 'codex',
      description: 'Uses your authenticated OpenAI Codex CLI (`codex exec`).',
      isInstalled: false,
    ),
    InstalledCliTool(
      id: 'gemini',
      name: 'Gemini CLI',
      binaryName: 'gemini',
      description: 'Uses your authenticated Google Gemini CLI (`gemini -p`).',
      isInstalled: false,
    ),
    InstalledCliTool(
      id: 'ollama',
      name: 'Ollama CLI',
      binaryName: 'ollama',
      description: 'Uses locally installed open-weight models via Ollama.',
      isInstalled: false,
      supportsDynamicModels: true,
    ),
  ];

  /// Scans PATH and common macOS/Linux/Windows binary directories for installed CLIs.
  Future<List<InstalledCliTool>> discoverInstalledClis() async {
    if (!isSupported) return const [];

    final searchDirs = _candidateBinDirs();
    final results = <InstalledCliTool>[];

    for (final tool in _catalog) {
      final path = await _resolveBinary(tool.binaryName, searchDirs);
      if (path != null) {
        final version = await _readVersion(path);
        results.add(
          tool.copyWith(
            isInstalled: true,
            executablePath: path,
            version: version,
          ),
        );
      } else {
        results.add(tool);
      }
    }

    // Put installed CLIs at the top for quick connection.
    results.sort((a, b) {
      if (a.isInstalled == b.isInstalled) return 0;
      return a.isInstalled ? -1 : 1;
    });
    return results;
  }

  /// Dynamically fetches available models for CLIs that expose a model listing command.
  Future<List<AiModelInfo>> fetchModelsForCli(InstalledCliTool cli) async {
    final exe = cli.executablePath;
    if (!isSupported || exe == null || exe.isEmpty) return const [];

    if (cli.id == 'agy') {
      final res = await Process.run(
        exe,
        ['models'],
        environment: _augmentedEnv(),
      );
      if (res.exitCode != 0) return const [];
      final lines = res.stdout.toString().split('\n');
      final models = <AiModelInfo>[];
      for (final raw in lines) {
        final line = raw.trim();
        if (line.isEmpty || line.startsWith('Fetching')) continue;
        final parts = line.split('\t');
        if (parts.length >= 2) {
          models.add(
            AiModelInfo(
              id: parts[0].trim(),
              displayName: parts[1].trim(),
            ),
          );
        }
      }
      return models;
    }

    if (cli.id == 'ollama') {
      final res = await Process.run(
        exe,
        ['list'],
        environment: _augmentedEnv(),
      );
      if (res.exitCode != 0) return const [];
      final lines = res.stdout.toString().split('\n');
      final models = <AiModelInfo>[];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final name = line.split(RegExp(r'\s+')).first;
        if (name.isNotEmpty) {
          models.add(AiModelInfo(id: name, displayName: name));
        }
      }
      return models;
    }

    return const [];
  }

  /// Executes a non-interactive prompt through the connected CLI using its own auth.
  Future<String> runPrompt({
    required InstalledCliTool cli,
    required String prompt,
    String? model,
  }) async {
    final exe = cli.executablePath;
    if (!isSupported || exe == null || exe.isEmpty) {
      throw Exception('${cli.name} executable not found on this machine.');
    }

    final cleanModel = model?.trim() ?? '';
    final List<String> args;

    switch (cli.id) {
      case 'agy':
        args = [
          '--print',
          '--output-format',
          'text',
          if (cleanModel.isNotEmpty) ...['--model', cleanModel],
          prompt,
        ];
      case 'claude':
        args = [
          '-p',
          prompt,
          '--output-format',
          'text',
          if (cleanModel.isNotEmpty) ...['--model', cleanModel],
        ];
      case 'codex':
        args = [
          'exec',
          '--skip-git-repo-check',
          if (cleanModel.isNotEmpty) ...['-m', cleanModel],
          prompt,
        ];
      case 'gemini':
        args = [
          '-p',
          prompt,
          if (cleanModel.isNotEmpty) ...['-m', cleanModel],
        ];
      case 'ollama':
        if (cleanModel.isEmpty) {
          throw Exception(
            'Select an installed Ollama model in Settings first.',
          );
        }
        args = ['run', cleanModel, prompt];
      default:
        args = ['-p', prompt];
    }

    final result = await Process.run(
      exe,
      args,
      environment: _augmentedEnv(),
    );

    final stdoutStr = result.stdout.toString().trim();
    final stderrStr = result.stderr.toString().trim();

    if (result.exitCode != 0) {
      final errDetail = stderrStr.isNotEmpty ? stderrStr : stdoutStr;
      throw Exception(
        '${cli.name} exited with code ${result.exitCode}: $errDetail',
      );
    }

    if (stdoutStr.isEmpty) {
      throw Exception('${cli.name} returned an empty response.');
    }
    return stdoutStr;
  }

  Map<String, String> _augmentedEnv() {
    final env = Map<String, String>.from(Platform.environment);
    final dirs = _candidateBinDirs();
    final sep = Platform.isWindows ? ';' : ':';
    final existing = env['PATH'] ?? '';
    env['PATH'] = [...dirs, if (existing.isNotEmpty) existing].join(sep);
    return env;
  }

  List<String> _candidateBinDirs() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (Platform.isWindows) {
      return [
        if (home.isNotEmpty) '$home\\.local\\bin',
        if (home.isNotEmpty) '$home\\AppData\\Roaming\\npm',
      ];
    }
    return [
      if (home.isNotEmpty) '$home/.local/bin',
      '/opt/homebrew/bin',
      '/usr/local/bin',
      if (home.isNotEmpty) '$home/.npm-global/bin',
      if (home.isNotEmpty) '$home/.cargo/bin',
      if (home.isNotEmpty) '$home/.bun/bin',
      '/usr/bin',
      '/bin',
    ];
  }

  Future<String?> _resolveBinary(String binary, List<String> dirs) async {
    final ext = Platform.isWindows ? '.exe' : '';
    for (final dir in dirs) {
      final candidate = '$dir${Platform.pathSeparator}$binary$ext';
      if (await File(candidate).exists()) {
        return candidate;
      }
    }
    try {
      final lookupCmd = Platform.isWindows ? 'where' : 'which';
      final res = await Process.run(
        lookupCmd,
        [binary],
        environment: _augmentedEnv(),
      );
      if (res.exitCode == 0) {
        final first = res.stdout.toString().trim().split('\n').first.trim();
        if (first.isNotEmpty && await File(first).exists()) {
          return first;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _readVersion(String executablePath) async {
    try {
      final res = await Process.run(
        executablePath,
        ['--version'],
        environment: _augmentedEnv(),
      ).timeout(const Duration(seconds: 4));
      final raw = (res.stdout.toString().trim().isNotEmpty
              ? res.stdout.toString()
              : res.stderr.toString())
          .trim();
      if (raw.isEmpty) return null;
      return raw.split('\n').first.trim();
    } catch (_) {
      return null;
    }
  }
}
