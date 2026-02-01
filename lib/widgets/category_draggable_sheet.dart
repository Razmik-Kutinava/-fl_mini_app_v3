import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/menu_provider.dart';
import 'product_card.dart';
import 'promo_section.dart';

/// 🎡 Трёхуровневая карусель категорий с вертикальным драгом
/// @version DEPLOY-2026-0201-003
///
/// Три вертикальных состояния:
/// - MIN (10%) = только ручка видна
/// - MID (50%) = начальное состояние, категории + 1 ряд товаров
/// - MAX (90%) = полноэкранный режим, все товары
///
/// - Вертикальный свайп = смена уровня (MIN/MID/MAX)
/// - Горизонтальный свайп = смена категории
class CategoryDraggableSheet extends StatefulWidget {
  final MenuProvider menuProvider;
  final List<PromoItem> promotions;
  final Function(String?) onCategoryChanged;

  const CategoryDraggableSheet({
    super.key,
    required this.menuProvider,
    required this.promotions,
    required this.onCategoryChanged,
  });

  @override
  State<CategoryDraggableSheet> createState() => _CategoryDraggableSheetState();
}

/// Состояния вертикальной карусели
enum SheetState { min, mid, max }

class _CategoryDraggableSheetState extends State<CategoryDraggableSheet> with SingleTickerProviderStateMixin {
  PageController? _pageController;
  PageController? _maxPageController; // Отдельный контроллер для MAX состояния
  late AnimationController _heightAnimationController;

  int _currentIndex = 0;
  double _pageOffset = 0.0;
  final ScrollController _expandedScrollController = ScrollController();
  
  // Геттеры для контроллеров с ленивой инициализацией
  PageController get pageController {
    if (_pageController == null) {
      _pageController = PageController(
        viewportFraction: 0.88,
        initialPage: _currentIndex,
      );
      _pageController!.addListener(_onPageScroll);
    }
    return _pageController!;
  }
  
  PageController get maxPageController {
    if (_maxPageController == null) {
      _maxPageController = PageController(initialPage: _currentIndex);
      _maxPageController!.addListener(_onMaxPageScroll);
    }
    return _maxPageController!;
  }

  // Вертикальное состояние
  SheetState _sheetState = SheetState.mid;
  double _sheetHeight = 0.50; // Текущая высота (0.10 - 0.90)

  // Константы высот
  static const double minHeight = 0.10;  // 10% экрана
  static const double midHeight = 0.50;  // 50% экрана (по умолчанию)
  static const double maxHeight = 0.90;  // 90% экрана

  @override
  void initState() {
    super.initState();

    // Контроллер анимации для плавных переходов между состояниями
    _heightAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    print('🚀 CategoryDraggableSheet initialized with 3 states (MIN/MID/MAX)');
  }

