import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

/// Small reusable UI helpers.
/// Provides a top notification banner similar to iOS transient banners.
class _TopNotification extends StatefulWidget {
  final String message;
  final Duration duration;
  final Duration? autoDismissAfter;
  final VoidCallback onDismiss;
  final bool persistent;

  const _TopNotification({required this.message, required this.duration, this.autoDismissAfter, required this.onDismiss, this.persistent = false});

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<Offset> _animation = Tween(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // Auto-dismiss behavior:
    // - If an explicit autoDismissAfter is provided, use that to dismiss the banner
    //   regardless of the `persistent` flag.
    // - Otherwise, if not persistent, dismiss after `duration`.
    final auto = widget.autoDismissAfter;
    if (auto != null) {
      Future.delayed(auto, () async {
        if (mounted) await _dismiss();
      });
    } else if (!widget.persistent) {
      Future.delayed(widget.duration, () async {
        if (mounted) await _dismiss();
      });
    }
  }

  Future<void> _dismiss() async {
    try {
      await _controller.reverse();
    } catch (_) {}
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Avoid using Positioned here so the notification can be rendered safely
    // both inside an Overlay (which provides a Stack) and other contexts.
    return SafeArea(
      top: true,
      child: SlideTransition(
        position: _animation,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColor.neutralWhite,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(color: AppColor.neutralGrey900, fontSize: 14),
                      ),
                    ),
                    // Note: no close button for persistent banners. Banners should be
                    // toggled programmatically by the caller using the returned OverlayEntry.
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppWidgets {
  static Widget backButton(BuildContext context, VoidCallback onTap) {
    return IconButton(
        padding: EdgeInsets.all(0),
        onPressed: onTap,
        icon: Icon(Icons.arrow_back_ios, color: context.theme.primaryColor,));
  }

  /// Show a transient top notification using an OverlayEntry.
  /// Message will animate from the top and dismiss after [duration].
  /// Show a top notification and return its [OverlayEntry].
  /// Caller may remove the entry to hide the notification.
  static OverlayEntry showTopNotification(BuildContext context, String message, {Duration duration = const Duration(seconds: 6), Duration? autoDismissAfter, bool persistent = false, VoidCallback? onDismissed}) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _TopNotification(
      message: message,
      duration: duration,
      autoDismissAfter: autoDismissAfter,
      persistent: persistent,
      onDismiss: () {
        entry.remove();
        try {
          onDismissed?.call();
        } catch (_) {}
      },
    ));

  overlay.insert(entry);
    return entry;
  }

  /// Convenience helper to hide a previously returned [OverlayEntry].
  static void hideTopNotification(OverlayEntry? entry) {
    try {
      entry?.remove();
    } catch (_) {}
  }
}