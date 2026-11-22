/// Metadata and discovery status for a locally installed AI CLI tool.
class InstalledCliTool {
  const InstalledCliTool({
    required this.id,
    required this.name,
    required this.binaryName,
    required this.description,
    required this.isInstalled,
    this.executablePath,
    this.version,
    this.supportsDynamicModels = false,
  });

  /// Canonical tool identifier: `agy`, `claude`, `codex`, `gemini`, `ollama`.
  final String id;
  final String name;
  final String binaryName;
  final String description;
  final bool isInstalled;
  final String? executablePath;
  final String? version;
  final bool supportsDynamicModels;

  InstalledCliTool copyWith({
    bool? isInstalled,
    String? executablePath,
    String? version,
  }) {
    return InstalledCliTool(
      id: id,
      name: name,
      binaryName: binaryName,
      description: description,
      isInstalled: isInstalled ?? this.isInstalled,
      executablePath: executablePath ?? this.executablePath,
      version: version ?? this.version,
      supportsDynamicModels: supportsDynamicModels,
    );
  }
}
