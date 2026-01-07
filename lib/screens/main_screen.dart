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
import '../widgets/background_hero_banner.dart';
import '../widgets/location_app_bar.dart';
import '../widgets/hero_promo_content.dart';
import '../widgets/bottom_category_navigation.dart';
import '../widgets/promo_section.dart';
import 'cart_screen.dart';
import 'location_select_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  /// Обработка нажатия на иконку геолокации — открываем экран выбора кофейни.
  void _handleGeoRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationSelectScreen(),
      ),
    );
  }

  /// Проверяет, выбрана ли категория "акции"
  bool _isPromotionsCategory(String? categoryId, List categories) {
    if (categoryId == null) return false;
    
    // Ищем категорию по id или названию
    try {
      categories.firstWhere(
        (cat) => cat.id == categoryId || 
                 cat.name.toLowerCase().contains('акци') ||
                 cat.name.toLowerCase().contains('промо'),
      );
      return true;
    } catch (e) {
      return false;
    }
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
          BackgroundHeroBanner(
            scrollController: _scrollController,
          ),
          
          // Основной контент поверх фона
          Column(
            children: [
              // Location App Bar
              LocationAppBar(
                location: location,
                onLocationTap: _handleGeoRequest,
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
                            
                            // Белый фон для контента ниже промо
                            SliverToBoxAdapter(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    topRight: Radius.circular(30),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Динамический контент в зависимости от категории
                                    if (isPromotions)
                                      PromoSection(
                                        promotions: _getPromotions(),
                                      )
                                    else
                                      _buildProductsSection(menuProvider),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Отступ для bottom navigation
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 90),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          
          // Bottom Navigation (фиксированная внизу)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomCategoryNavigation(
              categories: menuProvider.categories,
              selectedCategoryId: menuProvider.selectedCategoryId,
              onCategorySelected: (categoryId) {
                menuProvider.selectCategory(categoryId);
              },
            ),
          ),
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
              badgeStyle: const badges.BadgeStyle(
                badgeColor: AppColors.accent,
              ),
              position: badges.BadgePosition.topEnd(top: -8, end: -8),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  print('🛒 Cart button pressed, items: ${cartProvider.items.length}');
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

  Widget _buildProductsSection(MenuProvider menuProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Products Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
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
        ],
      ),
    );
  }
}
