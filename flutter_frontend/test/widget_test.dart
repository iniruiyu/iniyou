import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('app boots', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const IniyouApp());
    expect(find.byType(IniyouHome), findsOneWidget);
  });
}
