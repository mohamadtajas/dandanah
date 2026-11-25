import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakeenah_mobile/app.dart';

void main() {
  testWidgets('shell shows the four destinations', (tester) async {
    await tester.pumpWidget(const SakeenahApp());
    await tester.pumpAndSettle();

    expect(find.text('سَكينة'), findsWidgets);
    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('المصحف'), findsWidgets);
    expect(find.text('الأذكار'), findsWidgets);
    expect(find.text('الصوت'), findsWidgets);
  });

  testWidgets('tapping the Mushaf tab opens the Quran page', (tester) async {
    await tester.pumpWidget(const SakeenahApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('المصحف').last);
    await tester.pumpAndSettle();

    expect(find.text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'), findsOneWidget);
  });

  testWidgets('settings opens and switches the theme', (tester) async {
    await tester.pumpWidget(const SakeenahApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('الإعدادات'), findsWidgets);

    await tester.tap(find.text('فاتح'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('فاتح'));
    expect(Theme.of(context).brightness, Brightness.light);
  });
}
