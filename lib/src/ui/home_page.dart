import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_controller.dart';

/// The Home surface: reflects the [HomeController] state and offers the
/// encrypt/decrypt actions. Renders decrypted content read-only in Quill.
class HomePage extends StatelessWidget {
  final HomeController? controller;
  final Future<void> Function() onCheckClipboard;

  const HomePage({
    super.key,
    required this.controller,
    required this.onCheckClipboard,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) {
      return const _Centered(
        icon: Icons.key_off,
        title: 'No API token',
        message: 'Add your Capacities API token in Settings to begin.',
      );
    }
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: _buildState(context, c),
      ),
    );
  }

  Widget _buildState(BuildContext context, HomeController c) {
    return switch (c.state) {
      HomeIdle() => _Centered(
          icon: Icons.content_paste_search,
          title: 'Copy a Capacities link',
          message: 'Copy a capacities:// block link — it is detected '
              'automatically.',
          action: FilledButton.icon(
            onPressed: onCheckClipboard,
            icon: const Icon(Icons.paste),
            label: const Text('Check clipboard'),
          ),
        ),
      HomeNeedsBlock() => const _Centered(
          icon: Icons.link,
          title: 'Link a specific block',
          message: 'This link points at an object. Copy a link to a specific '
              'block (with ?bid=…).',
        ),
      HomeInvalidLink() => const _Centered(
          icon: Icons.link_off,
          title: 'Invalid link',
          message: 'That capacities:// link could not be parsed.',
        ),
      HomeLoading() => const Center(child: CircularProgressIndicator()),
      HomeLoadedPlain() => _Centered(
          icon: Icons.lock_open,
          title: 'Plain block',
          message: 'This block is not encrypted.',
          action: FilledButton.icon(
            onPressed: c.encryptCurrent,
            icon: const Icon(Icons.lock),
            label: const Text('Encrypt'),
          ),
        ),
      HomeLoadedEncrypted() => _Centered(
          icon: Icons.lock,
          title: 'Encrypted block',
          message: 'This block is a HIDDEN-CAP blob.',
          action: FilledButton.icon(
            onPressed: c.decryptCurrent,
            icon: const Icon(Icons.lock_open),
            label: const Text('Decrypt'),
          ),
        ),
      HomeWrongPassword() => _Centered(
          icon: Icons.error_outline,
          title: 'Incorrect password',
          message: 'The passphrase did not decrypt this block. Check it in '
              'Settings.',
          action: FilledButton.icon(
            onPressed: c.decryptCurrent,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      HomeDecrypted(:final deltaOps) => _DecryptedView(deltaOps: deltaOps),
      HomeEncrypted(:final link) => _Centered(
          icon: Icons.check_circle_outline,
          title: 'Encrypted',
          message: 'Stored as a HIDDEN-CAP code block.',
          action: FilledButton.icon(
            onPressed: () => launchUrl(Uri.parse(link.build())),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in Capacities'),
          ),
        ),
      HomeError(:final message) => _Centered(
          icon: Icons.warning_amber,
          title: 'Something went wrong',
          message: message,
        ),
    };
  }
}

class _DecryptedView extends StatefulWidget {
  final List<Map<String, dynamic>> deltaOps;
  const _DecryptedView({required this.deltaOps});

  @override
  State<_DecryptedView> createState() => _DecryptedViewState();
}

class _DecryptedViewState extends State<_DecryptedView> {
  late final QuillController _quill;

  @override
  void initState() {
    super.initState();
    _quill = QuillController(
      document: Document.fromJson(widget.deltaOps),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _quill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Icon(Icons.lock_open),
            SizedBox(width: 8),
            Text('Decrypted', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: QuillEditor.basic(controller: _quill),
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _Centered({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}
