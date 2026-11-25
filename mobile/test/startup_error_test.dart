import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/startup_error_app.dart';

void main() {
  testWidgets('startup failure shows Arabic recovery copy and retries', (
    tester,
  ) async {
    var retries = 0;

    await tester.pumpWidget(
      StartupErrorApp(
        error: StateError('database unavailable'),
        onRetry: () async => retries++,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذّر بدء سَكينة'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(retries, 1);
  });
}
