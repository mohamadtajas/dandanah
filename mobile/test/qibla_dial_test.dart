import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:sakeenah_mobile/widgets/qibla_dial.dart';

void main() {
  Future<void> pumpDial(WidgetTester tester, double bearing) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(child: QiblaDial(bearing: bearing)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows a readable bearing badge and semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpDial(tester, 160.7);

    expect(find.text('161°'), findsOneWidget);
    expect(find.bySemanticsLabel('اتجاه القبلة 161°'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('normalizes a full turn to zero degrees', (tester) async {
    await pumpDial(tester, 359.6);
    expect(find.text('0°'), findsOneWidget);
  });
}
