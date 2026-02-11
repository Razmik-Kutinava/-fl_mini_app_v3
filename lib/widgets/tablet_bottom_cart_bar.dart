import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../screens/cart_screen.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';

/// Нижняя панель корзины для планшетной версии
class TabletBottomCartBar extends StatelessWidget {
  const TabletBottomCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    
    if (cartProvider.itemCount == 0) {
      return const SizedBox.shrink();
    }

    // Формируем список позиций для отображения
    final itemsPreview = cartProvider.items.take(3).map((item) {
      return '${item.quantity}x ${item.product.name.toUpperCase()}';
    }).toList();
    
    final remainingCount = cartProvider.itemCount - itemsPreview.length;

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.statusPanel,
        border: Border(
          top: BorderSide(
            color: AppColors.borderPrimary,
            width: 1,
          ),
          left: BorderSide(
            color: AppColors.borderGlow,
            width: 4,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Левая часть - метка заказа и список позиций
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ЗАКАЗ #${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  style: AppTextStyles.bodyTiny(),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  children: [
                    ...itemsPreview.map((item) => Text(
                      item,
                      style: AppTextStyles.bodySmall(),
                    )),
                    if (remainingCount > 0)
                      Text(
                        'И ЕЩЕ $remainingCount',
                        style: AppTextStyles.bodyTiny(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Центр - итоговая сумма
          Text(
            '${cartProvider.total.toStringAsFixed(0)} ₽',
            style: AppTextStyles.tabletPrice(),
          ),
          
          // Правая часть - кнопка оплаты
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(
                  color: AppColors.borderGlow,
                  width: 2,
                ),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⏎',
                  style: AppTextStyles.tabletButton(),
                ),
                const SizedBox(width: 8),
                Text(
                  'ОПЛАТА',
                  style: AppTextStyles.tabletButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
