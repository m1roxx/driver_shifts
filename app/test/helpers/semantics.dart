import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

bool inLiveRegion(WidgetTester tester, Finder finder) {
  for (
    SemanticsNode? node = tester.getSemantics(finder);
    node != null;
    node = node.parent
  ) {
    if (node.flagsCollection.isLiveRegion) return true;
  }
  return false;
}
