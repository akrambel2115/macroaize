import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';

class _TopNotification extends StatefulWidget {
  final String message;
  final Duration duration;
  final Duration? autoDismissAfter;
  final VoidCallback onDismiss;
  final bool persistent;

  const _TopNotification({
    required this.message,
    required this.duration,
    this.autoDismissAfter,
    required this.onDismiss,
    this.persistent = false,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<Offset> _animation = Tween(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // auto dismiss handling
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
    // safe in overlay
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColor.neutralWhite,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: AppColor.neutralGrey900,
                          fontSize: 14,
                        ),
                      ),
                    ),
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
      padding: EdgeInsets.zero,
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          onTap();
        }
      },
      icon: Icon(Icons.arrow_back_ios, color: context.theme.primaryColor),
    );
  }

  // show top notification
  static OverlayEntry showTopNotification(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 6),
    Duration? autoDismissAfter,
    bool persistent = false,
    VoidCallback? onDismissed,
  }) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => _TopNotification(
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
          ),
    );

    overlay.insert(entry);
    return entry;
  }

  // hide notification
  static void hideTopNotification(OverlayEntry? entry) {
    try {
      entry?.remove();
    } catch (_) {}
  }
}
