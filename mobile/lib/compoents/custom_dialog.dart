import 'package:flutter/material.dart';

enum CustomDialogPosition { center, bottom, top }

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    required this.child,
    this.position = CustomDialogPosition.center,
    this.title,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 16),
    this.borderRadius,
    this.backgroundColor,
    this.maxWidth = 560,
  });

  final CustomDialogPosition position;
  final Widget child;
  final String? title;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? _defaultRadius(position);
    final maxHeight =
        MediaQuery.sizeOf(context).height * _maxHeightFraction(position);

    return Material(
      color:
          backgroundColor ??
          theme.dialogTheme.backgroundColor ??
          theme.colorScheme.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Flexible(child: child),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: action,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius _defaultRadius(CustomDialogPosition position) {
    return switch (position) {
      CustomDialogPosition.center => BorderRadius.circular(20),
      CustomDialogPosition.bottom => const BorderRadius.vertical(
        top: Radius.circular(20),
      ),
      CustomDialogPosition.top => const BorderRadius.vertical(
        bottom: Radius.circular(20),
      ),
    };
  }

  double _maxHeightFraction(CustomDialogPosition position) {
    return switch (position) {
      CustomDialogPosition.center => 0.72,
      CustomDialogPosition.bottom => 0.82,
      CustomDialogPosition.top => 0.72,
    };
  }
}

Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required Widget child,
  CustomDialogPosition position = CustomDialogPosition.center,
  String? title,
  List<Widget> actions = const [],
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 20, 20, 16),
  BorderRadius? borderRadius,
  Color? backgroundColor,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  final dialog = CustomDialog(
    position: position,
    title: title,
    actions: actions,
    padding: padding,
    borderRadius: borderRadius,
    backgroundColor: backgroundColor,
    maxWidth: position == CustomDialogPosition.bottom ? double.infinity : 560,
    child: child,
  );

  switch (position) {
    case CustomDialogPosition.center:
      return showGeneralDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: barrierColor ?? Colors.black54,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Center(child: dialog);
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );

    case CustomDialogPosition.bottom:
      return showModalBottomSheet<T>(
        context: context,
        isDismissible: barrierDismissible,
        enableDrag: barrierDismissible,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: barrierColor ?? Colors.black54,
        builder: (context) => SafeArea(child: dialog),
      );

    case CustomDialogPosition.top:
      return showGeneralDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: barrierColor ?? Colors.black54,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: dialog,
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
  }
}
