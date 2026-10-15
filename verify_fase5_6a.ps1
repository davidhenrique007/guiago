# GuiaGo — verifica se os ficheiros da Fase 5 + 6A estão no sítio
# certo, com o conteúdo certo. Corre a partir da raiz do projeto:
#   .\verify_fase5_6a.ps1

$root = Get-Location
$checks = @(
    # path relativo                                                                  padrão que TEM de aparecer no ficheiro
    @{ Path = "lib\features\performance\application\performance_controller.dart";     Pattern = "static const int _recentWindowDays" },
    @{ Path = "lib\features\performance\data\occurrence_outcome_mapper.dart";         Pattern = "day.year, day.month, day.day \+ 1" },
    @{ Path = "lib\features\scheduler\data\scheduler_providers.dart";                 Pattern = "final PerformanceController performanceController" },
    @{ Path = "lib\features\dashboard\domain\dashboard_period.dart";                  Pattern = "enum DashboardPeriod" },
    @{ Path = "lib\features\dashboard\domain\trend_point.dart";                       Pattern = "class TrendPoint" },
    @{ Path = "lib\features\dashboard\domain\dashboard_snapshot.dart";                Pattern = "class DashboardSnapshot" },
    @{ Path = "lib\features\dashboard\application\trend_engine.dart";                 Pattern = "class TrendEngine" },
    @{ Path = "lib\features\dashboard\application\dashboard_service.dart";            Pattern = "class DashboardService" },
    @{ Path = "lib\features\dashboard\application\dashboard_controller.dart";         Pattern = "class DashboardController" },
    @{ Path = "lib\features\dashboard\data\dashboard_providers.dart";                 Pattern = "dashboardServiceProvider" },
    @{ Path = "test\features\performance\support\in_memory_repositories.dart";        Pattern = "class InMemoryTaskOccurrenceRepository" },
    @{ Path = "test\features\performance\application\performance_controller_test.dart"; Pattern = "onOccurrenceResolved" },
    @{ Path = "test\features\dashboard\domain\dashboard_period_test.dart";            Pattern = "DashboardPeriod.rangeAt" },
    @{ Path = "test\features\dashboard\application\trend_engine_test.dart";           Pattern = "TrendEngine.calculate" },
    @{ Path = "test\features\dashboard\application\dashboard_service_test.dart";      Pattern = "DashboardService" },
    @{ Path = "lib\design_system\components\app_metric_card.dart";                    Pattern = "class AppMetricCard" },
    @{ Path = "lib\design_system\components\app_trend_chart.dart";                    Pattern = "class AppTrendChart" },
    @{ Path = "lib\design_system\design_system.dart";                                 Pattern = "app_trend_chart.dart" },
    @{ Path = "lib\features\dashboard\presentation\widgets\dashboard_period_selector.dart"; Pattern = "class DashboardPeriodSelector" },
    @{ Path = "lib\features\dashboard\presentation\widgets\dashboard_metrics_grid.dart";    Pattern = "class DashboardMetricsGrid" },
    @{ Path = "lib\features\dashboard\presentation\widgets\dashboard_trend_section.dart";   Pattern = "class DashboardTrendSection" },
    @{ Path = "lib\features\dashboard\presentation\screens\dashboard_screen.dart";     Pattern = "class DashboardScreen" },
    @{ Path = "lib\app\router\app_routes.dart";                                       Pattern = "dashboardName" },
    @{ Path = "lib\app\router\app_router.dart";                                       Pattern = "HomeScreen" },
    @{ Path = "test\features\dashboard\presentation\dashboard_screen_test.dart";      Pattern = "overrides: \[appDatabaseProvider" },
    @{ Path = "lib\features\home\domain\today_task_item.dart";                        Pattern = "class TodayTaskItem" },
    @{ Path = "lib\features\home\domain\home_snapshot.dart";                          Pattern = "class HomeSnapshot" },
    @{ Path = "lib\features\home\application\home_service.dart";                      Pattern = "class HomeService" },
    @{ Path = "lib\features\home\application\home_controller.dart";                   Pattern = "class HomeController" },
    @{ Path = "lib\features\home\data\home_providers.dart";                           Pattern = "homeServiceProvider" },
    @{ Path = "lib\features\home\presentation\widgets\home_greeting.dart";            Pattern = "class HomeGreeting" },
    @{ Path = "lib\features\home\presentation\widgets\home_progress_card.dart";       Pattern = "class HomeProgressCard" },
    @{ Path = "lib\features\home\presentation\widgets\home_next_task_card.dart";      Pattern = "class HomeNextTaskCard" },
    @{ Path = "lib\features\home\presentation\widgets\home_today_list.dart";          Pattern = "class HomeTodayList" },
    @{ Path = "lib\features\home\presentation\screens\home_screen.dart";              Pattern = "class HomeScreen" },
    @{ Path = "test\features\home\presentation\home_screen_test.dart";                Pattern = "DASHBOARD" },
    @{ Path = "test\features\home\support\in_memory_repositories.dart";               Pattern = "class InMemoryTaskRepository" },
    @{ Path = "test\features\home\application\home_service_test.dart";                Pattern = "joins today" },
    @{ Path = "lib\features\tasks\presentation\widgets\task_create_priority_selector.dart"; Pattern = "class TaskCreatePrioritySelector" },
    @{ Path = "lib\features\tasks\presentation\widgets\task_create_selector_chip.dart";     Pattern = "class SelectorChip" },
    @{ Path = "lib\features\tasks\presentation\widgets\task_create_recurrence_selector.dart"; Pattern = "class TaskCreateRecurrenceSelector" },
    @{ Path = "lib\features\tasks\presentation\screens\task_create_screen.dart";      Pattern = "class TaskCreateScreen" },
    @{ Path = "lib\app\router\app_routes.dart";                                       Pattern = "taskCreateName" },
    @{ Path = "lib\app\router\app_router.dart";                                       Pattern = "TaskCreateScreen" },
    @{ Path = "lib\features\home\presentation\screens\home_screen.dart";              Pattern = "taskCreateName" },
    @{ Path = "test\features\tasks\presentation\task_create_screen_test.dart";        Pattern = "creates the task and returns" }
)

