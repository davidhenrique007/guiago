import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// Used as `MaterialApp.builder`: makes `AppColors` follow the theme
/// that is active.
///
/// `AppColors` roles resolve to [AppPalette.current]. Many widgets read
/// them in `build` without depending on `Theme`, so changing the theme
/// alone would leave those on screen with the old colors. When the
/// brightness changes, this rebuilds the whole tree once (state, scroll
/// positions and navigation are kept — it is the same trick Flutter's
/// own docs use for locale changes).
Widget themedAppBuilder(BuildContext context, Widget? child) {
  return PaletteScope(
    brightness: Theme.of(context).brightness,
    child: child ?? const SizedBox.shrink(),
  );
}

class PaletteScope extends StatefulWidget {
  const PaletteScope({
    required this.brightness,
    required this.child,
    super.key,
  });

  final Brightness brightness;
  final Widget child;

  @override
  State<PaletteScope> createState() => _PaletteScopeState();
}

class _PaletteScopeState extends State<PaletteScope> {
  Brightness? _applied;

  static void _rebuildAll(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_rebuildAll);
  }

  @override
  Widget build(BuildContext context) {
    final bool changed = _applied != null && _applied != widget.brightness;
    // Set before the children build, so they read the right palette.
    AppPalette.use(widget.brightness);
    _applied = widget.brightness;
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) (context as Element).visitChildren(_rebuildAll);
      });
    }

    final bool isDark = widget.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: widget.child,
    );
  }
}
