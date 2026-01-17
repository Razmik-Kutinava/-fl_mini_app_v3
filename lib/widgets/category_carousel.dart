import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final PageController? pageController; // Внешний контроллер для синхронизации

  const CategoryCarousel({
    super.key,
    required this.menuProvider,
    required this.promotions,
    required this.onCategoryChanged,
    this.onCategoryExpand,
    this.pageController,
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
    
    // Синхронизируем с выбранной категорией из provider
    _syncWithSelectedCategory();
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

    return SliverFillRemaining(
      hasScrollBody: false,
      child: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.horizontal,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          
          // Уведомляем о смене категории
          final page = pages[index];
          widget.onCategoryChanged(page.id);
        },
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final page = pages[index];
          return _buildCategoryPage(page);
        },
      ),
    );
  }

  /// Строит страницу категории с товарами
  Widget _buildCategoryPage(CategoryPageItem page) {
    final products = _getProductsForCategory(page.id);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: page.isPromo
            ? _buildPromoContent(products)
            : _buildProductsContent(products),
      ),
    );
  }

  /// Контент с промо (для страницы "для тебя")
  Widget _buildPromoContent(List<Product> products) {
    // Получаем первые два товара из первой категории
    List<Product> firstTwoProducts = [];
    if (widget.menuProvider.categories.isNotEmpty) {
      final firstCategory = widget.menuProvider.categories.first;
      final categoryProducts = _getProductsForCategory(firstCategory.id);
      firstTwoProducts = categoryProducts.take(2).toList();
    }

    return SingleChildScrollView(
      child: PromoSection(
        promotions: widget.promotions,
        products: firstTwoProducts,
      ),
    );
  }

  /// Контент с товарами
  Widget _buildProductsContent(List<Product> products) {
    final padding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = Responsive.responsiveSize(
      context,
      mobile: screenWidth * 0.45,
      tablet: 200.0,
      desktop: 250.0,
    );

    final cardHeight = cardWidth / 0.75;

    if (products.isEmpty) {
      return Center(
        child: Text(
          'Нет товаров в этой категории',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: cardWidth,
            height: cardHeight,
            margin: EdgeInsets.only(right: padding),
            child: ProductCard(product: product)
                .animate(delay: Duration(milliseconds: 50 * index))
                .fadeIn()
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),
          );
        },
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
