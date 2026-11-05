import '../domain/level.dart';

/// Portuguese display names of the level tiers, shared by every
/// screen that shows a level.
extension LevelTierLabel on LevelTier {
  String get label => switch (this) {
        LevelTier.beginner => 'Iniciante',
        LevelTier.consistent => 'Consistente',
        LevelTier.disciplined => 'Disciplinado',
        LevelTier.elite => 'Elite',
      };
}
