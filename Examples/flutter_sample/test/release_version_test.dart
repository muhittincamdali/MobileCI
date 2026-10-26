import 'package:flutter/material.dart';
import 'package:flutter_sample/main.dart';
import 'package:flutter_sample/release_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReleaseVersion.tryParse', () {
    test('reads the name and the build number', () {
      final version = ReleaseVersion.tryParse('1.4.0+27')!;
      expect(version.name, '1.4.0');
      expect(version.build, 27);
      expect(version.label, 'Version 1.4.0 (27)');
    });

    test('accepts a version without a build number', () {
      expect(ReleaseVersion.tryParse('2.0.1')!.label, 'Version 2.0.1');
    });

    test('refuses versions Flutter would not build', () {
      for (final text in ['1.4', '1.4.0+', '1.4.0+2+3', 'v1.4.0', '1.4.x+1', '1.4.0+-1', '']) {
        expect(ReleaseVersion.tryParse(text), isNull, reason: text);
      }
    });

    test('refuses build numbers above the Google Play limit instead of overflowing', () {
      expect(ReleaseVersion.tryParse('1.0.0+2100000000')!.build, 2100000000);
      expect(ReleaseVersion.tryParse('1.0.0+2100000001'), isNull);
      expect(ReleaseVersion.tryParse('1.0.0+99999999999999999999'), isNull);
    });
  });

  testWidgets('shows how the typed version is read', (tester) async {
    await tester.pumpWidget(const SampleApp());
    expect(find.text('Version 1.4.0 (27)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input')), '2.0.0+3');
    await tester.pump();
    expect(find.text('Version 2.0.0 (3)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input')), '2.0');
    await tester.pump();
    expect(find.text('Not a Flutter version'), findsOneWidget);
  });
}
