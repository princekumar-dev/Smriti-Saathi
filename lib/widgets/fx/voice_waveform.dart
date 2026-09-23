import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An animated multi-bar amplitude visualizer for the voice assistant.
///
/// - While listening, pass a live [level] (e.g. SpeechService.soundLevel) to
///   make the bars react to the user's real voice.
/// - While speaking (TTS) or idle-active, leave [level] null and set [active];
///   the bars animate with a gentle synthetic rhythm.
class VoiceWaveform extends StatefulWidget {
  const VoiceWaveform({
    super.key,
    this.active = true,
    this.level,
    this.color = Colors.white,
    this.barCount = 5,
    this.height = 34,
    this.barWidth = 5,
    this.spacing = 5,
  });

  /// Whether the waveform should animate at all.
  final bool active;

  /// Live sound level (typically -2..10 from speech_to_text). When provided,
  /// bar heights are driven by real input amplitude.
  final double? level;

  final Color color;
  final int barCount;
  final double height;
  final double barWidth;
  final double spacing;

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final List<double> _phases = List<double>.generate(
    widget.barCount,
    (i) => i * (math.pi / widget.barCount),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Normalize speech_to_text sound level (~ -2..10) to 0..1.
  double get _normalizedLevel {
    final l = widget.level;
    if (l == null) return 0;
    return ((l + 2) / 12).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 2 * math.pi;
          final live = _normalizedLevel;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              // Base rhythm wave (0..1)
              final wave = (math.sin(t + _phases[i]) + 1) / 2;
              // If a live level is provided, blend it in so bars react to voice.
              final amp = widget.level != null
                  ? (0.25 + 0.75 * live) * (0.5 + 0.5 * wave)
                  : (widget.active ? (0.28 + 0.72 * wave) : 0.18);
              final barHeight = (widget.height * amp).clamp(4.0, widget.height);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  width: widget.barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(widget.barWidth),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
