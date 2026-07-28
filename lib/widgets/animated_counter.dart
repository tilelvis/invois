import 'package:flutter/material.dart';

/// Animates a numeric value counting up from 0 (or its previous value)
/// to [value] whenever it changes, formatting each frame with [formatter].
class AnimatedCounterText extends StatelessWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounterText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          formatter(animatedValue),
          style: style,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// Animates an integer count (e.g. "3 unpaid") counting up.
class AnimatedCounterInt extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounterInt({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text('${animatedValue.round()}', style: style);
      },
    );
  }
}
