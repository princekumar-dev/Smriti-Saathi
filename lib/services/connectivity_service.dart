import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'sync_service.dart';

/// Single source of truth for online/offline state across the app.
///
/// Wraps `connectivity_plus` **once** (the old per-widget subscriptions are
/// replaced by listening to this notifier) and reconciles the OS-level
/// connectivity signal with a real backend health ping — a device can be on
/// Wi-Fi yet unable to reach the server, and vice-versa on captive portals.
///
/// On an offline→online transition it kicks [SyncService.syncAll] so pending
/// local writes are pushed and fresh data pulled.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._internal();
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _sub;
  Timer? _healthTimer;

  /// True once [init] has run.
  bool _initialized = false;

  /// Raw OS connectivity (has *a* network interface up).
  bool _hasNetwork = true;

  /// Verified reachability of the backend (health ping succeeded).
  bool _serverReachable = false;

  /// Explicit "work offline" override. When true, [isOnline] is forced false
  /// and auto push/pull is disabled regardless of the real network. Left off
  /// by default; wire a settings toggle to [setForcedOffline] to expose it.
  bool _forcedOffline = false;

  /// The app's effective online state: a network is up, the server answered,
  /// and the user hasn't forced offline.
  bool get isOnline => _hasNetwork && _serverReachable && !_forcedOffline;

  /// True when the device has a network interface but we still treat the app
  /// as offline (server unreachable) — useful for nuanced UI messaging.
  bool get hasNetworkButNoServer =>
      _hasNetwork && !_serverReachable && !_forcedOffline;

  bool get forcedOffline => _forcedOffline;

  /// Opens the connectivity subscription, does an initial health probe, and
  /// starts a periodic reachability re-check. Idempotent.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final results = await _connectivity.checkConnectivity();
      _hasNetwork = _resultsOnline(results);
    } catch (_) {
      _hasNetwork = true; // fail open — assume network, health ping decides
    }

    await _refreshServerReachable();

    try {
      _sub = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    } catch (_) {}

    // Re-probe the server periodically so we recover from server-side outages
    // even when the OS connectivity signal never changes.
    _healthTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshServerReachable(),
    );

    notifyListeners();
  }

  Future<void> _onConnectivityChanged(dynamic event) async {
    final wasOnline = isOnline;
    _hasNetwork = _resultsOnline(event);
    if (_hasNetwork) {
      await _refreshServerReachable();
    } else {
      _serverReachable = false;
    }
    _emitAndMaybeSync(wasOnline);
  }

  /// Pings the backend and updates [_serverReachable].
  Future<void> _refreshServerReachable() async {
    final wasOnline = isOnline;
    if (!_hasNetwork || _forcedOffline) {
      _serverReachable = false;
      _emitAndMaybeSync(wasOnline);
      return;
    }
    bool reachable;
    try {
      reachable = await ApiService().checkHealth();
    } catch (_) {
      reachable = false;
    }
    _serverReachable = reachable;
    _emitAndMaybeSync(wasOnline);
  }

  /// Notifies listeners and, on a false→true transition, triggers a full sync.
  void _emitAndMaybeSync(bool wasOnline) {
    notifyListeners();
    if (!wasOnline && isOnline) {
      // Reconnected — flush the outbox and pull fresh data.
      unawaited(SyncService().syncAll());
    }
  }

  /// User toggle: force the app to behave as offline (disables auto sync).
  Future<void> setForcedOffline(bool value) async {
    if (_forcedOffline == value) return;
    final wasOnline = isOnline;
    _forcedOffline = value;
    if (!value && _hasNetwork) {
      await _refreshServerReachable();
    }
    _emitAndMaybeSync(wasOnline);
  }

  /// Manually re-check reachability (e.g. a "retry" button).
  Future<void> recheck() => _refreshServerReachable();

  static bool _resultsOnline(dynamic event) {
    if (event is List<ConnectivityResult>) {
      return event.isNotEmpty && !event.contains(ConnectivityResult.none);
    }
    if (event is ConnectivityResult) {
      return event != ConnectivityResult.none;
    }
    return true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _healthTimer?.cancel();
    super.dispose();
  }
}
