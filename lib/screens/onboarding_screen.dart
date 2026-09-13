import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/onboarding.dart';
import '../core/device_timezone.dart';
import '../services/api_service.dart';
import '../providers/profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _cycleDaysController = TextEditingController();
  final _periodDaysController = TextEditingController();
  
  DateTime? _lastPeriodStart;
  DateTime? _lastPeriodEnd;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _lastPeriodStart = picked;
        } else {
          _lastPeriodEnd = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _lastPeriodStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your name and last period start date.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final request = OnboardingRequest(
        name: name,
        lastPeriodStart: _lastPeriodStart!.toIso8601String().split('T')[0],
        lastPeriodEnd: _lastPeriodEnd?.toIso8601String().split('T')[0],
        usualCycleDays: int.tryParse(_cycleDaysController.text),
        usualPeriodDays: int.tryParse(_periodDaysController.text),
        // Persist the device zone atomically with onboarding so the
        // backend computes user-local dates from the very first request.
        timezone: await deviceTimeZoneId(),
      );

      final updatedProfile = await ref.read(apiServiceProvider).completeOnboarding(request);
      
      if (updatedProfile != null) {
        ref.read(profileProvider.notifier).setProfile(updatedProfile);
      } else {
        await ref.read(profileProvider.notifier).reload();
      }
    } on DioException catch (e) {
      if (mounted) {
        final serverMessage = e.response?.data is Map && e.response?.data['detail'] != null
            ? e.response?.data['detail'].toString()
            : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              serverMessage != null
                  ? 'Error: $serverMessage'
                  : 'Unable to connect to MenoMate. Please check your connection and try again.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to MenoMate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Let\'s personalize your experience.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'What should we call you?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            const Text('When did your last period start?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_lastPeriodStart == null ? 'Select Start Date' : dateFormat.format(_lastPeriodStart!)),
              onPressed: () => _selectDate(context, true),
            ),
            const SizedBox(height: 24),

            const Text('When did it end? (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_lastPeriodEnd == null ? 'Select End Date' : dateFormat.format(_lastPeriodEnd!)),
              onPressed: () => _selectDate(context, false),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cycleDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Usual Cycle (Days)',
                      border: OutlineInputBorder(),
                      helperText: 'e.g. 28',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _periodDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Usual Period (Days)',
                      border: OutlineInputBorder(),
                      helperText: 'e.g. 5',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Complete Onboarding', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
