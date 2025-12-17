// Этот файл предоставляется Flutter для тестирования виджетов.

import 'package:flutter_test/flutter_test.dart';

import 'package:geo_sensors_app/main.dart';

void main() {
  testWidgets('Приложение запускается и отображает заголовок', (WidgetTester tester) async {
    // Создаем виджет и запускаем кадр.
    await tester.pumpWidget(const GeoSensorsApp());

    // Проверяем, что заголовок приложения отображается.
    expect(find.text('Geo & Sensors'), findsOneWidget);
  });
}