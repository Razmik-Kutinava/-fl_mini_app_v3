import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart' as models;
import '../utils/responsive.dart';

/// Навигация по категориям внутри скроллируемого контента
/// Полупрозрачный черный фон, только текст, без кнопок
/// ИЗМЕНЕНО: теперь без горизонтального скролла - просто Row
class CategoryNavigationScrollable extends StatefulWidget {
  final List<models.Category> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;
  final Function(String?)? onCategoryExpand;
  final bool showAll;

  const CategoryNavigationScrollable({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.onCategoryExpand,
    this.showAll = true,
  });

  @override
  State<CategoryNavigationScrollable> createState() =>
      _CategoryNavigationScrollableState();
}

class _CategoryNavigationScrollableState
    extends State<CategoryNavigationScrollable> {
  @override
  void initState() {
    super.initState();
    print(
      '🚀 [CategoryRow] initState: selectedCategoryId=${widget.selectedCategoryId}, categories count=${widget.categories.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              if (widget.showAll)
                _CategoryTextItem(
                  label: 'для тебя',
                  isSelected: widget.selectedCategoryId == null,
                  fontSize: fontSize,
                  spacing: categorySpacing,
                  onTap: () => widget.onCategorySelected(null),
                ),
              ...widget.categories.map((category) {
                final isSelected = widget.selectedCategoryId == category.id;
                return _CategoryTextItem(
                  label: category.name,
                  isSelected: isSelected,
                  fontSize: fontSize,
                  spacing: categorySpacing,
                  onTap: () => widget.onCategorySelected(category.id),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Текстовый элемент категории - ТОЛЬКО onTap, БЕЗ обработки свайпов
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
    // Используем InkWell вместо GestureDetector для лучшей обработки тапов
    // НЕ обрабатываем горизонтальные жесты здесь!
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: spacing),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
