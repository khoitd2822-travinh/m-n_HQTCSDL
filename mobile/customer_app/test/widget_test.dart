import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';
import 'dart:ui';

void main() {
  testWidgets('Man hinh dang nhap hien thi', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DroneApp());
    expect(find.text('SmartDrone'), findsWidgets);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}