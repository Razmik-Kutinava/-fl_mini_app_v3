import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/menu_provider.dart';
import 'package:provider/provider.dart';

/// Терминальная строка внизу для планшетной версии
class TabletTerminalFooter extends StatelessWidget {
  final String? selectedCategoryId;

  const TabletTerminalFooter({
    super.key,
    required this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final now = DateTime.now();
    final syncTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    final categoryName = selectedCategoryId == null
        ? 'all'
        : menuProvider.categories
            .firstWhere(
              (c) => c.id == selectedCategoryId,
              orElse: () => menuProvider.categories.first,
            )
            .name
            .toLowerCase()
            .replaceAll(' ', '-');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '\$ ./coffee --tablet --category=$categoryName',
            style: AppTextStyles.tabletTerminal(),
          ),
          Text(
            'ПОСЛ. СИНХР: $syncTime',
            style: AppTextStyles.tabletTerminal(AppColors.accent),
          ),
        ],
      ),
    );
  }
}
