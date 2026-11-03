import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Flutter auto-loads this for every test in `test/`. Without this,
/// `GoogleFonts.fraunces(...) / ibmPlexSans(...)` (used throughout the design system)
/// would try to fetch the font over the network on every test run —
/// slow and flaky in CI. This makes it fall back to the platform
/// default font instead, which is all a layout/logic test needs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
