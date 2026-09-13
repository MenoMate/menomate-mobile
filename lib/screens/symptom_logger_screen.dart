import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/sync_policy.dart';
import '../core/theme.dart';
import '../models/daily_log.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';
import '../widgets/offline_banner.dart';

class SymptomLoggerScreen extends ConsumerStatefulWidget {
  /// ISO `yyyy-MM-dd` date this logger edits. Defaults to today.
  /// History/calendar passes the selected day so saved logs are
  /// discoverable and editable in place — same record per user+date,
  /// never a duplicate.
  final String? initialDate;

  const SymptomLoggerScreen({super.key, this.initialDate});

  @override
  ConsumerState<SymptomLoggerScreen> createState() => _SymptomLoggerScreenState();
}

class _SymptomLoggerScreenState extends ConsumerState<SymptomLoggerScreen> {
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  DataState<DailyLogResponse?>? _loadState;

  /// Whether a saved log existed when this screen opened. A save that
  /// creates the record resets the form; a save that edits keeps values.
  bool _existedAtOpen = false;
  
  int _pain = 0;
  String? _mood;
  String? _flow;
  
  // Backend Enums
  final List<String> _moodOptions = [
    'happy', 'calm', 'neutral', 'sad', 'irritable', 'anxious', 'tired'
  ];
  
  final List<String> _flowOptions = [
    'light', 'medium', 'heavy', 'spotting'
  ];

  final List<int> _painOptions = List.generate(11, (index) => index);

  late String _dateString;

  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate;
    _dateString = (initial != null && _isoDate.hasMatch(initial))
        ? initial
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadDailyLog();
  }

  Future<void> _loadDailyLog() async {
    final userId = ref.read(currentUserIdProvider);
    DataState<DailyLogResponse?> state =
        const Unavailable('Signed out.');
    if (userId != null) {
      try {
        state = await ref
            .read(dailyLogRepositoryProvider)
            .loadLog(userId, _dateString);
      } catch (_) {
        state = const Unavailable('Couldn\'t load this log.');
      }
    }

    if (!mounted) return;
    final log = state.dataOrNull;
    setState(() {
      _loadState = state;
      _existedAtOpen = log != null;
      if (log != null) {
        _pain = log.pain;
        _mood = log.mood;
        _flow = log.flow;
        _notesController.text = log.notes ?? '';
      }
      _isLoading = false;
    });
  }

  void _resetForm() {
    _pain = 0;
    _mood = null;
    _flow = null;
    _notesController.clear();
  }

  String _prettyDate() {
    try {
      return DateFormat('EEEE, MMMM d').format(DateTime.parse(_dateString));
    } catch (_) {
      return _dateString;
    }
  }

  Future<void> _saveLog() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out. Please sign in again.')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final payload = DailyLogCreate(
      logDate: _dateString,
      pain: _pain,
      mood: _mood,
      flow: _flow,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      symptoms: [],
    );

    // Local-first: the entry is persisted before any network attempt, so
    // an offline save is never lost. Same user+date always updates the
    // same local/server record — never a duplicate.
    final wasCreate = !_existedAtOpen;
    DataState<DailyLogResponse> result;
    try {
      result = await ref
          .read(dailyLogRepositoryProvider)
          .saveLog(userId, payload);
    } catch (_) {
      result = const Unavailable('Couldn\'t save right now.');
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _loadState = result;
      if (wasCreate &&
          (result is Fresh<DailyLogResponse> ||
              result is PendingSync<DailyLogResponse>)) {
        // A fresh create resets the form; the record now exists, so any
        // further save edits it rather than looking like a new entry.
        _resetForm();
        _existedAtOpen = true;
      }
    });

    // Explicit result: where the data went is never ambiguous. The screen
    // stays open so the pending/not-synced state remains visible offline.
    switch (result) {
      case Fresh():
        refreshAllAppData(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily log saved')),
        );
      case PendingSync():
        refreshAllAppData(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved on this device')),
        );
      case ConflictState(message: final m):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved on this device, needs review: $m')),
        );
      case Unavailable(message: final m):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m)),
        );
      case NoData():
      case Cached():
        refreshAllAppData(ref);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Daily Wellness Log',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadState != null) SyncStatusChip(state: _loadState!),
            Text(
              _prettyDate(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _existedAtOpen
                  ? 'Editing your saved log'
                  : 'How are you feeling today?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Mood', context),
            const SizedBox(height: 12),
            _buildBubbleGrid<String>(
              items: _moodOptions,
              selectedValue: _mood,
              onSelected: (val) => setState(() => _mood = val),
              labelBuilder: (val) => val[0].toUpperCase() + val.substring(1),
              activeColor: MenoMateTheme.sakuraInteraction,
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Flow', context),
            const SizedBox(height: 12),
            _buildBubbleGrid<String>(
              items: _flowOptions,
              selectedValue: _flow,
              onSelected: (val) => setState(() => _flow = val),
              labelBuilder: (val) => val[0].toUpperCase() + val.substring(1),
              // Blood logging shares the menstrual rose token.
              activeColor: MenoMateTheme.sakuraPrimaryDark,
            ),

            const SizedBox(height: 32),
            
            _buildSectionTitle('Pain Severity (0-10)', context),
            const SizedBox(height: 12),
            _buildBubbleGrid<int>(
              items: _painOptions,
              selectedValue: _pain,
              onSelected: (val) => setState(() => _pain = val),
              labelBuilder: (val) => val.toString(),
              activeColor: MenoMateTheme.sakuraAmber,
              crossAxisCount: 6,
            ),

            const SizedBox(height: 32),
            
            _buildSectionTitle('Notes', context),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Any other symptoms or thoughts?',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              // Theme elevated style: rose primary action, no custom purple.
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLog,
                child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildBubbleGrid<T>({
    required List<T> items,
    required T? selectedValue,
    required Function(T) onSelected,
    required String Function(T) labelBuilder,
    required Color activeColor,
    int crossAxisCount = 4,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item == selectedValue;
        
        return GestureDetector(
          onTap: () => onSelected(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? activeColor : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: isSelected 
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(70),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
            ),
            child: Center(
              child: Text(
                labelBuilder(item),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: crossAxisCount > 4 ? 14 : 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
