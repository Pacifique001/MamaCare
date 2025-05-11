import 'package:flutter/material.dart';

class MamaCareAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? trailing;
  final String title;
  final TextStyle? titleStyle;
  final Color? backgroundColor;
  final Color? textColor;
  final bool centerTitle;
  final double elevation;
  final List<BoxShadow>? shadow;
  final EdgeInsetsGeometry? trailingPadding;
  final Widget? trailingWidget;
  final bool automaticallyImplyLeading;

  const MamaCareAppBar({
    super.key,
    this.leading,
    this.actions,
    this.trailing,
    required this.title,
    this.backgroundColor = Colors.transparent,
    this.textColor,
    this.centerTitle = true,
    this.elevation = 0,
    this.shadow,
    this.trailingPadding = const EdgeInsets.all(8.0),
    this.trailingWidget,
    this.automaticallyImplyLeading = true,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge?.copyWith(
      color: textColor ?? theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    return Container(
      decoration: BoxDecoration(boxShadow: shadow),
      child: AppBar(
        leading: leading,
        title: Text(
          title,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: [
          if (trailing != null)
            Padding(padding: trailingPadding!, child: trailing!),
        ],
        backgroundColor: backgroundColor,
        centerTitle: centerTitle,
        elevation: elevation,
        iconTheme: IconThemeData(
          color: textColor ?? theme.colorScheme.onSurface,
        ),
        toolbarTextStyle: textStyle,
        titleTextStyle: textStyle,
        surfaceTintColor: Colors.transparent,
        //automaticallyImplyLeading: leading != null,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
