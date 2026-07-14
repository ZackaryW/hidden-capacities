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
          title: 'Ready',
          message: 'Copy a capacities:// block link — it is picked up when you '
              'switch back to this window.',
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
      HomeLoadedPlain(:final initialOps) => _PlainEditor(
          key: const ValueKey('plainEditor'),
          initialOps: initialOps,
          onEncrypt: c.encryptCurrent,
          onBack: c.backToHome,
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
      HomeDecrypted(:final deltaOps) =>
        _DecryptedView(deltaOps: deltaOps, onEdit: c.editCurrent),
      HomeEditingDecrypted(:final deltaOps) => _PlainEditor(
          key: const ValueKey('editEditor'),
          initialOps: deltaOps,
          onEncrypt: c.saveEdit,
          onBack: c.backToHome,
          heading: 'Editing decrypted content — save to re-encrypt',
          buttonIcon: Icons.save,
          buttonLabel: 'Save',
        ),
      HomeEncrypted(:final link) => _Centered(
          icon: Icons.check_circle_outline,
          title: 'Encrypted',
          message: 'Stored as a HIDDEN-CAP code block.',
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse(link.build())),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in Capacities'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: c.editEncrypted,
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ],
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

/// Editable Quill view of a plain block: seeded with the block's content so
/// the user can review/edit before encrypting. The live editor delta is what
/// gets encrypted.
class _PlainEditor extends StatefulWidget {
  final List<Map<String, dynamic>> initialOps;
  final Future<void> Function(List<Map<String, dynamic>>) onEncrypt;
  final VoidCallback onBack;
  final String heading;
  final IconData buttonIcon;
  final String buttonLabel;

  const _PlainEditor({
    super.key,
    required this.initialOps,
    required this.onEncrypt,
    required this.onBack,
    this.heading = 'Plain block — review or edit before encrypting',
    this.buttonIcon = Icons.lock,
    this.buttonLabel = 'Encrypt',
  });

  @override
  State<_PlainEditor> createState() => _PlainEditorState();
}

class _PlainEditorState extends State<_PlainEditor> {
  late final QuillController _quill;

  @override
  void initState() {
    super.initState();
    _quill = QuillController(
      document: Document.fromJson(widget.initialOps),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _quill.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _currentOps() =>
      _quill.document.toDelta().toJson().cast<Map<String, dynamic>>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to home',
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(widget.heading,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        QuillSimpleToolbar(controller: _quill),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: QuillEditor.basic(controller: _quill),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => widget.onEncrypt(_currentOps()),
          icon: Icon(widget.buttonIcon),
          label: Text(widget.buttonLabel),
        ),
      ],
    );
  }
}

class _DecryptedView extends StatefulWidget {
  final List<Map<String, dynamic>> deltaOps;
  final VoidCallback onEdit;
  const _DecryptedView({required this.deltaOps, required this.onEdit});

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
          children: [
            const Icon(Icons.lock_open),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Decrypted',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            OutlinedButton.icon(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: QuillEditor.basic(
            controller: _quill,
            // Read-only viewer: no blinking cursor (also lets widget tests
            // settle instead of spinning on the cursor timer).
            config: const QuillEditorConfig(showCursor: false),
          ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // LocalSend-style circular hero.
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
              ),
              child: Icon(icon, size: 60, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 28), action!],
          ],
        ),
      ),
    );
  }
}
