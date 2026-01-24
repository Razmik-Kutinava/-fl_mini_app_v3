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
  final ScrollController? horizontalScrollController; // Общий контроллер для синхронизации

  const CategoryNavigationScrollable({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.onCategoryExpand,
    this.showAll = true,
    this.horizontalScrollController,
  });

  @override
  State<CategoryNavigationScrollable> createState() =>
      _CategoryNavigationScrollableState();
}

class _CategoryNavigationScrollableState
    extends State<CategoryNavigationScrollable> {
  late ScrollController _scrollController;
  final Map<String, GlobalKey> _categoryKeys = {};
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    // Используем внешний контроллер или создаем свой
    _scrollController = widget.horizontalScrollController ?? ScrollController();
    
    // Добавляем listener для синхронизации
    _scrollController.addListener(_onScroll);
    
    print(
      '🚀 [CategoryRow] initState: selectedCategoryId=${widget.selectedCategoryId}, categories count=${widget.categories.length}',
    );
    // Создаем ключи для каждой категории
    _createCategoryKeys();
    // Скроллим к выбранной категории после первого кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  void _onScroll() {
    // При скролле навигации синхронизируем с товарами
    // Это обрабатывается в CategoryCarousel через общий контроллер
  }

  @override
  void didUpdateWidget(CategoryNavigationScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если категории изменились, обновляем ключи
    if (oldWidget.categories.length != widget.categories.length) {
      _createCategoryKeys();
    }
    // Если выбранная категория изменилась, скроллим к ней
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedCategory();
      });
    }
  }

  void _createCategoryKeys() {
    _categoryKeys.clear();
    if (widget.showAll) {
      _categoryKeys['для тебя'] = GlobalKey();
    }
    for (var category in widget.categories) {
      _categoryKeys[category.id] = GlobalKey();
    }
  }

  void _scrollToSelectedCategory() {
    if (!_scrollController.hasClients) return;
    if (_isProgrammaticScroll) return; // Не скроллим если это программный скролл

    GlobalKey? targetKey;
    if (widget.selectedCategoryId == null) {
      targetKey = _categoryKeys['для тебя'];
    } else {
      targetKey = _categoryKeys[widget.selectedCategoryId];
    }

    if (targetKey?.currentContext != null) {
      final RenderBox? renderBox =
          targetKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final screenWidth = MediaQuery.of(context).size.width;
        final categoryCenter = position.dx + (renderBox.size.width / 2);
        final scrollOffset = categoryCenter - (screenWidth / 2);

        _isProgrammaticScroll = true;
        _scrollController.animateTo(
          scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500), // Плавнее
          curve: Curves.easeOutCubic,
        ).then((_) {
          _isProgrammaticScroll = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    // Удаляем только если мы создали контроллер сами
    if (widget.horizontalScrollController == null) {
      _scrollController.dispose();
    }
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
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              if (widget.showAll)
                _CategoryTextItem(
                  key: _categoryKeys['для тебя'],
                  label: 'для тебя',
                  isSelected: widget.selectedCategoryId == null,
                  fontSize: fontSize,
                  spacing: categorySpacing,
                  onTap: () => widget.onCategorySelected(null),
                ),
              ...widget.categories.map((category) {
                final isSelected = widget.selectedCategoryId == category.id;
                return _CategoryTextItem(
                  key: _categoryKeys[category.id],
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
    super.key,
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
