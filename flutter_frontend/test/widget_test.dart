import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const IniyouApp());
    expect(find.text('iniyou'), findsOneWidget);
  });
}
