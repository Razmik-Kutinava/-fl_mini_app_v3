import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/menu_provider.dart';
import '../utils/responsive.dart';
import 'product_card.dart';
import 'promo_section.dart';

/// 🎡 3D Expandable Carousel with DraggableScrollableSheet
///
/// GESTURE LOGIC:
/// - Horizontal swipe → category switch (blocks vertical)
/// - Vertical swipe → expand/collapse (blocks horizontal)
/// - Tap (< 20px) → open product detail
/// - Fast swipe (velocity > 1000) → instant detection
///
/// ARCHITECTURE:
/// - Stack with Header, Background, Tabs (AnimatedOpacity)
/// - DraggableScrollableSheet (0.35 collapsed, 1.0 expanded)
/// - PageView for horizontal category navigation
/// - GridView for vertical product scrolling
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

  // === CONTROLLERS ===
  late DraggableScrollableController _sheetController;
  late PageController _pageController;
  ScrollController? _scrollController; // Provided by DraggableScrollableSheet

  // === STATE ===
  bool _isExpanded = false;
  bool _isFirstLoad = true;
  int _currentIndex = 0;
  double _pageOffset = 0.0;

  // === GESTURE DETECTION ===
  double _dragStartX = 0;
  double _dragStartY = 0;
  bool _isDragging = false;
  bool _isHorizontalGesture = false;
  bool _isVerticalGesture = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _sheetController = DraggableScrollableController();
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: 0,
    );

    // First appearance animation
    if (_isFirstLoad) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _sheetController.animateTo(
            0.35,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
      _isFirstLoad = false;
    }

    // Add listeners
    _sheetController.addListener(_onSheetChanged);
    _pageController.addListener(_onPageChanged);

    final categories = _getAllCategories();
    print('🚀 Category3DCarouselView initialized: ${categories.length} categories');
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _pageController.removeListener(_onPageChanged);
    _sheetController.dispose();
    _pageController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  // === LISTENERS ===

  void _onSheetChanged() {
    if (!_sheetController.isAttached) return;

    final size = _sheetController.size;
    final wasExpanded = _isExpanded;
    final nowExpanded = size > 0.6;

    if (wasExpanded != nowExpanded) {
      setState(() {
        _isExpanded = nowExpanded;
      });

      if (nowExpanded) {
        HapticFeedback.lightImpact();
        print('📖 Sheet expanded (size: ${size.toStringAsFixed(2)})');
      } else {
        print('📕 Sheet collapsed (size: ${size.toStringAsFixed(2)})');
      }
    }
  }

  void _onPageChanged() {
    if (!_pageController.hasClients) return;

    setState(() {
      _pageOffset = _pageController.page ?? 0;
    });
  }

  // === EXPAND/COLLAPSE METHODS ===

  void _expandSheet() {
    if (!_sheetController.isAttached) return;

    print('⬆️ Expanding sheet');
    _sheetController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _collapseSheet() {
    if (!_sheetController.isAttached) return;

    print('⬇️ Collapsing sheet');
    _sheetController.animateTo(
      0.35,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  // === CATEGORY HELPERS ===

  List<CategoryItem> _getAllCategories() {
    final categories = <CategoryItem>[];

    // First category - "для тебя"
    categories.add(CategoryItem(
      id: null,
      name: 'для тебя',
      isPromo: true,
    ));

    // Rest of categories
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

    return SliverToBoxAdapter(
      child: SizedBox(
        height: screenHeight - 180, // Full available height minus app bar
        child: Stack(
          children: [
            // Header (fades out when expanded)
            AnimatedOpacity(
              opacity: _isExpanded ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: _buildHeader(categories),
            ),

            // DraggableScrollableSheet with products
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.35,
              minChildSize: 0.35,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.35, 1.0],
              builder: (context, scrollController) {
                // Store scroll controller
                _scrollController = scrollController;

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _buildProductCarousel(categories, scrollController),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<CategoryItem> categories) {
    final currentCategory = categories[_currentIndex];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Position indicator
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
          ],
        ),
      ),
    );
  }

  Widget _buildProductCarousel(List<CategoryItem> categories, ScrollController scrollController) {
    if (_isExpanded) {
      // EXPANDED: Full grid view with vertical scroll
      return _buildExpandedView(categories, scrollController);
    } else {
      // COLLAPSED: 3D carousel with horizontal PageView
      return _build3DCarousel(categories);
    }
  }

  Widget _build3DCarousel(List<CategoryItem> categories) {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        print('🔄 Swiped to index $index (${categories[index].name})');
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

  Widget _build3DCard(CategoryItem category, int index) {
    // Calculate offset for 3D transform
    double diff = (index - _pageOffset);

    // Rotation angle (limited)
    double rotationY = diff.clamp(-1.0, 1.0) * 0.3; // Up to ~17°

    // Scale based on distance from center
    double scale = 1 - (diff.abs() * 0.15).clamp(0.0, 0.3);

    // Opacity for side cards
    double opacity = 1 - (diff.abs() * 0.3).clamp(0.0, 0.5);

    // Translate for depth
    double translateX = diff * 20;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(rotationY)
            ..scale(scale)
            ..translate(translateX),
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

    return _buildProductsCard(products, isActive, category);
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

  Widget _buildProductsCard(List<Product> products, bool isActive, CategoryItem category) {
    final padding = Responsive.responsiveSize(
      context,
      mobile: 14.0,
      tablet: 22.0,
      desktop: 30.0,
    );

    final displayProducts = products.take(2).toList();

    if (displayProducts.isEmpty) {
      return _buildEmptyCard();
    }

    return GestureDetector(
      // === GESTURE DETECTION FOR EXPAND/COLLAPSE ===
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _dragStartX = details.globalPosition.dx;
        _isDragging = true;
        _isVerticalGesture = false;
        _isHorizontalGesture = false;
      },
      onVerticalDragUpdate: (details) {
        if (!_isDragging) return;

        final deltaY = details.globalPosition.dy - _dragStartY;
        final deltaX = details.globalPosition.dx - _dragStartX;
        final distance = (deltaX * deltaX + deltaY * deltaY);

        // Determine gesture direction
        if (!_isVerticalGesture && !_isHorizontalGesture) {
          // Determine direction based on distance threshold
          if (distance > 400) { // 20px * 20px threshold
            // Determine direction based on ratio
            if (deltaY.abs() > deltaX.abs() * 1.3) {
              _isVerticalGesture = true;
            } else if (deltaX.abs() > deltaY.abs() * 1.3) {
              _isHorizontalGesture = true;
            }
          }
        }

        // Execute gesture
        if (_isVerticalGesture) {
          // Vertical gesture: expand/collapse
          if (!_isExpanded && deltaY < -80) {
            _expandSheet();
          }
        }
        // Horizontal gestures handled by PageView automatically
      },
      onVerticalDragEnd: (details) {
        _isDragging = false;
        _isVerticalGesture = false;
        _isHorizontalGesture = false;
      },
      child: Container(
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
            BoxShadow(
              color: isActive
                  ? Colors.pink.withOpacity(0.25)
                  : Colors.black.withOpacity(0.12),
              blurRadius: isActive ? 35 : 20,
              offset: const Offset(0, 12),
              spreadRadius: isActive ? 3 : 0,
            ),
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
              // Decorative top stripe
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

              // Product grid (2 products)
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

              // "Swipe up" indicator
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
      ),
    );
  }

  Widget _buildEmptyCard() {
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

  Widget _buildExpandedView(List<CategoryItem> categories, ScrollController scrollController) {
    final currentCategory = categories[_currentIndex];
    final products = _getProductsForCategory(currentCategory.id);
    final padding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return Column(
      children: [
        // Expanded header with close button
        Container(
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
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.black54, size: 20),
                ),
                onPressed: _collapseSheet,
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
            ],
          ),
        ),

        // Product grid with vertical scroll
        Expanded(
          child: GestureDetector(
            onVerticalDragStart: (details) {
              _dragStartY = details.globalPosition.dy;
              _isDragging = true;
            },
            onVerticalDragUpdate: (details) {
              if (!_isDragging) return;

              final delta = details.globalPosition.dy - _dragStartY;

              // Collapse only if at top of scroll and swiping down
              if (_isExpanded &&
                  scrollController.hasClients &&
                  scrollController.offset == 0 &&
                  delta > 80) {
                _collapseSheet();
              }
            },
            onVerticalDragEnd: (details) {
              _isDragging = false;
            },
            child: _buildProductGrid(products, scrollController, padding),
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid(List<Product> products, ScrollController scrollController, double padding) {
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

    return CustomScrollView(
      controller: scrollController,
      physics: _isExpanded
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(padding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: padding,
              crossAxisSpacing: padding,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ProductCard(product: products[index])
                    .animate(delay: Duration(milliseconds: 50 * index))
                    .fadeIn()
                    .slideY(begin: 0.05, end: 0)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0));
              },
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// Category item model
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
