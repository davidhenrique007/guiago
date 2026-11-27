import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/errors/failures.dart';
import 'package:guiago/core/result/result.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/design_system/components/app_bottom_sheet.dart';
import 'package:guiago/features/onboarding/data/drift_settings_repository.dart';
import 'package:guiago/features/onboarding/domain/settings.dart';
import 'package:guiago/features/profile/application/profile_photo_providers.dart';
import 'package:guiago/features/profile/domain/profile_photo_store.dart';
import 'package:guiago/features/profile/presentation/screens/profile_screen.dart';
import 'package:guiago/features/profile/presentation/widgets/profile_avatar.dart';

class _FakeStore implements ProfilePhotoStore {
  Result<String?> next = const Success<String?>(null);
  final List<ProfilePhotoSource> asked = <ProfilePhotoSource>[];
  final List<String> deleted = <String>[];

  @override
  Future<Result<String?>> pick(ProfilePhotoSource source) async {
    asked.add(source);
    return next;
  }

  @override
  Future<void> delete(String path) async => deleted.add(path);
}

// A valid 1x1 PNG.
final List<int> _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  late AppDatabase db;
  late _FakeStore store;
  late Directory temp;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = _FakeStore();
    temp = Directory.systemTemp.createTempSync('guiago_photo_');
  });

  tearDown(() async {
    await db.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<void> pumpProfile(WidgetTester tester, {String photo = ''}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await DriftSettingsRepository(db).saveSettings(
      Settings.initial.copyWith(userName: 'Ana', photoPath: photo),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          profilePhotoStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Settings> saved() async =>
      (await DriftSettingsRepository(db).getSettings()).valueOrNull!;

  Finder inSheet(String text) => find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.text(text),
      );

  group('ProfileAvatar', () {
    testWidgets('shows the initial without a photo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileAvatar(name: 'ana', photoPath: '')),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows the initial when the file is gone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileAvatar(name: 'Ana', photoPath: '${temp.path}/x.jpg'),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows the photo when the file exists', (tester) async {
      final File file = File('${temp.path}/me.png')..writeAsBytesSync(_png);
      await tester.pumpWidget(
        MaterialApp(home: ProfileAvatar(name: 'Ana', photoPath: file.path)),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows ? without a name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileAvatar(name: ' ', photoPath: '')),
      );

      expect(find.text('?'), findsOneWidget);
    });
  });

  group('ProfileScreen photo', () {
    testWidgets('tapping the avatar offers camera and gallery only', (
      tester,
    ) async {
      await pumpProfile(tester);

      await tester.tap(find.byTooltip('Alterar foto'));
      await tester.pumpAndSettle();

      expect(inSheet('Tirar foto'), findsOneWidget);
      expect(inSheet('Escolher da galeria'), findsOneWidget);
      expect(inSheet('Remover foto'), findsNothing);
    });

    testWidgets('choosing from the gallery saves the new path', (
      tester,
    ) async {
      store.next = const Success<String?>('/app/profile_1.jpg');
      await pumpProfile(tester);

      await tester.tap(find.byTooltip('Alterar foto'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet('Escolher da galeria'));
      await tester.pumpAndSettle();

      expect(store.asked, <ProfilePhotoSource>[ProfilePhotoSource.gallery]);
      expect((await saved()).photoPath, '/app/profile_1.jpg');
      expect(store.deleted, isEmpty);
    });

    testWidgets('the camera asks for the camera', (tester) async {
      store.next = const Success<String?>('/app/profile_2.jpg');
      await pumpProfile(tester);

      await tester.tap(find.byTooltip('Alterar foto'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet('Tirar foto'));
      await tester.pumpAndSettle();

      expect(store.asked, <ProfilePhotoSource>[ProfilePhotoSource.camera]);
      expect((await saved()).photoPath, '/app/profile_2.jpg');
    });

    testWidgets('cancelling changes nothing', (tester) async {
      await pumpProfile(tester, photo: '/app/old.jpg');

      await tester.tap(find.byTooltip('Alterar foto'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet('Escolher da galeria'));
      await tester.pumpAndSettle();

      expect((await saved()).photoPath, '/app/old.jpg');
      expect(store.deleted, isEmpty);
    });

    testWidgets('a new photo deletes the previous copy', (tester) async {
      store.next = const Success<String?>('/app/new.jpg');
      await pumpProfile(tester, photo: '/app/old.jpg');

      await tester.tap(find.byTooltip('Alterar foto'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet('Escolher da galeria'));
      await tester.pumpAndSettle();

      expect((await saved()).photoPath, '/app/new.jpg');
      expect(store.deleted, <String>['/app/old.jpg']);
    });

    testWidgets('a failure keeps the photo and says so', (tester) async {
      store.next = const Fail<String?>(PlatformFailure('boom'));
      await pumpProfile(tester, photo: '/app/old.jpg');

      await tester.tap(find.byTooltip('Alterar foto'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet('Escolher da galeria'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível usar essa foto.'), findsOneWidget);
      expect((await saved()).photoPath, '/app/old.jpg');
    });

    testWidgets('removing clears the path and deletes the copy', (
      tester,
    ) async {
      await pumpProfile(tester, photo: '/app/old.jpg');

      await tester.tap(find.byTooltip('Alterar foto'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet('Remover foto'));
      await tester.pumpAndSettle();

      expect((await saved()).photoPath, '');
      expect(store.deleted, <String>['/app/old.jpg']);
    });
  });
}
