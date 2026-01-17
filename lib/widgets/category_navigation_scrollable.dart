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
  final ScrollController? horizontalScrollController;
  final ScrollController? productsScrollController;

  const CategoryNavigationScrollable({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.onCategoryExpand,
    this.showAll = true,
    this.horizontalScrollController,
    this.productsScrollController,
  });

  @override
  State<CategoryNavigationScrollable> createState() =>
      _CategoryNavigationScrollableState();
}

class _CategoryNavigationScrollableState
    extends State<CategoryNavigationScrollable> {
  late ScrollController _scrollController;
  String? _lastSelectedCategoryId;
  bool _isScrolling = false;
  bool _isProgrammaticScroll = false;

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

  @override
  void initState() {
    super.initState();
    // Используем внешний контроллер, если он предоставлен, иначе создаем свой
    _scrollController = widget.horizontalScrollController ?? ScrollController();
    _lastSelectedCategoryId = widget.selectedCategoryId;
    print(
      '🚀 [CategoryScroll] initState: selectedCategoryId=${widget.selectedCategoryId}, categories count=${widget.categories.length}, using external controller: ${widget.horizontalScrollController != null}',
    );

    // Добавляем listener на ScrollController для отслеживания скролла
    _scrollController.addListener(_onScroll);
    print('✅ [CategoryScroll] ScrollController listener added');
  }

  @override
  void didUpdateWidget(CategoryNavigationScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Если selectedCategoryId изменился извне (не из скролла), прокручиваем к категории
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId &&
        !_isScrolling &&
        widget.selectedCategoryId != _lastSelectedCategoryId) {
      _scrollToSelectedCategory();
    }
  }

  /// Обработчик скролла - определяет центральную категорию и переключает товары
  void _onScroll() {
    if (!_scrollController.hasClients || _isProgrammaticScroll) return;

    _isScrolling = true;
    final pixels = _scrollController.position.pixels;
    print('🔄 [CategoryScroll] _onScroll: pixels=$pixels');

    // Отменяем предыдущий таймер если был
    // Используем таймер для определения окончания скролла
    // так как ScrollEndNotification может не срабатывать надежно
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || !_scrollController.hasClients) return;
      if (_isProgrammaticScroll) return;

      // Проверяем, остановился ли скролл (позиция не изменилась)
      final currentPixels = _scrollController.position.pixels;
      if ((currentPixels - pixels).abs() < 1.0) {
        print('🛑 [CategoryScroll] Scroll stopped at: $currentPixels');
        _updateCategoryFromScroll();
        _isScrolling = false;
      }
    });
  }

  /// Обновляет категорию на основе текущей позиции скролла
  void _updateCategoryFromScroll() {
    print('🔍 [CategoryScroll] _updateCategoryFromScroll() called');
    if (!_scrollController.hasClients) {
      print('❌ [CategoryScroll] No clients');
      return;
    }
    if (_isProgrammaticScroll) {
      print('❌ [CategoryScroll] Programmatic scroll, skipping');
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final scrollPosition = _scrollController.position.pixels;
    final centerPosition = scrollPosition + (screenWidth / 2);

    print(
      '📊 [CategoryScroll] screenWidth: $screenWidth, scrollPosition: $scrollPosition, centerPosition: $centerPosition',
    );

    // Вычисляем индекс категории в центре
    final categoryIndex = _getCategoryIndexAtCenter(centerPosition);
    print('📊 [CategoryScroll] Calculated categoryIndex: $categoryIndex');

    // Получаем ID категории по индексу
    final allCategories = _getAllCategories();
    print('📊 [CategoryScroll] Total categories: ${allCategories.length}');
    if (categoryIndex >= 0 && categoryIndex < allCategories.length) {
      final categoryId = allCategories[categoryIndex].id;
      print(
        '📊 [CategoryScroll] Category ID at index $categoryIndex: $categoryId',
      );
      print(
        '📊 [CategoryScroll] Last selected: $_lastSelectedCategoryId, Current widget: ${widget.selectedCategoryId}',
      );

      // Переключаем только если категория изменилась
      if (categoryId != _lastSelectedCategoryId) {
        print(
          '✅ [CategoryScroll] Switching to category: $categoryId (was: $_lastSelectedCategoryId)',
        );
        _lastSelectedCategoryId = categoryId;
        print(
          '📞 [CategoryScroll] Calling widget.onCategorySelected($categoryId)',
        );
        widget.onCategorySelected(categoryId);
        print('✅ [CategoryScroll] widget.onCategorySelected called');
      } else {
        print('⏭️ [CategoryScroll] Category unchanged ($categoryId), skipping');
      }
    } else {
      print('❌ [CategoryScroll] Invalid categoryIndex: $categoryIndex');
    }
  }

  /// Вычисляет индекс категории, которая находится в центре экрана
  int _getCategoryIndexAtCenter(double centerPosition) {
    final allCategories = _getAllCategories();
    if (allCategories.isEmpty) return 0;

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

    final fontSize = Responsive.responsiveSize(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );

    // Начальная позиция с учетом padding
    double currentPosition = horizontalPadding;

    // Находим категорию, центр которой ближе всего к centerPosition
    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < allCategories.length; i++) {
      final category = allCategories[i];

      // Приблизительная ширина категории: текст + padding + spacing
      final textWidth = _estimateTextWidth(category.name, fontSize);
      // Увеличиваем оценку ширины для более точного определения
      final categoryWidth =
          textWidth +
          24.0 +
          categorySpacing; // padding 8*2 + дополнительные отступы

      // Центр категории
      final categoryCenter = currentPosition + (categoryWidth / 2);

      // Расстояние от центра экрана до центра категории
      final distance = (centerPosition - categoryCenter).abs();

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }

      currentPosition += categoryWidth;
    }

    return closestIndex;
  }

  /// Оценивает ширину текста на основе длины и размера шрифта
  double _estimateTextWidth(String text, double fontSize) {
    // Используем TextPainter для более точного измерения ширины текста
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat',
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    // Добавляем небольшой запас для более точного определения
    return textPainter.width + 8.0;
  }

  /// Прокручивает список категорий так, чтобы выбранная категория была в центре
  void _scrollToSelectedCategory() {
    if (!_scrollController.hasClients) return;

    final allCategories = _getAllCategories();
    final currentIndex = _getCurrentIndex();
    if (currentIndex < 0 || currentIndex >= allCategories.length) return;

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

    final fontSize = Responsive.responsiveSize(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );

    final screenWidth = MediaQuery.of(context).size.width;

    // Вычисляем позицию начала выбранной категории
    double targetPosition = horizontalPadding;
    for (int i = 0; i < currentIndex; i++) {
      final category = allCategories[i];
      final textWidth = _estimateTextWidth(category.name, fontSize);
      final categoryWidth = textWidth + 16.0 + categorySpacing;
      targetPosition += categoryWidth;
    }

    // Вычисляем ширину выбранной категории
    final selectedCategory = allCategories[currentIndex];
    final selectedTextWidth = _estimateTextWidth(
      selectedCategory.name,
      fontSize,
    );
    final selectedCategoryWidth = selectedTextWidth + 16.0 + categorySpacing;

    // Прокручиваем так, чтобы категория была в центре
    final scrollPosition =
        targetPosition + (selectedCategoryWidth / 2) - (screenWidth / 2);

    // Ограничиваем границы скролла
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedPosition = scrollPosition.clamp(0.0, maxScroll);

    _isProgrammaticScroll = true;
    _scrollController
        .animateTo(
          clampedPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          _isProgrammaticScroll = false;
        });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    // Удаляем контроллер только если мы его создали сами
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
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Отладочная информация для всех типов событий скролла
            if (notification is ScrollStartNotification) {
              print(
                '🟢 [CategoryScroll] Scroll START - pixels: ${_scrollController.position.pixels}',
              );
            }
            if (notification is ScrollUpdateNotification) {
              print(
                '🟡 [CategoryScroll] Scroll UPDATE - pixels: ${_scrollController.position.pixels}, velocity: ${notification.scrollDelta}',
              );

              // СИНХРОНИЗАЦИЯ: скроллим товары вместе с категориями
              if (widget.productsScrollController != null &&
                  widget.productsScrollController!.hasClients) {
                final scrollDelta = notification.scrollDelta ?? 0.0;
                final newOffset = widget.productsScrollController!.offset + scrollDelta;
                final maxScroll = widget.productsScrollController!.position.maxScrollExtent;
                final clampedOffset = newOffset.clamp(0.0, maxScroll);

                widget.productsScrollController!.jumpTo(clampedOffset);
                print('🔗 [CategoryScroll] Synced products scroll to: $clampedOffset');
              }
            }
            // Переключаем категорию после окончания скролла для точности
            if (notification is ScrollEndNotification) {
              print(
                '🔴 [CategoryScroll] Scroll END - pixels: ${_scrollController.position.pixels}, isProgrammatic: $_isProgrammaticScroll',
              );
              if (!_isProgrammaticScroll && _scrollController.hasClients) {
                print(
                  '✅ [CategoryScroll] Calling _updateCategoryFromScroll() from ScrollEndNotification',
                );
                _updateCategoryFromScroll();
                _isScrolling = false;
              } else {
                print(
                  '❌ [CategoryScroll] Skipped: isProgrammatic=$_isProgrammaticScroll, hasClients=${_scrollController.hasClients}',
                );
              }
            }
            // БЛОКИРУЕМ передачу уведомлений вертикальному скроллу
            return true; // true = блокируем события
          },
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            physics: const AlwaysScrollableScrollPhysics(),
            primary: false, // КРИТИЧНО! Отключает связь с родительским скроллом
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
