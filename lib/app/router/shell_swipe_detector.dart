import 'package:flutter/material.dart';

/// Lets the user move between the main tabs by swiping sideways.
///
/// Swiping left goes to the next tab and swiping right to the previous
/// one; the first and last tabs do not wrap around. Only a quick flick
/// counts ([minVelocity]), so slow drags and taps are left alone.
///
/// Horizontal scrollables placed inside [child] compete for the same
/// gesture and, being deeper in the tree, win it — so a future
/// sideways-scrolling widget keeps working without any change here.
class ShellSwipeDetector extends StatelessWidget {
  const ShellSwipeDetector({
    required this.currentIndex,
    required this.itemCount,
    required this.onChanged,
    required this.child,
    this.enabled = true,
    this.minVelocity = 300,
    super.key,
  });

  final int currentIndex;
  final int itemCount;
  final ValueChanged<int> onChanged;
  final Widget child;

  /// False while a tab shows a nested screen (e.g. Insights), where a
  /// swipe must not throw the user out of it.
  final bool enabled;

  /// Minimum horizontal speed, in logical pixels per second.
  final double minVelocity;

  void _onDragEnd(DragEndDetails details) {
    if (!enabled) return;
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < minVelocity) return;

    final int target = velocity < 0 ? currentIndex + 1 : currentIndex - 1;
    if (target < 0 || target >= itemCount) return;
    onChanged(target);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: _onDragEnd,
      child: child,
    );
  }
}
