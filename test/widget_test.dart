import 'package:english_forge/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SectionHeader renders its complete content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            eyebrow: 'PROGRESSO',
            title: 'EnglishForge',
            subtitle: 'Aprendizagem consistente',
            action: Icon(Icons.settings),
          ),
        ),
      ),
    );

    expect(find.text('PROGRESSO'), findsOneWidget);
    expect(find.text('EnglishForge'), findsOneWidget);
    expect(find.text('Aprendizagem consistente'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
