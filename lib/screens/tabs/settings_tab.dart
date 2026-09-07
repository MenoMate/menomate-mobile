import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/device.dart';
import '../../providers/theme_provider.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final TextEditingController _macController = TextEditingController();
  bool _isLoading = false;

  void _registerDevice() async {
    final mac = _macController.text.trim();
    if (mac.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Settings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Wearable Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manually Register Device MAC Address'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _macController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 00:1A:2B:3C:4D:5E',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerDevice,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Register Device'),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              return SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeMode == ThemeMode.dark,
                onChanged: (isDark) {
                  ref.read(themeModeProvider.notifier).toggleTheme(isDark);
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.logout, color: Colors.red),
            onTap: () async {
              await ref.read(supabaseClientProvider).auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
