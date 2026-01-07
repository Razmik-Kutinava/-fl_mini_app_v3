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

  /// Получить список всех категорий включая "для тебя"
  List<CategoryItem> _getAllCategories() {
    final items = <CategoryItem>[];
    if (showAll) {
      items.add(CategoryItem(id: null, name: 'для тебя'));
    }
    for (var cat in categories) {
      items.add(CategoryItem(id: cat.id, name: cat.name));
    }
    return items;
  }

  /// Найти индекс текущей выбранной категории
  int _getCurrentIndex() {
    final allCategories = _getAllCategories();
    for (int i = 0; i < allCategories.length; i++) {
      if (allCategories[i].id == selectedCategoryId) {
        return i;
      }
    }
    return 0; // По умолчанию первая ("для тебя")
  }

  /// Переключить на следующую/предыдущую категорию
  void _switchCategory(int direction) {
    // direction: -1 = влево (предыдущая), 1 = вправо (следующая)
    final allCategories = _getAllCategories();
    if (allCategories.isEmpty) return;

    final currentIndex = _getCurrentIndex();
    int newIndex = currentIndex + direction;

    // Ограничиваем границы
    if (newIndex < 0) newIndex = allCategories.length - 1;
    if (newIndex >= allCategories.length) newIndex = 0;

    final newCategory = allCategories[newIndex];
    onCategorySelected(newCategory.id);
  }

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
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          
          // Свайп вправо (отрицательная скорость) -> следующая категория
          if (details.primaryVelocity! < -300) {
            _switchCategory(1); // Следующая
          }
          // Свайп влево (положительная скорость) -> предыдущая категория
          else if (details.primaryVelocity! > 300) {
            _switchCategory(-1); // Предыдущая
          }
        },
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
      ),
    );
  }
}

/// Вспомогательный класс для представления категории
class CategoryItem {
  final String? id;
  final String name;

  CategoryItem({this.id, required this.name});
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

