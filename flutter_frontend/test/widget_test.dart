import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_frontend/main.dart';
import 'package:flutter_frontend/models/app_models.dart';

void main() {
  testWidgets('app boots', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const IniyouApp());
    expect(find.byType(IniyouHome), findsOneWidget);
  });

  test('chat message parses REST and websocket payload shapes', () {
    final restMessage = ChatMessage.fromJson({
      'ID': 'm1',
      'SenderID': 'u1',
      'ReceiverID': 'u2',
      'Content': 'hello',
      'CreatedAt': '2026-03-13T10:00:00Z',
    });
    expect(restMessage.id, 'm1');
    expect(restMessage.from, 'u1');
    expect(restMessage.to, 'u2');
    expect(restMessage.content, 'hello');

    final socketMessage = ChatMessage.fromJson({
      'from': 'u2',
      'to': 'u1',
      'content': 'reply',
      'created_at': '2026-03-13T10:01:00Z',
    });
    expect(socketMessage.from, 'u2');
    expect(socketMessage.to, 'u1');
    expect(socketMessage.content, 'reply');
  });
}
