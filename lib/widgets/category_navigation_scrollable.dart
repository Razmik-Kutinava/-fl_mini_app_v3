import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart' as models;
import '../utils/responsive.dart';

/// Навигация по категориям внутри скроллируемого контента
/// Полупрозрачный черный фон, только текст, без кнопок
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
  final ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0.0;
  DateTime _lastScrollTime = DateTime.now();

  /// Получить список всех категорий включая "для тебя"
  List<CategoryItem> _getAllCategories() {
    final items = <CategoryItem>[];
    if (widget.showAll) {
      items.add(CategoryItem(id: null, name: 'для тебя'));
    }
    for (var cat in widget.categories) {
      items.add(CategoryItem(id: cat.id, name: cat.name));
    }
    return items;
  }

  /// Найти индекс текущей выбранной категории
  int _getCurrentIndex() {
    final allCategories = _getAllCategories();
    for (int i = 0; i < allCategories.length; i++) {
      if (allCategories[i].id == widget.selectedCategoryId) {
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
    widget.onCategorySelected(newCategory.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Отслеживаем быстрые свайпы для переключения категорий
            if (notification is ScrollUpdateNotification) {
              final now = DateTime.now();
              final timeDelta = now.difference(_lastScrollTime).inMilliseconds;
              final positionDelta =
                  (_scrollController.position.pixels - _lastScrollPosition)
                      .abs();

              // Если скролл очень быстрый (большое смещение за короткое время)
              // это может быть свайп для переключения категории
              if (timeDelta > 0 && timeDelta < 100) {
                final velocity = positionDelta / timeDelta * 1000; // пикселей в секунду
                if (velocity > 1000) {
                  // Очень быстрый скролл - возможен свайп для переключения
                  // Но не обрабатываем здесь, чтобы не конфликтовать с обычным скроллом
                }
              }

              _lastScrollPosition = _scrollController.position.pixels;
              _lastScrollTime = now;
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            physics: const BouncingScrollPhysics(),
            itemCount: widget.categories.length + (widget.showAll ? 1 : 0),
            itemBuilder: (context, index) {
              if (widget.showAll && index == 0) {
                final isSelected = widget.selectedCategoryId == null;
                return _CategoryTextItem(
                  label: 'для тебя',
                  isSelected: isSelected,
                  fontSize: fontSize,
                  spacing: categorySpacing,
                  onTap: () => widget.onCategorySelected(null),
                );
              }

              final categoryIndex = widget.showAll ? index - 1 : index;
              final category = widget.categories[categoryIndex];
              final isSelected = widget.selectedCategoryId == category.id;

              return _CategoryTextItem(
                label: category.name,
                isSelected: isSelected,
                fontSize: fontSize,
                spacing: categorySpacing,
                onTap: () => widget.onCategorySelected(category.id),
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
