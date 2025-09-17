import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant/AppColor.dart';

enum ModernButtonStyle {
  primary,
  secondary,
  outline,
  ghost,
  gradient,
}

enum ModernButtonSize {
  small,
  medium,
  large,
}

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonStyle style;
  final ModernButtonSize size;
  final Widget? icon;
  final bool loading;
  final bool disabled;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = ModernButtonStyle.primary,
    this.size = ModernButtonSize.medium,
    this.icon,
    this.loading = false,
    this.disabled = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  this.textStyle,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.disabled && !widget.loading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _resetState();
  }

  void _onTapCancel() {
    _resetState();
  }

  void _resetState() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.disabled && !widget.loading && widget.onPressed != null;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: isEnabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width,
              height: widget.height ?? _getButtonHeight(),
              padding: widget.padding ?? _getButtonPadding(),
              decoration: _getButtonDecoration(context, isEnabled),
              child: _buildButtonContent(context),
            ),
          ),
        );
      },
    );
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return 40;
      case ModernButtonSize.medium:
        return 48;
      case ModernButtonSize.large:
        return 56;
    }
  }

  EdgeInsetsGeometry _getButtonPadding() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ModernButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ModernButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  BoxDecoration _getButtonDecoration(BuildContext context, bool isEnabled) {
    final isDark = context.theme.brightness == Brightness.dark;
    final opacity = isEnabled ? 1.0 : 0.5;
    
    switch (widget.style) {
      case ModernButtonStyle.primary:
        return BoxDecoration(
          gradient: isEnabled 
            ? AppColor.primaryGradient
            : LinearGradient(
                colors: [
                  AppColor.primaryOrange.withOpacity(opacity),
                  AppColor.primaryGreenLight.withOpacity(opacity),
                ],
              ),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          boxShadow: isEnabled && !_isPressed ? [
            BoxShadow(
              color: AppColor.primaryOrange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        );
        
      case ModernButtonStyle.secondary:
        return BoxDecoration(
          color: (isDark ? AppColor.darkCard : AppColor.neutralGrey100)
              .withOpacity(opacity),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? AppColor.darkBorder : AppColor.neutralGrey300)
                .withOpacity(opacity),
            width: 1,
          ),
        );
        
      case ModernButtonStyle.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: AppColor.primaryOrange.withOpacity(opacity),
            width: 2,
          ),
        );
        
      case ModernButtonStyle.ghost:
        return BoxDecoration(
          color: _isPressed 
            ? AppColor.primaryOrange.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        );
        
      case ModernButtonStyle.gradient:
        return BoxDecoration(
          gradient: isEnabled 
            ? AppColor.accentGradient
            : LinearGradient(
                colors: [
                  AppColor.accentOrange.withOpacity(opacity),
                  AppColor.accentOrangeLight.withOpacity(opacity),
                ],
              ),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          boxShadow: isEnabled && !_isPressed ? [
            BoxShadow(
              color: AppColor.accentOrange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        );
    }
  }

  Widget _buildButtonContent(BuildContext context) {
    final textColor = _getTextColor(context);
  final effectiveTextStyle = (widget.textStyle ?? _getTextStyle(context)).copyWith(color: textColor);

    if (widget.loading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    final children = <Widget>[];
    final textDirection = Directionality.of(context);

    if (widget.icon != null && textDirection == TextDirection.ltr) {
      children.add(widget.icon!);
      children.add(const SizedBox(width: 8));
    }

    children.add(
      Text(
        widget.text,
        style: effectiveTextStyle,
        textAlign: TextAlign.center,
      ),
    );

    if (widget.icon != null && textDirection == TextDirection.rtl) {
      children.add(const SizedBox(width: 8));
      children.add(widget.icon!);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  Color _getTextColor(BuildContext context) {
    final isEnabled = !widget.disabled && !widget.loading;
    final opacity = isEnabled ? 1.0 : 0.5;
    
    switch (widget.style) {
      case ModernButtonStyle.primary:
      case ModernButtonStyle.gradient:
        return AppColor.neutralWhite.withOpacity(opacity);
        
      case ModernButtonStyle.secondary:
        return context.theme.primaryColor.withOpacity(opacity);
        
      case ModernButtonStyle.outline:
      case ModernButtonStyle.ghost:
        return AppColor.primaryOrange.withOpacity(opacity);
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    switch (widget.size) {
      case ModernButtonSize.small:
        return context.textTheme.labelMedium!;
      case ModernButtonSize.medium:
        return context.textTheme.labelLarge!;
      case ModernButtonSize.large:
        return context.textTheme.titleMedium!;
    }
  }
}
