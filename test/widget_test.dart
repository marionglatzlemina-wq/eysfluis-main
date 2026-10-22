import 'package:flutter_test/flutter_test.dart';
import 'package:eysfluis/main.dart';

void main() {
  testWidgets('EYSFLUIS App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EysfluisApp());

    // Verify app title or core elements exist
    expect(find.text('EYSFLUIS - EYSFWIS'), findsOneWidget);
  });
}
