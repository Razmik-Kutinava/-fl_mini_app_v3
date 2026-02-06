import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/product.dart';
import '../providers/menu_provider.dart';
import '../utils/responsive.dart';
import 'product_card.dart';
import 'promo_section.dart';

/// Карусель категорий с товарами
/// Каждая страница = одна категория с её товарами
/// Горизонтальный свайп переключает между категориями
class CategoryCarousel extends StatefulWidget {
  final MenuProvider menuProvider;
  final List<PromoItem> promotions;
  final Function(String?) onCategoryChanged;
  final Function(String?)? onCategoryExpand;
  final void Function(String? categoryId, List<Product> products, String categoryName)? onProductsHoverExpand;
  final PageController? pageController;
  final ScrollController? horizontalScrollController;

  const CategoryCarousel({
    super.key,
    required this.menuProvider,
    required this.promotions,
    required this.onCategoryChanged,
    this.onCategoryExpand,
    this.onProductsHoverExpand,
    this.pageController,
    this.horizontalScrollController,
  });

  @override
  State<CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<CategoryCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  
  PageController get pageController => widget.pageController ?? _pageController;

  /// Получить список всех категорий включая "для тебя"
  List<CategoryPageItem> _getAllCategoryPages() {
    final pages = <CategoryPageItem>[];
    
    // Первая страница - "для тебя"
    pages.add(CategoryPageItem(
      id: null,
      name: 'для тебя',
      isPromo: true,
    ));
    
    // Остальные категории (автоматически добавляются из menuProvider)
    for (var category in widget.menuProvider.categories) {
      pages.add(CategoryPageItem(
        id: category.id,
        name: category.name,
        isPromo: false,
      ));
    }
    
    return pages;
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
    // Используем внешний контроллер или создаем свой
    if (widget.pageController == null) {
      _pageController = PageController(initialPage: 0);
    }
    
    // Добавляем listener на общий контроллер для синхронизации
    if (widget.horizontalScrollController != null) {
      widget.horizontalScrollController!.addListener(_onHorizontalScroll);
    }
    
    // Синхронизируем с выбранной категорией из provider
    _syncWithSelectedCategory();
  }

  void _onHorizontalScroll() {
    // Синхронизация горизонтального скролла навигации с переключением страниц
    // Обрабатывается через переключение страниц в PageView
  }

  /// Синхронизирует скролл навигации с текущей страницей
  void _syncNavigationScroll(int pageIndex, List<CategoryPageItem> pages) {
    // Пропорционально скроллим навигацию в зависимости от текущей страницы
    if (pages.isEmpty) return;
    
    final maxPages = pages.length - 1;
    if (maxPages <= 0) return;
    
    final ratio = pageIndex / maxPages;
    final navMax = widget.horizontalScrollController!.position.maxScrollExtent;
    if (navMax > 0) {
      final targetOffset = ratio * navMax;
      widget.horizontalScrollController!.animateTo(
        targetOffset.clamp(0.0, navMax),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void didUpdateWidget(CategoryCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Если категории изменились (добавились новые), обновляем карусель
    if (oldWidget.menuProvider.categories.length != 
        widget.menuProvider.categories.length) {
      setState(() {
        // Карусель автоматически обновится через rebuild
      });
    }
    
    // Синхронизируем с выбранной категорией
    _syncWithSelectedCategory();
  }

  /// Синхронизирует PageView с выбранной категорией из provider
  void _syncWithSelectedCategory() {
    final selectedId = widget.menuProvider.selectedCategoryId;
    final pages = _getAllCategoryPages();
    
    // Находим индекс страницы для выбранной категории
    int targetIndex = 0;
    for (int i = 0; i < pages.length; i++) {
      if (pages[i].id == selectedId) {
        targetIndex = i;
        break;
      }
    }
    
    // Если текущая страница не совпадает с выбранной, переключаем
    if (_currentPage != targetIndex && pageController.hasClients) {
      pageController.jumpToPage(targetIndex);
      _currentPage = targetIndex;
    }
  }

  @override
  void dispose() {
    // Удаляем listener
    if (widget.horizontalScrollController != null) {
      widget.horizontalScrollController!.removeListener(_onHorizontalScroll);
    }
    
    // Удаляем только если мы создали контроллер сами
    if (widget.pageController == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getAllCategoryPages();
    
    if (pages.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final height = MediaQuery.of(context).size.height - 280;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: height > 0 ? height : 400,
        child: PageView.builder(
          controller: pageController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // Более плавный свайп
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });

            // Уведомляем о смене категории
            final page = pages[index];
            widget.onCategoryChanged(page.id);
            
            // Синхронизируем горизонтальный скролл навигации с текущей страницей
            if (widget.horizontalScrollController != null && 
                widget.horizontalScrollController!.hasClients) {
              _syncNavigationScroll(index, pages);
            }
          },
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            return _buildCategoryPage(page, index);
          },
        ),
      ),
    );
  }

  /// Строит страницу категории с товарами
  Widget _buildCategoryPage(CategoryPageItem page, int pageIndex) {
    final products = _getProductsForCategory(page.id);
    
    return Container(
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.4),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.zero,
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 2),
              left: BorderSide(color: AppColors.primary, width: 2),
              right: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          child: page.isPromo
              ? _buildPromoContent(products, page)
              : _buildProductsContent(products, pageIndex, page),
        ),
      );
  }

  /// Контент с промо (для страницы "для тебя")
  Widget _buildPromoContent(List<Product> products, CategoryPageItem page) {
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
          widget.onCategoryExpand?.call(page.id);
        }
      },
      child: MouseRegion(
        onEnter: (_) {
          widget.onProductsHoverExpand?.call(page.id, firstTwoProducts, page.name);
        },
        child: SingleChildScrollView(
          child: PromoSection(
            promotions: widget.promotions,
            products: firstTwoProducts,
          ),
        ),
      ),
    );
  }

  /// Контент с товарами - показывает только первые два товара
  Widget _buildProductsContent(List<Product> products, int pageIndex, CategoryPageItem page) {
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
            'НЕТ ТОВАРОВ В ЭТОЙ КАТЕГОРИИ',
            style: AppTextStyles.body().copyWith(color: AppColors.textSecondary),
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
          widget.onCategoryExpand?.call(page.id);
        }
      },
      child: MouseRegion(
        onEnter: (_) {
          widget.onProductsHoverExpand?.call(page.id, products, page.name);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 0.75,
                  child: ProductCard(product: displayProducts[0])
                      .animate(delay: 50.ms)
                      .fadeIn()
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: displayProducts.length > 1
                    ? AspectRatio(
                        aspectRatio: 0.75,
                        child: ProductCard(product: displayProducts[1])
                            .animate(delay: 100.ms)
                            .fadeIn()
                            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Элемент страницы категории
class CategoryPageItem {
  final String? id;
  final String name;
  final bool isPromo;

  CategoryPageItem({
    this.id,
    required this.name,
    required this.isPromo,
  });
}
