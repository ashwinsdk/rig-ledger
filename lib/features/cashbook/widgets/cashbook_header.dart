import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/platform_helper.dart';

/// Header for Account Ledger root screens: gradient on mobile, slim with a
/// bottom border on desktop (same rule as AdaptiveHeader, but accepts a
/// widget title such as the book selector).
class CashHeader extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final List<Widget> actions;

  const CashHeader({
    super.key,
    this.leading,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final desktop = PlatformHelper.isDesktop;
    final fg = desktop ? AppColors.textPrimary : Colors.white;
    final row = Padding(
      padding: EdgeInsets.symmetric(
          horizontal: desktop ? 16 : 8, vertical: desktop ? 8 : 10),
      child: IconTheme(
        data: IconThemeData(color: fg),
        child: DefaultTextStyle(
          style: TextStyle(
              color: fg,
              fontSize: desktop ? 18 : 20,
              fontWeight: FontWeight.w600),
          child: Row(
            children: [
              if (leading != null) leading!,
              Expanded(child: title),
              ...actions,
            ],
          ),
        ),
      ),
    );
    if (desktop) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: row,
      );
    }
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
      child: SafeArea(bottom: false, child: row),
    );
  }
}
