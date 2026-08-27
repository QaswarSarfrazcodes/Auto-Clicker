import 'package:flutter/material.dart';
import 'spring_curve.dart';

/// A [PageRouteBuilder] that transitions with [SpringCurve] — a fade plus a
/// gentle horizontal slide, matching the "Navigate to → Smart animate →
/// Spring" interaction set on the onboarding flow in Figma.
///
/// Usage:
/// ```dart
/// Navigator.of(context).push(
///   SpringPageRoute(builder: (_) => const OnboardingNoRootRequiredScreen()),
/// );
/// ```
class SpringPageRoute<T> extends PageRouteBuilder<T> {
  SpringPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: const SpringCurve(mass: 1, stiffness: 44.44, damping: 10),
            );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
