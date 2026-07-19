import 'package:flutter_test/flutter_test.dart';
import 'package:techdex/main.dart';

void main() {
  testWidgets('앱이 렌더된다', (WidgetTester tester) async {
    await tester.pumpWidget(const TechDexApp());
    expect(find.text('TechDex'), findsWidgets);
  });
}
