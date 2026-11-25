import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../data/app_services.dart';
import '../../data/models/adhkar.dart';
import '../../data/worship/adhkar_practice.dart';
import '../../data/worship/timezone_bootstrap.dart';
import '../../l10n/app_localizations.dart';

class AdhkarCategoryPage extends StatefulWidget {
  const AdhkarCategoryPage({
    super.key,
    required this.category,
    this.clock,
    this.onGoHome,
  });

  final AdhkarCategory category;

  /// Test seam; defaults to [DateTime.now].
  final DateTime Function()? clock;
  final VoidCallback? onGoHome;

  @override
  State<AdhkarCategoryPage> createState() => _AdhkarCategoryPageState();
}

class _AdhkarCategoryPageState extends State<AdhkarCategoryPage> {
  late final AppServices _services = AppServices.current;
  final PageController _pages = PageController();
  Timer? _dateTimer;
  Timer? _advance;
  AppLifecycleListener? _lifecycle;
  List<AdhkarItem> _items = const [];
  Map<String, int> _counts = {};
  int _index = 0;
  bool _loading = true;
  bool _failed = false;
  bool _completionShown = false;
  late String _date = _todayKey();
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _services.prayerSettings.addListener(_checkDate);
    _load();
    _dateTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkDate(),
    );
    _lifecycle = AppLifecycleListener(onResume: _checkDate);
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    _advance?.cancel();
    _lifecycle?.dispose();
    _services.prayerSettings.removeListener(_checkDate);
    _pages.dispose();
    super.dispose();
  }

  String _todayKey() => dateKeyInTimezone(
    _services.prayerSettings.value.timezone,
    now: widget.clock?.call(),
  );

  void _checkDate() {
    if (!mounted || _todayKey() == _date) return;
    _load();
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    final today = _todayKey();
    _cancelAdvance();
    try {
      final items = await _services.adhkar.itemsFor(widget.category.id);
      final counts = await _services.adhkarPractice.completedCounts(
        items,
        today,
      );
      var index = items.indexWhere(
        (item) => (counts[item.id] ?? 0) < item.repeatCount,
      );
      if (index < 0) index = 0;
      if (!mounted || token != _loadToken) return;
      final dayChanged = today != _date;
      setState(() {
        _items = items;
        _counts = counts;
        _index = index;
        _date = today;
        _loading = false;
        _failed = false;
        if (dayChanged) _completionShown = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pages.hasClients || _pages.page == index) return;
        _pages.jumpToPage(index);
      });
    } catch (_) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _load();
  }

  int _count(AdhkarItem item) => _counts[item.id] ?? 0;

  int get _completedItems =>
      _items.where((item) => _count(item) >= item.repeatCount).length;

  Future<void> _tap(AdhkarItem item) async {
    if (_count(item) >= item.repeatCount) return;
    _cancelAdvance();

    final today = _todayKey();
    if (today != _date) {
      await _load();
      if (!mounted || today != _date) return;
      if (_count(item) >= item.repeatCount) return;
    }

    _haptic(HapticFeedback.selectionClick);
    final AdhkarTapResult result;
    try {
      result = await _services.adhkarPractice.increment(
        widget.category,
        item,
        _date,
      );
    } catch (_) {
      if (mounted) _showActionError();
      return;
    }
    if (!mounted) return;
    setState(() {
      _counts[item.id] = (_count(item) + 1).clamp(0, item.repeatCount);
    });

    if (!result.itemCompleted) return;
    _haptic(HapticFeedback.mediumImpact);
    if (!mounted) return;
    if (result.categoryCompleted) {
      _showCompletion();
      return;
    }

    final completedIndex = _index;
    _advance = Timer(const Duration(milliseconds: 350), () {
      _advance = null;
      if (!mounted || _index != completedIndex) return;
      final next = _nextUnfinished(completedIndex);
      if (next == null || !_pages.hasClients) return;
      _pages.animateToPage(
        next,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  int? _nextUnfinished(int from) {
    for (var offset = 1; offset <= _items.length; offset++) {
      final index = (from + offset) % _items.length;
      final item = _items[index];
      if (_count(item) < item.repeatCount) return index;
    }
    return null;
  }

  void _cancelAdvance() {
    _advance?.cancel();
    _advance = null;
  }

  void _haptic(Future<void> Function() action) {
    unawaited(action().catchError((_) {}));
  }

  void _showActionError() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.adhkarActionError)));
  }

  void _showCompletion() {
    if (_completionShown) return;
    _completionShown = true;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adhkarCompletedTitle),
        content: Text(
          widget.category.hasStreak
              ? l10n.adhkarCompletedBody
              : l10n.adhkarCompletedBodyGeneric,
        ),
        actions: [
          if (widget.onGoHome != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final navigator = Navigator.of(this.context);
                if (navigator.canPop()) navigator.pop();
                widget.onGoHome!();
              },
              child: Text(l10n.adhkarGoHome),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.adhkarClose),
          ),
        ],
      ),
    );
  }

  Future<void> _resetItem(AdhkarItem item) async {
    _cancelAdvance();
    try {
      await _services.adhkarPractice.resetItem(widget.category, item, _date);
    } catch (_) {
      if (mounted) _showActionError();
      return;
    }
    if (!mounted) return;
    setState(() {
      _counts[item.id] = 0;
      _completionShown = false;
    });
  }

  Future<void> _resetCategory() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adhkarResetCategory),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.adhkarResetCategory),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _cancelAdvance();
    try {
      await _services.adhkarPractice.resetCategory(widget.category, _date);
    } catch (_) {
      if (mounted) _showActionError();
      return;
    }
    if (!mounted) return;
    setState(() {
      _counts = {};
      _index = 0;
      _completionShown = false;
    });
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        actions: [
          IconButton(
            tooltip: l10n.adhkarResetCategory,
            onPressed: _resetCategory,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 42,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.adhkarLoadError,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(onPressed: _retry, child: Text(l10n.retry)),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adhkarCategoryProgress(
                          _completedItems,
                          _items.length,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _items.isEmpty
                              ? 0
                              : _completedItems / _items.length,
                          minHeight: 6,
                          backgroundColor: scheme.outline,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _items.length,
                    onPageChanged: (value) {
                      _cancelAdvance();
                      setState(() => _index = value);
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _AdhkarItemPage(
                        item: item,
                        count: _count(item),
                        onTap: () => _tap(item),
                        onReset: () => _resetItem(item),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: l10n.adhkarPrevious,
                          onPressed: _index == 0
                              ? null
                              : () => _pages.previousPage(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                ),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            '${_index + 1} / ${_items.length}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: l10n.adhkarNext,
                          onPressed: _index >= _items.length - 1
                              ? null
                              : () => _pages.nextPage(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                ),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AdhkarItemPage extends StatelessWidget {
  const _AdhkarItemPage({
    required this.item,
    required this.count,
    required this.onTap,
    required this.onReset,
  });

  final AdhkarItem item;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final done = count >= item.repeatCount;
    final remaining = (item.repeatCount - count).clamp(0, item.repeatCount);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Text(
                      item.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.9,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (item.reference.isNotEmpty)
                  Text(
                    item.reference,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.92),
            border: Border(top: BorderSide(color: scheme.outline)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Semantics(
                  button: true,
                  enabled: !done,
                  excludeSemantics: true,
                  label: done ? l10n.adhkarDone : l10n.adhkarTapToCount,
                  value: l10n.adhkarRemaining('$remaining'),
                  child: InkWell(
                    key: ValueKey('adhkar-counter-${item.id}'),
                    onTap: done ? null : onTap,
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? scheme.primary.withValues(alpha: 0.16)
                            : scheme.surface,
                        border: Border.all(
                          color: done ? scheme.primary : scheme.outline,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (done)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 42,
                                    color: scheme.primary,
                                  )
                                else
                                  Text(
                                    '$remaining',
                                    style: TextStyle(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.primary,
                                      height: 1,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  done
                                      ? l10n.adhkarDone
                                      : l10n.adhkarTapToCount,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (done)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: Text(
                    l10n.adhkarResetItem,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
