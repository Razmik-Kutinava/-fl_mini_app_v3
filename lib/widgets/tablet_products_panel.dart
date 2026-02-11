import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../models/category.dart' as models;
import 'package:provider/provider.dart';
import '../screens/product_modifiers_screen.dart';
import 'glowing_line.dart';

/// Панель товаров для планшетной версии
class TabletProductsPanel extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String?) onCategoryChanged;

  const TabletProductsPanel({
    super.key,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final cartProvider = context.watch<CartProvider>();
    
    // Получаем категорию
    models.Category? category;
    String categoryName;
    String categoryIcon;
    
    if (selectedCategoryId == null) {
      // "для тебя" - все товары
      categoryName = 'ДЛЯ ТЕБЯ';
      categoryIcon = '⭐';
    } else {
      category = menuProvider.categories.firstWhere(
        (c) => c.id == selectedCategoryId,
        orElse: () => menuProvider.categories.isNotEmpty 
            ? menuProvider.categories.first 
            : throw StateError('No categories available'),
      );
      categoryName = category.name.toUpperCase();
      categoryIcon = category.emoji.isNotEmpty ? category.emoji : '☕';
    }
    
    // Получаем товары для категории
    final products = selectedCategoryId == null
        ? menuProvider.allProducts
        : menuProvider.allProducts
            .where((p) => p.categoryId == selectedCategoryId)
            .toList();
    
    final productsCount = products.length;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Хедер категории
          _CategoryHeader(
            icon: categoryIcon,
            name: categoryName,
            count: productsCount,
            cartTotal: cartProvider.total,
            cartItemCount: cartProvider.itemCount,
          ),
          
          const SizedBox(height: 12),
          
          // Разделитель со свечением
          GlowingLine(
            height: 1,
            color: AppColors.borderPrimary,
          ),
          const SizedBox(height: 12),
          
          // Сетка товаров
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Text(
                      'НЕТ ТОВАРОВ',
                      style: AppTextStyles.h2(),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                      final minCardWidth = 220.0;
                      final gap = 20.0;
                      final availableWidth = constraints.maxWidth - (gap * (crossAxisCount - 1));
                      final cardWidth = (availableWidth / crossAxisCount).clamp(minCardWidth, double.infinity);
                      
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: cardWidth / 280,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _TabletProductCard(product: product);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  int _getCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    return 2;
  }
}

/// Хедер категории с превью корзины
class _CategoryHeader extends StatelessWidget {
  final String icon;
  final String name;
  final int count;
  final double cartTotal;
  final int cartItemCount;

  const _CategoryHeader({
    required this.icon,
    required this.name,
    required this.count,
    required this.cartTotal,
    required this.cartItemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Левая часть - заголовок
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$icon $name',
              style: AppTextStyles.tabletH1(),
            ),
            const SizedBox(height: 4),
            Text(
              '$count ПОЗИЦИЙ',
              style: AppTextStyles.bodyTiny(),
            ),
          ],
        ),
        
        // Правая часть - превью корзины
        if (cartItemCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.03),
              border: Border.all(
                color: AppColors.borderGlow,
                width: 1,
              ),
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'ЗАКАЗ',
                  style: AppTextStyles.bodySmall(),
                ),
                const SizedBox(width: 12),
                Text(
                  '${cartTotal.toStringAsFixed(0)} ₽',
                  style: AppTextStyles.tabletPrice(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Карточка товара для планшета
class _TabletProductCard extends StatefulWidget {
  final Product product;

  const _TabletProductCard({required this.product});

  @override
  State<_TabletProductCard> createState() => _TabletProductCardState();
}

class _TabletProductCardState extends State<_TabletProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductModifiersScreen(product: widget.product),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border.all(
              color: _isHovered ? AppColors.borderGlow : AppColors.borderPrimary,
              width: 1,
            ),
            borderRadius: BorderRadius.zero,
            boxShadow: _isHovered ? AppColors.neonGlow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название
              Text(
                widget.product.name.toUpperCase(),
                style: AppTextStyles.h2(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 10),
              GlowingLine(
                height: 1,
                color: AppColors.borderSecondary,
              ),
              const SizedBox(height: 10),
              
              // Описание
              Expanded(
                child: Text(
                  widget.product.description,
                  style: AppTextStyles.bodySmall(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Футер с ценой и кнопкой
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${widget.product.price.toStringAsFixed(0)} ₽',
                    style: AppTextStyles.tabletPrice(),
                  ),
                  
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductModifiersScreen(product: widget.product),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDarker,
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                      '+ ВЗЯТЬ',
                      style: AppTextStyles.tabletButton(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
