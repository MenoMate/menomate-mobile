import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';
import '../providers/cycle_provider.dart';
import '../services/api_service.dart';

class SymptomLoggerScreen extends ConsumerStatefulWidget {
  const SymptomLoggerScreen({super.key});

  @override
  ConsumerState<SymptomLoggerScreen> createState() => _SymptomLoggerScreenState();
}

class _SymptomLoggerScreenState extends ConsumerState<SymptomLoggerScreen> {
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  
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

  late String _todayDateString;

  @override
  void initState() {
    super.initState();
    _todayDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadDailyLog();
  }

  Future<void> _loadDailyLog() async {
    final apiService = ref.read(apiServiceProvider);
    final log = await apiService.getDailyLog(_todayDateString);
    
    if (log != null && mounted) {
      setState(() {
        _pain = log.pain;
        _mood = log.mood;
        _flow = log.flow;
        _notesController.text = log.notes ?? '';
      });
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLog() async {
    setState(() {
      _isSaving = true;
    });

    final apiService = ref.read(apiServiceProvider);
    
    final payload = DailyLogCreate(
      logDate: _todayDateString,
      pain: _pain,
      mood: _mood,
      flow: _flow,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      symptoms: [], 
    );

    final result = await apiService.upsertDailyLog(payload);
    
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      
      if (result != null) {
        refreshAllAppData(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wellness log saved!')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save log. Please try again.')),
        );
      }
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
            Text(
              'How are you feeling today?',
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
              activeColor: Colors.blueAccent,
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Flow', context),
            const SizedBox(height: 12),
            _buildBubbleGrid<String>(
              items: _flowOptions,
              selectedValue: _flow,
              onSelected: (val) => setState(() => _flow = val),
              labelBuilder: (val) => val[0].toUpperCase() + val.substring(1),
              activeColor: Colors.redAccent,
            ),

            const SizedBox(height: 32),
            
            _buildSectionTitle('Pain Severity (0-10)', context),
            const SizedBox(height: 12),
            _buildBubbleGrid<int>(
              items: _painOptions,
              selectedValue: _pain,
              onSelected: (val) => setState(() => _pain = val),
              labelBuilder: (val) => val.toString(),
              activeColor: Colors.orangeAccent,
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
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA855F7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
