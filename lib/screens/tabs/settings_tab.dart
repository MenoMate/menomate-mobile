import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync_policy.dart';
import '../../core/theme.dart';
import '../../models/device.dart';
import '../../models/profile.dart';
import '../../providers/cycle_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _nameController = TextEditingController();
  final _cycleLengthController = TextEditingController();
  final _periodLengthController = TextEditingController();
  final _macController = TextEditingController();

  String _selectedUnits = 'metric';
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isRegisteringDevice = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    _macController.dispose();
    super.dispose();
  }

  void _initFields(Profile? profile) {
    if (profile == null || _isInitialized) return;
    _nameController.text = profile.name ?? '';
    _cycleLengthController.text = profile.usualCycleDays?.toString() ?? '28';
    _periodLengthController.text = profile.usualPeriodDays?.toString() ?? '5';
    _selectedUnits = (profile.units?.toLowerCase() == 'imperial') ? 'imperial' : 'metric';
    _isInitialized = true;
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final cycleStr = _cycleLengthController.text.trim();
    final periodStr = _periodLengthController.text.trim();

    final cycleDays = int.tryParse(cycleStr);
    final periodDays = int.tryParse(periodStr);

    if (cycleDays != null && (cycleDays < 20 || cycleDays > 45)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usual cycle length must be between 20 and 45 days.')),
      );
      return;
    }

    if (periodDays != null && (periodDays < 1 || periodDays > 12)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usual period length must be between 1 and 12 days.')),
      );
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out. Please sign in again.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentThemeMode = ref.read(themeModeProvider);
      final themeStr = currentThemeMode == ThemeMode.dark ? 'dark' : 'light';

      final payload = <String, dynamic>{
        'name': name.isNotEmpty ? name : null,
        'usual_cycle_days': cycleDays,
        'usual_period_days': periodDays,
        'theme': themeStr,
        'units': _selectedUnits,
      };

      // Local-first: applies immediately, syncs when reachable.
      final result = await ref
          .read(profileRepositoryProvider)
          .saveProfile(userId, payload);
      refreshAllAppData(ref);

      if (mounted) {
        final message = switch (result) {
          PendingSync() =>
            'Saved locally. Will sync when you\'re online.',
          ConflictState(message: final m) =>
            'Saved locally, needs review: $m',
          _ => 'Profile preferences saved successfully.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _registerDevice() async {
    final mac = _macController.text.trim();
    if (mac.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a device identifier or MAC address.')),
      );
      return;
    }

    setState(() => _isRegisteringDevice = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.registerDevice(DeviceCreate(deviceIdentifier: mac, name: 'MenoMate Wearable'));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device registered successfully!')),
        );
        _macController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering device: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegisteringDevice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Selection states use the restrained interaction indigo (theme
    // toggle, checked controls) — never menstrual rose.
    final interaction =
        MenoMateTheme.interactionColor(theme.brightness == Brightness.dark);
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);

    profileAsync.whenData((profileState) {
      if (!_isInitialized) {
        _initFields(profileState.dataOrNull);
      }
    });

    return Scaffold(
      // Transparent: the shared ThemeAtmosphereBackground painted by
      // HomeScreen shows through.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
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
              // --- 1. Profile Section ---
              _buildSectionHeader('Profile', colorScheme),
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
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. Cycle & Period Preferences ---
              _buildSectionHeader('Cycle & Period Baseline', colorScheme),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _cycleLengthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Usual Cycle Length (days)',
                        hintText: 'e.g. 28',
                        prefixIcon: Icon(Icons.repeat_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _periodLengthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Usual Period Length (days)',
                        hintText: 'e.g. 5',
                        prefixIcon: Icon(Icons.water_drop_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 3. Appearance ---
              _buildSectionHeader('Appearance', colorScheme),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (themeMode != ThemeMode.light) {
                            ref.read(themeModeProvider.notifier).toggleTheme(false);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: themeMode == ThemeMode.light
                                ? interaction.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.light_mode_outlined,
                                size: 18,
                                color: themeMode == ThemeMode.light
                                    ? interaction
                                    : colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Light',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: themeMode == ThemeMode.light ? FontWeight.bold : FontWeight.normal,
                                  color: themeMode == ThemeMode.light
                                      ? interaction
                                      : colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (themeMode != ThemeMode.dark) {
                            ref.read(themeModeProvider.notifier).toggleTheme(true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: themeMode == ThemeMode.dark
                                ? interaction.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dark_mode_outlined,
                                size: 18,
                                color: themeMode == ThemeMode.dark
                                    ? interaction
                                    : colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Dark',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: themeMode == ThemeMode.dark ? FontWeight.bold : FontWeight.normal,
                                  color: themeMode == ThemeMode.dark
                                      ? interaction
                                      : colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 4. Units Preference ---
              _buildSectionHeader('Units', colorScheme),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Measurement Units', style: TextStyle(fontWeight: FontWeight.w500)),
                    DropdownButton<String>(
                      value: _selectedUnits,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'metric', child: Text('Metric (°C)')),
                        DropdownMenuItem(value: 'imperial', child: Text('Imperial (°F)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnits = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save Preferences Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Profile Preferences'),
                ),
              ),
              const SizedBox(height: 28),

              // --- 5. Wearable Device Section ---
              _buildSectionHeader('MenoMate Wearable', colorScheme),
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
                    const Text(
                      'Pair Wearable Hardware',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your MenoMate device identifier or BLE MAC address to register your hardware link.',
                      style: TextStyle(fontSize: 12, color: colorScheme.secondary, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _macController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 00:1A:2B:3C:4D:5E',
                        prefixIcon: Icon(Icons.bluetooth),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isRegisteringDevice ? null : _registerDevice,
                        child: _isRegisteringDevice
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Register Device'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // --- 6. Account & Sign Out ---
              _buildSectionHeader('Account', colorScheme),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                // Own Material so the ListTile ink splash paints visibly
                // instead of hiding behind the decorated container.
                child: Material(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                  onTap: () async {
                    // Wipes local rows + cached prediction so the next user
                    // on this device never sees this account's data.
                    await signOutAndClearLocalData(ref);
                  },
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
