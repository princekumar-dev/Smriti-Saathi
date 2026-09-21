import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BreathingOrb extends StatefulWidget {
  final double size;
  final bool isListening;
  final IconData icon;
  final VoidCallback? onTap;

  const BreathingOrb({
    super.key,
    this.size = 140,
    this.isListening = false,
    this.icon = Icons.mic_rounded,
    this.onTap,
  });

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = _controller.value;
          final scaleOuter = 1.0 + (pulse * 0.18);
          final scaleMid = 1.0 + (pulse * 0.09);
          final opacityOuter = (0.28 - (pulse * 0.18)).clamp(0.05, 0.4);

          return SizedBox(
            width: widget.size * 1.35,
            height: widget.size * 1.35,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse Ring
                Transform.scale(
                  scale: scaleOuter,
                  child: Container(
                    width: widget.size * 1.25,
                    height: widget.size * 1.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.emerald.withValues(alpha: opacityOuter),
                    ),
                  ),
                ),

                // Mid Wave Ring
                Transform.scale(
                  scale: scaleMid,
                  child: Container(
                    width: widget.size * 1.1,
                    height: widget.size * 1.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.sage.withValues(alpha: 0.45),
                    ),
                  ),
                ),

                // Core Sphere
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.emeraldGradient,
                    boxShadow: AppTheme.emeraldGlow,
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.size * 0.44,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
