import 'dart:async';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../theme/studio_colors.dart';

/// Callback fired when a custom A2UI component triggers a local notification.
typedef A2uiNotificationCallback =
    void Function({
      required String title,
      required String body,
      bool scheduled,
    });

/// Callback fired when a custom A2UI component emits telemetry.
typedef A2uiTelemetryCallback = void Function(String line);

/// Callback fired when an embedded [MiniChatPanel] sends a live message to the AI.
typedef A2uiMiniChatCallback =
    Future<String> Function(String message, String appContext);

/// Custom A2UI v1.0 catalog for A2UI Studio mini apps.
class StudioCatalog {
  static const String id = 'https://a2ui.studio/catalog/v1';

  static CatalogImplementation create({
    A2uiNotificationCallback? onNotify,
    A2uiTelemetryCallback? onTelemetry,
    A2uiMiniChatCallback? onMiniChat,
  }) {
    return CatalogImplementation(
      id: id,
      protocolVersion: A2uiProtocolVersion.v1_0,
      title: 'A2UI Studio Mini App Catalog',
      description:
          'Interactive Flutter mini-app components: MiniAppHeader, CalendarWidget, '
          'TodoBoard, MiniChatPanel, LocalNotificationCard, MetricChartCard, '
          'PomodoroTimer, and HabitHeatmap.',
      components: [
        _miniAppHeader(onNotify: onNotify, onTelemetry: onTelemetry),
        _calendarWidget(onTelemetry: onTelemetry),
        _todoBoard(onNotify: onNotify, onTelemetry: onTelemetry),
        _miniChatPanel(onMiniChat: onMiniChat, onTelemetry: onTelemetry),
        _localNotificationCard(onNotify: onNotify, onTelemetry: onTelemetry),
        _metricChartCard(),
        _pomodoroTimer(onNotify: onNotify, onTelemetry: onTelemetry),
        _habitHeatmap(onTelemetry: onTelemetry),
      ],
    );
  }

