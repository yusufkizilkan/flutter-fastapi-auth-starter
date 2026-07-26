import 'package:auth_starter/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AuthStarterApp()));
    await tester.pump();
    expect(find.byType(AuthStarterApp), findsOneWidget);
  });
}
