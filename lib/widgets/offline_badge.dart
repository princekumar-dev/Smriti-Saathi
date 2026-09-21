import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'animated_scale_button.dart';

/// Reactive Online / Offline state badge with live connectivity detection
class OfflineBadge extends StatefulWidget {
  final bool compact;

  const OfflineBadge({
    super.key,
    this.compact = false,
  });

  @override
  State<OfflineBadge> createState() => _OfflineBadgeState();
}

class _OfflineBadgeState extends State<OfflineBadge> {
  bool _isOnline = true;
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscribeToConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateStatus(results);
    } catch (_) {
      // Default to online if error
      if (mounted) setState(() => _isOnline = true);
    }
  }

  void _subscribeToConnectivity() {
    try {
      _subscription = Connectivity().onConnectivityChanged.listen((event) {
        _updateStatus(event);
      });
    } catch (_) {}
  }

  void _updateStatus(dynamic event) {
    if (!mounted) return;
    bool online = true;
    if (event is List<ConnectivityResult>) {
      online = event.isNotEmpty && !event.contains(ConnectivityResult.none);
    } else if (event is ConnectivityResult) {
      online = event != ConnectivityResult.none;
    }
    setState(() => _isOnline = online);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _showConnectivityInfo(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _isOnline ? AppTheme.forest : AppTheme.deepForest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(
              _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isOnline
                    ? 'Connected Online • Live AI & Sync Active'
                    : 'Offline Mode Active • Local Voice & Memories Ready',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isOnline ? const Color(0xFFE8F5EE) : const Color(0xFFFEF3E8);
    final borderColor = _isOnline
        ? AppTheme.emerald.withValues(alpha: 0.3)
        : AppTheme.warmAmber.withValues(alpha: 0.4);
    final dotColor = _isOnline ? const Color(0xFF16A34A) : AppTheme.warmAmber;
    final textColor = _isOnline ? const Color(0xFF0F5A3E) : const Color(0xFF9A5207);
    final statusText = _isOnline ? 'Online' : 'Offline';

    return AnimatedScaleButton(
      onTap: () => _showConnectivityInfo(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 10 : 12,
          vertical: widget.compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: dotColor.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live status dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.45),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 5),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
