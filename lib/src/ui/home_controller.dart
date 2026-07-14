import 'package:flutter/foundation.dart';
import 'package:unofficial_capacities/unofficial_capacities.dart';

import '../clipboard/link_target.dart';
import '../crypto/hidden_cap_cipher.dart';
import '../integration/capacities_gateway.dart';
import '../service/hidden_cap_service.dart';
import '../settings/settings_store.dart';
import '../transform/block_quill_transform.dart';

/// UI-facing state of the Home surface.
sealed class HomeState {
  const HomeState();
}

class HomeIdle extends HomeState {
  const HomeIdle();
}

class HomeNeedsBlock extends HomeState {
  const HomeNeedsBlock();
}

class HomeInvalidLink extends HomeState {
  const HomeInvalidLink();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoadedPlain extends HomeState {
  final LoadedBlock target;

  /// The block's content as editable Quill delta ops, seeding the
  /// pre-encryption editor. The user may edit these before encrypting.
  final List<Map<String, dynamic>> initialOps;
  const HomeLoadedPlain(this.target, this.initialOps);
}

class HomeLoadedEncrypted extends HomeState {
  final LoadedBlock target;
  const HomeLoadedEncrypted(this.target);
}

class HomeDecrypted extends HomeState {
  final List<Map<String, dynamic>> deltaOps;
  const HomeDecrypted(this.deltaOps);
}

class HomeEncrypted extends HomeState {
  final CapacitiesLink link;
  const HomeEncrypted(this.link);
}

class HomeWrongPassword extends HomeState {
  final LoadedBlock target;
  const HomeWrongPassword(this.target);
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
}

/// Drives the detect-then-offer flow: resolve a clipboard deeplink, load the
/// block, and either offer encryption (plain) or decryption (HIDDEN-CAP),
/// governed by the auto-decrypt setting.
class HomeController extends ChangeNotifier {
  final HiddenCapService service;
  final SettingsStore settings;

  HomeState _state = const HomeIdle();
  HomeState get state => _state;

  /// Space id of the current target's deeplink, carried so the post-encrypt
  /// deeplink is shareable.
  String? _spaceId;

  HomeController({required this.service, required this.settings});

  void _set(HomeState next) {
    _state = next;
    notifyListeners();
  }

  /// Classifies [raw] clipboard content and loads the target if it is a
  /// block-specific deeplink.
  Future<void> handleClipboard(String raw) async {
    final target = LinkTarget.resolve(raw);
    switch (target.kind) {
      case LinkTargetKind.notADeeplink:
        return; // ignore noise, keep current state
      case LinkTargetKind.malformed:
        _set(const HomeInvalidLink());
      case LinkTargetKind.needsBlock:
        _set(const HomeNeedsBlock());
      case LinkTargetKind.ready:
        await _load(target.link!);
    }
  }

  Future<void> _load(CapacitiesLink link) async {
    _spaceId = link.spaceId;
    _set(const HomeLoading());
    try {
      final loaded = await service.gateway.loadBlock(link);
      if (!loaded.isEncrypted) {
        try {
          _set(HomeLoadedPlain(loaded, service.editableOps(loaded.block)));
        } on UnsupportedBlockException catch (e) {
          _set(HomeError('unsupported block type: ${e.blockType}'));
        }
        return;
      }
      final prefs = await settings.load();
      switch (prefs.autoDecrypt) {
        case AutoDecrypt.on:
          _decrypt(loaded, prefs.passphrase);
        case AutoDecrypt.ask:
        case AutoDecrypt.off:
          _set(HomeLoadedEncrypted(loaded));
      }
    } on CapacitiesApiException catch (e) {
      _set(HomeError(e.message));
    } on BlockNotFoundException {
      _set(const HomeError('block not found'));
    }
  }

  /// Manually decrypt a loaded encrypted block (Off/Ask paths).
  Future<void> decryptCurrent() async {
    final current = _state;
    if (current is! HomeLoadedEncrypted && current is! HomeWrongPassword) return;
    final target = current is HomeLoadedEncrypted
        ? current.target
        : (current as HomeWrongPassword).target;
    final prefs = await settings.load();
    _decrypt(target, prefs.passphrase);
  }

  void _decrypt(LoadedBlock target, String? passphrase) {
    if (passphrase == null || passphrase.isEmpty) {
      _set(HomeWrongPassword(target));
      return;
    }
    try {
      _set(HomeDecrypted(service.decrypt(target: target, passphrase: passphrase)));
    } on WrongPasswordException {
      _set(HomeWrongPassword(target));
    } on MalformedBlobException catch (e) {
      _set(HomeError(e.message));
    }
  }

  /// Encrypt the currently-loaded plain block, replacing it with a HIDDEN-CAP
  /// code block. [editedOps] is the live Quill delta from the editor (the user
  /// may have edited it), which becomes the encrypted payload.
  Future<void> encryptCurrent(List<Map<String, dynamic>> editedOps) async {
    final current = _state;
    if (current is! HomeLoadedPlain) return;
    final prefs = await settings.load();
    final passphrase = prefs.passphrase;
    if (passphrase == null || passphrase.isEmpty) {
      _set(const HomeError('set a passphrase in Settings first'));
      return;
    }
    _set(const HomeLoading());
    try {
      final link = await service.encrypt(
        target: current.target,
        deltaOps: editedOps,
        passphrase: passphrase,
        spaceId: _spaceId ?? '',
      );
      _set(HomeEncrypted(link));
    } on CapacitiesApiException catch (e) {
      _set(HomeError(e.message));
    }
  }
}
