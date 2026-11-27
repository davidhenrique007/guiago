import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/app/theme/app_colors.dart';
import 'package:guiago/app/theme/app_palette.dart';
import 'package:guiago/app/theme/app_theme.dart';
import 'package:guiago/app/theme/app_theme_mode.dart';
import 'package:guiago/app/theme/palette_scope.dart';
import 'package:guiago/app/theme/theme_mode_provider.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/onboarding/application/settings_controller.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';

/// Reads AppColors in build and does NOT depend on Theme — exactly the
/// kind of widget that would keep stale colors without PaletteScope.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey<String>('probe'),
      color: AppColors.background,
    );
  }
}

class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode.themeMode,
      themeAnimationDuration: Duration.zero,
      builder: themedAppBuilder,
      home: const Scaffold(body: _Probe()),
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    AppPalette.use(Brightness.dark);
    await db.close();
  });

  Color probeColor(WidgetTester tester) => tester
      .widget<ColoredBox>(find.byKey(const ValueKey<String>('probe')))
      .color;

  Future<ProviderContainer> pump(WidgetTester tester, String themeMode) async {
    await DriftSettingsRepository(db).saveSettings(
      Settings.initial.copyWith(themeMode: themeMode),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _Harness(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('light: the app uses the light palette', (
    WidgetTester tester,
  ) async {
    await pump(tester, 'light');

    expect(probeColor(tester), AppPalette.light.background);
  });

  testWidgets('dark: the app keeps the original palette', (
    WidgetTester tester,
  ) async {
    await pump(tester, 'dark');

    expect(probeColor(tester), AppPalette.dark.background);
  });

  testWidgets('changing the theme updates widgets that ignore Theme', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pump(tester, 'dark');
    expect(probeColor(tester), AppPalette.dark.background);

    await container
        .read(settingsControllerProvider.notifier)
        .saveChange((Settings s) => s.copyWith(themeMode: 'light'));
    await tester.pumpAndSettle();
    expect(probeColor(tester), AppPalette.light.background);

    await container
        .read(settingsControllerProvider.notifier)
        .saveChange((Settings s) => s.copyWith(themeMode: 'dark'));
    await tester.pumpAndSettle();
    expect(probeColor(tester), AppPalette.dark.background);
  });

  testWidgets('system: follows the phone brightness, live', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await pump(tester, 'system');
    expect(probeColor(tester), AppPalette.light.background);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(probeColor(tester), AppPalette.dark.background);
  });
}
