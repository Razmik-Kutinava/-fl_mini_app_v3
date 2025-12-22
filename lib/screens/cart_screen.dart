import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_colors.dart';
import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

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
      cartProvider.clear();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
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
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ваш заказ будет готов через ~15 минут',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
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

    return Scaffold(
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
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            if (userProvider.userName != null && userProvider.userName!.isNotEmpty)
              Text(
                userProvider.userName!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
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
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                        child:
                            Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
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
                                        borderRadius: BorderRadius.circular(12),
                                        child: item.product.imageUrl.isEmpty
                                            ? Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      AppColors.gradientCoffee,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
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
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            ...item.modifiersList.map(
                                              (mod) => Text(
                                                mod,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
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
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
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
                                                  style: GoogleFonts.montserrat(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
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
                                                    color: AppColors.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${item.totalPrice.toStringAsFixed(0)} ₽',
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.primary,
                                            ),
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
                                  decoration: InputDecoration(
                                    hintText: 'Промокод',
                                    hintStyle: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    errorText: _promoError,
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
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isApplyingPromo
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Применить',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
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
                                    style: GoogleFonts.inter(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${cartProvider.subtotal.toStringAsFixed(0)} ₽',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                              ),
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
                                style: GoogleFonts.inter(
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                '-${cartProvider.discount.toStringAsFixed(0)} ₽',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.success,
                                ),
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
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${cartProvider.total.toStringAsFixed(0)} ₽',
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
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
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.credit_card, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'Оформить заказ',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${cartProvider.total.toStringAsFixed(0)} ₽',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
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
              shape: BoxShape.circle,
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
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Добавьте что-нибудь вкусное!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Перейти к меню',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}
