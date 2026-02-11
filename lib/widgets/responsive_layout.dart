import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import '../screens/cart_screen.dart';

/// Адаптивный layout с сайдбаром для веб и планшетов
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final Widget? sidebar;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.sidebar,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final isMobile = Responsive.isMobile(context);

    // Для мобильных устройств - обычный layout без сайдбара
    if (isMobile) {
      return child;
    }

    // Для планшетов и десктопов - layout с сайдбаром
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ширина сайдбара зависит от размера экрана
        final sidebarWidth = isTablet 
          ? 280.0 
          : 320.0;

        return Row(
          children: [
            // Сайдбар слева
            Container(
              width: sidebarWidth,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  right: BorderSide(
                    color: AppColors.borderPrimary,
                    width: 1,
                  ),
                ),
              ),
              child: sidebar ?? _buildDefaultSidebar(context),
            ),
            
            // Основной контент - занимает всю оставшуюся область
            Expanded(
              child: child,
            ),
          ],
        );
      },
    );
  }

  /// Дефолтный сайдбар с категориями и корзиной
  Widget _buildDefaultSidebar(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final userProvider = context.watch<UserProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Column(
      children: [
        // Header сайдбара
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderPrimary,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Меню',
                style: AppTextStyles.h2(),
              ),
              if (locationProvider.selectedLocation != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationProvider.selectedLocation!.name,
                        style: AppTextStyles.bodySmall(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (userProvider.userName != null) ...[
                const SizedBox(height: 4),
                Text(
                  userProvider.userName!,
                  style: AppTextStyles.bodyTiny(AppColors.accent),
                ),
              ],
            ],
          ),
        ),

        // Корзина в сайдбаре
        if (cartProvider.itemCount > 0)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              border: Border.all(
                color: AppColors.borderGlow,
                width: 1,
              ),
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Корзина',
                        style: AppTextStyles.body(),
                      ),
                    ),
                    badges.Badge(
                      badgeContent: Text(
                        '${cartProvider.itemCount}',
                        style: AppTextStyles.bodyTiny(AppColors.background),
                      ),
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: AppColors.accent,
                      ),
                      child: const SizedBox(width: 24, height: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${cartProvider.total.toStringAsFixed(0)} ₽',
                  style: AppTextStyles.h3(AppColors.accent),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDarker,
                      foregroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(
                          color: AppColors.borderGlow,
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Открыть корзину',
                      style: AppTextStyles.button(),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Пустое место
        const Spacer(),

        // Footer сайдбара
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.borderPrimary,
                width: 1,
              ),
            ),
          ),
          child: Text(
            'Coffee Mini App',
            style: AppTextStyles.bodyTiny(AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
