import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/chat_session.dart';
import '../../core/a2ui/a2ui_surface_host.dart';
import '../../core/theme/studio_colors.dart';
import '../../core/widgets/save_mini_app_dialog.dart';
import '../studio/studio_view_model.dart';

/// Multi-chat interface where users create multiple chats, specify mini apps,
/// iterate with AI, inspect live A2UI previews, and save to Library.
class ChatSessionsView extends StatefulWidget {
  const ChatSessionsView({super.key, required this.viewModel});

  final StudioViewModel viewModel;

  @override
  State<ChatSessionsView> createState() => _ChatSessionsViewState();
}

class _ChatSessionsViewState extends State<ChatSessionsView> {
  final _promptCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _mobileShowList = false;

  static const _suggestions = [
    'Create a mini app to track my to-dos with chat, calendar, and local notifications',
    'Add a Pomodoro focus timer',
    'Add a daily habit streak heatmap',
    'Add a monthly expense metric sparkline',
  ];

  @override
  void dispose() {
    _promptCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit([String? overridePrompt]) async {
    final text = (overridePrompt ?? _promptCtrl.text).trim();
    if (text.isEmpty) return;
    _promptCtrl.clear();
    await widget.viewModel.sendPrompt(text);
    if (_scrollCtrl.hasClients) {
      await _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 400,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 860;
            if (isCompact) {
              return _mobileShowList
                  ? _buildConversationsSidebar(context, isCompact: true)
                  : _buildChatPane(context, isCompact: true);
            }
            return Row(
              children: [
                SizedBox(
                  width: 300,
                  child: _buildConversationsSidebar(context, isCompact: false),
                ),
                VerticalDivider(
                  width: 1,
                  color: StudioColors.of(context).borderSubtle,
                ),
                Expanded(child: _buildChatPane(context, isCompact: false)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConversationsSidebar(
    BuildContext context, {
    required bool isCompact,
  }) {
    final c = StudioColors.of(context);
    final vm = widget.viewModel;
    final sessions = vm.filteredSessions;
    final active = vm.activeSession;

    return Container(
      color: c.panelBg,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_outlined, size: 18, color: c.cyanAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Conversations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.primaryAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${vm.sessions.length} Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                vm.createNewChat();
                if (isCompact) setState(() => _mobileShowList = false);
              },
              icon: const Icon(Icons.add_circle_outline, size: 17),
              label: const Text('New Chat'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: vm.setChatSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Filter conversations...',
              prefixIcon: Icon(Icons.search, size: 17),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'RECENT GENERATIONS',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: sessions.isEmpty
                ? Center(
                    child: Text(
                      'No chats match your filter.',
                      style: TextStyle(color: c.textMuted, fontSize: 12.5),
                    ),
                  )
                : ListView.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      final selected = active?.id == s.id;
                      return _ConversationTile(
                        session: s,
                        selected: selected,
                        onTap: () {
                          vm.selectSession(s.id);
                          if (isCompact) {
                            setState(() => _mobileShowList = false);
                          }
                        },
                        onPin: () => vm.togglePinSession(s.id),
                        onDelete: () => vm.deleteSession(s.id),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.elevatedBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'a2ui_flutter Engine',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.circle, size: 7, color: c.success),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.72,
                    minHeight: 4,
                    backgroundColor: c.borderSubtle,
                    color: c.cyanAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'v1.0',
                      style: TextStyle(fontSize: 10.5, color: c.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.settings.isReadyForLiveGeneration
                            ? vm.settings.activeEngineLabel
                            : 'Connect CLI / Key',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: vm.settings.isReadyForLiveGeneration
                              ? c.cyanAccent
                              : c.warning,
                        ),
                      ),
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

  Widget _buildChatPane(BuildContext context, {required bool isCompact}) {
    final c = StudioColors.of(context);
    final vm = widget.viewModel;
    final session = vm.activeSession;

    return Container(
      color: c.canvasBg,
      child: Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: c.panelBg,
              border: Border(bottom: BorderSide(color: c.borderSubtle)),
            ),
            child: Row(
              children: [
                if (isCompact) ...[
                  IconButton(
                    tooltip: 'All Chats',
                    icon: const Icon(Icons.menu_open_rounded, size: 20),
                    onPressed: () => setState(() => _mobileShowList = true),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session?.title ?? 'New Mini App Chat',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (session != null)
                        Text(
                          '${session.iterationCount} iterations • ${session.hasGeneratedUi ? "Mini App Ready" : "Waiting for spec"}',
                          style: TextStyle(fontSize: 11.5, color: c.textMuted),
                        ),
                    ],
                  ),
                ),
                if (session != null && session.hasGeneratedUi) ...[
                  OutlinedButton.icon(
                    onPressed: () => vm.setSection(StudioSection.studioWorkspace),
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: Text(isCompact ? 'Studio' : 'Open in Studio'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final saved = await SaveMiniAppDialog.show(context, vm);
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
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: Text(isCompact ? 'Save' : 'Save to Library'),
                  ),
                ],
              ],
            ),
          ),

          // Live API configuration banner when no key/model is configured yet
          if (!vm.settings.isReadyForLiveGeneration)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: c.warning.withValues(alpha: 0.12),
                border: Border(
                  bottom: BorderSide(color: c.warning.withValues(alpha: 0.35)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.key_rounded, size: 17, color: c.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connect an installed AI CLI (Antigravity, Claude, Codex, Gemini) or enter a Gemini API key to start generating mini apps.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => vm.setSection(StudioSection.settings),
                    icon: const Icon(Icons.tune_rounded, size: 15),
                    label: const Text('Connect CLI or API Key'),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: session == null || session.messages.isEmpty
                ? _buildEmptyChatState(context)
                : ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: session.messages.length + (vm.isGenerating ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index >= session.messages.length) {
                        return _buildGeneratingBubble(context);
                      }
                      final msg = session.messages[index];
                      return _ChatMessageCard(
                        message: msg,
                        viewModel: vm,
                      );
                    },
                  ),
          ),

          // Suggestions + Composer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: c.panelBg,
              border: Border(top: BorderSide(color: c.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: c.textMuted,
                      ),
                      const SizedBox(width: 6),
                      for (final suggestion in _suggestions) ...[
                        ActionChip(
                          label: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: c.textSecondary,
                            ),
                          ),
                          backgroundColor: c.elevatedBg,
                          side: BorderSide(color: c.borderSubtle),
                          onPressed: vm.isGenerating
                              ? null
                              : () => _submit(suggestion),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptCtrl,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          hintText:
                              'Describe your mini app or ask for iterations (e.g. "Add a calendar, chat, and local notifications")...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: vm.isGenerating ? null : () => _submit(),
                      icon: vm.isGenerating
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Send'),
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

  Widget _buildEmptyChatState(BuildContext context) {
    final c = StudioColors.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.primaryAccent, c.cyanAccent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Build a Flutter Mini App with A2UI',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Describe the features you want — like a to-do tracker with a calendar, embedded chat, and local notifications. Iterate until it feels right, then save it to your Private or Public Library.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _submit(
                  'Create a mini app that I can use to track my to-dos. It should have a chat, a calendar, and a local notification.',
                ),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('Try: To-Do + Calendar + Chat + Local Notifs'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingBubble(BuildContext context) {
    final c = StudioColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primaryAccent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: c.cyanAccent,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'A2UI Engine is compiling your Flutter component surface...',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  final ChatSession session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected
              ? c.primaryAccent.withValues(alpha: 0.14)
              : c.elevatedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? c.primaryAccent : c.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: session.hasGeneratedUi ? c.success : c.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    session.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? c.cyanAccent : c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onPin,
                  child: Icon(
                    session.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 14,
                    color: session.isPinned ? c.warning : c.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline, size: 15, color: c.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              session.lastMessagePreview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: c.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.canvasBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${session.iterationCount} iter • ${session.hasGeneratedUi ? "Ready" : "Draft"}',
                    style: TextStyle(fontSize: 10.5, color: c.cyanAccent),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat.jm().format(session.updatedAt),
                  style: TextStyle(fontSize: 10.5, color: c.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageCard extends StatelessWidget {
  const _ChatMessageCard({
    required this.message,
    required this.viewModel,
  });

  final ChatMessage message;
  final StudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final isUser = message.role == ChatMessageRole.user;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.elevatedBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: c.primaryAccent,
                      child: const Text(
                        'U',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: c.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat.jm().format(message.timestamp),
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.text,
                  style: TextStyle(fontSize: 13.5, color: c.textPrimary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.panelBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.primaryAccent, c.cyanAccent],
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'A2UI Engine',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                if (message.modelLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.elevatedBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      message.modelLabel!,
                      style: TextStyle(fontSize: 10.5, color: c.cyanAccent),
                    ),
                  ),
                const Spacer(),
                if (message.compileDurationMs != null)
                  Text(
                    '⚡ ${message.compileDurationMs}ms compile',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.success,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message.text,
              style: TextStyle(fontSize: 13.5, color: c.textPrimary),
            ),
            if (message.telemetrySteps.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.codeBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Execution Telemetry (${message.telemetrySteps.length} steps resolved)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final step in message.telemetrySteps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 13,
                              color: c.success,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                step,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (message.hasSurface) ...[
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: c.canvasBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: c.primaryAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message.generatedAppTitle ?? 'Generated Mini App',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: c.publicBadgeBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Live a2ui_flutter',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.publicBadgeFg,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => viewModel.setSection(
                                  StudioSection.studioWorkspace,
                                ),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 14,
                                ),
                                label: const Text('Studio Canvas'),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final saved = await SaveMiniAppDialog.show(
                                    context,
                                    viewModel,
                                  );
                                  if (saved != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Saved "${saved.title}" (${saved.visibility.badgeLabel})!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.bookmark_add_outlined,
                                  size: 14,
                                ),
                                label: const Text('Save to Library'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: c.borderSubtle),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 460),
                      child: A2uiSurfaceHost(
                        messages: message.a2uiMessages!,
                        onNotify: viewModel.triggerLocalNotification,
                        onTelemetry: viewModel.addTelemetry,
                        onMiniChat: viewModel.sendMiniAppChat,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
