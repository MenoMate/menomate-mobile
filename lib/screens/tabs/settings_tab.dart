import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart' show OfflineAdoptionCounts;
import '../../data/sync_policy.dart';
import '../../core/theme.dart';
import '../../models/device.dart';
import '../../models/profile.dart';
import '../../providers/cycle_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/logo_variant_provider.dart';
import '../../providers/offline_mode_provider.dart';
import '../../widgets/menomate_logo.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _cycleLengthController = TextEditingController();
  final _periodLengthController = TextEditingController();
  final _macController = TextEditingController();

  String _selectedUnits = 'metric';
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isRegisteringDevice = false;
  bool _isAdopting = false;

  @override
  void dispose() {
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    _macController.dispose();
    super.dispose();
  }

  void _initFields(Profile? profile) {
    if (profile == null || _isInitialized) return;
    // No fake defaults: an unset length stays empty (null), never 28/5.
    // (Name is edited in Profile, not here.)
    _cycleLengthController.text = profile.usualCycleDays?.toString() ?? '';
    _periodLengthController.text = profile.usualPeriodDays?.toString() ?? '';
    _selectedUnits = (profile.units?.toLowerCase() == 'imperial')
        ? 'imperial'
        : 'metric';
    _isInitialized = true;
  }

  Future<void> _saveProfile() async {
    final cycleStr = _cycleLengthController.text.trim();
    final periodStr = _periodLengthController.text.trim();

    final cycleDays = int.tryParse(cycleStr);
    final periodDays = int.tryParse(periodStr);

    if (cycleDays != null && (cycleDays < 20 || cycleDays > 45)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usual cycle length must be between 20 and 45 days.'),
        ),
      );
      return;
    }

    if (periodDays != null && (periodDays < 1 || periodDays > 12)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usual period length must be between 1 and 12 days.'),
        ),
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
        'usual_cycle_days': cycleDays,
        'usual_period_days': periodDays,
        'theme': themeStr,
        'units': _selectedUnits,
      };

      // Local-first: applies immediately, syncs when reachable.
      // Local-only tracking never attempts the remote patch.
      final result = await ref
          .read(profileRepositoryProvider)
          .saveProfile(
            userId,
            payload,
            localOnly: ref.read(isOfflineTrackingProvider),
          );
      refreshAllAppData(ref);

      if (mounted) {
        final message = switch (result) {
          PendingSync() => 'Saved locally. Will sync when you\'re online.',
          ConflictState(message: final m) => 'Saved locally, needs review: $m',
          _ => 'Profile preferences saved successfully.',
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving preferences: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _adoptOfflineData() async {
    if (_isAdopting) return;
    setState(() => _isAdopting = true);
    try {
      final counts = await adoptOfflineDataIntoAccount(ref);
      if (!mounted) return;
      final parts = _adoptionParts(counts);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your offline data (${parts.join(' · ')}) is now part of '
            'this account.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn\'t move your offline data right now.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdopting = false);
    }
  }

  Future<void> _dismissAdoption() async {
    final authId = ref.read(authUserIdProvider);
    if (authId != null) {
      await ref.read(offlineModeProvider.notifier).declineAdoption(authId);
    }
    ref.invalidate(offlineAdoptionProvider);
  }

  Future<void> _registerDevice() async {
    // Device registration is account-bound: gate it instead of failing
    // with a raw network/auth error.
    if (ref.read(isOfflineTrackingProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You\'re using MenoMate offline. '
            'Sign in to register a wearable device.',
          ),
        ),
      );
      return;
    }
    final mac = _macController.text.trim();
    if (mac.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a device identifier or MAC address.'),
        ),
      );
      return;
    }

    setState(() => _isRegisteringDevice = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.registerDevice(
        DeviceCreate(deviceIdentifier: mac, name: 'MenoMate Wearable'),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device registered successfully!')),
        );
        _macController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error registering device: $e')));
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
    final interaction = MenoMateTheme.interactionColor(
      theme.brightness == Brightness.dark,
    );
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final offline = ref.watch(isOfflineTrackingProvider);
    final adoption = ref.watch(offlineAdoptionProvider).value;
    // Identity summary for the Account card. Name editing lives only in
    // Profile; Settings shows (never duplicates) the stored value.
    final accountName = profileAsync.value?.dataOrNull?.name?.trim();
    final accountInitial = (accountName != null && accountName.isNotEmpty)
        ? accountName[0].toUpperCase()
        : null;

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
        // Root tab: never show a back arrow here.
        automaticallyImplyLeading: false,
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
              // --- 0. Account: identity first, then account actions. ---
              // Name editing lives only in Profile now; this card links
              // there instead of duplicating the field.
              _buildSectionHeader('PROFILE · Account', colorScheme),
              if (offline) ...[
                // Local-only user: status + privacy note + sign-in path.
                // There is no account to sign out of and nothing is broken.
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
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 20,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Using MenoMate offline',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your tracking data is stored only on this device. '
                        'Sign in later to sync it across devices.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('Sign In / Create Account'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Signed-in identity at a glance; details live in Profile.
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Material(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: colorScheme.primaryContainer,
                        child: accountInitial != null
                            ? Text(
                                accountInitial,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : Icon(
                                Icons.person_outline,
                                color: colorScheme.onPrimaryContainer,
                              ),
                      ),
                      title: Text(
                        (accountName != null && accountName.isNotEmpty)
                            ? accountName
                            : 'MenoMate User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Signed in — syncing across devices',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: colorScheme.secondary,
                      ),
                      onTap: () => context.push('/profile'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Consented move of offline-created rows into this account.
                // Shown only while adoptable rows exist and were not
                // dismissed. Never automatic, never silent.
                if (adoption != null) ...[
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
                        Text(
                          'Offline data on this device',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _adoptionDescription(adoption),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.secondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isAdopting ? null : _adoptOfflineData,
                            child: _isAdopting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sync to this account'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _isAdopting ? null : _dismissAdoption,
                            child: const Text('Dismiss'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.redAccent,
                      ),
                      onTap: () async {
                        // Guard against silently discarding offline work: if any
                        // local row is still pending sync (or needs review),
                        // confirm explicitly. "Stay signed in" is the safe path;
                        // the existing wipe still runs on explicit confirmation.
                        bool unsynced = false;
                        try {
                          unsynced = await ref
                              .read(appDatabaseProvider)
                              .hasUnsyncedData();
                        } catch (_) {
                          unsynced = false;
                        }
                        if (!context.mounted) return;
                        if (unsynced) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'Unsynced changes on this device',
                              ),
                              content: const Text(
                                'Some of your recent changes have not synced '
                                'yet. Logging out now may discard them. '
                                'Reconnect and let the app sync first, or stay '
                                'signed in.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Stay signed in'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Log out anyway'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                        }
                        // Wipes local rows + cached prediction so the next user
                        // on this device never sees this account's data.
                        await signOutAndClearLocalData(ref);
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // --- 1. Profile & Health hub ---
              // Personal info, conditions, medications and other optional
              // context live on dedicated screens; Settings keeps only its
              // existing quick preferences.
              _buildSectionHeader('PROFILE · Profile & Health', colorScheme),
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
                      Icons.person_outline,
                      color: colorScheme.primary,
                    ),
                    title: const Text(
                      'Profile & Health',
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
                    // Profile hub; its Health & Context card gates the
                    // one-time intro via openHealthContext.
                    onTap: () => context.push('/profile'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                      Icons.calendar_month_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text(
                      'History & Calendar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Past cycles, logged days and predictions',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.secondary,
                    ),
                    // Detail route (not a tab): back returns here.
                    onTap: () => context.push('/calendar'),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. Cycle & Period Preferences ---
              _buildSectionHeader('PROFILE · Cycle baseline', colorScheme),
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
                        helperText: 'Leave blank if you\u2019re not sure.',
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
                        helperText: 'Leave blank if you\u2019re not sure.',
                        prefixIcon: Icon(Icons.water_drop_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 3. Appearance ---
              _buildSectionHeader('APP · Appearance', colorScheme),
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
                            ref
                                .read(themeModeProvider.notifier)
                                .toggleTheme(false);
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
                                  fontWeight: themeMode == ThemeMode.light
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
                            ref
                                .read(themeModeProvider.notifier)
                                .toggleTheme(true);
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
                                  fontWeight: themeMode == ThemeMode.dark
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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

              // --- 3b. App icon (launcher): the requested logo selection
              // concerns the APPLICATION/LAUNCHER ICON — not the Home
              // greeting logo beside "Hello, [name]", which stays fixed
              // brand identity (standard circle). The choice below previews
              // launcher variants; true OS launcher switching requires
              // native config — see docs/launcher_icon.md. It never
              // changes the Home header.
              _buildSectionHeader('APP · App icon (launcher)', colorScheme),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Previews the launcher icon style. The Home greeting logo stays the classic MenoMate mark. Applying a launcher icon needs a native rebuild (see docs).',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    for (final variant in AppLogoVariant.values)
                      _LogoOptionTile(variant: variant),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 4. Units Preference ---
              _buildSectionHeader('APP · Preferences', colorScheme),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Measurement Units',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    DropdownButton<String>(
                      value: _selectedUnits,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'metric',
                          child: Text('Metric (°C)'),
                        ),
                        DropdownMenuItem(
                          value: 'imperial',
                          child: Text('Imperial (°F)'),
                        ),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Profile Preferences'),
                ),
              ),
              const SizedBox(height: 28),

              // --- 5. Wearable Device Section ---
              _buildSectionHeader('APP · MenoMate Wearable', colorScheme),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your MenoMate device identifier or BLE MAC address to register your hardware link.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                        height: 1.3,
                      ),
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
                        onPressed: _isRegisteringDevice
                            ? null
                            : _registerDevice,
                        child: _isRegisteringDevice
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Register Device'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 6. Privacy & Data ---
              _buildSectionHeader(
                'DATA & PRIVACY · Privacy & Data',
                colorScheme,
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      offline
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        offline
                            ? 'Offline tracking — your data stays on this device until you sign in and choose to sync it.'
                            : 'Signed in — your data syncs to your account across devices.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.secondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 7. Help & support ---
              _buildSectionHeader('HELP · Help & support', colorScheme),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                // Own Material (not just a colored box): ExpansionTile
                // paints its ink on the nearest Material, so a bare
                // DecoratedBox would hide it and trip the debug assertion.
                child: Material(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: const Column(
                    children: [
                      _HelpEntry(
                        title: 'How does syncing work?',
                        body:
                            'When signed in, MenoMate saves each entry on this '
                            'device first, then sends it to your account. If the '
                            'connection drops, entries wait safely and sync '
                            'later — nothing is lost.',
                      ),
                      _HelpEntry(
                        title: 'What does offline tracking mean?',
                        body:
                            'You can track periods, symptoms, and wellness '
                            'without an account. Everything stays on this '
                            'device. Sign in later to move it into an account — '
                            'only ever with your explicit choice.',
                      ),
                      _HelpEntry(
                        title: 'Are predictions certain?',
                        body:
                            'No. Dates and phases are estimates based on your '
                            'logged history and can vary from cycle to cycle. '
                            'Treat them as context, not a diagnosis — and talk '
                            'to a clinician you trust if something feels off.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 8. About MenoMate ---
              _buildSectionHeader('HELP · About MenoMate', colorScheme),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  children: [
                    const Center(child: MenoMateBrandLogo(size: 56)),
                    const SizedBox(height: 12),
                    Text(
                      'Understand your cycle. Support your you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.secondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the "N periods · M daily logs ..." fragments shared by the
  /// offer card and the post-adoption confirmation.
  List<String> _adoptionParts(OfflineAdoptionCounts counts) {
    return <String>[
      if (counts.cycles > 0)
        '${counts.cycles} ${counts.cycles == 1 ? 'period' : 'periods'}',
      if (counts.logs > 0)
        '${counts.logs} ${counts.logs == 1 ? 'daily log' : 'daily logs'}',
      if (counts.conditions > 0)
        '${counts.conditions} '
            '${counts.conditions == 1 ? 'condition' : 'conditions'}',
      if (counts.medications > 0)
        '${counts.medications} '
            '${counts.medications == 1 ? 'medication' : 'medications'}',
      if (counts.healthContext) 'health details',
    ];
  }

  /// Words the adoption offer from reliable in-transaction counts.
  /// Display preferences are intentionally not moved: the account profile
  /// stays authoritative, which the copy below discloses.
  String _adoptionDescription(OfflineAdoptionCounts counts) {
    return 'You have ${_adoptionParts(counts).join(' and ')} on this '
        'device from offline use. Move them into this account? Your '
        'offline display preferences will reset to this account\u2019s '
        'settings.';
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

/// One logo choice: live preview of the actual mark, name, short
/// description, and a radio for selection state. The whole tile taps
/// (min 48dp target) with an accessible label — selected state never
/// rests on color alone.
class _LogoOptionTile extends ConsumerWidget {
  final AppLogoVariant variant;

  const _LogoOptionTile({required this.variant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(logoVariantProvider.notifier).setVariant(variant),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Natural width: the compact presentation carries a wordmark
              // beside its mark and must never be squeezed into the
              // circle-only box (debug overflow, clipped text otherwise).
              MenoMateLogo(
                size: variant == AppLogoVariant.compact ? 32 : 44,
                variant: variant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kLogoVariantLabels[variant] ?? variant.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kLogoVariantDescriptions[variant] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              RadioGroup<AppLogoVariant>(
                groupValue: ref.watch(logoVariantProvider),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(logoVariantProvider.notifier).setVariant(value);
                  }
                },
                child: Radio<AppLogoVariant>(value: variant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One expandable help answer. Static, honest product copy only — no
/// links, no contact details that do not exist, no invented features.
class _HelpEntry extends StatelessWidget {
  final String title;
  final String body;

  const _HelpEntry({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          body,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.secondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
