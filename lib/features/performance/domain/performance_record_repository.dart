// GuiaGo — Fase 5: Performance Engine + Gamification
// Interface de repositório (secção 5: Domain não pode depender
// de SQLite/Drift — só a implementação em data/ conhece isso).

import '../../../core/result/result.dart';
import 'performance_record.dart';

abstract interface class PerformanceRecordRepository {
  Future<Result<PerformanceRecord>> saveRecord(PerformanceRecord record);

  Future<Result<List<PerformanceRecord>>> getRecordsInRange(
    DateTime periodStart,
    DateTime periodEnd,
  );
}
