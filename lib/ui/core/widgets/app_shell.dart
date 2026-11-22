import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/chat_sessions/chat_sessions_view.dart';
import '../../features/device_preview/device_preview_view.dart';
import '../../features/library/mini_app_library_view.dart';
import '../../features/settings/settings_view.dart';
import '../../features/studio/studio_view_model.dart';
import '../../features/workspace/studio_workspace_view.dart';
import '../theme/studio_colors.dart';
import 'notification_toast_overlay.dart';

/// Adaptive shell supporting Desktop/Web sidebar, Tablet rail, and Mobile bottom nav.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.viewModel});

  final StudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final c = StudioColors.of(context);
        final body = _buildActiveSection();

        return Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                if (width >= 1040) {
                  return _buildDesktopLayout(context, c, body);
                } else if (width >= 680) {
                  return _buildTabletLayout(context, c, body);
                } else {
                  return _buildMobileLayout(context, c, body);
                }
              },
            ),
            NotificationToastOverlay(
              notificationService: viewModel.notificationService,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveSection() {
    return switch (viewModel.activeSection) {
      StudioSection.chatSessions => ChatSessionsView(viewModel: viewModel),
      StudioSection.studioWorkspace => StudioWorkspaceView(
        viewModel: viewModel,
      ),
      StudioSection.miniAppLibrary => MiniAppLibraryView(viewModel: viewModel),
      StudioSection.devicePreview => DevicePreviewView(viewModel: viewModel),
      StudioSection.settings => SettingsView(viewModel: viewModel),
    };
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    StudioColors c,
    Widget body,
  ) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(context, c, compact: false),
          Expanded(
            child: Row(
              children: [
                _buildDesktopSidebar(context, c),
                VerticalDivider(width: 1, color: c.borderSubtle),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    StudioColors c,
    Widget body,
  ) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(context, c, compact: true),
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  backgroundColor: c.panelBg,
                  selectedIndex: viewModel.activeSection.index,
                  onDestinationSelected: (i) =>
                      viewModel.setSection(StudioSection.values[i]),
                  labelType: NavigationRailLabelType.selected,
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: IconButton(
                          tooltip: 'Toggle Dark/Light Theme',
                          icon: Icon(
                            viewModel.settings.themeMode == ThemeMode.dark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                          ),
                          onPressed: viewModel.toggleThemeMode,
                        ),
                      ),
                    ),
                  ),
                  destinations: [
                    for (final section in StudioSection.values)
                      NavigationRailDestination(
                        icon: Icon(section.icon),
                        label: Text(section.label.split(' ').first),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: c.borderSubtle),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    StudioColors c,
    Widget body,
  ) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.panelBg,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            _BrandLogo(c: c),
            const SizedBox(width: 8),
            const Text(
              'A2UI Studio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New Mini App Chat',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => viewModel.createNewChat(),
          ),
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              viewModel.settings.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: viewModel.toggleThemeMode,
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        backgroundColor: c.panelBg,
        selectedIndex: viewModel.activeSection.index,
        onDestinationSelected: (i) =>
            viewModel.setSection(StudioSection.values[i]),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          for (final section in StudioSection.values)
            NavigationDestination(
              icon: Icon(section.icon, size: 21),
              label: section.label.split(' ').first,
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    StudioColors c, {
    required bool compact,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.panelBg,
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: Row(
        children: [
          _BrandLogo(c: c),
          const SizedBox(width: 10),
          Text(
            'A2UI Studio',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.elevatedBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Text(
              'a2ui_flutter v0.4',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: c.cyanAccent,
              ),
            ),
          ),
          const Spacer(),
          if (!compact) ...[
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => viewModel.setSection(StudioSection.settings),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: viewModel.settings.isReadyForLiveGeneration
                      ? c.publicBadgeBg
                      : c.privateBadgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: viewModel.settings.isReadyForLiveGeneration
                          ? c.success
                          : c.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      viewModel.settings.isReadyForLiveGeneration
                          ? 'Live: ${viewModel.settings.activeEngineLabel}'
                          : 'Connect AI CLI or API Key',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: viewModel.settings.isReadyForLiveGeneration
                            ? c.publicBadgeFg
                            : c.privateBadgeFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          FilledButton.icon(
            onPressed: () => viewModel.createNewChat(),
            icon: const Icon(Icons.add, size: 17),
            label: const Text('New Mini App'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Trigger Test Local Notification',
            icon: Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: c.textSecondary,
            ),
            onPressed: () => viewModel.triggerLocalNotification(
              title: 'A2UI Studio Engine',
              body: 'Local notifications are active across all your mini apps.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, StudioColors c) {
    return Container(
      width: 226,
      color: c.panelBg,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'PLATFORM NAVIGATION',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: c.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final section in StudioSection.values) ...[
            _SidebarNavItem(
              section: section,
              selected: viewModel.activeSection == section,
              badgeCount: section == StudioSection.chatSessions
                  ? viewModel.sessions.length
                  : section == StudioSection.miniAppLibrary
                  ? viewModel.library.length
                  : null,
              onTap: () => viewModel.setSection(section),
            ),
            const SizedBox(height: 4),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.elevatedBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'a2ui_flutter',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '0.4.0',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: c.cyanAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Protocol',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'v1.0',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                viewModel.settings.themeMode == ThemeMode.dark
                    ? 'Obsidian Dark'
                    : 'Lumen Light',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Switch Dark / Light Theme',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  viewModel.settings.themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 18,
                  color: c.cyanAccent,
                ),
                onPressed: viewModel.toggleThemeMode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.c});

  final StudioColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primaryAccent, c.cyanAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.section,
    required this.selected,
    required this.onTap,
    this.badgeCount,
  });

  final StudioSection section;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.primaryAccent.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? c.primaryAccent.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              section.icon,
              size: 17,
              color: selected ? c.cyanAccent : c.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? c.cyanAccent : c.textSecondary,
                ),
              ),
            ),
            if (badgeCount != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.elevatedBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(fontSize: 10.5, color: c.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
