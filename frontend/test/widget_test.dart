import 'package:flutter_test/flutter_test.dart';

import 'package:freshcart/main.dart';

void main() {
  testWidgets('FreshCart start screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const FreshCartApp());

    expect(find.text('FreshCart'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
