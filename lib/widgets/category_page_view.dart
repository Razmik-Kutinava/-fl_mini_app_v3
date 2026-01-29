import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/menu_provider.dart';
import '../utils/responsive.dart';
import 'product_card.dart';
import 'promo_section.dart';

/// Новый виджет: PageView категорий с четкими переходами и раскрытием товаров
/// Вариант A: PageView с ClampingScrollPhysics для четкого снапа
class CategoryPageView extends StatefulWidget {
  final MenuProvider menuProvider;
  final List<PromoItem> promotions;
  final Function(String?) onCategoryChanged;
  final Function(String?)? onCategoryExpand;
  final PageController? pageController;

  const CategoryPageView({
    super.key,
    required this.menuProvider,
    required this.promotions,
    required this.onCategoryChanged,
    this.onCategoryExpand,
    this.pageController,
  });

  @override
  State<CategoryPageView> createState() => _CategoryPageViewState();
}

class _CategoryPageViewState extends State<CategoryPageView> {
  late PageController _pageController;
  
  // Состояния раскрытия для каждой категории
  Map<int, bool> _expandedStates = {};
  
  // ScrollController для каждой категории
  Map<int, ScrollController> _scrollControllers = {};
  
  PageController get pageController => widget.pageController ?? _pageController;

  @override
  void initState() {
    super.initState();
    
    // Используем внешний контроллер или создаем свой
    if (widget.pageController == null) {
      _pageController = PageController(
        initialPage: 0,
        viewportFraction: 1.0, // Полная ширина экрана
      );
    }
    
    final categories = _getAllCategories();
    print('🚀 CategoryPageView initialized: ${categories.length} categories');
    
    // Логируем товары для каждой категории
    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      final products = _getProductsForCategory(category.id);
      print('📦 Category "${category.name}": ${products.length} products');
    }
  }

  @override
  void dispose() {
    // Удаляем все ScrollController
    _scrollControllers.forEach((key, controller) {
      controller.dispose();
    });
    _scrollControllers.clear();
    
    // Удаляем PageController только если мы его создали
    if (widget.pageController == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  /// Получить список всех категорий включая "для тебя"
  List<CategoryItem> _getAllCategories() {
    final categories = <CategoryItem>[];
    
    // Первая категория - "для тебя"
    categories.add(CategoryItem(
      id: null,
      name: 'для тебя',
      isPromo: true,
    ));
    
    // Остальные категории
    for (var category in widget.menuProvider.categories) {
      categories.add(CategoryItem(
        id: category.id,
        name: category.name,
        isPromo: false,
      ));
    }
    
    return categories;
  }

  /// Получить товары для категории
  List<Product> _getProductsForCategory(String? categoryId) {
    if (categoryId == null) {
      return widget.menuProvider.allProducts;
    }
    return widget.menuProvider.allProducts
        .where((p) => p.categoryId == categoryId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getAllCategories();
    
    if (categories.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - 280; // Высота с учетом верхних элементов

    return SliverToBoxAdapter(
      child: SizedBox(
        height: availableHeight > 0 ? availableHeight : 400,
        child: PageView.builder(
          controller: pageController,
          scrollDirection: Axis.horizontal, // Явно указываем горизонтальный скролл
          
          // БЫСТРЫЙ И ЧЕТКИЙ СКРОЛЛ:
          physics: const PageScrollPhysics(), // Быстрый и отзывчивый свайп
          pageSnapping: true, // Четкий снап к страницам
          padEnds: false, // Убираем отступы по краям
          
          onPageChanged: (index) {
            print('🔄 CategoryPageView: Page changed to index $index (${categories[index].name})');
            
            // Сворачиваем предыдущую категорию при переходе
            _expandedStates.forEach((key, value) {
              if (key != index && value) {
                print('📕 CategoryPageView: Auto-collapsing previous category at index $key');
                _expandedStates[key] = false;
              }
            });
            
            // Уведомляем о смене категории
            widget.onCategoryChanged(categories[index].id);
            
            // Обновляем состояние
            setState(() {});
          },
          
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryPage(categories[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryPage(CategoryItem category, int pageIndex) {
    final products = _getProductsForCategory(category.id);
    final isExpanded = _expandedStates[pageIndex] ?? false;
    
    // Создаем ScrollController для этой категории
    if (!_scrollControllers.containsKey(pageIndex)) {
      _scrollControllers[pageIndex] = ScrollController();
      _scrollControllers[pageIndex]!.addListener(() {
        _onCategoryScroll(pageIndex);
      });
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Заголовок категории + кнопка закрытия
            _buildHeader(category, pageIndex, isExpanded),
            
            // Товары с анимированной высотой
            Expanded(
              child: _buildProductsContainer(category, products, pageIndex, isExpanded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CategoryItem category, int pageIndex, bool isExpanded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.name,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          if (isExpanded)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                print('📕 CategoryPageView: Closing category "${category.name}" via button');
                setState(() {
                  _expandedStates[pageIndex] = false;
                });
              },
            )
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
        ],
      ),
    );
  }

  Widget _buildProductsContainer(CategoryItem category, List<Product> products, int pageIndex, bool isExpanded) {
    if (category.isPromo) {
      return _buildPromoContent(products, pageIndex);
    }
    
    return _buildProductsContent(products, pageIndex, isExpanded);
  }

  Widget _buildPromoContent(List<Product> products, int pageIndex) {
    // Получаем первые два товара из первой категории
    List<Product> firstTwoProducts = [];
    if (widget.menuProvider.categories.isNotEmpty) {
      final firstCategory = widget.menuProvider.categories.first;
      final categoryProducts = _getProductsForCategory(firstCategory.id);
      firstTwoProducts = categoryProducts.take(2).toList();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: PromoSection(
        promotions: widget.promotions,
        products: firstTwoProducts,
      ),
    );
  }

  Widget _buildProductsContent(List<Product> products, int pageIndex, bool isExpanded) {
    final padding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            'Нет товаров в этой категории',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    // В свернутом виде показываем только первые 2 товара
    final displayProducts = isExpanded ? products : products.take(2).toList();

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Если свайп вверх - раскрываем
        if (details.delta.dy < -10 && !isExpanded) {
          print('📖 CategoryPageView: Expanding category at index $pageIndex (swipe up detected)');
          setState(() {
            _expandedStates[pageIndex] = true;
          });
        }
        
        // Если свайп вниз от начала - сворачиваем
        final controller = _scrollControllers[pageIndex];
        if (controller != null && 
            details.delta.dy > 10 && 
            isExpanded && 
            controller.hasClients &&
            controller.offset <= 0) {
          print('📕 CategoryPageView: Collapsing category at index $pageIndex (swipe down detected)');
          setState(() {
            _expandedStates[pageIndex] = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: GridView.builder(
          controller: _scrollControllers[pageIndex],
          physics: isExpanded 
            ? const BouncingScrollPhysics() 
            : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: padding,
            crossAxisSpacing: padding,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (context, index) {
            return ProductCard(product: displayProducts[index])
                .animate(delay: Duration(milliseconds: 50 * index))
                .fadeIn()
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
          },
        ),
      ),
    );
  }

  void _onCategoryScroll(int pageIndex) {
    final controller = _scrollControllers[pageIndex];
    if (controller == null || !controller.hasClients) return;
    
    final offset = controller.offset;
    final maxExtent = controller.position.maxScrollExtent;
    
    // Логируем позицию скролла
    print('📜 CategoryPageView: Scroll at index $pageIndex - offset=${offset.toStringAsFixed(1)}, max=${maxExtent.toStringAsFixed(1)}');
    
    // Если скроллим в начале списка вниз - можем свернуть через жест
    if (offset <= 0 && _expandedStates[pageIndex] == true) {
      // Логика сворачивания обрабатывается в onVerticalDragUpdate
    }
  }
}

/// Элемент категории
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
