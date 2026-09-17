import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/format.dart' show kMonthNames;
import '../data/sync_policy.dart';
import '../models/health_context.dart' show validateBirthPair;
import '../models/profile.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/profile_provider.dart';
import 'health_intro_screen.dart';

/// Opens Health & Context, showing the one-time intro first unless the
/// user already dismissed it. Shared by the Settings tile and the Profile
/// health card so the first-encounter explanation is never skipped by
/// taking a different path.
Future<void> openHealthContext(BuildContext context, WidgetRef ref) async {
  final userId = ref.read(currentUserIdProvider);
  var dismissed = true;
  if (userId != null) {
    try {
      dismissed = await ref
          .read(offlineModeProvider.notifier)
          .isFeatureDismissed(kHealthIntroFeature, userId);
    } catch (_) {
      dismissed = true;
    }
  }
  if (!context.mounted) return;
  if (dismissed) {
    context.push('/profile/health');
  } else {
    context.push('/health-intro');
  }
}

/// Profile hub: personal information (name, birth month/year) plus the
/// entry point to Health & Context. Everything is optional; nothing here
/// gates tracking. Units live in Settings (single home, not duplicated).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _birthYearController = TextEditingController();

  int? _birthMonth;
  bool _isInitialized = false;
  bool _isSaving = false;
  String? _dobError;

  @override
  void dispose() {
    _nameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  void _initFields(Profile? profile) {
    if (profile == null || _isInitialized) return;
    _nameController.text = profile.name ?? '';
    _birthMonth = profile.birthMonth;
    _birthYearController.text = profile.birthYear?.toString() ?? '';
    _isInitialized = true;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final yearRaw = _birthYearController.text.trim();
    final int? year = yearRaw.isEmpty ? null : int.tryParse(yearRaw);
    if (yearRaw.isNotEmpty && year == null) {
      setState(() => _dobError = 'Please enter a 4-digit birth year.');
      return;
    }
    final dobError = validateBirthPair(year, _birthMonth);
    if (dobError != null) {
      setState(() => _dobError = dobError);
      return;
    }
    setState(() {
      _dobError = null;
      _isSaving = true;
    });

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign in or continue offline to save.'),
            ),
          );
        }
        return;
      }
      // Explicit birth keys (possibly null): the backend pair contract
      // treats both-or-neither atomically, and the local merge preserves
      // explicit nulls end-to-end like every other profile field.
      final result = await ref.read(profileRepositoryProvider).saveProfile(
        userId,
        {
          'name': name.isNotEmpty ? name : null,
          'birth_year': year,
          'birth_month': _birthMonth,
        },
        localOnly: ref.read(isOfflineTrackingProvider),
      );
      refreshAllAppData(ref);
      if (mounted) {
        final message = switch (result) {
          PendingSync() => 'Saved locally. Will sync when you\'re online.',
          ConflictState(message: final m) => 'Saved locally, needs review: $m',
          _ => 'Profile saved successfully.',
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(profileProvider);

    profileAsync.whenData((profileState) {
      if (!_isInitialized) {
        _initFields(profileState.dataOrNull);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _buildSectionHeader('Personal information', colorScheme),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Birth month',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              DropdownButton<int?>(
                                value: _birthMonth,
                                isExpanded: true,
                                underline: const SizedBox.shrink(),
                                hint: const Text('—'),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('—'),
                                  ),
                                  for (var i = 0; i < 12; i++)
                                    DropdownMenuItem<int?>(
                                      value: i + 1,
                                      child: Text(kMonthNames[i]),
                                    ),
                                ],
                                onChanged: (val) => setState(() {
                                  _birthMonth = val;
                                  _dobError = null;
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _birthYearController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 4,
                            buildCounter: (
                              context, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                            decoration: const InputDecoration(
                              labelText: 'Birth year',
                              hintText: 'e.g. 1990',
                              counterText: '',
                            ),
                            onChanged: (_) {
                              if (_dobError != null) {
                                setState(() => _dobError = null);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Month and year only — MenoMate never asks for your exact birth day.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                        height: 1.35,
                      ),
                    ),
                    if (_dobError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _dobError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('Health & Context', colorScheme),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Material(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    leading: Icon(
                      Icons.favorite_outline,
                      color: colorScheme.primary,
                    ),
                    title: const Text(
                      'Health & Context',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Optional: conditions, medications, contraception & more',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.secondary,
                    ),
                    onTap: () => openHealthContext(context, ref),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
