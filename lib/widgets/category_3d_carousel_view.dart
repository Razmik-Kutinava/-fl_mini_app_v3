import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/menu_provider.dart';
import '../utils/responsive.dart';
import 'product_card.dart';
import 'promo_section.dart';

/// 🎡 НАСТОЯЩАЯ 3D Карусель категорий с товарами
/// - Горизонтальный свайп = смена категории с 3D поворотом
/// - Вертикальный свайп ↑ = раскрытие списка товаров
/// - Крестик / свайп ↓ = сворачивание
class Category3DCarouselView extends StatefulWidget {
  final MenuProvider menuProvider;
  final List<PromoItem> promotions;
  final Function(String?) onCategoryChanged;

  const Category3DCarouselView({
    super.key,
    required this.menuProvider,
    required this.promotions,
    required this.onCategoryChanged,
  });

  @override
  State<Category3DCarouselView> createState() => _Category3DCarouselViewState();
}

class _Category3DCarouselViewState extends State<Category3DCarouselView> 
    with SingleTickerProviderStateMixin {
  
  late PageController _pageController;
  int _currentIndex = 0;
  double _pageOffset = 0.0;
  bool _isExpanded = false;
  final ScrollController _expandedScrollController = ScrollController();
  
  // Для отслеживания вертикального свайпа
  double _dragStartY = 0;
  double _dragDelta = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.75, // Видно соседние карточки
      initialPage: 0,
    );
    _pageController.addListener(_onPageScroll);
    
    final categories = _getAllCategories();
    print('🚀 Category3DCarouselView initialized: ${categories.length} categories');
  }

  void _onPageScroll() {
    setState(() {
      _pageOffset = _pageController.page ?? 0;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _expandedScrollController.dispose();
    super.dispose();
  }

  /// Получить список всех категорий
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
      return widget.menuProvider.allProducts.take(6).toList();
    }
    return widget.menuProvider.allProducts
        .where((p) => p.categoryId == categoryId)
        .toList();
  }

  void _expandCategory() {
    print('📖 Category3DCarouselView: Expanding category at index $_currentIndex');
    setState(() {
      _isExpanded = true;
    });
  }

  void _collapseCategory() {
    print('📕 Category3DCarouselView: Collapsing category');
    setState(() {
      _isExpanded = false;
    });
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
    final availableHeight = screenHeight - 280;

    return SliverToBoxAdapter(
      child: GestureDetector(
        onVerticalDragStart: (details) {
          _dragStartY = details.globalPosition.dy;
          _dragDelta = 0;
        },
        onVerticalDragUpdate: (details) {
          _dragDelta = details.globalPosition.dy - _dragStartY;
          
          // Свайп вверх - раскрываем
          if (_dragDelta < -50 && !_isExpanded) {
            _expandCategory();
          }
          
          // Свайп вниз - сворачиваем (если скролл в начале)
          if (_dragDelta > 50 && _isExpanded) {
            if (!_expandedScrollController.hasClients || 
                _expandedScrollController.offset <= 0) {
              _collapseCategory();
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          height: _isExpanded 
              ? screenHeight - 180
              : availableHeight > 0 ? availableHeight : 400,
          child: Container(
            // Белый фон без серых полос
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Заголовок текущей категории
                _buildHeader(categories),
                
                // 3D Карусель или развернутый список
                Expanded(
                  child: _isExpanded
                      ? _buildExpandedList(categories[_currentIndex])
                      : _build3DCarousel(categories),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<CategoryItem> categories) {
    final currentCategory = categories[_currentIndex];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          // Индикатор позиции
          Container(
            width: 4,
            height: 28,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.pink.shade400,
                  Colors.orange.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              currentCategory.name,
              style: GoogleFonts.pacifico(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          if (_isExpanded)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, color: Colors.black54, size: 20),
              ),
              onPressed: _collapseCategory,
            )
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
        ],
      ),
    );
  }

  Widget _build3DCarousel(List<CategoryItem> categories) {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        print('🔄 Category3DCarouselView: Swiped to index $index (${categories[index].name})');
        setState(() {
          _currentIndex = index;
        });
        widget.onCategoryChanged(categories[index].id);
      },
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _build3DCard(categories[index], index);
      },
    );
  }

  /// 🎯 Создание карточки с настоящим 3D эффектом
  Widget _build3DCard(CategoryItem category, int index) {
    // Вычисляем разницу между текущей позицией и индексом
    double diff = (index - _pageOffset);
    
    // Ограничиваем угол поворота
    double rotationY = diff.clamp(-1.0, 1.0) * 0.3; // До 0.3 радиан (~17°)
    
    // Масштаб зависит от удаленности от центра
    double scale = 1 - (diff.abs() * 0.15).clamp(0.0, 0.3);
    
    // Прозрачность для боковых карточек
    double opacity = 1 - (diff.abs() * 0.3).clamp(0.0, 0.5);
    
    // Смещение для глубины
    double translateX = diff * 20;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Перспектива
            ..rotateY(rotationY) // Поворот по Y
            ..scale(scale) // Масштаб
            ..translate(translateX), // Смещение
          child: Opacity(
            opacity: opacity,
            child: _buildCarouselCard(category, index == _currentIndex),
          ),
        );
      },
    );
  }

  Widget _buildCarouselCard(CategoryItem category, bool isActive) {
    final products = _getProductsForCategory(category.id);
    
    if (category.isPromo) {
      return _buildPromoCard(products, isActive);
    }
    
    return _buildProductsCard(products, isActive);
  }

  Widget _buildPromoCard(List<Product> products, bool isActive) {
    List<Product> firstTwoProducts = [];
    if (widget.menuProvider.categories.isNotEmpty) {
      final firstCategory = widget.menuProvider.categories.first;
      final categoryProducts = _getProductsForCategory(firstCategory.id);
      firstTwoProducts = categoryProducts.take(2).toList();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? Colors.pink.withOpacity(0.3) 
                : Colors.black.withOpacity(0.1),
            blurRadius: isActive ? 30 : 15,
            offset: const Offset(0, 10),
            spreadRadius: isActive ? 2 : 0,
          ),
        ],
        border: isActive ? Border.all(
          color: Colors.pink.withOpacity(0.2),
          width: 2,
        ) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: PromoSection(
            promotions: widget.promotions,
            products: firstTwoProducts,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsCard(List<Product> products, bool isActive) {
    final padding = Responsive.responsiveSize(
      context,
      mobile: 14.0,
      tablet: 22.0,
      desktop: 30.0,
    );

    final displayProducts = products.take(2).toList();

    if (displayProducts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade200,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Нет товаров',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          // Основная тень
          BoxShadow(
            color: isActive 
                ? Colors.pink.withOpacity(0.25) 
                : Colors.black.withOpacity(0.12),
            blurRadius: isActive ? 35 : 20,
            offset: const Offset(0, 12),
            spreadRadius: isActive ? 3 : 0,
          ),
          // Внутренний свет сверху
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: isActive ? Border.all(
          color: Colors.pink.withOpacity(0.15),
          width: 2,
        ) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Декоративная полоска сверху
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.shade300,
                    Colors.orange.shade300,
                    Colors.pink.shade300,
                  ],
                ),
              ),
            ),
            
            // Сетка с 2 товарами
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  children: displayProducts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final product = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: idx == 0 ? 0 : padding / 2,
                          right: idx == displayProducts.length - 1 ? 0 : padding / 2,
                        ),
                        child: ProductCard(product: product)
                            .animate(delay: Duration(milliseconds: 150 * idx))
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0)
                            .scale(
                              begin: const Offset(0.92, 0.92), 
                              end: const Offset(1.0, 1.0),
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Индикатор "свайпни вверх"
            if (products.length > 2)
              Container(
                padding: const EdgeInsets.only(bottom: 20, top: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.grey.shade50,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.grey[500],
                        size: 24,
                      )
                          .animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          )
                          .moveY(begin: 0, end: -4, duration: 700.ms),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ещё ${products.length - 2} товаров',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedList(CategoryItem category) {
    final products = _getProductsForCategory(category.id);
    final padding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    if (category.isPromo) {
      return SingleChildScrollView(
        controller: _expandedScrollController,
        physics: const BouncingScrollPhysics(),
        child: PromoSection(
          promotions: widget.promotions,
          products: products.take(6).toList(),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Нет товаров в этой категории',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _expandedScrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: padding,
        crossAxisSpacing: padding,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index])
            .animate(delay: Duration(milliseconds: 50 * index))
            .fadeIn()
            .slideY(begin: 0.05, end: 0)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0));
      },
    );
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
