import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 新拟态容器组件
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isPressed;
  final bool isDark;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.isPressed = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final shadowLight = isDark
        ? AppColors.darkShadowLight
        : AppColors.lightShadowLight;
    final shadowDark = isDark
        ? AppColors.darkShadowDark
        : AppColors.lightShadowDark;

    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                // 凹陷效果
                BoxShadow(
                  color: shadowDark,
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: shadowLight,
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: -2,
                ),
              ]
            : [
                // 凸起效果
                BoxShadow(
                  color: shadowLight,
                  offset: const Offset(-4, -4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: shadowDark,
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// 新拟态按钮组件
class NeumorphicButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isDark;

  const NeumorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 12,
    this.padding,
    this.isDark = false,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: NeumorphicContainer(
        isPressed: _isPressed,
        isDark: widget.isDark,
        padding: widget.padding ?? const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        borderRadius: widget.borderRadius,
        child: widget.child,
      ),
    );
  }
}

/// 新拟态图标按钮
class NeumorphicIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final Color? iconColor;
  final bool isDark;

  const NeumorphicIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 24,
    this.iconColor,
    this.isDark = false,
  });

  @override
  State<NeumorphicIconButton> createState() => _NeumorphicIconButtonState();
}

class _NeumorphicIconButtonState extends State<NeumorphicIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: NeumorphicContainer(
        isPressed: _isPressed,
        isDark: widget.isDark,
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        child: Icon(
          widget.icon,
          size: widget.size,
          color: widget.iconColor ??
              (widget.isDark
                  ? AppColors.darkPrimary
                  : AppColors.lightPrimary),
        ),
      ),
    );
  }
}