  static ComponentImplementation _miniAppHeader({
    A2uiNotificationCallback? onNotify,
    A2uiTelemetryCallback? onTelemetry,
  }) {
    return ComponentImplementation(
      name: 'MiniAppHeader',
      schema: Schema.object(
        properties: {
          'title': CommonSchemasV1.dynamicString,
          'subtitle': CommonSchemasV1.dynamicString,
          'badge': CommonSchemasV1.dynamicString,
          'showNotificationBell': CommonSchemasV1.dynamicBoolean,
        },
        required: ['title'],
      ),
      builder: (context, node, props, buildChild) {
        final c = StudioColors.of(context);
        final title = props.string('title') ?? 'Mini App';
        final subtitle = props.string('subtitle');
        final badge = props.string('badge') ?? 'a2ui live';
        final showBell = props.boolean('showNotificationBell') ?? true;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.panelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.primaryAccent, c.cyanAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.publicBadgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: c.publicBadgeFg,
                  ),
                ),
              ),
              if (showBell) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Test local notification',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: c.cyanAccent,
                  ),
                  onPressed: () {
                    onNotify?.call(
                      title: '$title Reminder',
                      body: 'Local notification engine is active and synced.',
                      scheduled: false,
                    );
                    onTelemetry?.call(
                      '[LocalNotif] Triggered bell notification from "$title".',
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static ComponentImplementation _calendarWidget({
    A2uiTelemetryCallback? onTelemetry,
  }) {
    return ComponentImplementation(
      name: 'CalendarWidget',
      schema: Schema.object(
        properties: {
          'title': CommonSchemasV1.dynamicString,
          'highlightDays': Schema.list(items: Schema.integer()),
        },
      ),
      builder: (context, node, props, buildChild) {
        final rawDays = props.value('highlightDays');
        final highlightDays = <int>{};
        if (rawDays is List) {
          for (final d in rawDays) {
            if (d is num) highlightDays.add(d.toInt());
          }
        }
        return _InteractiveCalendarCard(
          title: props.string('title') ?? 'Schedule Calendar',
          highlightDays: highlightDays,
          onDateSelected: (day) {
            onTelemetry?.call(
              '[CalendarWidget] Selected ${DateFormat.yMMMd().format(day)}.',
            );
          },
        );
      },
    );
  }

  static ComponentImplementation _todoBoard({
    A2uiNotificationCallback? onNotify,
    A2uiTelemetryCallback? onTelemetry,
  }) {
    return ComponentImplementation(
      name: 'TodoBoard',
      schema: Schema.object(
        properties: {
          'title': CommonSchemasV1.dynamicString,
          'reorderable': CommonSchemasV1.dynamicBoolean,
          'items': Schema.list(items: Schema.object()),
        },
      ),
      builder: (context, node, props, buildChild) {
        final rawItems = props.value('items');
        final initialTasks = <_TodoItemData>[];
        if (rawItems is List) {
          for (var i = 0; i < rawItems.length; i++) {
            final item = rawItems[i];
            if (item is Map) {
              initialTasks.add(
                _TodoItemData(
                  id: item['id']?.toString() ?? 'task_$i',
                  title: item['title']?.toString() ?? 'Task ${i + 1}',
                  dueLabel: item['due']?.toString() ?? 'Today',
                  priority: item['priority']?.toString() ?? 'Medium',
                  done: item['done'] == true,
                ),
              );
            }
          }
        }
        return _InteractiveTodoBoard(
          title: props.string('title') ?? 'Scheduled Tasks',
          reorderable: props.boolean('reorderable') ?? true,
          initialItems: initialTasks,
          onNotify: onNotify,
          onTelemetry: onTelemetry,
        );
      },
    );
  }

  static ComponentImplementation _miniChatPanel({
    A2uiMiniChatCallback? onMiniChat,
    A2uiTelemetryCallback? onTelemetry,
  }) {
    return ComponentImplementation(
      name: 'MiniChatPanel',
      schema: Schema.object(
        properties: {
          'title': CommonSchemasV1.dynamicString,
          'welcomeMessage': CommonSchemasV1.dynamicString,
          'placeholder': CommonSchemasV1.dynamicString,
        },
      ),
      builder: (context, node, props, buildChild) {
        return _InteractiveMiniChatCard(
          title: props.string('title') ?? 'AI Assistant',
          welcomeMessage:
              props.string('welcomeMessage') ??
              'Ask me anything about this mini app.',
          placeholder:
              props.string('placeholder') ?? 'Message AI assistant...',
          onMiniChat: onMiniChat,
          onTelemetry: onTelemetry,
        );
      },
    );
  }

  static ComponentImplementation _localNotificationCard({
    A2uiNotificationCallback? onNotify,
    A2uiTelemetryCallback? onTelemetry,
  }) {
    return ComponentImplementation(
      name: 'LocalNotificationCard',
      schema: Schema.object(
        properties: {
          'title': CommonSchemasV1.dynamicString,
          'subtitle': CommonSchemasV1.dynamicString,
          'channelId': CommonSchemasV1.dynamicString,
          'enabled': CommonSchemasV1.dynamicBoolean,
        },
      ),
      builder: (context, node, props, buildChild) {
        return _InteractiveNotificationCard(
          title: props.string('title') ?? 'Local Notifications',
          subtitle:
              props.string('subtitle') ??
              'Daily 9:00 AM reminders & due-date alerts',
          channelId: props.string('channelId') ?? 'a2ui_task_reminders',
          initialEnabled: props.boolean('enabled') ?? true,
          onNotify: onNotify,
          onTelemetry: onTelemetry,
        );
      },
    );
  }

  static ComponentImplementation _metricChartCard() {
    return ComponentImplementation(
      name: 'MetricChartCard',
      schema: Schema.object(
        properties: {
          'label': CommonSchemasV1.dynamicString,
          'value': CommonSchemasV1.dynamicString,
          'delta': CommonSchemasV1.dynamicString,
          'points': Schema.list(items: Schema.number()),
        },
      ),
      builder: (context, node, props, buildChild) {
        final c = StudioColors.of(context);
        final rawPoints = props.value('points');
        final points = <double>[];
        if (rawPoints is List) {
          for (final p in rawPoints) {
            if (p is num) points.add(p.toDouble());
          }
        }
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.panelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    props.string('label') ?? 'Metric Overview',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.publicBadgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      props.string('delta') ?? '+4.2%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.publicBadgeFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                props.string('value') ?? '\$1,420.50',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    points: points.isEmpty
                        ? const [28, 35, 31, 46, 42, 58, 54, 72]
                        : points,
                    color: c.success,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static ComponentImplementation _pomodoroTimer({
    A2uiNotificationCallback? onNotify,
    A2uiTelemetryCallback? onTelemetry,
  }) {
    return ComponentImplementation(
      name: 'PomodoroTimer',
      schema: Schema.object(
        properties: {
          'title': CommonSchemasV1.dynamicString,
          'focusMinutes': CommonSchemasV1.dynamicNumber,
        },
      ),
      builder: (context, node, props, buildChild) {
        return _InteractivePomodoroCard(
          title: props.string('title') ?? 'Focus Interval',
          focusMinutes: (props.number('focusMinutes') ?? 25).toInt(),
          onNotify: onNotify,
          onTelemetry: onTelemetry,
        );
      },
    );
  }

  static ComponentImplementation _habitHeatmap({
    A2uiTelemetryCallback? onTelemetry,
  }) {
    return ComponentImplementation(
      name: 'HabitHeatmap',
      schema: Schema.object(
        properties: {
          'title': CommonSchemasV1.dynamicString,
          'streakDays': CommonSchemasV1.dynamicNumber,
        },
      ),
      builder: (context, node, props, buildChild) {
        return _InteractiveHabitHeatmapCard(
          title: props.string('title') ?? 'Daily Habit Streak',
          initialStreak: (props.number('streakDays') ?? 14).toInt(),
          onTelemetry: onTelemetry,
        );
      },
    );
  }
}

class _InteractiveCalendarCard extends StatefulWidget {
  const _InteractiveCalendarCard({
    required this.title,
    required this.highlightDays,
    required this.onDateSelected,
  });

  final String title;
  final Set<int> highlightDays;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_InteractiveCalendarCard> createState() =>
      _InteractiveCalendarCardState();
}

class _InteractiveCalendarCardState extends State<_InteractiveCalendarCard> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;
    final monthLabel = DateFormat.yMMMM().format(_focusedMonth);

    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.calendar_month, size: 16, color: c.cyanAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left, size: 18),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    );
                  });
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right, size: 18),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.15,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox.shrink();
              final day = index - firstWeekday + 1;
              final isSelected = day == _selectedDay;
              final hasEvent = widget.highlightDays.contains(day);
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() => _selectedDay = day);
                  widget.onDateSelected(
                    DateTime(_focusedMonth.year, _focusedMonth.month, day),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? c.primaryAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: hasEvent && !isSelected
                        ? Border.all(
                            color: c.cyanAccent.withValues(alpha: 0.45),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : c.textPrimary,
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white : c.cyanAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TodoItemData {
  _TodoItemData({
    required this.id,
    required this.title,
    required this.dueLabel,
    required this.priority,
    required this.done,
  });

  final String id;
  final String title;
  final String dueLabel;
  final String priority;
  bool done;
}

class _InteractiveTodoBoard extends StatefulWidget {
  const _InteractiveTodoBoard({
    required this.title,
    required this.reorderable,
    required this.initialItems,
    this.onNotify,
    this.onTelemetry,
  });

  final String title;
  final bool reorderable;
  final List<_TodoItemData> initialItems;
  final A2uiNotificationCallback? onNotify;
  final A2uiTelemetryCallback? onTelemetry;

  @override
  State<_InteractiveTodoBoard> createState() => _InteractiveTodoBoardState();
}

class _InteractiveTodoBoardState extends State<_InteractiveTodoBoard> {
  late List<_TodoItemData> _items;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initialItems);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.insert(
        0,
        _TodoItemData(
          id: 't_${DateTime.now().millisecondsSinceEpoch}',
          title: text,
          dueLabel: 'Today • Reminder set',
          priority: 'Medium',
          done: false,
        ),
      );
      _controller.clear();
    });
    widget.onTelemetry?.call('[TodoBoard] Added task "$text".');
    widget.onNotify?.call(
      title: 'Task Reminder Scheduled',
      body: '"$text" added to calendar & notification queue.',
      scheduled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final completed = _items.where((t) => t.done).length;

    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.check_circle_outline, size: 16, color: c.primaryAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${widget.title} (${_items.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '$completed/${_items.length} done',
                style: TextStyle(
                  fontSize: 11.5,
                  color: c.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _addTask(),
                  decoration: const InputDecoration(
                    hintText: 'Add a to-do task...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addTask,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                ),
                child: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No tasks yet. Add your first task above.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ),
            )
          else if (widget.reorderable)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _items.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
                widget.onTelemetry?.call('[TodoBoard] Reordered task list.');
              },
              itemBuilder: (context, index) =>
                  _buildTaskTile(context, _items[index], index, c),
            )
          else
            Column(
              children: [
                for (var i = 0; i < _items.length; i++)
                  _buildTaskTile(context, _items[i], i, c),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    _TodoItemData item,
    int index,
    StudioColors c,
  ) {
    final priorityColor = switch (item.priority.toLowerCase()) {
      'high' => c.danger,
      'low' => c.success,
      _ => c.warning,
    };

    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.elevatedBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        children: [
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No tasks yet. Add your first task above.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ),
            )
          else if (widget.reorderable)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: c.textMuted,
                ),
              ),
            ),
          Checkbox(
            value: item.done,
            visualDensity: VisualDensity.compact,
            onChanged: (val) {
              setState(() => item.done = val ?? false);
              widget.onTelemetry?.call(
                '[TodoBoard] "${item.title}" -> ${item.done ? "completed" : "pending"}.',
              );
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: item.done ? TextDecoration.lineThrough : null,
                    color: item.done ? c.textMuted : c.textPrimary,
                  ),
                ),
                Text(
                  item.dueLabel,
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.priority,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: priorityColor,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 15, color: c.textMuted),
            onPressed: () {
              setState(() => _items.removeAt(index));
            },
          ),
        ],
      ),
    );
  }
}

