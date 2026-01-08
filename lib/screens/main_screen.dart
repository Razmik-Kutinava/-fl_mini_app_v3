import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:page_transition/page_transition.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../providers/menu_provider.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../widgets/background_hero_banner.dart';
import '../widgets/location_app_bar.dart';
import '../widgets/hero_promo_content.dart';
import '../widgets/category_navigation_scrollable.dart';
import '../widgets/promo_section.dart';
import '../utils/responsive.dart';
import 'cart_screen.dart';
import 'location_select_screen.dart';
import 'location_map_screen.dart';
import 'category_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // Состояние расширения категории
  bool _isCategoryExpanded = false;
  String? _expandedCategoryId;
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;
  late PageController _categoryPageController;
  int _currentCategoryPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMenu();

    // Инициализация анимации расширения
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );

    // Инициализация PageController для переключения категорий
    _categoryPageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _expansionController.dispose();
    _categoryPageController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    final menuProvider = context.read<MenuProvider>();
    final locationProvider = context.read<LocationProvider>();

    menuProvider.setLoading(true);

    final locationId = locationProvider.selectedLocation?.id ?? 'loc_1';
    final menuData = await _apiService.getMenu(locationId);

    menuProvider.setCategories(menuData['categories']);
    menuProvider.setProducts(menuData['products']);
    menuProvider.setLoading(false);
  }

  /// Обработка нажатия на иконку геолокации — открываем экран карты локации.
  void _handleGeoRequest() {
    final locationProvider = context.read<LocationProvider>();
    final location = locationProvider.selectedLocation;
    
    if (location != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationMapScreen(location: location),
        ),
      );
    } else {
      // Fallback: если локация не выбрана, открываем экран выбора
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
      );
    }
  }

  /// Проверяет, выбрана ли категория "акции" или "для тебя"
  bool _isPromotionsCategory(String? categoryId, List categories) {
    // Категория "для тебя" (selectedCategoryId == null) показывает промо
    if (categoryId == null) return true;

    // Ищем категорию по id
    try {
      final category = categories.firstWhere((cat) => cat.id == categoryId);
      // Проверяем название категории - если это "акции" или "промо", показываем промо
      final name = category.name.toLowerCase();
      return name.contains('акци') || name.contains('промо');
    } catch (e) {
      // Если категория не найдена, показываем товары (не промо)
      return false;
    }
  }

  /// Получает товары для категории
  List<Product> _getProductsForCategory(
    String? categoryId,
    MenuProvider menuProvider,
  ) {
    if (categoryId == null) return menuProvider.allProducts;
    return menuProvider.allProducts
        .where((p) => p.categoryId == categoryId)
        .toList();
  }

  /// Получает список промо-акций для отображения
  List<PromoItem> _getPromotions() {
    // TODO: Загружать реальные промо из API или БД
    // Пока используем моковые данные
    return [
      PromoItem(
        title: 'Время чудес',
        emoji: '❄️',
        gradient: AppColors.promoCardGradient1,
      ),
      PromoItem(
        title: 'Shimmering sprinkles',
        emoji: '✨',
        gradient: AppColors.promoCardGradient2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final location = locationProvider.selectedLocation;
    final isPromotions = _isPromotionsCategory(
      menuProvider.selectedCategoryId,
      menuProvider.categories,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Фоновый баннер на весь экран
          BackgroundHeroBanner(scrollController: _scrollController),

          // Основной контент поверх фона
          Column(
            children: [
              // Location App Bar
              LocationAppBar(
                location: location,
                onLocationTap: () {
                  // Открываем экран карты локации при нажатии на иконку или название
                  if (location != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationMapScreen(location: location),
                      ),
                    );
                  } else {
                    _handleGeoRequest();
                  }
                },
                onProfileTap: () {
                  // TODO: Открыть профиль
                },
              ),

              // Скроллируемый контент
              Expanded(
                child: menuProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadMenu,
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            // Hero промо-контент (текст поверх фона)
                            SliverToBoxAdapter(
                              child: const HeroPromoContent()
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideY(begin: 0.2, end: 0),
                            ),

                            // Навигация по категориям (внутри скролла, полупрозрачный черный фон)
                            CategoryNavigationScrollable(
                              categories: menuProvider.categories,
                              selectedCategoryId:
                                  menuProvider.selectedCategoryId,
                              onCategorySelected: (categoryId) {
                                // При нажатии просто показываем товары на главном экране
                                menuProvider.selectCategory(categoryId);
                              },
                              onCategoryExpand: (categoryId) {
                                // При свайпе вправо на категории - расширяем на полный экран
                                if (categoryId != null &&
                                    !_isCategoryExpanded) {
                                  print(
                                    '🔥 Expanding category from swipe: $categoryId',
                                  );
                                  final products = _getProductsForCategory(
                                    categoryId,
                                    menuProvider,
                                  );
                                  if (products.isNotEmpty) {
                                    _expandCategory(categoryId);
                                  }
                                }
                              },
                            ),

                            // Темный полупрозрачный фон для товаров/промо
                            SliverToBoxAdapter(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Белый контейнер с закругленными верхними углами (внутри темного фона)
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(30),
                                          topRight: Radius.circular(30),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Динамический контент в зависимости от категории
                                          if (isPromotions)
                                            // Промо секция (если выбрана категория "для тебя" или акции)
                                            PromoSection(
                                              promotions: _getPromotions(),
                                            )
                                          else
                                            // Товары в GridView (не Sliver, так как уже внутри SliverToBoxAdapter)
                                            _buildProductsGrid(
                                              context,
                                              menuProvider,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),

          // Расширенный вид категории (overlay при свайпе)
          if (_isCategoryExpanded) _buildExpandedCategoryView(menuProvider),
        ],
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.itemCount > 0) {
            return badges.Badge(
              badgeContent: Text(
                '${cartProvider.itemCount}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.accent),
              position: badges.BadgePosition.topEnd(top: -8, end: -8),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  print(
                    '🛒 Cart button pressed, items: ${cartProvider.items.length}',
                  );
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      child: const CartScreen(),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                  '${cartProvider.total.toStringAsFixed(0)} ₽',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.5);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// GridView товаров (не Sliver, для использования внутри SliverToBoxAdapter)
  Widget _buildProductsGrid(BuildContext context, MenuProvider menuProvider) {
    // Адаптивное количество колонок
    final crossAxisCount = Responsive.responsiveCrossAxisCount(context);

    // Адаптивные отступы
    final padding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return Container(
      padding: EdgeInsets.all(padding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: menuProvider.products.length,
        itemBuilder: (context, index) {
          final product = menuProvider.products[index];
          return ProductCard(product: product)
              .animate(delay: Duration(milliseconds: 50 * index))
              .fadeIn()
              .scale(begin: const Offset(0.9, 0.9));
        },
      ),
    );
  }

  /// Получить список категорий с товарами (для PageView)
  List<MapEntry<String, List<Product>>> _getCategoriesWithProducts(
    MenuProvider menuProvider,
  ) {
    final result = <MapEntry<String, List<Product>>>[];

    // Добавляем все категории, у которых есть товары
    for (var category in menuProvider.categories) {
      final products = _getProductsForCategory(category.id, menuProvider);
      if (products.isNotEmpty) {
        result.add(MapEntry(category.id, products));
      }
    }

    return result;
  }

  /// Найти индекс категории в списке категорий с товарами
  int _findCategoryIndex(
    String? categoryId,
    List<MapEntry<String, List<Product>>> categoriesWithProducts,
  ) {
    for (int i = 0; i < categoriesWithProducts.length; i++) {
      if (categoriesWithProducts[i].key == categoryId) {
        return i;
      }
    }
    return 0;
  }

  /// Расширенный вид категории (full-screen overlay) с PageView
  Widget _buildExpandedCategoryView(MenuProvider menuProvider) {
    if (_expandedCategoryId == null) return const SizedBox.shrink();

    final categoriesWithProducts = _getCategoriesWithProducts(menuProvider);
    if (categoriesWithProducts.isEmpty) return const SizedBox.shrink();

    // Убедимся, что PageController установлен на правильную страницу
    final initialIndex = _findCategoryIndex(
      _expandedCategoryId,
      categoriesWithProducts,
    );
    if (_categoryPageController.hasClients &&
        _currentCategoryPageIndex != initialIndex) {
      _categoryPageController.jumpToPage(initialIndex);
      _currentCategoryPageIndex = initialIndex;
    }

    return AnimatedBuilder(
      animation: _expansionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_expansionAnimation.value * 0.2), // От 0.8 до 1.0
          child: Opacity(
            opacity: _expansionAnimation.value,
            child: Stack(
              children: [
                // PageView для навигации между категориями (встроенные свайпы работают автоматически)
                PageView.builder(
                  controller: _categoryPageController,
                  itemCount: categoriesWithProducts.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentCategoryPageIndex = index;
                      _expandedCategoryId = categoriesWithProducts[index].key;
                    });
                    // Обновить выбранную категорию в provider
                    menuProvider.selectCategory(
                      categoriesWithProducts[index].key,
                    );
                  },
                  itemBuilder: (context, index) {
                    final entry = categoriesWithProducts[index];
                    final category = menuProvider.categories.firstWhere(
                      (cat) => cat.id == entry.key,
                      orElse: () => menuProvider.categories.first,
                    );

                    return CategoryScreen(
                      category: category,
                      products: entry.value,
                      onBack: _collapseCategory,
                    );
                  },
                ),
                // Прозрачный слой для закрытия свайпом вверх (НЕ перехватывает горизонтальные свайпы PageView)
                Positioned.fill(
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      // Свайп вверх - закрыть расширение
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! < -300) {
                        print(
                          '⬆️ Vertical swipe up detected - closing expanded view',
                        );
                        _collapseCategory();
                      }
                    },
                    // НЕ обрабатываем горизонтальные свайпы здесь - PageView делает это сам!
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Запуск расширения категории
  void _expandCategory(String? categoryId) {
    final menuProvider = context.read<MenuProvider>();
    final categoriesWithProducts = _getCategoriesWithProducts(menuProvider);
    final initialIndex = _findCategoryIndex(categoryId, categoriesWithProducts);

    setState(() {
      _expandedCategoryId = categoryId;
      _isCategoryExpanded = true;
      _currentCategoryPageIndex = initialIndex;
    });

    // Установить правильную страницу в PageController после первого кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_categoryPageController.hasClients &&
          _categoryPageController.page != initialIndex.toDouble()) {
        _categoryPageController.jumpToPage(initialIndex);
      }
    });

    _expansionController.forward();
  }

  /// Закрытие расширенного вида
  void _collapseCategory() {
    _expansionController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isCategoryExpanded = false;
          _expandedCategoryId = null;
        });
      }
    });
  }
}
