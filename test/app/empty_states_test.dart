import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiago/core/services/app_database.dart';
import 'package:guiago/core/services/database_provider.dart';
import 'package:guiago/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:guiago/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:guiago/features/home/presentation/screens/home_screen.dart';
import 'package:guiago/features/insights/presentation/screens/insights_screen.dart';
import 'package:guiago/features/profile/presentation/screens/profile_screen.dart';
import 'package:guiago/features/tasks/presentation/screens/tasks_screen.dart';

/// A brand-new app has no data at all: every tab must render without
/// errors and say what is missing, never show demo values.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pumpEmpty(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Início', (WidgetTester tester) async {
    await pumpEmpty(tester, const HomeScreen());

    expect(find.text('Sem tarefas para hoje'), findsOneWidget);
    expect(find.text('Tudo em dia por agora.'), findsOneWidget);
    expect(find.text('Nada agendado para hoje.'), findsOneWidget);
  });

  testWidgets('Tarefas', (WidgetTester tester) async {
    await pumpEmpty(tester, const TasksScreen());

    expect(find.text('Ainda sem tarefas'), findsOneWidget);
  });

  testWidgets('Calendário', (WidgetTester tester) async {
    await pumpEmpty(tester, const CalendarScreen());

    expect(find.text('Sem tarefas neste dia'), findsOneWidget);
  });

  testWidgets('Progresso', (WidgetTester tester) async {
    await pumpEmpty(tester, const DashboardScreen());

    expect(find.text('TAXA DE CUMPRIMENTO'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('Insights', (WidgetTester tester) async {
    await pumpEmpty(tester, const InsightsScreen());

    expect(find.text('Ainda sem dados suficientes'), findsOneWidget);
    expect(find.text('Ainda sem tarefas concluídas'), findsOneWidget);
  });

  testWidgets('Perfil', (WidgetTester tester) async {
    await pumpEmpty(tester, const ProfileScreen());

    expect(find.text('Perfil'), findsWidgets);
  });
}
