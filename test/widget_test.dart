import 'package:english_forge/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app opens', (tester) async {
    await tester.pumpWidget(const EnglishForgeApp());
    await tester.pumpAndSettle();
    expect(find.text('EnglishForge'), findsOneWidget);
  });
}