  @override
  void dispose() {
    _pageController?.removeListener(_onPageScroll);
    _pageController?.dispose();
    _maxPageController?.removeListener(_onMaxPageScroll);
    _maxPageController?.dispose();
    _expandedScrollController.dispose();
    _heightAnimationController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(CategoryDraggableSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCarouselWithSelection();
  }
  
  void _syncCarouselWithSelection() {
    final selectedId = widget.menuProvider.selectedCategoryId;
    final categories = _getAllCategories();
    
    int targetIndex = 0;
    if (selectedId != null) {
      for (int i = 0; i < categories.length; i++) {
        if (categories[i].id == selectedId) {
          targetIndex = i;
          break;
        }
      }
    }
    
    if (targetIndex != _currentIndex && _pageController?.hasClients == true) {
      pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageScroll() {
    if (_pageController?.hasClients == true) {
      setState(() {
        _pageOffset = _pageController!.page ?? 0;
      });
    }
  }
  
  void _onMaxPageScroll() {
    // Синхронизация MAX PageController с индексом и MID контроллером
    if (_maxPageController?.hasClients == true && _maxPageController!.page != null) {
      final newIndex = _maxPageController!.page!.round();
      if (newIndex != _currentIndex) {
        setState(() => _currentIndex = newIndex);
        widget.onCategoryChanged(_getAllCategories()[newIndex].id);
        HapticFeedback.selectionClick();
        print('📱 MAX scroll changed to index: $newIndex');
      }
    }
  }

  // Состояние для raw pointer tracking
  Offset? _pointerStart;
  double _dragStartHeight = 0;
  bool _isVerticalDrag = false;
  bool _isDragDecided = false;

  /// Listener handlers для низкоуровневой обработки pointer events
  void _onPointerDown(PointerDownEvent event) {
    _pointerStart = event.position;
    _dragStartHeight = _sheetHeight;
    _isVerticalDrag = false;
    _isDragDecided = false;
    print('👆 Pointer DOWN at ${event.position}');
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerStart == null) return;
    
    final delta = event.position - _pointerStart!;
    
    // Определяем направление только один раз
    if (!_isDragDecided && (delta.dx.abs() > 10 || delta.dy.abs() > 10)) {
      _isVerticalDrag = delta.dy.abs() > delta.dx.abs();
      _isDragDecided = true;
      print('🧭 Direction decided: ${_isVerticalDrag ? "VERTICAL" : "HORIZONTAL"}');
    }
    
    // Обрабатываем только вертикальный драг
    if (_isDragDecided && _isVerticalDrag) {
      final screenHeight = MediaQuery.of(context).size.height;
      final heightDelta = -delta.dy / screenHeight;
      final newHeight = (_dragStartHeight + heightDelta).clamp(minHeight, maxHeight);
      
      setState(() {
        _sheetHeight = newHeight;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_pointerStart == null || !_isDragDecided) {
      _pointerStart = null;
      return;
    }
    
    final delta = event.position - _pointerStart!;
    
    // Обработка вертикального свайпа
    if (!_isVerticalDrag) {
      _pointerStart = null;
      return;
    }
    
    final velocity = delta.dy; // Приблизительная скорость
    
    print('👆 Pointer UP: velocity=$velocity, height=${(_sheetHeight * 100).toInt()}%');
    
    SheetState targetState;

    if (velocity > 100) {
      // Свайп вниз
      targetState = _sheetState == SheetState.max ? SheetState.mid : SheetState.min;
    } else if (velocity < -100) {
      // Свайп вверх
      targetState = _sheetState == SheetState.min ? SheetState.mid : SheetState.max;
    } else {
      // Медленный - snap к ближайшей точке
      if (_sheetHeight < 0.30) {
        targetState = SheetState.min;
      } else if (_sheetHeight < 0.70) {
        targetState = SheetState.mid;
      } else {
        targetState = SheetState.max;
      }
    }

    _animateToState(targetState);
    _pointerStart = null;
  }
  
  void _onPointerCancel(PointerCancelEvent event) {
    _pointerStart = null;
    _isDragDecided = false;
  }

  /// Анимация перехода к указанному состоянию
  void _animateToState(SheetState state) {
    final targetHeight = switch (state) {
      SheetState.min => minHeight,
      SheetState.mid => midHeight,
      SheetState.max => maxHeight,
    };

    // Haptic feedback при смене состояния
    if (_sheetState != state) {
      HapticFeedback.mediumImpact();
      
      // Синхронизация контроллеров ПОСЛЕ перестройки виджета
      final savedIndex = _currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state == SheetState.max && _maxPageController?.hasClients == true) {
          if (_maxPageController!.page?.round() != savedIndex) {
            _maxPageController!.jumpToPage(savedIndex);
          }
        } else if (state == SheetState.mid && _pageController?.hasClients == true) {
          if (_pageController!.page?.round() != savedIndex) {
            _pageController!.jumpToPage(savedIndex);
          }
        }
        print('🔄 Synced to index $savedIndex after state change to $state');
      });
    }

    _sheetState = state;

    final animation = Tween<double>(
      begin: _sheetHeight,
      end: targetHeight,
    ).animate(CurvedAnimation(
      parent: _heightAnimationController,
      curve: Curves.easeInOut,
    ));

    animation.addListener(() {
      setState(() {
        _sheetHeight = animation.value;
      });
    });

    _heightAnimationController.forward(from: 0.0);

    print('🎯 Sheet animated to: $state (${(targetHeight * 100).toInt()}%)');
  }

  /// Быстрый переход к состоянию (для тапов на ручку/кнопки)
  void _switchToState(SheetState state) {
    _animateToState(state);
  }

  List<CategoryItem> _getAllCategories() {
    final categories = <CategoryItem>[];
    
    categories.add(CategoryItem(
      id: null,
      name: 'для тебя',
      isPromo: true,
    ));
    
    for (var category in widget.menuProvider.categories) {
      categories.add(CategoryItem(
        id: category.id,
        name: category.name,
        isPromo: false,
      ));
    }
    
    return categories;
  }
  
  List<Product> _getProductsForCategory(String? categoryId) {
    if (categoryId == null) {
      return widget.menuProvider.allProducts.take(6).toList();
    }
    return widget.menuProvider.allProducts
        .where((p) => p.categoryId == categoryId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getAllCategories();
    final screenHeight = MediaQuery.of(context).size.height;

    print('🚀 CategoryDraggableSheet BUILD: categories=${categories.length}, screenH=$screenHeight');

    if (categories.isEmpty) {
      print('⚠️ CategoryDraggableSheet: No categories, showing loading');
      return const Center(child: CircularProgressIndicator());
    }

    final sheetHeight = _sheetHeight * screenHeight;

    print('🎨 Sheet: state=$_sheetState, height=${(_sheetHeight * 100).toInt()}%, px=$sheetHeight');

    // Align снизу (оригинальный подход)
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: double.infinity,
        height: sheetHeight,
        child: _buildSheetContent(categories),
      ),
    );
  }

