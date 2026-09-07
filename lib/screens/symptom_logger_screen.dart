import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';
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
  
  // Hardcode supported mood strings as per MoodEnum in backend
  final List<String> _moodOptions = [
    'happy', 'calm', 'neutral', 'sad', 'irritable', 'anxious', 'tired'
  ];

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
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      symptoms: [], // Empty for now, can be expanded to include specific child symptoms
    );

    final result = await apiService.upsertDailyLog(payload);
    
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      
      if (result != null) {
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Daily Wellness Log',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Mood'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _moodOptions.map((mood) {
                return _buildChip(
                  mood[0].toUpperCase() + mood.substring(1),
                  _mood == mood,
                  () => setState(() => _mood = mood),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Pain Severity'),
            const SizedBox(height: 8),
            Slider(
              value: _pain.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: const Color(0xFFA855F7),
              label: '$_pain/10',
              onChanged: (val) {
                setState(() => _pain = val.toInt());
              },
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Notes'),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Any other symptoms or thoughts?',
                filled: true,
                fillColor: Colors.white,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA855F7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFA855F7) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
