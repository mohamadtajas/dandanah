import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/text.dart';

void main() {
  test('normalizes vocalised Arabic for search', () {
    expect(normalizeArabic('دُعَاءُ الاختبار'), 'دعاء الاختبار');
    expect(normalizeArabic('  ذِكْرٌ   لِلْبَحْثِ '), 'ذكر للبحث');
    expect(normalizeArabic('أَنَا'), 'انا');
  });
}
