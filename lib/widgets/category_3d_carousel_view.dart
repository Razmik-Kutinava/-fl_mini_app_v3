import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/product.dart';
import '../providers/menu_provider.dart';
import 'product_card.dart';
import 'promo_section.dart';

/// 🎡 3D Карусель категорий с товарами
/// - Горизонтальный свайп = смена категории с 3D эффектом
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

class _Category3DCarouselViewState extends State<Category3DCarouselView> {
  late PageController _pageController;
  
  bool _isExpanded = false;
  int _currentIndex = 0;
  double _pageOffset = 0.0;
  
  // Для вертикального свайпа
  double _dragStartY = 0;
  bool _isDragging = false;
  final ScrollController _expandedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 0,
    );
    _pageController.addListener(_onPageScroll);
    
    print('🚀 Category3DCarouselView initialized');
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _expandedScrollController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(Category3DCarouselView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Синхронизация карусели с выбранной категорией в menuProvider
    final selectedId = widget.menuProvider.selectedCategoryId;
    final categories = _getAllCategories();
    
    int targetIndex = 0; // По умолчанию "для тебя"
    if (selectedId != null) {
      for (int i = 0; i < categories.length; i++) {
        if (categories[i].id == selectedId) {
          targetIndex = i;
          break;
        }
      }
    }
    
    // Если индекс отличается - анимируем переход
    if (targetIndex != _currentIndex && _pageController.hasClients) {
      print('🔄 Syncing carousel to category: $selectedId (index $targetIndex)');
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }
  
  void _onPageScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _pageOffset = _pageController.page ?? 0;
      });
    }
  }
  
  void _expandCategory() {
    print('📖 Expanding category');
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = true;
    });
  }
  
  void _collapseCategory() {
    print('📕 Collapsing category');
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = false;
    });
  }

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
    
    if (categories.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedHeight = screenHeight * 0.45; // 45% экрана в свернутом
    final expandedHeight = screenHeight - 180; // Почти весь экран в развернутом

    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        height: _isExpanded ? expandedHeight : collapsedHeight,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.zero,
          border: Border(
            top: BorderSide(color: AppColors.primary, width: 2),
            left: BorderSide(color: AppColors.primary, width: 2),
            right: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        child: Column(
          children: [
            // Ручка для перетаскивания
            GestureDetector(
              onTap: () {
                if (_isExpanded) {
                  _collapseCategory();
                } else {
                  _expandCategory();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
            ),
            
            // Заголовок
            _buildHeader(categories),
            
            // Контент
            Expanded(
              child: _isExpanded
                  ? _buildExpandedList(categories[_currentIndex])
                  : _build3DCarousel(categories),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<CategoryItem> categories) {
    final currentCategory = categories[_currentIndex];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Градиентная полоска
          Container(
            width: 4,
            height: 28,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Expanded(
            child: Text(
              currentCategory.name.toUpperCase(),
              style: AppTextStyles.h2(),
            ),
          ),
          // Кнопка закрытия (только в раскрытом виде)
          if (_isExpanded)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Icon(Icons.close, color: AppColors.textPrimary, size: 18),
              ),
              onPressed: _collapseCategory,
            ),
        ],
      ),
    );
  }

  Widget _build3DCarousel(List<CategoryItem> categories) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _isDragging = true;
      },
      onVerticalDragUpdate: (details) {
        if (!_isDragging) return;
        final delta = details.globalPosition.dy - _dragStartY;
        // Свайп вверх - раскрываем
        if (delta < -60 && !_isExpanded) {
          _expandCategory();
          _isDragging = false;
        }
      },
      onVerticalDragEnd: (_) {
        _isDragging = false;
      },
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          print('🔄 Swiped to: ${categories[index].name}');
          setState(() {
            _currentIndex = index;
          });
          widget.onCategoryChanged(categories[index].id);
          HapticFeedback.selectionClick();
        },
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _build3DCard(categories[index], index);
        },
      ),
    );
  }

  Widget _build3DCard(CategoryItem category, int index) {
    // 3D трансформация
    double diff = (index - _pageOffset);
    double rotationY = diff.clamp(-1.0, 1.0) * 0.15; // До ~8°
    double scale = 1 - (diff.abs() * 0.1).clamp(0.0, 0.2);
    double opacity = 1 - (diff.abs() * 0.3).clamp(0.0, 0.5);
    
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(rotationY)
        ..scale(scale),
      child: Opacity(
        opacity: opacity,
        child: _buildCarouselCard(category, index == _currentIndex),
      ),
    );
  }

  Widget _buildCarouselCard(CategoryItem category, bool isActive) {
    final products = _getProductsForCategory(category.id);
    
    if (category.isPromo) {
      return _buildPromoCard(isActive);
    }
    
    return _buildProductsCard(products, isActive, category);
  }

  Widget _buildPromoCard(bool isActive) {
    List<Product> firstTwoProducts = [];
    if (widget.menuProvider.categories.isNotEmpty) {
      final firstCategory = widget.menuProvider.categories.first;
      final categoryProducts = _getProductsForCategory(firstCategory.id);
      firstTwoProducts = categoryProducts.take(2).toList();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? Colors.pink.withOpacity(0.2) 
                : Colors.black.withOpacity(0.08),
            blurRadius: isActive ? 25 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
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

  Widget _buildProductsCard(List<Product> products, bool isActive, CategoryItem category) {
    final displayProducts = products.take(2).toList();
    
    if (displayProducts.isEmpty) {
      return _buildEmptyCard();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? Colors.pink.withOpacity(0.2) 
                : Colors.black.withOpacity(0.08),
            blurRadius: isActive ? 25 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Column(
          children: [
            // Декоративная полоска
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.shade300,
                    Colors.orange.shade300,
                  ],
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
            
            // Индикатор "еще товары"
            if (products.length > 2)
              Container(
                padding: const EdgeInsets.only(bottom: 16, top: 4),
                child: Column(
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.grey[400],
                      size: 24,
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .moveY(begin: 0, end: -3, duration: 600.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Ещё ${products.length - 2}',
                      style: AppTextStyles.bodyTiny(AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.zero,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Нет товаров',
              style: AppTextStyles.bodySmall(AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedList(CategoryItem category) {
    final products = _getProductsForCategory(category.id);
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Нет товаров в категории',
              style: AppTextStyles.body(AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _isDragging = true;
      },
      onVerticalDragUpdate: (details) {
        if (!_isDragging) return;
        final delta = details.globalPosition.dy - _dragStartY;
        // Свайп вниз - сворачиваем (если в начале скролла)
        if (delta > 60 && _isExpanded) {
          if (!_expandedScrollController.hasClients || 
              _expandedScrollController.offset <= 0) {
            _collapseCategory();
            _isDragging = false;
          }
        }
      },
      onVerticalDragEnd: (_) {
        _isDragging = false;
      },
      child: GridView.builder(
        controller: _expandedScrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index])
              .animate(delay: Duration(milliseconds: 50 * index))
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.05, end: 0);
        },
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



