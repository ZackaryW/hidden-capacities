import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:unofficial_capacities/unofficial_capacities.dart';

import '../clipboard/clipboard_watcher.dart';
import '../crypto/hidden_cap_cipher.dart';
import '../integration/capacities_gateway.dart';
import '../service/hidden_cap_service.dart';
import '../integration/wire_log.dart';
import '../settings/flutter_secure_kv.dart';
import '../settings/settings_store.dart';
import '../transform/block_quill_transform.dart';
import 'home_controller.dart';
import 'home_page.dart';
import 'settings_page.dart';

/// Builds the encrypt/decrypt service for a given API [token].
typedef ServiceFactory = HiddenCapService Function(String token);

HiddenCapService _defaultServiceFactory(String token) => HiddenCapService(
      gateway: CapacitiesGateway(
        CapacitiesClient(apiToken: token, dio: wireLoggingDio()),
      ),
      cipher: HiddenCapCipher(),
      transform: BlockQuillTransform(),
    );

/// Root app. [settingsOverride]/[serviceFactory]/[watchClipboard] exist so
/// widget tests can inject an in-memory store, a fake service, and disable the
/// polling timer.
class HiddenCapApp extends StatelessWidget {
  final SettingsStore? settingsOverride;
  final ServiceFactory serviceFactory;
  final bool watchClipboard;

  const HiddenCapApp({
    super.key,
    this.settingsOverride,
    this.serviceFactory = _defaultServiceFactory,
    this.watchClipboard = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hidden Capacities',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomeShell(
        settings: settingsOverride ?? SettingsStore(FlutterSecureKv()),
        serviceFactory: serviceFactory,
        watchClipboard: watchClipboard,
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final SettingsStore settings;
  final ServiceFactory serviceFactory;
  final bool watchClipboard;

  const HomeShell({
    super.key,
    required this.settings,
    required this.serviceFactory,
    this.watchClipboard = true,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  final _watcher = ClipboardWatcher();
  HomeController? _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.watchClipboard) {
      WidgetsBinding.instance.addObserver(this);
    }
    // Check once on launch (a fresh focus), then rely on focus events.
    _rebuildController().then((_) {
      if (widget.watchClipboard) _checkClipboardIfIdle();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Window/app gained focus — pick up a freshly copied deeplink on demand,
    // instead of polling on a timer.
    if (state == AppLifecycleState.resumed) _checkClipboardIfIdle();
  }

  /// Checks the clipboard only when no editor/content view is open, so a
  /// focus change never clobbers what the user is editing or viewing.
  void _checkClipboardIfIdle() {
    final c = _controller;
    if (c == null || c.hasOpenEditor) return;
    _watcher.checkNow(c.handleClipboard);
  }

  Future<void> _rebuildController() async {
    final prefs = await widget.settings.load();
    final token = prefs.apiToken;
    setState(() {
      _controller = (token == null || token.isEmpty)
          ? null
          : HomeController(
              service: widget.serviceFactory(token),
              settings: widget.settings,
            );
    });
  }

  @override
  void dispose() {
    if (widget.watchClipboard) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        controller: _controller,
        onCheckClipboard: () =>
            _watcher.checkNow((raw) => _controller?.handleClipboard(raw)),
      ),
      SettingsPage(store: widget.settings, onSaved: _rebuildController),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Hidden Capacities')),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
