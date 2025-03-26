// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:a_dark_room/main.dart';
import 'package:a_dark_room/models/game_state.dart';
import 'package:a_dark_room/ui/screens/game_screen.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final gameState = GameState();
    await tester.pumpWidget(MyApp(gameState: gameState));

    // 添加一些基本的测试
    expect(find.byType(GameScreen), findsOneWidget);
  });
}
