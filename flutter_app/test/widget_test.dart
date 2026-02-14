import 'package:flutter_test/flutter_test.dart';
import 'package:coresync_app/main.dart';

void main() {
  testWidgets('CoreSync app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const CoreSyncApp());
    expect(find.text('CORESYNC'), findsOneWidget);
  });
}
