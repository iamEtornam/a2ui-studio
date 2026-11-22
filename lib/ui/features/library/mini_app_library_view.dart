import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/mini_app.dart';
import '../../core/theme/studio_colors.dart';
import '../../core/widgets/mini_app_runner_dialog.dart';
import '../studio/studio_view_model.dart';

/// Collection of saved Private Vault & Public Community A2UI mini apps.
class MiniAppLibraryView extends StatelessWidget {
  const MiniAppLibraryView({super.key, required this.viewModel});

  final StudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final c = StudioColors.of(context);
        final apps = viewModel.filteredLibrary;

        return Container(
          color: c.canvasBg,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
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
                                'REGISTRY • A2UI V1.0 • HOT RELOAD READY',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  color: c.cyanAccent,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mini App Library',
                                style: Theme.of(
                                  context,
                                ).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Explore your personal Private Vault and Public Community mini apps powered by a2ui_flutter.',
                                style: TextStyle(
                                  color: c.textSecondary,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: () => viewModel.createNewChat(),
                            icon: const Icon(Icons.add_circle_outline, size: 17),
                            label: const Text('Create New Mini App'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // KPI Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 720;
                          final cards = [
                            _StatCard(
                              label: 'Total Mini Apps Installed',
                              value: '${viewModel.installedAppsCount}',
                              sublabel: 'Ready to launch locally',
                              icon: Icons.download_done_rounded,
                              accent: c.primaryAccent,
                            ),
                            _StatCard(
                              label: 'Active Local Notifications',
                              value: '${viewModel.activeNotifAppsCount}',
                              sublabel: 'Background reminder loops',
                              icon: Icons.notifications_active_outlined,
                              accent: c.cyanAccent,
                            ),
                            _StatCard(
                              label: 'Public Community Apps',
                              value: '${viewModel.publicAppsCount}',
                              sublabel: 'Discoverable & forkable',
                              icon: Icons.public_rounded,
                              accent: c.success,
                            ),
                          ];
                          if (wide) {
                            return Row(
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 12),
                                Expanded(child: cards[1]),
                                const SizedBox(width: 12),
                                Expanded(child: cards[2]),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 10),
                              cards[1],
                              const SizedBox(height: 10),
                              cards[2],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Visibility Filter Tabs
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text('All Apps (${viewModel.library.length})'),
                            selected:
                                viewModel.libraryFilter == LibraryFilter.all,
                            onSelected: (_) =>
                                viewModel.setLibraryFilter(LibraryFilter.all),
                          ),
                          ChoiceChip(
                            avatar: Icon(
                              Icons.lock_outline_rounded,
                              size: 15,
                              color: c.privateBadgeFg,
                            ),
                            label: Text(
                              'My Private Vault (${viewModel.privateAppsCount})',
                            ),
                            selected:
                                viewModel.libraryFilter ==
                                LibraryFilter.privateVault,
                            onSelected: (_) => viewModel.setLibraryFilter(
                              LibraryFilter.privateVault,
                            ),
                          ),
                          ChoiceChip(
                            avatar: Icon(
                              Icons.public_rounded,
                              size: 15,
                              color: c.publicBadgeFg,
                            ),
                            label: Text(
                              'Public Community (${viewModel.publicAppsCount})',
                            ),
                            selected:
                                viewModel.libraryFilter ==
                                LibraryFilter.publicCommunity,
                            onSelected: (_) => viewModel.setLibraryFilter(
                              LibraryFilter.publicCommunity,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search + Category Filter
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: TextField(
                              onChanged: viewModel.setLibrarySearchQuery,
                              decoration: const InputDecoration(
                                hintText:
                                    'Search mini apps by title, tags, or author...',
                                prefixIcon: Icon(Icons.search, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: DropdownButtonFormField<String>(
                              initialValue: viewModel.libraryCategory,
                              isDense: true,
                              items: viewModel.availableCategories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(
                                        cat,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) viewModel.setLibraryCategory(v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (apps.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No mini apps match this filter yet. Build one in Chat Sessions and click Save to Library!',
                      style: TextStyle(color: c.textSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 292,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _MiniAppCard(
                        app: apps[index],
                        viewModel: viewModel,
                      ),
                      childCount: apps.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        sublabel,
                        style: TextStyle(fontSize: 11.5, color: accent),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MiniAppCard extends StatelessWidget {
  const _MiniAppCard({
    required this.app,
    required this.viewModel,
  });

  final MiniApp app;
  final StudioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: c.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: app.isPublic ? c.publicBadgeBg : c.privateBadgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      app.isPublic
                          ? Icons.public_rounded
                          : Icons.lock_outline_rounded,
                      size: 12,
                      color: app.isPublic ? c.publicBadgeFg : c.privateBadgeFg,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      app.visibility.badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: app.isPublic
                            ? c.publicBadgeFg
                            : c.privateBadgeFg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: c.elevatedBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  app.version,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    color: c.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              if (app.isOwnedByCurrentUser)
                IconButton(
                  tooltip: app.isPrivate
                      ? 'Make Public (share to community)'
                      : 'Make Private (only you can see/use)',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    app.isPrivate ? Icons.lock_open_rounded : Icons.lock_outline,
                    size: 16,
                    color: c.cyanAccent,
                  ),
                  onPressed: () => viewModel.toggleMiniAppVisibility(app.id),
                ),
              if (app.isOwnedByCurrentUser)
                IconButton(
                  tooltip: 'Delete Mini App',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: c.textMuted,
                  ),
                  onPressed: () => viewModel.deleteMiniApp(app.id),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.codeBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(
                  app.hasLocalNotifications
                      ? Icons.notifications_active_outlined
                      : Icons.widgets_outlined,
                  size: 18,
                  color: c.cyanAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${app.category} • a2ui_flutter',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: c.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            app.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            app.description,
            style: TextStyle(fontSize: 12.5, color: c.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final tag in app.tags.take(4))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.elevatedBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(fontSize: 10.5, color: c.cyanAccent),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'by ${app.authorName}',
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
              const Spacer(),
              if (app.isPublic) ...[
                InkWell(
                  onTap: () => viewModel.toggleLikeMiniApp(app.id),
                  child: Row(
                    children: [
                      Icon(
                        app.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: app.isLiked ? c.danger : c.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${app.likeCount}',
                        style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${app.installCount} installs',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (!app.isInstalled) {
                      viewModel.installMiniApp(app.id);
                    }
                    MiniAppRunnerDialog.show(context, app, viewModel);
                  },
                  icon: Icon(
                    app.isInstalled
                        ? Icons.play_arrow_rounded
                        : Icons.download_rounded,
                    size: 16,
                  ),
                  label: Text(
                    app.isInstalled ? 'Launch / Use' : 'Install & Run',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => viewModel.forkMiniAppToChat(app),
                icon: const Icon(Icons.call_split_rounded, size: 15),
                label: const Text('Fork'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
