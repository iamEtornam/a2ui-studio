import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/chat_session.dart';
import '../../core/a2ui/a2ui_surface_host.dart';
import '../../core/theme/studio_colors.dart';
import '../../core/widgets/save_mini_app_dialog.dart';
import '../studio/studio_view_model.dart';

enum _ViewportMode {
  mobile('Mobile', Icons.smartphone_rounded, 390),
  tablet('Tablet', Icons.tablet_mac_rounded, 680),
  desktop('Desktop', Icons.laptop_mac_rounded, 940),
  web('Web Canvas', Icons.language_rounded, double.infinity);

  const _ViewportMode(this.label, this.icon, this.maxWidth);
  final String label;
  final IconData icon;
  final double maxWidth;
}

/// Interactive Studio Workspace matching the Stitch split-pane IDE design.
class StudioWorkspaceView extends StatefulWidget {
  const StudioWorkspaceView({super.key, required this.viewModel});

  final StudioViewModel viewModel;

  @override
  State<StudioWorkspaceView> createState() => _StudioWorkspaceViewState();
}

class _StudioWorkspaceViewState extends State<StudioWorkspaceView>
    with SingleTickerProviderStateMixin {
  final _refineCtrl = TextEditingController();
  late final TabController _inspectorTabs;
  _ViewportMode _viewport = _ViewportMode.mobile;
  int _mobileTab = 0;

  @override
  void initState() {
    super.initState();
    _inspectorTabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _refineCtrl.dispose();
    _inspectorTabs.dispose();
    super.dispose();
  }

  Future<void> _applyUpdate() async {
    final text = _refineCtrl.text.trim();
    if (text.isEmpty) return;
    _refineCtrl.clear();
    await widget.viewModel.sendPrompt(text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 960;
            if (isCompact) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: StudioColors.of(context).panelBg,
                      border: Border(
                        bottom: BorderSide(
                          color: StudioColors.of(context).borderSubtle,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(
                                value: 0,
                                icon: Icon(Icons.phone_iphone, size: 16),
                                label: Text('Live Preview'),
                              ),
                              ButtonSegment(
                                value: 1,
                                icon: Icon(Icons.tune, size: 16),
                                label: Text('AI Refine & Tree'),
                              ),
                            ],
                            selected: {_mobileTab},
                            onSelectionChanged: (s) =>
                                setState(() => _mobileTab = s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _mobileTab == 0
                        ? _buildCanvasPane(context, isCompact: true)
                        : _buildInspectorPane(context),
                  ),
                ],
              );
            }

            return Row(
              children: [
                SizedBox(
                  width: 370,
                  child: _buildInspectorPane(context),
                ),
                VerticalDivider(
                  width: 1,
                  color: StudioColors.of(context).borderSubtle,
                ),
                Expanded(child: _buildCanvasPane(context, isCompact: false)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInspectorPane(BuildContext context) {
    final c = StudioColors.of(context);
    final vm = widget.viewModel;
    final session = vm.activeSession;
    final modifiers = session?.modifiers ?? const EngineModifiers();
    final nodes = _extractNodes(session?.currentA2uiMessages ?? const []);

    return Container(
      color: c.panelBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: c.elevatedBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.borderSubtle),
                      ),
                      child: Icon(
                        Icons.terminal_rounded,
                        size: 16,
                        color: c.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session?.currentAppTitle ?? 'No Active Session',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'a2ui_id: #${session?.id ?? "none"}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: c.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.primaryAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'v${session?.iterationCount ?? 0}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 15, color: c.cyanAccent),
                    const SizedBox(width: 6),
                    Text(
                      'AI Prompt Refinement',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 13.5),
                    ),
                    const Spacer(),
                    Text(
                      'a2ui_flutter 0.4',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _refineCtrl,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Iterate on this mini app (e.g. "Add a Pomodoro timer and habit tracker")...',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: vm.isGenerating ? null : _applyUpdate,
                      icon: vm.isGenerating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.bolt_rounded, size: 16),
                      label: const Text('Apply Update'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'ENGINE MODIFIERS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ModifierToggleChip(
                      label: 'M3 Dark Theme',
                      value: modifiers.m3DarkTheme,
                      onChanged: (v) =>
                          vm.updateModifiers(modifiers.copyWith(m3DarkTheme: v)),
                    ),
                    _ModifierToggleChip(
                      label: 'Local Notifs',
                      value: modifiers.localNotifications,
                      onChanged: (v) => vm.updateModifiers(
                        modifiers.copyWith(localNotifications: v),
                      ),
                    ),
                    _ModifierToggleChip(
                      label: 'Haptic Feedback',
                      value: modifiers.hapticFeedback,
                      onChanged: (v) => vm.updateModifiers(
                        modifiers.copyWith(hapticFeedback: v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.borderSubtle),
          TabBar(
            controller: _inspectorTabs,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'A2UI Tree'),
              Tab(text: 'A2UI JSON'),
              Tab(text: 'Properties'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _inspectorTabs,
              children: [
                // 1. A2UI Widget Tree
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    final isRoot = node['id'] == 'root';
                    return Container(
                      margin: EdgeInsets.only(
                        left: isRoot ? 0 : 14,
                        bottom: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: c.elevatedBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRoot
                                ? Icons.account_tree_outlined
                                : Icons.widgets_outlined,
                            size: 15,
                            color: c.cyanAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            node['component']?.toString() ?? 'Widget',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'id: ${node['id']}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: c.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // 2. A2UI JSON Buffer
                Container(
                  color: c.codeBg,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          final text = session?.toPrettyA2uiJson() ?? '[]';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied A2UI v1.0 JSON schema!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('Copy JSON'),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SelectableText(
                            session?.toPrettyA2uiJson() ?? '[]',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11.5,
                              color: c.textPrimary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 3. Properties
                ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    _PropRow('App Title', session?.currentAppTitle ?? '—'),
                    _PropRow('Category', session?.currentCategory ?? '—'),
                    _PropRow('Components', '${nodes.length} A2UI nodes'),
                    _PropRow('Protocol', 'A2UI v1.0'),
                    _PropRow(
                      'Catalogs',
                      'BasicCatalog + StudioCatalog',
                    ),
                    _PropRow(
                      'Tags',
                      (session?.currentTags ?? const []).join(', '),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasPane(BuildContext context, {required bool isCompact}) {
    final c = StudioColors.of(context);
    final vm = widget.viewModel;
    final session = vm.activeSession;

    return Container(
      color: c.canvasBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.panelBg,
              border: Border(bottom: BorderSide(color: c.borderSubtle)),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    for (final mode in _ViewportMode.values)
                      ChoiceChip(
                        avatar: Icon(mode.icon, size: 15),
                        label: Text(mode.label),
                        selected: _viewport == mode,
                        onSelected: (_) => setState(() => _viewport = mode),
                      ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: session == null || !session.hasGeneratedUi
                      ? null
                      : () async {
                          final saved = await SaveMiniAppDialog.show(
                            context,
                            vm,
                          );
                          if (saved != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Saved "${saved.title}" to ${saved.visibility.badgeLabel}!',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                  label: const Text('Save to Library'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 10 : 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  constraints: BoxConstraints(
                    maxWidth: _viewport.maxWidth,
                  ),
                  decoration: BoxDecoration(
                    color: c.panelBg,
                    borderRadius: BorderRadius.circular(
                      _viewport == _ViewportMode.mobile ? 28 : 14,
                    ),
                    border: Border.all(
                      color: c.borderStrong,
                      width: _viewport == _ViewportMode.mobile ? 4 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: A2uiSurfaceHost(
                    messages: session?.currentA2uiMessages ?? const [],
                    onNotify: vm.triggerLocalNotification,
                    onTelemetry: vm.addTelemetry,
                    onMiniChat: vm.sendMiniAppChat,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, Object?>> _extractNodes(
    List<Map<String, Object?>> messages,
  ) {
    final result = <Map<String, Object?>>[];
    for (final m in messages) {
      final update = m['updateComponents'];
      if (update is Map && update['components'] is List) {
        for (final comp in update['components'] as List) {
          if (comp is Map) {
            result.add(Map<String, Object?>.from(comp));
          }
        }
      }
    }
    return result;
  }
}

class _ModifierToggleChip extends StatelessWidget {
  const _ModifierToggleChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: value ? c.textPrimary : c.textSecondary,
        ),
      ),
      selected: value,
      onSelected: onChanged,
      backgroundColor: c.elevatedBg,
      selectedColor: c.primaryAccent.withValues(alpha: 0.26),
      checkmarkColor: c.cyanAccent,
      side: BorderSide(color: value ? c.primaryAccent : c.borderSubtle),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PropRow extends StatelessWidget {
  const _PropRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: c.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
