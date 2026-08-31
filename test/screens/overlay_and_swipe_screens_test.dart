import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_clicker/presentation/screens/click_points/place_click_points_screen.dart';
import 'package:auto_clicker/presentation/screens/swipe_parameters/swipe_parameters_screen.dart';

void main() {
  testWidgets('TC_CP_01: Place Click Points screen renders top instruction banner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlaceClickPointsScreen(),
      ),
    );

    expect(find.text('Tap Grid to Place Points'), findsOneWidget);
  });

  testWidgets('TC_SWP_01: Swipe Parameters screen renders default input controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SwipeParametersScreen(),
      ),
    );

    expect(find.text('Tap Canvas for START Point'), findsOneWidget);
  });

  testWidgets('TC_SWP_02: tapping canvas places start and end points', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SwipeParametersScreen(),
      ),
    );

    expect(find.text('Tap Canvas for START Point'), findsOneWidget);
    await tester.tapAt(const Offset(200, 300));
    await tester.pump();
    expect(find.text('Tap Canvas for END Point'), findsOneWidget);

    await tester.tapAt(const Offset(300, 500));
    await tester.pump();
    expect(find.text('Swipe Gesture Ready'), findsOneWidget);
  });
}
