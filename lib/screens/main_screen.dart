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
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/promo_banner.dart';
import 'cart_screen.dart';
import 'location_select_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadMenu();
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

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final location = locationProvider.selectedLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientCoffee,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.coffee, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location?.name ?? 'Кофейня',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            print('🔄 Consumer rebuild - userProvider.user: ${userProvider.user}');
                            final userName = userProvider.userName;
                            print('🔄 Consumer rebuild - userName: $userName');
                            if (userName != null && userName.isNotEmpty) {
                              return Text(
                                userName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }
                            return Text(
                              location?.address ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                onPressed: _handleGeoRequest,
                    icon: const Icon(Icons.location_on_outlined),
                    color: AppColors.primary,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.person_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.3),
            // Content
            Expanded(
              child: menuProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadMenu,
                      child: CustomScrollView(
                        slivers: [
                          // Promo Banner
                          SliverToBoxAdapter(
                            child: const PromoBanner()
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideX(begin: -0.2),
                          ),
                          // Categories
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: menuProvider.categories.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return CategoryChip(
                                      label: 'Все',
                                      emoji: '🔥',
                                      isSelected: menuProvider.selectedCategoryId == null,
                                      onTap: () => menuProvider.selectCategory(null),
                                    );
                                  }
                                  final category = menuProvider.categories[index - 1];
                                  return CategoryChip(
                                    label: category.name,
                                    emoji: category.emoji,
                                    isSelected: menuProvider.selectedCategoryId == category.id,
                                    onTap: () => menuProvider.selectCategory(category.id),
                                  );
                                },
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                          // Products Grid
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = menuProvider.products[index];
                                  return ProductCard(product: product)
                                      .animate(delay: Duration(milliseconds: 50 * index))
                                      .fadeIn()
                                      .scale(begin: const Offset(0.9, 0.9));
                                },
                                childCount: menuProvider.products.length,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 100)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          print('🛒 MainScreen rebuild - itemCount: ${cartProvider.itemCount}, total: ${cartProvider.total}');
          
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
          print('🛒 Cart is empty, not showing FAB');
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

