import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/installed_cli.dart';
import '../../../domain/models/mini_app.dart';
import '../../../domain/models/studio_settings.dart';
import '../../core/theme/studio_colors.dart';
import '../studio/studio_view_model.dart';

/// Workspace configuration for Installed AI CLIs (zero-API-key local auth),
/// live Gemini API + dynamic online model discovery, notifications, and theme.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.viewModel});

  final StudioViewModel viewModel;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _channelCtrl;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl = TextEditingController(
      text: widget.viewModel.settings.geminiApiKey,
    );
    _channelCtrl = TextEditingController(
      text: widget.viewModel.settings.notificationChannelId,
    );
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _channelCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndFetchModels() async {
    final s = widget.viewModel.settings;
    final key = _apiKeyCtrl.text.trim();
    widget.viewModel.updateSettings(
      s.copyWith(
        geminiApiKey: key,
        notificationChannelId: _channelCtrl.text.trim().isEmpty
            ? 'a2ui_task_reminders'
            : _channelCtrl.text.trim(),
      ),
    );

    if (key.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saved settings. Connect an installed CLI or enter a Gemini API key.',
            ),
          ),
        );
      }
      return;
    }

    final ok = await widget.viewModel.fetchLiveModels(apiKeyOverride: key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Connected! Loaded ${widget.viewModel.availableModels.length} live Gemini models.'
              : widget.viewModel.modelsError ?? 'Failed to fetch live models.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final c = StudioColors.of(context);
        final vm = widget.viewModel;
        final s = vm.settings;
        final models = vm.availableModels;
        final selectedValue = models.any((m) => m.id == s.selectedModel)
            ? s.selectedModel
            : (models.isNotEmpty ? models.first.id : null);

        final installedCount = vm.installedClis
            .where((cli) => cli.isInstalled)
            .length;

        return Container(
          color: c.canvasBg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1020),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.isReadyForLiveGeneration
                                  ? 'LIVE ENGINE ACTIVE • ${s.activeEngineLabel.toUpperCase()}'
                                  : 'LIVE API / CLI CONFIGURATION • A2UI V1.0',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                color: s.isReadyForLiveGeneration
                                    ? c.success
                                    : c.warning,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Settings & AI Connections',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect directly to an installed AI CLI (no API key needed) or use a live Gemini API key with dynamic model discovery.',
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        if (s.isReadyForLiveGeneration)
                          FilledButton.icon(
                            onPressed: () {
                              if (vm.sessions.isEmpty) {
                                vm.createNewChat();
                              } else {
                                vm.setSection(StudioSection.chatSessions);
                              }
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                            ),
                            label: const Text('Start Building Mini Apps'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. Installed AI CLIs (Zero API Key Local Auth)
                    _SectionCard(
                      icon: Icons.terminal_rounded,
                      title: 'Installed AI CLIs (Use Existing CLI Auth)',
                      subtitle: vm.supportsLocalCli
                          ? 'Automatically scans your machine for Antigravity, Claude Code, Codex, Gemini, and Ollama CLIs. Connect to any installed CLI to use its models without entering an API key.'
                          : 'Local CLI auto-discovery is available on Desktop (macOS, Linux, Windows). On Web/Mobile, use the Gemini API key section below.',
                      badge: vm.supportsLocalCli
                          ? (s.isUsingInstalledCli
                                ? 'Connected: ${s.connectedCliName}'
                                : '$installedCount Detected')
                          : 'Desktop Only',
                      badgeColor: s.isUsingInstalledCli
                          ? c.success
                          : c.cyanAccent,
                      trailingAction: vm.supportsLocalCli
                          ? OutlinedButton.icon(
                              onPressed: vm.isScanningClis
                                  ? null
                                  : vm.scanInstalledClis,
                              icon: vm.isScanningClis
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.radar_rounded, size: 16),
                              label: const Text('Rescan CLIs'),
                            )
                          : null,
                      child: !vm.supportsLocalCli
                          ? Text(
                              'Run A2UI Studio on macOS, Linux, or Windows desktop to connect to locally installed CLIs.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: c.textMuted,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final cli in vm.installedClis) ...[
                                  _InstalledCliRow(
                                    cli: cli,
                                    isConnected:
                                        s.isUsingInstalledCli &&
                                        s.connectedCliId == cli.id,
                                    onConnect: () async {
                                      await vm.connectInstalledCli(cli);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Connected to ${cli.name}! Ready to generate A2UI mini apps.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    onDisconnect: vm.disconnectInstalledCli,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // Dynamic CLI model picker when connected CLI exposes live models (e.g. agy / ollama)
                                if (s.isUsingInstalledCli &&
                                    (vm.isFetchingCliModels ||
                                        vm.cliModels.isNotEmpty)) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: c.codeBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: c.primaryAccent.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.auto_awesome,
                                              size: 15,
                                              color: c.cyanAccent,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${s.connectedCliName} Live Models (${vm.cliModels.length})',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: c.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (vm.isFetchingCliModels)
                                          Row(
                                            children: [
                                              const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Querying live models from ${s.connectedCliName}...',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: c.textSecondary,
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          DropdownButtonFormField<String>(
                                            initialValue:
                                                vm.cliModels.any(
                                                  (m) =>
                                                      m.id ==
                                                      s.cliSelectedModel,
                                                )
                                                ? s.cliSelectedModel
                                                : vm.cliModels.first.id,
                                            isExpanded: true,
                                            items: vm.cliModels
                                                .map(
                                                  (m) => DropdownMenuItem(
                                                    value: m.id,
                                                    child: Text(
                                                      '${m.displayName} (${m.id})',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (v) {
                                              if (v != null) {
                                                vm.updateSettings(
                                                  s.copyWith(
                                                    cliSelectedModel: v,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Direct Gemini API Key (Dynamic Online Model Discovery)
                    _SectionCard(
                      icon: Icons.key_rounded,
                      title: 'Google Gemini Direct API (Optional)',
                      subtitle:
                          'Alternatively, paste a Gemini API key to fetch the latest models directly from generativelanguage.googleapis.com/v1beta/models.',
                      badge:
                          s.backendMode == AiBackendMode.geminiApi &&
                              s.hasGeminiApiKey &&
                              s.hasSelectedModel
                          ? 'Active • ${models.length} models'
                          : 'Optional',
                      badgeColor:
                          s.backendMode == AiBackendMode.geminiApi &&
                              s.hasGeminiApiKey &&
                              s.hasSelectedModel
                          ? c.success
                          : c.textMuted,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GEMINI_API_KEY',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: c.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _apiKeyCtrl,
                                  obscureText: _obscureKey,
                                  onSubmitted: (_) => _saveAndFetchModels(),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Paste your Gemini API key (AIza...)',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureKey
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureKey = !_obscureKey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.icon(
                                onPressed: vm.isFetchingModels
                                    ? null
                                    : _saveAndFetchModels,
                                icon: vm.isFetchingModels
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.cloud_sync_outlined,
                                        size: 16,
                                      ),
                                label: const Text('Save & Fetch Models'),
                              ),
                            ],
                          ),
                          if (vm.modelsError != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: c.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: c.danger.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                vm.modelsError!,
                                style: TextStyle(fontSize: 12, color: c.danger),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 380,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Live Gemini API Model',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          models.isEmpty
                                              ? 'Not loaded'
                                              : '${models.length} available',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            color: c.cyanAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (models.isEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: c.codeBg,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: c.borderSubtle,
                                          ),
                                        ),
                                        child: Text(
                                          'Enter API key and click "Save & Fetch Models" to load live models.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.textMuted,
                                          ),
                                        ),
                                      )
                                    else
                                      DropdownButtonFormField<String>(
                                        initialValue: selectedValue,
                                        isExpanded: true,
                                        items: models
                                            .map(
                                              (m) => DropdownMenuItem(
                                                value: m.id,
                                                child: Text(
                                                  '${m.displayName} (${m.id})',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) {
                                            vm.updateSettings(
                                              s.copyWith(
                                                backendMode:
                                                    AiBackendMode.geminiApi,
                                                selectedModel: v,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 280,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Generation Temperature',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          s.temperature.toStringAsFixed(2),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            color: c.cyanAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: s.temperature,
                                      min: 0.0,
                                      max: 1.0,
                                      divisions: 20,
                                      onChanged: (v) => vm.updateSettings(
                                        s.copyWith(temperature: v),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Appearance & Local Notifications
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 760;
                        final appearanceCard = _SectionCard(
                          icon: Icons.palette_outlined,
                          title: 'Studio Appearance & Privacy',
                          subtitle:
                              'Switch between Obsidian Kinetic (Dark) and Lumen Kinetic (Light), and set default Library visibility.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Obsidian Kinetic Dark Mode'),
                                subtitle: Text(
                                  s.themeMode == ThemeMode.dark
                                      ? 'Dark IDE theme active'
                                      : 'Lumen Kinetic light theme active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSecondary,
                                  ),
                                ),
                                value: s.themeMode == ThemeMode.dark,
                                onChanged: (_) => vm.toggleThemeMode(),
                              ),
                              const Divider(),
                              const SizedBox(height: 6),
                              Text(
                                'Default Mini App Visibility',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<MiniAppVisibility>(
                                segments: const [
                                  ButtonSegment(
                                    value: MiniAppVisibility.privateVault,
                                    icon: Icon(
                                      Icons.lock_outline_rounded,
                                      size: 16,
                                    ),
                                    label: Text('Private Vault'),
                                  ),
                                  ButtonSegment(
                                    value: MiniAppVisibility.publicCommunity,
                                    icon: Icon(Icons.public_rounded, size: 16),
                                    label: Text('Public Community'),
                                  ),
                                ],
                                selected: {s.defaultVisibility},
                                onSelectionChanged: (sel) => vm.updateSettings(
                                  s.copyWith(defaultVisibility: sel.first),
                                ),
                              ),
                            ],
                          ),
                        );

                        final notifCard = _SectionCard(
                          icon: Icons.notifications_active_outlined,
                          title: 'Local Notification Daemon',
                          subtitle:
                              'Test and configure local notification reminders across Mobile, Web, and Desktop.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notification Channel ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _channelCtrl,
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Background Loop Daemon'),
                                subtitle: Text(
                                  'Enables scheduled reminders inside live mini apps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSecondary,
                                  ),
                                ),
                                value: s.backgroundNotificationDaemon,
                                onChanged: (v) => vm.updateSettings(
                                  s.copyWith(backgroundNotificationDaemon: v),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => vm.triggerLocalNotification(
                                    title: 'Local Notification Test',
                                    body:
                                        'Channel "${s.notificationChannelId}" is operational!',
                                  ),
                                  icon: const Icon(Icons.bolt, size: 16),
                                  label: const Text(
                                    'Test Local Notification Trigger',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: appearanceCard),
                              const SizedBox(width: 16),
                              Expanded(child: notifCard),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            appearanceCard,
                            const SizedBox(height: 16),
                            notifCard,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InstalledCliRow extends StatelessWidget {
  const _InstalledCliRow({
    required this.cli,
    required this.isConnected,
    required this.onConnect,
    required this.onDisconnect,
  });

  final InstalledCliTool cli;
  final bool isConnected;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected
            ? c.primaryAccent.withValues(alpha: 0.14)
            : c.elevatedBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isConnected
              ? c.primaryAccent
              : (cli.isInstalled
                    ? c.borderStrong
                    : c.borderSubtle.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cli.isInstalled
                  ? (isConnected
                        ? c.primaryAccent.withValues(alpha: 0.25)
                        : c.publicBadgeBg)
                  : c.codeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              cli.isInstalled
                  ? Icons.terminal_rounded
                  : Icons.highlight_off_rounded,
              size: 18,
              color: cli.isInstalled
                  ? (isConnected ? c.cyanAccent : c.publicBadgeFg)
                  : c.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      cli.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: cli.isInstalled ? c.textPrimary : c.textMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cli.isInstalled ? c.publicBadgeBg : c.codeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        cli.isInstalled
                            ? (cli.version ?? 'Installed')
                            : 'Not Found',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          color: cli.isInstalled
                              ? c.publicBadgeFg
                              : c.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  cli.isInstalled && cli.executablePath != null
                      ? '${cli.executablePath} — ${cli.description}'
                      : cli.description,
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isConnected)
            OutlinedButton.icon(
              onPressed: onDisconnect,
              icon: Icon(Icons.check_circle, size: 15, color: c.success),
              label: const Text('Connected'),
            )
          else if (cli.isInstalled)
            FilledButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.link_rounded, size: 15),
              label: const Text('Connect'),
            )
          else
            Text(
              'Not installed',
              style: TextStyle(fontSize: 11.5, color: c.textMuted),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
    this.badgeColor,
    this.trailingAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Material(
      color: c.panelBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: c.cyanAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? c.success).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor ?? c.success,
                    ),
                  ),
                ),
              ],
              if (trailingAction != null) ...[
                const SizedBox(width: 10),
                trailingAction!,
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.5, color: c.textSecondary),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
      ),
    );
  }
}
