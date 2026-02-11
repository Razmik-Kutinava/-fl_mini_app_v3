import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/menu_provider.dart';
import 'package:provider/provider.dart';
import 'tablet_top_bar.dart';
import 'tablet_categories_sidebar.dart';
import 'tablet_products_panel.dart';
import 'tablet_bottom_cart_bar.dart';
import 'tablet_terminal_footer.dart';

/// Полный layout для планшетной/веб версии
class TabletLayout extends StatelessWidget {
  const TabletLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final selectedCategoryId = menuProvider.selectedCategoryId;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(
          color: AppColors.borderGlow,
          width: 2,
        ),
        boxShadow: AppColors.neonGlowStrong,
      ),
      child: Column(
        children: [
          // Верхняя панель
          const TabletTopBar(),
          
          // Основной контент
          Expanded(
            child: Row(
              children: [
                // Сайдбар категорий
                TabletCategoriesSidebar(
                  selectedCategoryId: selectedCategoryId,
                  onCategorySelected: (categoryId) {
                    menuProvider.selectCategory(categoryId);
                  },
                ),
                
                // Панель товаров
                Expanded(
                  child: TabletProductsPanel(
                    selectedCategoryId: selectedCategoryId,
                    onCategoryChanged: (categoryId) {
                      menuProvider.selectCategory(categoryId);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Нижняя панель корзины
          const TabletBottomCartBar(),
          
          // Терминальная строка
          TabletTerminalFooter(
            selectedCategoryId: selectedCategoryId,
          ),
        ],
      ),
    );
  }
}
