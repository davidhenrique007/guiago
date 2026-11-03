import 'package:flutter/painting.dart';

/// GuiaGo elevation tokens. The product is flat and bordered by
/// default (master spec §7) — depth is reserved for the one primary
/// floating action, which gets a soft emerald glow.
abstract final class AppElevation {
  static const List<BoxShadow> none = <BoxShadow>[];

  static const List<BoxShadow> fab = <BoxShadow>[
    BoxShadow(
      color: Color(0x802FBF83),
      blurRadius: 28,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];
}
