import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/menu_provider.dart';
import 'product_card.dart';
import 'promo_section.dart';

/// 🎡 Draggable Sheet с 3D каруселью категорий
/// 
/// Три состояния (snap points):
/// - MIN (10%) - карусель почти скрыта
/// - MID (50%) - 1 ряд с 2 товарами  
/// - MAX (100%) - полный экран со всеми товарами
///
/// Горизонтальный свайп работает ВСЕГДА
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

class _CategoryDraggableSheetState extends State<CategoryDraggableSheet> {
  // Контроллеры
  late DraggableScrollableController _sheetController;
  late PageController _pageController;
  
  // Состояние
  int _currentIndex = 0;
  double _pageOffset = 0.0;
  double _sheetSize = 0.5; // Текущий размер sheet
  
  // Snap points
  static const double _minSize = 0.12;  // 12% - минимум (только ручка)
  static const double _midSize = 0.50;  // 50% - середина (1 ряд товаров)
  static const double _maxSize = 1.0;   // 100% - полный экран

  @override
  void initState() {
    super.initState();
    
    _sheetController = DraggableScrollableController();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 0,
    );
    
    _pageController.addListener(_onPageScroll);
    _sheetController.addListener(_onSheetChanged);
    
    print('🚀 CategoryDraggableSheet initialized');
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _sheetController.removeListener(_onSheetChanged);
    _pageController.dispose();
    _sheetController.dispose();
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
    
    if (targetIndex != _currentIndex && _pageController.hasClients) {
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
  
  void _onSheetChanged() {
    if (_sheetController.isAttached) {
      setState(() {
        _sheetSize = _sheetController.size;
      });
    }
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
  
  bool get _isFullScreen => _sheetSize > 0.85;
  bool get _isMidState => _sheetSize > 0.35 && _sheetSize <= 0.85;
  bool get _isMinState => _sheetSize <= 0.35;

  @override
  Widget build(BuildContext context) {
    final categories = _getAllCategories();
    
    if (categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _midSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [_minSize, _midSize, _maxSize],
      snapAnimationDuration: const Duration(milliseconds: 300),
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_isFullScreen ? 0 : 32),
              topRight: Radius.circular(_isFullScreen ? 0 : 32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Ручка для перетаскивания
              _buildDragHandle(),
              
              // Заголовок категории
              _buildHeader(categories),
              
              // Контент (карусель или полный список)
              Expanded(
                child: _isFullScreen
                    ? _buildFullScreenContent(categories, scrollController)
                    : _build3DCarousel(categories),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        // Цикличное переключение между состояниями
        if (_isMinState) {
          _sheetController.animateTo(
            _midSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else if (_isMidState) {
          _sheetController.animateTo(
            _maxSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _sheetController.animateTo(
            _midSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isFullScreen ? 60 : 40,
            height: 4,
            decoration: BoxDecoration(
              color: _isFullScreen ? Colors.grey.shade400 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<CategoryItem> categories) {
    final currentCategory = categories[_currentIndex];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: _isFullScreen ? 12 : 8,
      ),
      child: Row(
        children: [
          // Градиентная полоска
          Container(
            width: 4,
            height: _isFullScreen ? 32 : 28,
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
                fontSize: _isFullScreen ? 26 : 22,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Кнопка закрытия (только в полноэкранном режиме)
          if (_isFullScreen)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.black54, size: 20),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                _sheetController.animateTo(
                  _midSize,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _build3DCarousel(List<CategoryItem> categories) {
    return PageView.builder(
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
    );
  }

  Widget _build3DCard(CategoryItem category, int index) {
    double diff = (index - _pageOffset);
    double rotationY = diff.clamp(-1.0, 1.0) * 0.15;
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
    
    return _buildProductsCard(products, isActive);
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
        borderRadius: BorderRadius.circular(24),
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
        borderRadius: BorderRadius.circular(24),
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
    final displayProducts = products.take(2).toList();
    
    if (displayProducts.isEmpty) {
      return _buildEmptyCard();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Градиентная полоска сверху
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
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[500],
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

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Нет товаров',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenContent(List<CategoryItem> categories, ScrollController scrollController) {
    final currentCategory = categories[_currentIndex];
    final products = _getProductsForCategory(currentCategory.id);
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Нет товаров в категории',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Горизонтальная карусель категорий (всегда видна)
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = index == _currentIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentIndex = index);
                  widget.onCategoryChanged(cat.id);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.pink.shade300 : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
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
        
        const SizedBox(height: 8),
        
        // Сетка товаров
        Expanded(
          child: GridView.builder(
            controller: scrollController,
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
        ),
      ],
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
