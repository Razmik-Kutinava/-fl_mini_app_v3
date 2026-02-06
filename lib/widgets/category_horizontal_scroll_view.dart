import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import '../models/product.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import '../providers/menu_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import '../utils/responsive.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import 'product_card.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';
import 'promo_section.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';

/// Горизонтальный скролл категорий с товарами
/// Все категории видны в одной горизонтальной полосе
/// Каждая категория показывает 2 товара в одну строку
class CategoryHorizontalScrollView extends StatefulWidget {
  final MenuProvider menuProvider;
  final List<PromoItem> promotions;
  final Function(String?) onCategoryChanged;
  final Function(String?)? onCategoryExpand;
  final void Function(String? categoryId, List<Product> products, String categoryName)? onProductsHoverExpand;
  final ScrollController? horizontalScrollController;

  const CategoryHorizontalScrollView({
    super.key,
    required this.menuProvider,
    required this.promotions,
    required this.onCategoryChanged,
    this.onCategoryExpand,
    this.onProductsHoverExpand,
    this.horizontalScrollController,
  });

  @override
  State<CategoryHorizontalScrollView> createState() => _CategoryHorizontalScrollViewState();
}

class _CategoryHorizontalScrollViewState extends State<CategoryHorizontalScrollView> {
  final Map<String, GlobalKey> _categoryKeys = {};
  bool _isScrolling = false;

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
  void initState() {
    super.initState();
    _initializeKeys();
    
    // Добавляем listener для синхронизации с навигацией
    if (widget.horizontalScrollController != null) {
      widget.horizontalScrollController!.addListener(_onScroll);
      print('✅ CategoryHorizontalScrollView: horizontalScrollController initialized');
    } else {
      print('⚠️ CategoryHorizontalScrollView: horizontalScrollController is null!');
    }
  }

  void _initializeKeys() {
    final categories = _getAllCategories();
    for (var category in categories) {
      final key = category.id ?? 'для тебя';
      _categoryKeys[key] = GlobalKey();
    }
  }

  void _onScroll() {
    if (_isScrolling || widget.horizontalScrollController == null) return;
    
    // Обновляем выбранную категорию на основе позиции скролла
    if (widget.horizontalScrollController!.hasClients) {
      final scrollPosition = widget.horizontalScrollController!.offset;
      final screenWidth = MediaQuery.of(context).size.width;
      final padding = Responsive.responsiveSize(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      );
      final itemWidth = screenWidth - padding * 2;
      if (itemWidth > 0) {
        final currentIndex = (scrollPosition / itemWidth).round();
        
        final categories = _getAllCategories();
        if (currentIndex >= 0 && currentIndex < categories.length) {
          final category = categories[currentIndex];
          if (widget.menuProvider.selectedCategoryId != category.id) {
            widget.onCategoryChanged(category.id);
          }
        }
      }
    }
  }

