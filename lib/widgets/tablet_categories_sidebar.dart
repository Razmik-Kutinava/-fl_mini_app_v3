import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/menu_provider.dart';
import 'package:provider/provider.dart';

/// Сайдбар категорий для планшетной версии
class TabletCategoriesSidebar extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const TabletCategoriesSidebar({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final categories = menuProvider.categories;
    
    // Получаем количество товаров для каждой категории
    final categoryCounts = <String?, int>{};
    // "для тебя" - все товары
    categoryCounts[null] = menuProvider.allProducts.length;
    for (var category in categories) {
      final count = menuProvider.allProducts
          .where((p) => p.categoryId == category.id)
          .length;
      categoryCounts[category.id] = count;
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(
          right: BorderSide(
            color: AppColors.borderGlow,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок категорий
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.sidebarBackground,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderPrimary,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              '⎇ КАТЕГОРИИ',
              style: AppTextStyles.tabletCategoryLabel(),
            ),
          ),
          
          // Список категорий
          Expanded(
            child: ListView.builder(
              itemCount: categories.length + 1, // +1 для "для тебя"
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Первая категория - "для тебя"
                  final isActive = selectedCategoryId == null;
                  final count = categoryCounts[null] ?? 0;
                  
                  return _CategoryItem(
                    categoryName: 'ДЛЯ ТЕБЯ',
                    categoryId: null,
                    emoji: '⭐',
                    count: count,
                    isActive: isActive,
                    onTap: () => onCategorySelected(null),
                  );
                }
                
                final category = categories[index - 1];
                final isActive = selectedCategoryId == category.id;
                final count = categoryCounts[category.id] ?? 0;
                
                return _CategoryItem(
                  categoryName: category.name,
                  categoryId: category.id,
                  emoji: category.emoji.isNotEmpty ? category.emoji : '☕',
                  count: count,
                  isActive: isActive,
                  onTap: () => onCategorySelected(category.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final String categoryName;
  final String? categoryId;
  final String emoji;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.categoryName,
    required this.categoryId,
    required this.emoji,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.isActive 
                ? AppColors.categoryActiveGradient 
                : null,
            color: widget.isActive 
                ? null 
                : (_isHovered ? AppColors.hoverBackground : Colors.transparent),
            border: Border.all(
              color: widget.isActive 
                  ? AppColors.borderGlow 
                  : AppColors.borderPrimary,
              width: 1,
            ),
            boxShadow: widget.isActive ? AppColors.neonGlow : null,
          ),
          child: Stack(
            children: [
              // Индикатор активной категории слева
              if (widget.isActive)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: AppColors.borderGlow,
                  ),
                ),
              
              // Контент категории
              Row(
                children: [
                  // Иконка категории (эмодзи или символ)
                  Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 16),
                  
                  // Название категории
                  Expanded(
                    child: Text(
                      widget.categoryName.toUpperCase(),
                      style: AppTextStyles.h3(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Счетчик товаров
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.05),
                      border: Border.all(
                        color: AppColors.borderPrimary,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      '${widget.count}',
                      style: AppTextStyles.bodyTiny(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
