import 'package:flutter/material.dart';

import '../settings/settings_store.dart';

/// Settings surface: API token, passphrase (both secure-storage backed), and
/// the auto-decrypt preference.
class SettingsPage extends StatefulWidget {
  final SettingsStore store;

  /// Called after a save so the app can rebuild the client with a new token.
  final Future<void> Function() onSaved;

  const SettingsPage({super.key, required this.store, required this.onSaved});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _token = TextEditingController();
  final _passphrase = TextEditingController();
  AutoDecrypt _autoDecrypt = AutoDecrypt.off;
  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await widget.store.load();
    setState(() {
      _token.text = s.apiToken ?? '';
      _passphrase.text = s.passphrase ?? '';
      _autoDecrypt = s.autoDecrypt;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await widget.store.saveApiToken(_token.text.trim());
    await widget.store.savePassphrase(_passphrase.text);
    await widget.store.saveAutoDecrypt(_autoDecrypt);
    await widget.onSaved();
    if (mounted) setState(() => _saved = true);
  }

  @override
  void dispose() {
    _token.dispose();
    _passphrase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          key: const Key('tokenField'),
          controller: _token,
          decoration: const InputDecoration(
            labelText: 'Capacities API token',
            hintText: 'cap-api-…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('passphraseField'),
          controller: _passphrase,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Encryption passphrase',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text('Auto-decrypt', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<AutoDecrypt>(
          segments: const [
            ButtonSegment(value: AutoDecrypt.off, label: Text('Off')),
            ButtonSegment(value: AutoDecrypt.ask, label: Text('Ask')),
            ButtonSegment(value: AutoDecrypt.on, label: Text('On')),
          ],
          selected: {_autoDecrypt},
          onSelectionChanged: (s) => setState(() => _autoDecrypt = s.first),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('saveButton'),
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
        if (_saved)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Saved.', key: Key('savedNotice')),
          ),
      ],
    );
  }
}