class _InteractiveMiniChatCard extends StatefulWidget {
  const _InteractiveMiniChatCard({
    required this.title,
    required this.welcomeMessage,
    required this.placeholder,
    this.onMiniChat,
    this.onTelemetry,
  });

  final String title;
  final String welcomeMessage;
  final String placeholder;
  final A2uiMiniChatCallback? onMiniChat;
  final A2uiTelemetryCallback? onTelemetry;

  @override
  State<_InteractiveMiniChatCard> createState() =>
      _InteractiveMiniChatCardState();
}

class _InteractiveMiniChatCardState extends State<_InteractiveMiniChatCard> {
  final _controller = TextEditingController();
  late final List<(bool isUser, String text)> _messages;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages = [(false, widget.welcomeMessage)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() {
      _messages.add((true, text));
      _controller.clear();
      _isSending = true;
    });
    widget.onTelemetry?.call('[MiniChatPanel] Sent live prompt: "$text"');

    try {
      final callback = widget.onMiniChat;
      final reply = callback != null
          ? await callback(text, widget.title)
          : 'Connect your Gemini API key in Settings to enable live AI chat replies.';
      if (mounted) {
        setState(() => _messages.add((false, reply)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add((false, 'Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.auto_awesome, size: 16, color: c.cyanAccent),
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (isUser, msg) in _messages.take(6))
            Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: isUser ? c.primaryAccent : c.elevatedBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  msg,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isUser ? Colors.white : c.textPrimary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InteractiveNotificationCard extends StatefulWidget {
  const _InteractiveNotificationCard({
    required this.title,
    required this.subtitle,
    required this.channelId,
    required this.initialEnabled,
    this.onNotify,
    this.onTelemetry,
  });

  final String title;
  final String subtitle;
  final String channelId;
  final bool initialEnabled;
  final A2uiNotificationCallback? onNotify;
  final A2uiTelemetryCallback? onTelemetry;

  @override
  State<_InteractiveNotificationCard> createState() =>
      _InteractiveNotificationCardState();
}

class _InteractiveNotificationCardState
    extends State<_InteractiveNotificationCard> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _enabled
              ? c.cyanAccent.withValues(alpha: 0.45)
              : c.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: c.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: (v) {
                  setState(() => _enabled = v);
                  widget.onTelemetry?.call(
                    '[LocalNotifications] Channel "${widget.channelId}" ${v ? "enabled" : "muted"}.',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _enabled
                    ? () {
                        widget.onNotify?.call(
                          title: widget.title,
                          body:
                              'Reminder fired from channel ${widget.channelId}.',
                          scheduled: false,
                        );
                      }
                    : null,
                icon: const Icon(Icons.bolt, size: 15),
                label: const Text('Test Alert Now'),
              ),
              OutlinedButton.icon(
                onPressed: _enabled
                    ? () {
                        widget.onNotify?.call(
                          title: 'Scheduled: ${widget.title}',
                          body:
                              'Your 4-second scheduled local reminder arrived!',
                          scheduled: true,
                        );
                      }
                    : null,
                icon: const Icon(Icons.schedule, size: 15),
                label: const Text('Schedule (4s)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InteractivePomodoroCard extends StatefulWidget {
  const _InteractivePomodoroCard({
    required this.title,
    required this.focusMinutes,
    this.onNotify,
    this.onTelemetry,
  });

  final String title;
  final int focusMinutes;
  final A2uiNotificationCallback? onNotify;
  final A2uiTelemetryCallback? onTelemetry;

  @override
  State<_InteractivePomodoroCard> createState() =>
      _InteractivePomodoroCardState();
}

class _InteractivePomodoroCardState extends State<_InteractivePomodoroCard> {
  late int _secondsRemaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.focusMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsRemaining <= 1) {
          t.cancel();
          setState(() {
            _running = false;
            _secondsRemaining = 0;
          });
          widget.onNotify?.call(
            title: '${widget.title} Complete!',
            body: 'Time for a 5-minute break.',
            scheduled: false,
          );
        } else {
          setState(() => _secondsRemaining -= 1);
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _secondsRemaining = widget.focusMinutes * 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final mins = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            '$mins:$secs',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _toggle,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow, size: 18),
                label: Text(_running ? 'Pause' : 'Start Focus'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InteractiveHabitHeatmapCard extends StatefulWidget {
  const _InteractiveHabitHeatmapCard({
    required this.title,
    required this.initialStreak,
    this.onTelemetry,
  });

  final String title;
  final int initialStreak;
  final A2uiTelemetryCallback? onTelemetry;

  @override
  State<_InteractiveHabitHeatmapCard> createState() =>
      _InteractiveHabitHeatmapCardState();
}

class _InteractiveHabitHeatmapCardState
    extends State<_InteractiveHabitHeatmapCard> {
  late List<bool> _days;

  @override
  void initState() {
    super.initState();
    _days = List.generate(21, (i) => i != 4 && i != 11 && i < 20);
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final activeCount = _days.where((d) => d).length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Streak: $activeCount Days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _days.length; i++)
                InkWell(
                  onTap: () {
                    setState(() => _days[i] = !_days[i]);
                    widget.onTelemetry?.call(
                      '[HabitHeatmap] Toggled day ${i + 1}.',
                    );
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _days[i]
                          ? (i % 3 == 0 ? c.cyanAccent : c.primaryAccent)
                          : c.elevatedBg,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: c.borderSubtle),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs() < 0.001 ? 1.0 : maxVal - minVal;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - ((points[i] - minVal) / range) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
