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
import '../models/product.dart';
import '../widgets/background_hero_banner.dart';
import '../widgets/location_app_bar.dart';
import '../widgets/hero_promo_content.dart';
import '../widgets/promo_section.dart';
import '../widgets/promo_card.dart';
import '../widgets/category_horizontal_scroll_view.dart';
import '../widgets/category_navigation_scrollable.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'location_select_screen.dart';
import 'location_map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final PageController _expandedCategoryPageController = PageController(initialPage: 0); // Для overlay с раскрытыми категориями
  final ScrollController _horizontalScrollController = ScrollController(); // Общий контроллер для синхронизации

  // Состояние расширения категории
  bool _isCategoryExpanded = false;
  String? _expandedCategoryId;
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;
  ScrollController? _expandedCategoryScrollController; // Контроллер для отслеживания скролла в раскрытой категории
  double _dragOffset = 0.0; // Смещение при "тянущемся" эффекте
  bool _isDragging = false; // Флаг активного перетаскивания
  
  // Состояние промо-акций
  List<PromoItem> _promotions = [];
  bool _isLoadingPromotions = false;

  // Развёртка при наведении на товары: полноэкран, вертикальный + горизонтальный скролл
  bool _isProductsHoverExpanded = false;
  PageController? _productsHoverPageController;
  DateTime? _lastOverlayCloseTime; // Время последнего закрытия оверлея

  @override
  void initState() {
    super.initState();
    _loadMenu();

    // Инициализация анимации расширения
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Чуть медленнее
    );
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );

    // PageController уже инициализирован в объявлении
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _expandedCategoryPageController.dispose();
    _horizontalScrollController.dispose();
    _productsHoverPageController?.dispose();
    _expandedCategoryScrollController?.dispose();
    _expansionController.dispose();
    super.dispose();
  }

  void _closeProductsHoverOverlay() {
    _productsHoverPageController?.dispose();
    _productsHoverPageController = null;
    _lastOverlayCloseTime = DateTime.now(); // Запоминаем время закрытия
    setState(() {
      _isProductsHoverExpanded = false;
    });
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
    
    // Загружаем промо после загрузки меню
    _loadPromotions();
  }
  
  Future<void> _loadPromotions() async {
    if (_isLoadingPromotions) return;
    
    setState(() {
      _isLoadingPromotions = true;
    });
    
    try {
      final promotions = await _getPromotions();
      setState(() {
        _promotions = promotions;
        _isLoadingPromotions = false;
      });
    } catch (e) {
      print('⚠️ [loadPromotions] Error: $e');
      setState(() {
        _isLoadingPromotions = false;
      });
    }
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

  /// Переключает горизонтальный скролл на указанную категорию
  void _switchToCategory(String? categoryId, MenuProvider menuProvider) {
    // Синхронизация происходит автоматически через CategoryHorizontalScrollView
    // при изменении selectedCategoryId в menuProvider
  }

  /// Получает список промо-акций для отображения
  Future<List<PromoItem>> _getPromotions() async {
    final promotions = <PromoItem>[];
    
    // ВСЕГДА добавляем первую акцию "Весеннее настроение" - одна в строке
    promotions.add(
      PromoItem(
        title: 'Весеннее настроение',
        emoji: '🌸',
        gradient: AppColors.promoCardGradientSpring,
      ),
    );
    
    print('✅ [getPromotions] Added "Весеннее настроение" promo');
    
    print('✅ [getPromotions] Total promotions: ${promotions.length}');
    return promotions;
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final location = locationProvider.selectedLocation;

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
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            // Отслеживаем вертикальный скролл для раскрытия категории
                            if (notification is ScrollUpdateNotification && !_isCategoryExpanded) {
                              final scrollDelta = notification.scrollDelta;
                              if (scrollDelta != null && scrollDelta > 0) {
                                // Скролл вниз - проверяем, нужно ли раскрыть категорию
                                final scrollPosition = notification.metrics.pixels;
                                
                                // Если скроллим вниз и достигли области категорий (примерно после Hero контента)
                                // Порог: после 200px скролла начинаем проверять раскрытие
                                if (scrollPosition > 200) {
                                  final menuProvider = context.read<MenuProvider>();
                                  final selectedCategoryId = menuProvider.selectedCategoryId;
                                  if (selectedCategoryId != null) {
                                    final products = _getProductsForCategory(selectedCategoryId, menuProvider);
                                    if (products.isNotEmpty) {
                                      // Раскрываем категорию при скролле вниз
                                      _expandCategory(selectedCategoryId);
                                    }
                                  }
                                }
                              }
                            }
                            return false; // Позволяем скроллу продолжаться
                          },
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

                            // Навигация по категориям (все заголовки видны)
                            CategoryNavigationScrollable(
                              categories: menuProvider.categories,
                              selectedCategoryId: menuProvider.selectedCategoryId,
                              horizontalScrollController: _horizontalScrollController,
                              onCategorySelected: (categoryId) {
                                // При клике на категорию - переключаем карусель
                                menuProvider.selectCategory(categoryId);
                                _switchToCategory(categoryId, menuProvider);
                              },
                              onCategoryExpand: (categoryId) {
                                // При свайпе вправо на категории - расширяем на полный экран
                                if (categoryId != null && !_isCategoryExpanded) {
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

                            // Карусель категорий с товарами
                            _isLoadingPromotions
                                ? const SliverToBoxAdapter(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  )
                                : CategoryHorizontalScrollView(
                                    menuProvider: menuProvider,
                                    promotions: _promotions,
                                    horizontalScrollController: _horizontalScrollController,
                                    onCategoryChanged: (categoryId) {
                                      menuProvider.selectCategory(categoryId);
                                    },
                                    onCategoryExpand: (categoryId) {
                                      if (categoryId != null && !_isCategoryExpanded) {
                                        final products = _getProductsForCategory(categoryId, menuProvider);
                                        if (products.isNotEmpty) _expandCategory(categoryId);
                                      }
                                    },
                                    onProductsHoverExpand: (categoryId, products, categoryName) {
                                      if (products.isEmpty && categoryId != null) return;
                                      print('🖱️ [HoverExpand] Triggered for: $categoryName');
                                      
                                      // Предотвращаем резкое повторное открытие сразу после закрытия
                                      if (_lastOverlayCloseTime != null && 
                                          DateTime.now().difference(_lastOverlayCloseTime!) < const Duration(milliseconds: 600)) {
                                        return;
                                      }

                                      final menuProvider = context.read<MenuProvider>();
                                      final cats = _getCategoriesWithProducts(menuProvider);
                                      
                                      // Вычисляем индекс: 0 для «для тебя», либо 1 + индекс категории
                                      int idx = 0;
                                      if (categoryId != null) {
                                        if (cats.isEmpty) return;
                                        idx = 1 + _findCategoryIndex(categoryId, cats);
                                      }

                                      _productsHoverPageController?.dispose();
                                      _productsHoverPageController = PageController(initialPage: idx);
                                      setState(() {
                                        _isProductsHoverExpanded = true;
                                      });
                                    },
                                  ),
                          ],
                          ),
                        ),
                      ),
              ),
            ],
          ),

          // Расширенный вид категории (overlay при свайпе)
          if (_isCategoryExpanded) _buildExpandedCategoryView(menuProvider),
          // Развёртка при наведении на товары: полноэкранный вертикальный список
          if (_isProductsHoverExpanded) _buildProductsHoverExpandedOverlay(),
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

  /// Расширенный вид категории (full-screen overlay) с отслеживанием скролла
  Widget _buildExpandedCategoryView(MenuProvider menuProvider) {
    if (!_isCategoryExpanded) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _expansionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_expansionAnimation.value * 0.2), // От 0.8 до 1.0
          child: Opacity(
            opacity: _expansionAnimation.value,
            child: _buildExpandableCategoryOverlay(),
          ),
        );
      },
    );
  }

  /// Оверлей с раскрытой категорией - показывает все товары с PageView для горизонтальной навигации
  Widget _buildExpandableCategoryOverlay() {
    final menuProvider = context.watch<MenuProvider>();
    
    // Создаем список всех категорий включая "для тебя"
    final allCategories = <MapEntry<String?, List<Product>>>[];
    
    // Всегда добавляем "для тебя" первой
    allCategories.add(MapEntry(null, _getProductsForCategory(null, menuProvider)));
    
    // Добавляем остальные категории с товарами
    final categoriesWithProducts = _getCategoriesWithProducts(menuProvider);
    allCategories.addAll(categoriesWithProducts);
    
    // Находим начальный индекс для PageView
    int initialIndex = 0;
    for (int i = 0; i < allCategories.length; i++) {
      if (allCategories[i].key == _expandedCategoryId) {
        initialIndex = i;
        break;
      }
    }
    
    // Убеждаемся, что PageController установлен на правильную страницу
    if (_expandedCategoryPageController.hasClients) {
      if (_expandedCategoryPageController.page != initialIndex.toDouble()) {
        _expandedCategoryPageController.jumpToPage(initialIndex);
      }
    }

    return Positioned.fill(
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: PageView.builder(
            controller: _expandedCategoryPageController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            onPageChanged: (index) {
              if (index < allCategories.length) {
                setState(() {
                  _expandedCategoryId = allCategories[index].key;
                });
                menuProvider.selectCategory(allCategories[index].key);
              }
            },
            itemCount: allCategories.length,
            itemBuilder: (context, pageIndex) {
              final entry = allCategories[pageIndex];
              final currentCategory = entry.key == null
                  ? null
                  : menuProvider.categories.firstWhere(
                      (cat) => cat.id == entry.key,
                      orElse: () => menuProvider.categories.first,
                    );
              final categoryProducts = entry.value;
              final categoryName = currentCategory?.name ?? 'для тебя';
              
              // Создаем ScrollController для этой страницы если его еще нет
              if (_expandedCategoryScrollController == null) {
                _expandedCategoryScrollController = ScrollController();
                _expandedCategoryScrollController!.addListener(_onExpandedCategoryScroll);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Заголовок с названием категории
                  Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            categoryName,
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _collapseCategory,
                          icon: const Icon(Icons.close),
                          tooltip: 'Закрыть',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Список всех товаров в GridView с эффектом "тянущегося"
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        // Обработка эффекта "тянущегося" при скролле вниз от начала
                        if (notification is ScrollUpdateNotification &&
                            _expandedCategoryScrollController != null &&
                            _expandedCategoryScrollController!.hasClients) {
                          final position = _expandedCategoryScrollController!.position;
                          final scrollDelta = notification.scrollDelta;
                          
                          // Если скроллим вниз и находимся в начале списка
                          if (scrollDelta != null && scrollDelta > 0 && position.pixels <= 0) {
                            _dragOffset += scrollDelta;
                            _isDragging = true;
                            setState(() {});
                          } else if (position.pixels > 0 && _isDragging) {
                            // Если скроллим вверх, сбрасываем эффект
                            _dragOffset = 0.0;
                            _isDragging = false;
                            setState(() {});
                          }
                        }
                        return false;
                      },
                      child: GestureDetector(
                        onVerticalDragUpdate: (details) {
                          // При перетаскивании вниз создаем эффект "тянущегося"
                          if (details.delta.dy > 0 && _expandedCategoryScrollController != null) {
                            final currentOffset = _expandedCategoryScrollController!.offset;
                            if (currentOffset <= 0) {
                              _dragOffset += details.delta.dy;
                              _isDragging = true;
                              setState(() {});
                            }
                          }
                        },
                        onVerticalDragEnd: (details) {
                          // При отпускании: если перетащили достаточно сильно - закрываем
                          if (_isDragging && _dragOffset > 100) {
                            _collapseCategory();
                          } else {
                            // Иначе возвращаем в исходное положение с анимацией
                            _dragOffset = 0.0;
                            _isDragging = false;
                            setState(() {});
                          }
                        },
                        child: Transform.translate(
                          offset: Offset(0, _dragOffset * 0.5), // Эффект "тянущегося"
                          child: Opacity(
                            opacity: _isDragging ? (1.0 - _dragOffset / 300).clamp(0.5, 1.0) : 1.0,
                            child: GridView.builder(
                            controller: _expandedCategoryScrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.82,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                            itemCount: categoryProducts.length,
                            itemBuilder: (context, index) {
                              final product = categoryProducts[index];
                              return ProductCard(product: product)
                                  .animate(delay: Duration(milliseconds: 30 * index))
                                  .fadeIn()
                                  .slideY(begin: 0.1, end: 0);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Обработчик скролла в раскрытой категории - эффект "тянущегося" при скролле вниз
  void _onExpandedCategoryScroll() {
    if (_expandedCategoryScrollController == null || !_expandedCategoryScrollController!.hasClients) {
      return;
    }

    final position = _expandedCategoryScrollController!.position;
    
    // Если скроллим вниз от начала (отрицательное значение или близко к 0)
    // и скроллим дальше вниз, создаем эффект "тянущегося"
    if (position.pixels < 0) {
      _dragOffset = position.pixels.abs();
      _isDragging = true;
      setState(() {}); // Обновляем UI для эффекта
    } else if (_isDragging && position.pixels >= 0) {
      // Если вернулись к началу, сбрасываем эффект
      _dragOffset = 0.0;
      _isDragging = false;
      setState(() {});
    }
  }

  /// Оверлей при наведении на товары: полноэкран, вертикальный скролл + горизонтальный (смена категорий). Первая страница — «для тебя»: большая акция + 2 товара в два столбца.
  Widget _buildProductsHoverExpandedOverlay() {
    final menuProvider = context.watch<MenuProvider>();
    final categoriesWithProducts = _getCategoriesWithProducts(menuProvider);
    if (_productsHoverPageController == null) {
      return const SizedBox.shrink();
    }

    const headerHeight = 72.0;

    return Positioned.fill(
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: PageView.builder(
            controller: _productsHoverPageController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // Более мягкий скролл
            itemCount: 1 + categoriesWithProducts.length,
            itemBuilder: (context, pageIndex) {
              if (pageIndex == 0) {
                return _buildDlyaTebyaOverlayPage(headerHeight, menuProvider, categoriesWithProducts);
              }
              final entry = categoriesWithProducts[pageIndex - 1];
              final category = menuProvider.categories.firstWhere((c) => c.id == entry.key);
              final name = category.name;
              final products = entry.value;
              final displayProducts = products.take(2).toList(); // Только первые два товара

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOverlayHeader(headerHeight, name),
                  const Divider(height: 1),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (displayProducts.isNotEmpty)
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 0.75,
                                      child: ProductCard(product: displayProducts[0]),
                                    ),
                                  ),
                                if (displayProducts.isNotEmpty)
                                  const SizedBox(width: 24),
                                if (displayProducts.length > 1)
                                  Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 0.75,
                                      child: ProductCard(product: displayProducts[1]),
                                    ),
                                  )
                                else if (displayProducts.isNotEmpty)
                                  const Expanded(child: SizedBox()),
                              ],
                            ),
                            if (products.length > 2)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Text(
                                  'И еще ${products.length - 2} товаров в этой категории',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayHeader(double headerHeight, String title) {
    return SizedBox(
      height: headerHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              onPressed: _closeProductsHoverOverlay,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  /// Страница «для тебя» в оверлее: главная большая акция + два товара в два столбца
  Widget _buildDlyaTebyaOverlayPage(
    double headerHeight,
    MenuProvider menuProvider,
    List<MapEntry<String, List<Product>>> categoriesWithProducts,
  ) {
    final firstPromo = _promotions.isNotEmpty ? _promotions[0] : null;
    final firstTwoProducts = categoriesWithProducts.isNotEmpty
        ? categoriesWithProducts[0].value.take(2).toList()
        : <Product>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOverlayHeader(headerHeight, 'для тебя'),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'акции',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                if (firstPromo != null)
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      const padding = 24.0 * 2;
                      final cardWidth = screenWidth - padding;
                      return SizedBox(
                        width: double.infinity,
                        height: cardWidth,
                        child: PromoCard(
                          title: firstPromo.title,
                          imageUrl: firstPromo.imageUrl,
                          emoji: firstPromo.emoji,
                          gradient: firstPromo.gradient,
                          onTap: firstPromo.onTap,
                        ),
                      );
                    },
                  ),
                if (firstTwoProducts.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Container(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 0.75,
                          child: ProductCard(product: firstTwoProducts[0]),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: firstTwoProducts.length > 1
                            ? AspectRatio(
                                aspectRatio: 0.75,
                                child: ProductCard(product: firstTwoProducts[1]),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Запуск расширения категории
  void _expandCategory(String? categoryId) {
    print('🚀 [ExpandCategory] Opening full screen for: $categoryId');
    
    // Создаем ScrollController для отслеживания скролла
    _expandedCategoryScrollController?.dispose();
    _expandedCategoryScrollController = ScrollController();
    _expandedCategoryScrollController!.addListener(_onExpandedCategoryScroll);

    setState(() {
      _expandedCategoryId = categoryId;
      _isCategoryExpanded = true;
    });

    _expansionController.forward();
  }

  /// Закрытие расширенного вида
  void _collapseCategory() {
    _expansionController.reverse().then((_) {
      if (mounted) {
        _expandedCategoryScrollController?.removeListener(_onExpandedCategoryScroll);
        _expandedCategoryScrollController?.dispose();
        _expandedCategoryScrollController = null;
        _dragOffset = 0.0;
        _isDragging = false;
        setState(() {
          _isCategoryExpanded = false;
          _expandedCategoryId = null;
        });
      }
    });
  }
}
