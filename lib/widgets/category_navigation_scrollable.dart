import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart' as models;
import '../utils/responsive.dart';

/// Навигация по категориям внутри скроллируемого контента
/// Полупрозрачный черный фон, только текст, без кнопок
class CategoryNavigationScrollable extends StatelessWidget {
  final List<models.Category> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;
  final bool showAll;

  const CategoryNavigationScrollable({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: логируем количество категорий
    print('🔍 CategoryNavigationScrollable: categories.length=${categories.length}');
    print('🔍 CategoryNavigationScrollable: showAll=$showAll');
    print('🔍 CategoryNavigationScrollable: selectedCategoryId=$selectedCategoryId');
    for (var cat in categories) {
      print('🔍 Category: id=${cat.id}, name=${cat.name}');
    }
    
    // Адаптивные размеры
    final fontSize = Responsive.responsiveSize(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );
    
    final height = Responsive.responsiveSize(
      context,
      mobile: 50.0,
      tablet: 55.0,
      desktop: 60.0,
    );

    final horizontalPadding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    final categorySpacing = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    return SliverToBoxAdapter(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          itemCount: categories.length + (showAll ? 1 : 0),
          itemBuilder: (context, index) {
            if (showAll && index == 0) {
              final isSelected = selectedCategoryId == null;
              return _CategoryTextItem(
                label: 'для тебя',
                isSelected: isSelected,
                fontSize: fontSize,
                spacing: categorySpacing,
                onTap: () => onCategorySelected(null),
              );
            }

            final categoryIndex = showAll ? index - 1 : index;
            final category = categories[categoryIndex];
            final isSelected = selectedCategoryId == category.id;

            return _CategoryTextItem(
              label: category.name,
              isSelected: isSelected,
              fontSize: fontSize,
              spacing: categorySpacing,
              onTap: () => onCategorySelected(category.id),
            );
          },
        ),
      ),
    );
  }
}

/// Текстовый элемент категории без видимых кнопок/рамок
class _CategoryTextItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final double fontSize;
  final double spacing;
  final VoidCallback onTap;

  const _CategoryTextItem({
    required this.label,
    required this.isSelected,
    required this.fontSize,
    required this.spacing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onHorizontalDragEnd: (details) {
        // Свайп вправо - открываем категорию (если это категория с товарами, не "для тебя")
        if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
          // Свайп вправо (отрицательная скорость)
          onTap();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(right: spacing),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

