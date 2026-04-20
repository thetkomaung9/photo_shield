import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photoshield_app/app.dart';

void main() {
  testWidgets('app renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PhotoShieldApp()),
    );
    await tester.pump();

    expect(find.text('PhotoShield Korea'), findsOneWidget);
  });
}
