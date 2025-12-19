import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_colors.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

class ProductDetailSheet extends StatefulWidget {
  final Product product;

  const ProductDetailSheet({super.key, required this.product});

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  int selectedSize = 0;
  int selectedMilk = 0;
  List<int> selectedExtras = [];
  int quantity = 1;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  double get totalPrice {
    double total = widget.product.price;

    if (widget.product.modifiers?.size != null) {
      total += widget.product.modifiers!.size!.options[selectedSize].price;
    }

    if (widget.product.modifiers?.milk != null) {
      total += widget.product.modifiers!.milk!.options[selectedMilk].price;
    }

    if (widget.product.modifiers?.extras != null) {
      for (var idx in selectedExtras) {
        total += widget.product.modifiers!.extras!.options[idx].price;
      }
    }

    return total * quantity;
  }

  Future<void> _addToCart() async {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    final cartItem = CartItem(
      product: widget.product,
      modifiers: {
        'size': selectedSize,
        'milk': selectedMilk,
        'extras': selectedExtras,
      },
      quantity: quantity,
      totalPrice: totalPrice,
    );

    context.read<CartProvider>().addItem(cartItem);
    
    // Confetti animation
    _confettiController.play();
    
    // Toast notification
    Fluttertoast.showToast(
      msg: '${widget.product.name} добавлен в корзину! 🎉',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.success,
      textColor: Colors.white,
      fontSize: 14.0,
    );
    
    // Close after short delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.product.imageUrl.isEmpty
                        ? Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientCoffee,
                            ),
                            child: const Center(
                              child: Icon(Icons.coffee, size: 50, color: Colors.white70),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: widget.product.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientCoffee,
                              ),
                              child: const Center(
                                child: Icon(Icons.coffee, size: 50, color: Colors.white70),
                              ),
                            ),
                          ),
                  ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    widget.product.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Size selector
                  if (widget.product.modifiers?.size != null) ...[
                    _buildSectionTitle('Размер', required: true),
                    const SizedBox(height: 12),
                    _buildSizeSelector(),
                    const SizedBox(height: 24),
                  ],
                  // Milk selector
                  if (widget.product.modifiers?.milk != null) ...[
                    _buildSectionTitle('Молоко'),
                    const SizedBox(height: 12),
                    _buildMilkSelector(),
                    const SizedBox(height: 24),
                  ],
                  // Extras selector
                  if (widget.product.modifiers?.extras != null) ...[
                    _buildSectionTitle('Дополнительно'),
                    const SizedBox(height: 12),
                    _buildExtrasSelector(),
                    const SizedBox(height: 24),
                  ],
                  // Quantity
                  _buildSectionTitle('Количество'),
                  const SizedBox(height: 12),
                  _buildQuantitySelector(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _addToCart,
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
                      const Icon(Icons.shopping_cart, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Добавить в корзину',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${totalPrice.toStringAsFixed(0)} ₽',
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
            ),
          ),
        ],
      ),
    ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [
              AppColors.primary,
              AppColors.accent,
              Colors.orange,
              Colors.brown,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool required = false}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(color: AppColors.accent, fontSize: 16),
          ),
        ],
      ],
    );
  }

  Widget _buildSizeSelector() {
    final sizes = widget.product.modifiers!.size!.options;
    return Row(
      children: List.generate(sizes.length, (index) {
        final size = sizes[index];
        final isSelected = selectedSize == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedSize = index),
            child: Container(
              margin: EdgeInsets.only(right: index < sizes.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    size.label,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (size.volume != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      size.volume!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    size.price > 0 ? '+${size.price.toStringAsFixed(0)} ₽' : 'Бесплатно',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMilkSelector() {
    final milks = widget.product.modifiers!.milk!.options;
    return Column(
      children: List.generate(milks.length, (index) {
        final milk = milks[index];
        final isSelected = selectedMilk == index;
        return GestureDetector(
          onTap: () => setState(() => selectedMilk = index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    milk.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  milk.price > 0 ? '+${milk.price.toStringAsFixed(0)} ₽' : '',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildExtrasSelector() {
    final extras = widget.product.modifiers!.extras!.options;
    return Column(
      children: List.generate(extras.length, (index) {
        final extra = extras[index];
        final isSelected = selectedExtras.contains(index);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedExtras.remove(index);
              } else {
                selectedExtras.add(index);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isSelected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    extra.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  '+${extra.price.toStringAsFixed(0)} ₽',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
            icon: const Icon(Icons.remove_circle),
            color: quantity > 1 ? AppColors.primary : Colors.grey,
            iconSize: 32,
          ),
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => quantity++),
            icon: const Icon(Icons.add_circle),
            color: AppColors.primary,
            iconSize: 32,
          ),
        ],
      ),
    );
  }
}