  /// Построение контента в зависимости от состояния
  Widget _buildSheetContent(List<CategoryItem> categories) {
    switch (_sheetState) {
      case SheetState.min:
        return _buildMinState(categories);
      case SheetState.mid:
        return _buildMidState(categories);
      case SheetState.max:
        return _buildMaxState(categories);
    }
  }

  /// MIN состояние (10%) - только ручка
  Widget _buildMinState(List<CategoryItem> categories) {
    return GestureDetector(
      onTap: () => _switchToState(SheetState.mid),
      behavior: HitTestBehavior.opaque,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        behavior: HitTestBehavior.translucent,
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
      ), // Закрываем Listener
    );
  }

  /// MID состояние (50%) - категории + карусель с товарами
  Widget _buildMidState(List<CategoryItem> categories) {
    return Listener(
      // Низкоуровневая обработка pointer events для вертикального свайпа
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent, // Пропускаем горизонтальные события к PageView
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Ручка - тап для раскрытия
            GestureDetector(
              onTap: () => _switchToState(SheetState.max),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

            // Заголовок категории
            _buildHeader(categories[_currentIndex]),

            // Горизонтальная навигация категорий
            _buildCategoryNavigation(categories),

            // PageView карусель
            // Используем NotificationListener чтобы отслеживать горизонтальный скролл
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Логируем scroll notifications для отладки
                  if (notification is ScrollStartNotification) {
                    print('📜 PageView scroll started');
                  }
                  return false; // Не блокируем нотификации
                },
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: PageView.builder(
                    controller: pageController,
                    physics: const PageScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      widget.onCategoryChanged(categories[index].id);
                      HapticFeedback.selectionClick();
                      print('📱 MID Swiped to: ${categories[index].name}');
                    },
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return _buildVerticalDraggableCard(categories[index], index);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка с вертикальным драгом (для MID state)
  Widget _buildVerticalDraggableCard(CategoryItem category, int index) {
    final products = _getProductsForCategory(category.id);
    
    // 3D эффект
    double diff = (index - _pageOffset);
    double scale = 1 - (diff.abs() * 0.08).clamp(0.0, 0.15);
    double opacity = 1 - (diff.abs() * 0.25).clamp(0.0, 0.4);
    
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: category.isPromo
            ? _buildPromoCard(products)
            : _buildProductsCard(products),
      ),
    );
  }

  /// MAX состояние (90%) - полноэкранный режим с PageView для горизонтального свайпа
  Widget _buildMaxState(List<CategoryItem> categories) {
    final category = categories[_currentIndex];

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Ручка для свайпа вниз
            GestureDetector(
              onTap: () => _switchToState(SheetState.mid),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            
            // Заголовок с кнопкой закрытия
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade400, Colors.orange.shade400],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      category.name,
                      style: GoogleFonts.pacifico(
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                    onPressed: () => _switchToState(SheetState.mid),
                  ),
                ],
              ),
            ),

            // Горизонтальная навигация категорий (табы)
            SizedBox(
              height: 40,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        if (maxPageController.hasClients) {
                          maxPageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                        setState(() => _currentIndex = index);
                        widget.onCategoryChanged(cat.id);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.pink.shade50 : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.pink.shade300 : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? Colors.pink.shade600 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // PageView для горизонтального свайпа между категориями
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: PageView.builder(
                  controller: maxPageController,
                  physics: const PageScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    widget.onCategoryChanged(categories[index].id);
                    HapticFeedback.selectionClick();
                    print('📱 MAX Swiped to: ${categories[index].name}');
                  },
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return _buildMaxProductsGrid(categories[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Сетка товаров для MAX состояния (внутри PageView)
  Widget _buildMaxProductsGrid(CategoryItem category) {
    // Для "для тебя" показываем баннер + товары
    if (category.isPromo) {
      return _buildMaxPromoContent();
    }
    
    final products = _getProductsForCategory(category.id);
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Нет товаров',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index])
              .animate(delay: Duration(milliseconds: 40 * index))
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }
  
  /// Контент "для тебя" в MAX состоянии - баннер акции + товары
  Widget _buildMaxPromoContent() {
    final promo = widget.promotions.isNotEmpty ? widget.promotions.first : null;
    
    // Собираем товары из всех категорий для рекомендаций
    List<Product> recommendedProducts = [];
    for (var cat in widget.menuProvider.categories) {
      final catProducts = _getProductsForCategory(cat.id);
      if (catProducts.isNotEmpty) {
        recommendedProducts.addAll(catProducts.take(2));
      }
      if (recommendedProducts.length >= 6) break;
    }
    
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок "акции"
            Text(
              'акции',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Большой баннер акции
            AspectRatio(
              aspectRatio: 1.2,
              child: promo != null
                  ? _buildPromoBanner(promo)
                  : _buildDefaultPromoBanner(),
            ),
            
            const SizedBox(height: 24),
            
            // Заголовок "рекомендации"
            Text(
              'рекомендации',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Сетка рекомендованных товаров
            if (recommendedProducts.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: recommendedProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: recommendedProducts[index])
                      .animate(delay: Duration(milliseconds: 50 * index))
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: 0.05, end: 0);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryNavigation(List<CategoryItem> categories) {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == _currentIndex;

          return GestureDetector(
            onTap: () {
              setState(() => _currentIndex = index);
              widget.onCategoryChanged(category.id);
              if (pageController.hasClients) {
                pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                );
              }
              HapticFeedback.selectionClick();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? Border.all(
                  color: Colors.pink.shade300,
                  width: 2,
                ) : null,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  category.name,
                  style: GoogleFonts.pacifico(
                    fontSize: 14,
                    color: isSelected ? Colors.pink.shade600 : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }


  Widget _buildHeader(CategoryItem category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade400, Colors.orange.shade400],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              category.name,
              style: GoogleFonts.pacifico(
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(List<Product> products) {
    // Берём первую акцию для баннера
    final promo = widget.promotions.isNotEmpty ? widget.promotions.first : null;
    
    // Для "для тебя" показываем первые 2 товара из первой категории
    List<Product> displayProducts = [];
    if (widget.menuProvider.categories.isNotEmpty) {
      final firstCat = widget.menuProvider.categories.first;
      displayProducts = _getProductsForCategory(firstCat.id).take(2).toList();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Градиент сверху
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade300, Colors.orange.shade300],
                ),
              ),
            ),
            
            // Баннер акции (занимает основное место)
            Expanded(
              flex: 3,
              child: promo != null
                  ? _buildPromoBanner(promo)
                  : _buildDefaultPromoBanner(),
            ),
            
            // Разделитель
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.grey.shade200,
            ),
            
            // Товары снизу (если есть)
            if (displayProducts.isNotEmpty)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: displayProducts.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final product = entry.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: idx == 0 ? 0 : 4,
                            right: idx == displayProducts.length - 1 ? 0 : 4,
                          ),
                          child: ProductCard(product: product)
                              .animate(delay: Duration(milliseconds: 100 * idx))
                              .fadeIn(duration: 300.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.0, 1.0),
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            
            // Индикатор "свайп вверх"
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.pink.shade400,
                size: 24,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -3, duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Баннер акции
  Widget _buildPromoBanner(PromoItem promo) {
    return GestureDetector(
      onTap: promo.onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: promo.gradient ?? LinearGradient(
            colors: [Colors.pink.shade300, Colors.orange.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Фоновое изображение
            if (promo.imageUrl != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    promo.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            // Градиентный оверлей
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Контент
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (promo.emoji != null)
                    Text(
                      promo.emoji!,
                      style: const TextStyle(fontSize: 32),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    promo.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Подробнее',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.pink.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
    );
  }
  
  /// Дефолтный баннер когда нет акций
  Widget _buildDefaultPromoBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.pink.shade200, Colors.orange.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              'Скоро акции!',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard(List<Product> products) {
    final displayProducts = products.take(2).toList();
    
    if (displayProducts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('Нет товаров', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Градиент сверху
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade300, Colors.orange.shade300],
                ),
              ),
            ),
            
            // Товары
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: displayProducts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final product = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: idx == 0 ? 0 : 6,
                          right: idx == displayProducts.length - 1 ? 0 : 6,
                        ),
                        child: ProductCard(product: product)
                            .animate(delay: Duration(milliseconds: 100 * idx))
                            .fadeIn(duration: 300.ms)
                            .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1.0, 1.0),
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Кнопка "ещё" (тап для раскрытия до MAX)
            if (products.length > 2)
              GestureDetector(
                onTap: () => _switchToState(SheetState.max),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 16, top: 4),
                  child: Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.pink.shade400,
                        size: 28,
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: 0, end: -4, duration: 600.ms),
                      Text(
                        'Ещё ${products.length - 2} →',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.pink.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}

/// Модель категории
class CategoryItem {
  final String? id;
  final String name;
  final bool isPromo;

  CategoryItem({
    this.id,
    required this.name,
    required this.isPromo,
  });
}
