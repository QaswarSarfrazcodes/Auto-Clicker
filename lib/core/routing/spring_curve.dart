import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// A [Curve] that reproduces a Figma "Smart Animate → Spring" interaction.
///
/// Figma exposes spring interactions as `mass`, `stiffness`, and `damping`
/// values (see the "Interactions" panel on the splash → onboarding
/// transition: mass 1, stiffness 44.44, damping 10). Flutter's animation
/// system works with [Curve]s, so this class runs an actual
/// [SpringSimulation] under the hood and samples it as a curve — the same
/// numbers the designer set, reused as-is instead of approximated with a
/// generic [Curves.easeOut].
class SpringCurve extends Curve {
  const SpringCurve({
    this.mass = 1,
    this.stiffness = 44.44,
    this.damping = 10,
  });

  final double mass;
  final double stiffness;
  final double damping;

  @override
  double transformInternal(double t) {
    final SpringDescription spring = SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
    final SpringSimulation simulation = SpringSimulation(spring, 0, 1, 0);
    return simulation.x(t).clamp(0.0, 1.0);
  }
}
