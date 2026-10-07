import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void expectWordsWhole(WidgetTester tester, Finder within) {
  final texts = find.descendant(of: within, matching: find.byType(RichText));
  expect(texts, findsWidgets);
  for (final element in texts.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(
      paragraph.size.width,
      greaterThanOrEqualTo(
        paragraph.getMinIntrinsicWidth(double.infinity) - 0.5,
      ),
      reason: '«${paragraph.text.toPlainText()}» breaks inside a word',
    );
  }
}
