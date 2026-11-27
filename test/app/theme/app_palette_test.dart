import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/app/theme/app_colors.dart';
import 'package:guiago/app/theme/app_palette.dart';
import 'package:guiago/app/theme/app_theme.dart';
import 'package:guiago/app/theme/app_theme_mode.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => AppPalette.use(Brightness.dark));

  group('AppColors follows the active palette', () {
    test('dark is the default', () {
      expect(AppColors.background, AppPalette.dark.background);
      expect(AppColors.textPrimary, AppPalette.dark.textPrimary);
    });

    test('switching to light changes every role that must change', () {
      AppPalette.use(Brightness.light);

      expect(AppColors.background, AppPalette.light.background);
      expect(AppColors.surface, AppPalette.light.surface);
      expect(AppColors.textPrimary, AppPalette.light.textPrimary);
      expect(AppColors.background, isNot(AppPalette.dark.background));
      expect(AppColors.textPrimary, isNot(AppPalette.dark.textPrimary));
    });

    test('switching back to dark restores the original colors', () {
      AppPalette.use(Brightness.light);
      AppPalette.use(Brightness.dark);

      expect(AppColors.primary, const Color(0xFF2FBF83));
      expect(AppColors.background, const Color(0xFF0A100D));
    });
  });

  group('contrast (WCAG AA, 4.5:1 for text)', () {
    const List<AppPalette> palettes = <AppPalette>[
      AppPalette.dark,
      AppPalette.light,
    ];
    for (final AppPalette p in palettes) {
      final String name = p.brightness.name;

      test('$name: main text on its backgrounds', () {
        expect(_contrast(p.textPrimary, p.background), greaterThan(7));
        expect(_contrast(p.textPrimary, p.surface), greaterThan(7));
        expect(_contrast(p.textSecondary, p.background), greaterThan(4.5));
        expect(_contrast(p.textSecondary, p.surface), greaterThan(4.5));
        expect(_contrast(p.textSecondary, p.surfaceMuted), greaterThan(4.5));
      });

      test('$name: text on the primary color', () {
        expect(_contrast(p.textOnPrimary, p.primary), greaterThan(4.5));
      });

      test('$name: primary, warning and error as text', () {
        for (final Color c in <Color>[p.primary, p.warning, p.error]) {
          expect(_contrast(c, p.background), greaterThan(4.5));
          expect(_contrast(c, p.surface), greaterThan(4.5));
        }
      });
    }
  });

  group('AppTheme', () {
    testWidgets('the light theme is light and uses the light palette',
        (WidgetTester tester) async {
      final ThemeData theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppPalette.light.background);
      expect(theme.colorScheme.onSurface, AppPalette.light.textPrimary);
      expect(
        theme.textTheme.bodyLarge?.color,
        AppPalette.light.textPrimary,
      );
      await tester.pump();
    });

    testWidgets('the dark theme keeps the original palette',
        (WidgetTester tester) async {
      final ThemeData theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppPalette.dark.background);
      expect(theme.textTheme.bodyMedium?.color, AppPalette.dark.textSecondary);
      await tester.pump();
    });

    testWidgets('building a theme does not depend on the active palette',
        (WidgetTester tester) async {
      AppPalette.use(Brightness.light);

      final ThemeData theme = AppTheme.dark();

      expect(theme.scaffoldBackgroundColor, AppPalette.dark.background);
      await tester.pump();
    });
  });

  group('AppThemeMode', () {
    test('fromKey finds each mode and falls back to dark', () {
      for (final AppThemeMode mode in AppThemeMode.values) {
        expect(AppThemeMode.fromKey(mode.key), mode);
      }
      expect(AppThemeMode.fromKey('???'), AppThemeMode.dark);
      expect(AppThemeMode.fromKey(null), AppThemeMode.dark);
    });

    test('maps to the Flutter ThemeMode', () {
      expect(AppThemeMode.light.themeMode, ThemeMode.light);
      expect(AppThemeMode.dark.themeMode, ThemeMode.dark);
      expect(AppThemeMode.system.themeMode, ThemeMode.system);
    });
  });
}
