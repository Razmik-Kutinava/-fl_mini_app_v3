import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/menu_provider.dart';
import 'product_card.dart';
import 'promo_section.dart';

/// 🎡 Карусель категорий с раскрытием
/// 
/// Простая и надёжная версия без DraggableScrollableSheet
/// - Горизонтальный свайп = смена категории
/// - Вертикальный свайп вверх = раскрытие на весь экран
/// - Кнопка закрытия = возврат к карусели
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
  late PageController _pageController;
  
  int _currentIndex = 0;
  double _pageOffset = 0.0;
  bool _isExpanded = false;
  
  // Для отслеживания свайпа
  double _dragStartY = 0;
  bool _isDragging = false;
  final ScrollController _expandedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: 0,
    );
    _pageController.addListener(_onPageScroll);
    print('🚀 CategoryDraggableSheet initialized');
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _expandedScrollController.dispose();
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
  
  void _expand() {
    HapticFeedback.lightImpact();
    setState(() => _isExpanded = true);
    print('📖 Expanded');
  }
  
  void _collapse() {
    HapticFeedback.lightImpact();
    setState(() => _isExpanded = false);
    print('📕 Collapsed');
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
    
    if (categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Навигация категорий (всегда видна)
        _buildCategoryNavigation(categories),
        
        // Карусель или развёрнутый список
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isExpanded
                ? _buildExpandedView(categories)
                : _buildCarousel(categories),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryNavigation(List<CategoryItem> categories) {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == _currentIndex;
          
          return GestureDetector(
            onTap: () {
              setState(() => _currentIndex = index);
              widget.onCategoryChanged(category.id);
              if (_pageController.hasClients) {
                _pageController.animateToPage(
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
    );
  }

  Widget _buildCarousel(List<CategoryItem> categories) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _isDragging = true;
      },
      onVerticalDragUpdate: (details) {
        if (!_isDragging) return;
        final delta = details.globalPosition.dy - _dragStartY;
        if (delta < -50) {
          _expand();
          _isDragging = false;
        }
      },
      onVerticalDragEnd: (_) => _isDragging = false,
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
            // Ручка
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Заголовок
            _buildHeader(categories[_currentIndex]),
            
            // PageView карусель
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  widget.onCategoryChanged(categories[index].id);
                  HapticFeedback.selectionClick();
                },
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildCard(categories[index], index);
                },
              ),
            ),
          ],
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
          if (_isExpanded)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close, size: 18, color: Colors.black54),
              ),
              onPressed: _collapse,
            ),
        ],
      ),
    );
  }

  Widget _buildCard(CategoryItem category, int index) {
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

  Widget _buildPromoCard(List<Product> products) {
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
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: PromoSection(
            promotions: widget.promotions,
            products: displayProducts,
          ),
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
            
            // Индикатор "ещё"
            if (products.length > 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.grey[400],
                      size: 24,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: 0, end: -3, duration: 600.ms),
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

  Widget _buildExpandedView(List<CategoryItem> categories) {
    final category = categories[_currentIndex];
    final products = _getProductsForCategory(category.id);
    
    return Container(
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
          // Заголовок с кнопкой закрытия
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
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
                  onPressed: _collapse,
                ),
              ],
            ),
          ),
          
          // Горизонтальная навигация
          SizedBox(
            height: 40,
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
          
          const SizedBox(height: 8),
          
          // Сетка товаров
          Expanded(
            child: products.isEmpty
                ? Center(
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
                  )
                : GridView.builder(
                    controller: _expandedScrollController,
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
          ),
        ],
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