  /// Скроллить к категории
  void _scrollToCategory(String? categoryId) {
    if (widget.horizontalScrollController == null) return;
    
    final categories = _getAllCategories();
    int index = 0;
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].id == categoryId) {
        index = i;
        break;
      }
    }
    
    if (widget.horizontalScrollController!.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final padding = Responsive.responsiveSize(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      );
      final itemWidth = screenWidth - padding * 2;
      final targetOffset = index * itemWidth;
      
      _isScrolling = true;
      widget.horizontalScrollController!.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ).then((_) {
          _isScrolling = false;
        });
    }
  }

  @override
  void didUpdateWidget(CategoryHorizontalScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Если категории изменились, обновляем ключи
    if (oldWidget.menuProvider.categories.length != widget.menuProvider.categories.length) {
      _initializeKeys();
    }
    
    // Синхронизируем скролл с выбранной категорией
    final selectedId = widget.menuProvider.selectedCategoryId;
    if (selectedId != oldWidget.menuProvider.selectedCategoryId) {
      _scrollToCategory(selectedId);
    }
  }

  @override
  void dispose() {
    if (widget.horizontalScrollController != null) {
      widget.horizontalScrollController!.removeListener(_onScroll);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getAllCategories();
    
    print('📦 CategoryHorizontalScrollView: categories count=${categories.length}, products count=${widget.menuProvider.allProducts.length}');
    
    if (categories.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final padding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    final itemWidth = screenWidth - padding * 2;
    
    print('📐 CategoryHorizontalScrollView: screenWidth=$screenWidth, padding=$padding, itemWidth=$itemWidth');
    print('🎛️ CategoryHorizontalScrollView: horizontalScrollController=${widget.horizontalScrollController != null ? "exists" : "null"}');

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 320, // Увеличена высота для отображения товаров
        child: ListView.builder(
          controller: widget.horizontalScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          itemCount: categories.length,
          itemExtent: itemWidth, // Фиксированная ширина для каждого элемента
          itemBuilder: (context, index) {
            final category = categories[index];
            final products = _getProductsForCategory(category.id);
            print('🏷️ Building category block: ${category.name}, products count=${products.length}');
            return _buildCategoryBlock(category, index, padding);
          },
        ),
      ),
    );
  }

  /// Строит блок категории с названием и 2 товарами
  Widget _buildCategoryBlock(CategoryItem category, int index, double padding) {
    final products = _getProductsForCategory(category.id);
    
    return Container(
      key: _categoryKeys[category.id ?? 'для тебя'],
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: category.isPromo
          ? _buildPromoBlock(products, category)
          : _buildProductsBlock(products, category),
    );
  }

  /// Блок с промо (для категории "для тебя")
  Widget _buildPromoBlock(List<Product> products, CategoryItem category) {
    // Получаем первые два товара из первой категории
    List<Product> firstTwoProducts = [];
    if (widget.menuProvider.categories.isNotEmpty) {
      final firstCategory = widget.menuProvider.categories.first;
      final categoryProducts = _getProductsForCategory(firstCategory.id);
      firstTwoProducts = categoryProducts.take(2).toList();
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -5) {
          widget.onCategoryExpand?.call(category.id);
        }
      },
      child: MouseRegion(
        onEnter: (_) {
          widget.onProductsHoverExpand?.call(category.id, firstTwoProducts, category.name);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Название категории
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  category.name,
                  style: AppTextStyles.h2(AppColors.textPrimary),
                ),
              ),
              // Промо секция с двумя товарами
              PromoSection(
                promotions: widget.promotions,
                products: firstTwoProducts,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Блок с товарами (для обычных категорий)
  Widget _buildProductsBlock(List<Product> products, CategoryItem category) {
    final padding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    final spacing = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            'Нет товаров в этой категории',
            style: AppTextStyles.body(AppColors.textSecondary),
          ),
        ),
      );
    }

    // Берем только первые два товара
    final displayProducts = products.take(2).toList();

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Если свайп вверх достаточно сильный
        if (details.delta.dy < -5) {
          widget.onCategoryExpand?.call(category.id);
        }
      },
      child: MouseRegion(
        onEnter: (_) {
          widget.onProductsHoverExpand?.call(category.id, products, category.name);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Название категории
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
              child: Text(
                category.name,
                style: AppTextStyles.h2(AppColors.textPrimary),
              ),
            ),
            // Два товара в Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final totalPadding = padding * 2;
                  final totalSpacing = spacing;
                  final cardWidth = (screenWidth - totalPadding - totalSpacing) / 2;
                  final cardHeight = cardWidth / 0.75;
                  
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: ProductCard(product: displayProducts[0])
                            .animate(delay: 50.ms)
                            .fadeIn()
                            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),
                      ),
                      SizedBox(width: spacing),
                      displayProducts.length > 1
                          ? SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: ProductCard(product: displayProducts[1])
                                  .animate(delay: 100.ms)
                                  .fadeIn()
                                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),
                            )
                          : SizedBox(width: cardWidth),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
