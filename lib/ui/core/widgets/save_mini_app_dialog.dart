import 'package:flutter/material.dart';
import '../../../domain/models/mini_app.dart';
import '../../features/studio/studio_view_model.dart';
import '../theme/studio_colors.dart';

/// Modal dialog matching the Stitch "Save Mini App to Library" design.
class SaveMiniAppDialog extends StatefulWidget {
  const SaveMiniAppDialog({super.key, required this.viewModel});

  final StudioViewModel viewModel;

  static Future<MiniApp?> show(
    BuildContext context,
    StudioViewModel viewModel,
  ) {
    return showDialog<MiniApp>(
      context: context,
      builder: (_) => SaveMiniAppDialog(viewModel: viewModel),
    );
  }

  @override
  State<SaveMiniAppDialog> createState() => _SaveMiniAppDialogState();
}

class _SaveMiniAppDialogState extends State<SaveMiniAppDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final _tagCtrl = TextEditingController();
  late String _category;
  late MiniAppVisibility _visibility;
  late List<String> _tags;

  static const _categories = [
    'Productivity & Utilities',
    'Health & Habits',
    'Finance & Analytics',
    'Team & Collaboration',
    'Developer Tools',
  ];

  @override
  void initState() {
    super.initState();
    final session = widget.viewModel.activeSession;
    _titleCtrl = TextEditingController(
      text: session?.currentAppTitle ?? 'TaskPulse — Schedule & To-Dos',
    );
    _descCtrl = TextEditingController(
      text:
          session?.currentAppDescription.isNotEmpty == true
          ? session!.currentAppDescription
          : 'Interactive mini app powered by a2ui_flutter.',
    );
    _category = _categories.contains(session?.currentCategory)
        ? session!.currentCategory
        : _categories.first;
    _visibility = widget.viewModel.settings.defaultVisibility;
    _tags = List.of(session?.currentTags ?? const ['flutter', 'a2ui']);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final clean = _tagCtrl.text.trim().replaceAll('#', '');
    if (clean.isEmpty || _tags.contains(clean)) return;
    setState(() {
      _tags.add(clean);
      _tagCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Dialog(
      backgroundColor: c.panelBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.borderStrong),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c.primaryAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bookmark_add_outlined,
                      color: c.primaryAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save Mini App to Library',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Store in your private vault or share with the public library',
                          style: TextStyle(fontSize: 12, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Mini App Title', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. TaskPulse — Schedule & To-Dos',
                ),
              ),
              const SizedBox(height: 14),
              Text('Description', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe what this mini app does...',
                ),
              ),
              const SizedBox(height: 14),
              Text('Category', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Publish Visibility',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _VisibilityOptionCard(
                      selected: _visibility == MiniAppVisibility.privateVault,
                      icon: Icons.lock_outline_rounded,
                      title: 'Private',
                      subtitle:
                          'Only you can see, install, and use this mini app.',
                      accent: c.warning,
                      onTap: () => setState(
                        () => _visibility = MiniAppVisibility.privateVault,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VisibilityOptionCard(
                      selected:
                          _visibility == MiniAppVisibility.publicCommunity,
                      icon: Icons.public_rounded,
                      title: 'Public',
                      subtitle:
                          'Others can discover, install, fork, and use it.',
                      accent: c.success,
                      onTap: () => setState(
                        () => _visibility = MiniAppVisibility.publicCommunity,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Tags', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.codeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in _tags)
                          Chip(
                            label: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: c.cyanAccent,
                              ),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _tags.remove(tag)),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: c.elevatedBg,
                            side: BorderSide(color: c.borderSubtle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagCtrl,
                            onSubmitted: (_) => _addTag(),
                            decoration: const InputDecoration(
                              hintText: 'Add tag...',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _addTag,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      final saved = widget.viewModel
                          .saveCurrentMiniAppToLibrary(
                            title: _titleCtrl.text,
                            description: _descCtrl.text,
                            category: _category,
                            visibility: _visibility,
                            tags: _tags,
                          );
                      Navigator.of(context).pop(saved);
                    },
                    icon: const Icon(Icons.cloud_upload_outlined, size: 17),
                    label: const Text('Confirm & Save to Library'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityOptionCard extends StatelessWidget {
  const _VisibilityOptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : c.elevatedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : c.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: selected ? accent : c.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected ? accent : c.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 17,
                  color: selected ? accent : c.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11.5, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
