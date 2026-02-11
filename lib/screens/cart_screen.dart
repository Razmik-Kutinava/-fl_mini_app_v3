import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isApplyingPromo = false;
  String? _promoError;

  Future<void> _applyPromoCode() async {
    if (_promoController.text.isEmpty) return;

    setState(() {
      _isApplyingPromo = true;
      _promoError = null;
    });

    final result = await _apiService.validatePromoCode(_promoController.text);

    if (mounted) {
      setState(() => _isApplyingPromo = false);

      if (result['valid'] == true) {
        final cartProvider = context.read<CartProvider>();
        final discountPercent = result['discountPercent'] as int;
        final discountAmount = cartProvider.subtotal * discountPercent / 100;
        cartProvider.applyPromoCode(
          _promoController.text.toUpperCase(),
          discountAmount,
        );

        HapticFeedback.lightImpact();
        Fluttertoast.showToast(
          msg: 'Промокод применён: -$discountPercent% 🎉',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.success,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      } else {
        setState(() => _promoError = 'Недействительный промокод');
      }
    }
  }

  Future<void> _checkout() async {
    HapticFeedback.mediumImpact();

    if (!mounted) return;
    final cartProvider = context.read<CartProvider>();
    final locationProvider = context.read<LocationProvider>();
    final userProvider = context.read<UserProvider>();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    print('=== CHECKOUT START ===');
    print('Location: ${locationProvider.selectedLocation?.id}');
    print('Items count: ${cartProvider.items.length}');
    print('Total: ${cartProvider.total}');
    print('User: ${userProvider.user}');
    print('User Name: ${userProvider.userName}');
    print('Telegram ID: ${userProvider.telegramId}');

    await _apiService.createOrder({
      'locationId': locationProvider.selectedLocation?.id ?? '',
      'items': cartProvider.items
          .map(
            (item) => {
              'productId': item.product.id,
              'productName': item.product.name,
              'quantity': item.quantity,
              'price': item.product.price,
              'total': item.totalPrice,
              'modifiers': item.modifiers,
            },
          )
          .toList(),
      'promoCode': cartProvider.promoCode,
      'discount': cartProvider.discount,
      'total': cartProvider.total,
      'telegramUserId': userProvider.telegramId,
      'userId': userProvider.userId,
      'customerName': userProvider.userName,
    });

    if (mounted) {
      Navigator.pop(context); // Close loading

      // Получаем имя пользователя ДО очистки корзины
      final userName = userProvider.userName ?? userProvider.firstName;
      final displayName = (userName != null && userName.isNotEmpty)
          ? userName.replaceAll('@', '') // Убираем @ если это username
          : null;

      print('📱 User name for success dialog: $displayName');
      print('📱 From Telegram: ${userProvider.telegramId}');

      cartProvider.clear();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Заказ оформлен!',
                style: AppTextStyles.h2(),
              ),
              const SizedBox(height: 8),
              // Показываем имя пользователя из Telegram
              Text(
                displayName != null
                    ? '$displayName, ваш заказ будет готов через ~15 минут 🎉'
                    : 'Ваш заказ будет готов через ~15 минут',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall(),
              ),
              // Показываем Telegram ID для отладки
              if (userProvider.telegramId != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.telegram, color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Telegram: ${userProvider.telegramId}',
                        style: AppTextStyles.bodyTiny(Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                'Отлично!',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final userProvider = context.watch<UserProvider>();
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    final content = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Корзина',
              style: AppTextStyles.h3(),
            ),
            if (userProvider.userName != null &&
                userProvider.userName!.isNotEmpty)
              Text(
                userProvider.userName!,
                style: AppTextStyles.bodySmall(AppColors.accent),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: cartProvider.items.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) async {
                                HapticFeedback.mediumImpact();
                                cartProvider.removeItem(item);
                              },
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Удалить',
                              borderRadius: BorderRadius.zero,
                            ),
                          ],
                        ),
                        child:
                            Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.zero,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.zero,
                                        child: item.product.imageUrl.isEmpty
                                            ? Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      AppColors.gradientCoffee,
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                ),
                                                child: const Icon(
                                                  Icons.coffee,
                                                  color: Colors.white70,
                                                  size: 30,
                                                ),
                                              )
                                            : CachedNetworkImage(
                                                imageUrl: item.product.imageUrl,
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) =>
                                                    Container(
                                                      width: 70,
                                                      height: 70,
                                                      decoration: BoxDecoration(
                                                        gradient: AppColors
                                                            .gradientCoffee,
                                                        borderRadius: BorderRadius.zero,
                                                      ),
                                                      child: const Icon(
                                                        Icons.coffee,
                                                        color: Colors.white70,
                                                        size: 30,
                                                      ),
                                                    ),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item.product.name} ${item.sizeLabel}',
                                              style: AppTextStyles.bodySmall(),
                                            ),
                                            ...item.modifiersList.map(
                                              (mod) => Text(
                                                mod,
                                                style: AppTextStyles.bodyTiny(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () async {
                                                  HapticFeedback.selectionClick();
                                                  cartProvider.updateQuantity(
                                                    item,
                                                    item.quantity - 1,
                                                  );
                                                },
                                                child: Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                  ),
                                                  child: const Icon(
                                                    Icons.remove,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                child: Text(
                                                  '${item.quantity}',
                                                  style: AppTextStyles.body(),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  HapticFeedback.selectionClick();
                                                  cartProvider.updateQuantity(
                                                    item,
                                                    item.quantity + 1,
                                                  );
                                                },
                                                child: Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accent,
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    size: 18,
                                                    color: AppColors.background,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${item.totalPrice.toStringAsFixed(0)} ₽',
                                            style: AppTextStyles.price(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                                .animate(
                                  delay: Duration(milliseconds: 100 * index),
                                )
                                .fadeIn()
                                .slideX(begin: 0.2),
                      );
                    },
                  ),
                ),
                // Bottom section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Promo code
                        if (cartProvider.promoCode == null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _promoController,
                                  style: AppTextStyles.body(),
                                  decoration: InputDecoration(
                                    hintText: 'Промокод',
                                    hintStyle: AppTextStyles.bodyTiny(),
                                    filled: true,
                                    fillColor: AppColors.cardBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide: BorderSide(
                                        color: AppColors.borderPrimary,
                                        width: 1,
                                      ),
                                    ),
                                    errorText: _promoError,
                                    errorStyle: AppTextStyles.bodyTiny(AppColors.error),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isApplyingPromo
                                    ? null
                                    : _applyPromoCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentDarker,
                                  foregroundColor: AppColors.accent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                    side: BorderSide(
                                      color: AppColors.borderGlow,
                                      width: 1,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isApplyingPromo
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.accent,
                                        ),
                                      )
                                    : Text(
                                        'Применить',
                                        style: AppTextStyles.button(),
                                      ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Промокод ${cartProvider.promoCode} применён',
                                    style: AppTextStyles.bodySmall(AppColors.success),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      cartProvider.removePromoCode(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.success,
                                  ),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Товары (${cartProvider.itemCount} шт)',
                              style: AppTextStyles.bodySmall(),
                            ),
                            Text(
                              '${cartProvider.subtotal.toStringAsFixed(0)} ₽',
                              style: AppTextStyles.price(),
                            ),
                          ],
                        ),
                        if (cartProvider.discount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Скидка (${cartProvider.promoCode})',
                                style: AppTextStyles.bodySmall(AppColors.success),
                              ),
                              Text(
                                '-${cartProvider.discount.toStringAsFixed(0)} ₽',
                                style: AppTextStyles.price(AppColors.success),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Итого:',
                              style: AppTextStyles.h3(),
                            ),
                            Text(
                              '${cartProvider.total.toStringAsFixed(0)} ₽',
                              style: AppTextStyles.h1(AppColors.accent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _checkout,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.credit_card, size: 20, color: AppColors.accent),
                                const SizedBox(width: 12),
                                Text(
                                  'Оформить заказ',
                                  style: AppTextStyles.button(),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.2),
                                    borderRadius: BorderRadius.zero,
                                    border: Border.all(
                                      color: AppColors.borderGlow,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${cartProvider.total.toStringAsFixed(0)} ₽',
                                    style: AppTextStyles.button(),
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
    );

    // Для десктопа и планшетов - ограничиваем ширину и центрируем
    if (isDesktop || isTablet) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : 600,
          ),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 24),
          Text(
            'Корзина пуста',
            style: AppTextStyles.h2(),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Добавьте что-нибудь вкусное!',
            style: AppTextStyles.bodySmall(),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDarker,
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
              'Перейти к меню',
              style: AppTextStyles.button(),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}
