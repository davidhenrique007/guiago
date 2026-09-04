/// Derives a stable, positive 32-bit int alarm ID from an
/// occurrence's UUID string.
///
/// `flutter_local_notifications` needs a platform-native int ID per
/// notification. This is a pure djb2-style hash — deliberately NOT
/// Dart's built-in `String.hashCode`, since that isn't guaranteed
/// stable across Dart/Flutter versions, and this ID gets persisted
/// in [AlarmRecord] and must resolve the same way if ever
/// recomputed (it normally isn't — see ADR-006).
abstract final class AlarmIdGenerator {
  static int fromOccurrenceId(String occurrenceId) {
    int hash = 5381;
    for (final int codeUnit in occurrenceId.codeUnits) {
      hash = ((hash << 5) + hash) + codeUnit; // hash * 33 + c
      hash &= 0x7FFFFFFF; // keep it a positive 31-bit int
    }
    return hash;
  }
}
