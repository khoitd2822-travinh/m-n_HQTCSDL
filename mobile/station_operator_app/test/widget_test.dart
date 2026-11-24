import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartdrone_station_operator_app/main.dart';

void main() {
  testWidgets('App tram dung len duoc', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StationOperatorApp());
    expect(find.byType(StationOperatorApp), findsOneWidget);
  });
}