$badLocations = @(
    "lib\features\dashboard\data\in_memory_repositories.dart",
    "test\features\dashboard\dashboard_service_test.dart",
    "test\features\dashboard\dashboard_period_test.dart",
    "test\features\dashboard\trend_engine_test.dart"
)

Write-Host "`n=== Ficheiros esperados ===" -ForegroundColor Cyan
$missing = 0
$wrongContent = 0
foreach ($c in $checks) {
    $full = Join-Path $root $c.Path
    if (-not (Test-Path $full)) {
        Write-Host "FALTA:    $($c.Path)" -ForegroundColor Red
        $missing++
        continue
    }
    $match = Select-String -Path $full -Pattern $c.Pattern -Quiet
    if ($match) {
        Write-Host "OK:       $($c.Path)" -ForegroundColor Green
    } else {
        Write-Host "CONTEÚDO ERRADO: $($c.Path) (não contém '$($c.Pattern)' — provavelmente é a versão antiga)" -ForegroundColor Yellow
        $wrongContent++
    }
}

Write-Host "`n=== Ficheiros que NÃO deviam existir (sítio errado) ===" -ForegroundColor Cyan
$stray = 0
foreach ($p in $badLocations) {
    $full = Join-Path $root $p
    if (Test-Path $full) {
        Write-Host "APAGAR:   $p" -ForegroundColor Red
        $stray++
    }
}
if ($stray -eq 0) { Write-Host "(nenhum encontrado)" -ForegroundColor Green }

Write-Host "`n=== Resumo ===" -ForegroundColor Cyan
Write-Host "Em falta: $missing | Conteúdo errado: $wrongContent | Ficheiros a mais: $stray"