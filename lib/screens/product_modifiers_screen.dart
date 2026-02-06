import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../widgets/modifier_cube.dart';

class ProductModifiersScreen extends StatefulWidget {
  final Product product;

  const ProductModifiersScreen({super.key, required this.product});

  @override
  State<ProductModifiersScreen> createState() => _ProductModifiersScreenState();
}

class _ProductModifiersScreenState extends State<ProductModifiersScreen> {
  late List<ModifierScreenData> _screens;
  late Map<String, dynamic> _selectedModifiers;
  late ConfettiController _confettiController;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _selectedModifiers = <String, dynamic>{}; // Явно указываем тип
    _buildScreens();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _buildScreens() {
    _screens = [];
    
    print('Building modifier screens for: ${widget.product.name}');
    print('Modifiers: ${widget.product.modifiers}');
    
    // Экран 1: Размер (если есть)
    if (widget.product.modifiers?.size != null) {
      print('Adding size screen');
      _screens.add(ModifierScreenData(
        title: 'Выберите размер',
        group: widget.product.modifiers!.size!,
        key: 'size',
      ));
    }

    // Экран 2: Молоко (если есть)
    if (widget.product.modifiers?.milk != null) {
      _screens.add(ModifierScreenData(
        title: 'Выберите молоко',
        group: widget.product.modifiers!.milk!,
        key: 'milk',
        isOptional: !widget.product.modifiers!.milk!.required,
      ));
    }

    // Экран 3: Дополнительно (если есть)
    if (widget.product.modifiers?.extras != null) {
      _screens.add(ModifierScreenData(
        title: 'Дополнительно',
        group: widget.product.modifiers!.extras!,
        key: 'extras',
        isOptional: !widget.product.modifiers!.extras!.required,
      ));
    }

    // Если нет модификаторов, сразу показываем финальный экран
    if (_screens.isEmpty) {
      print('⚠️ No modifiers found for product: ${widget.product.name}');
      print('⚠️ Product ID: ${widget.product.id}');
      print('⚠️ This usually means:');
      print('   1. No ModifierGroups created in Supabase');
      print('   2. No ProductModifierGroup links created');
      print('   3. RLS policies blocking access');
      print('⚠️ Solution: Run create_product_modifier_links.sql in Supabase SQL Editor');
      _screens.add(ModifierScreenData(
        title: 'Добавить в корзину',
        group: null,
        key: 'final',
        isFinal: true,
      ));
    }
    
    print('Total screens: ${_screens.length}');
  }


  double get _totalPrice {
    double total = widget.product.price;

    // Добавляем цену всех выбранных модификаторов
    for (var screen in _screens) {
      if (screen.group == null) continue;

      final value = _selectedModifiers[screen.key];
      if (value == null) continue;

      // Собираем индексы (всегда как список)
      List<int> indices;
      if (value is List<int>) {
        indices = value;
      } else if (value is List) {
        indices = value.whereType<int>().toList();
      } else if (value is int) {
        indices = <int>[value];
      } else {
        continue;
      }

      for (var idx in indices) {
        if (idx >= 0 && idx < screen.group!.options.length) {
          total += screen.group!.options[idx].price;
        }
      }
    }

    return total;
  }

  List<SelectedCube> get _selectedCubes {
    final cubes = <SelectedCube>[];

    for (var screen in _screens) {
      if (screen.group == null) continue;

      final value = _selectedModifiers[screen.key];
      if (value == null) continue;

      // Собираем все выбранные индексы (всегда как список)
      List<int> indices;
      if (value is List<int>) {
        indices = value;
      } else if (value is List) {
        indices = value.whereType<int>().toList();
      } else if (value is int) {
        indices = <int>[value];
      } else {
        continue;
      }

      for (var idx in indices) {
        if (idx >= 0 && idx < screen.group!.options.length) {
          final option = screen.group!.options[idx];
          cubes.add(SelectedCube(
            label: option.label,
            volume: option.volume,
            price: option.price,
            emoji: option.emoji,
          ));
        }
      }
    }

    return cubes;
  }

  void _onModifierTap(ModifierScreenData screen, int index) {
    setState(() {
      // Всегда сохраняем как List<int> — позволяет выбрать несколько модификаторов
      final currentValue = _selectedModifiers[screen.key];
      List<int> current;

      if (currentValue is List<int>) {
        current = List<int>.from(currentValue);
      } else if (currentValue is int) {
        current = <int>[currentValue];
      } else {
        current = <int>[];
      }

      if (current.contains(index)) {
        current.remove(index);
      } else {
        current.add(index);
      }
      _selectedModifiers[screen.key] = current;
    });
    HapticFeedback.selectionClick();
  }


  Future<void> _addToCart() async {
    print('🛒 _addToCart called for product: ${widget.product.name}');
    HapticFeedback.mediumImpact();
    
    // Формируем модификаторы для корзины
    final modifiers = <String, dynamic>{};
    if (_selectedModifiers['size'] != null) {
      modifiers['size'] = _selectedModifiers['size'];
    }
    if (_selectedModifiers['milk'] != null) {
      modifiers['milk'] = _selectedModifiers['milk'];
    }
    if (_selectedModifiers['extras'] != null) {
      modifiers['extras'] = _selectedModifiers['extras'];
    }

    print('🛒 Modifiers: $modifiers');
    print('🛒 Total price: $_totalPrice');

    final cartItem = CartItem(
      product: widget.product,
      modifiers: modifiers,
      quantity: 1,
      totalPrice: _totalPrice,
    );

    print('🛒 CartItem created: ${cartItem.product.name}, price: ${cartItem.totalPrice}');
    
    try {
      final cartProvider = context.read<CartProvider>();
      print('🛒 CartProvider found, current items count: ${cartProvider.items.length}');
      
      cartProvider.addItem(cartItem);
      
      print('🛒 Item added to cart, new items count: ${cartProvider.items.length}');
      print('🛒 Cart total: ${cartProvider.total}, itemCount: ${cartProvider.itemCount}');
    } catch (e, stackTrace) {
      print('❌ Error adding to cart: $e');
      print('❌ Stack trace: $stackTrace');
    }
    
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
      print('🛒 Closing ProductModifiersScreen');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Единый вертикальный поток: header → image → modifiers
          Column(
            children: [
              // Компактный header с gradient
              _buildProductHeader(),

              // Scrollable: image + description + все модификаторы
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: _selectedCubes.isEmpty ? 80 + bottomPadding : 140 + bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact image + description row
                      _buildProductInfoRow(),

                      // Разделитель
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.borderGlow.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Все группы модификаторов подряд
                      for (var screen in _screens)
                        if (!screen.isFinal)
                          _buildModifierSection(screen),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky HUD-tray внизу: выбранные модификаторы + итого
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSelectedModifiersTray(bottomPadding),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 1.57,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Compact gradient header: [X] PRODUCT_NAME   PRICE
  Widget _buildProductHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradient1,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.accent, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.product.name.toUpperCase(),
                  style: AppTextStyles.h3(AppColors.accent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderGlow, width: 1),
                  color: AppColors.cardBackground,
                ),
                child: Text(
                  '${widget.product.price.toStringAsFixed(0)}₽',
                  style: AppTextStyles.price(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact row: image on left, description toggle on right
  Widget _buildProductInfoRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image — compact square
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderPrimary, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: widget.product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.cardBackground,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.cardBackground,
                        child: const Icon(Icons.coffee, size: 40, color: AppColors.accentDarker),
                      ),
                    )
                  : Container(
                      color: AppColors.cardBackground,
                      child: const Icon(Icons.coffee, size: 40, color: AppColors.accentDarker),
                    ),
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(width: 16),

          // Description toggle + text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.product.description.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                      HapticFeedback.selectionClick();
                    },
                    borderRadius: BorderRadius.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '> INFO',
                            style: AppTextStyles.bodyTiny(AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _isDescriptionExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isDescriptionExpanded) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.product.description,
                      style: AppTextStyles.bodyTiny(AppColors.textSecondary).copyWith(height: 1.5),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ] else
                  Text(
                    widget.product.name,
                    style: AppTextStyles.bodySmall(AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky HUD tray: shows selected modifier cubes + total price
  Widget _buildSelectedModifiersTray(double safeAreaBottom) {
    final cubes = _selectedCubes;
    final hasCubes = cubes.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: hasCubes ? AppColors.borderGlow : AppColors.borderPrimary,
            width: hasCubes ? 2 : 1,
          ),
        ),
        boxShadow: hasCubes
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -8),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: hasCubes
            ? _buildFilledTray(cubes)
            : _buildEmptyTray(),
      ),
    );
  }

  /// Empty tray: blinking terminal prompt
  Widget _buildEmptyTray() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            '> ',
            style: AppTextStyles.bodySmall(AppColors.textTertiary),
          ),
          Text(
            'ВЫБЕРИТЕ ОПЦИИ',
            style: AppTextStyles.bodySmall(AppColors.textTertiary),
          ),
          // Blinking cursor
          Text(
            ' _',
            style: AppTextStyles.bodySmall(AppColors.textTertiary),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 500.ms)
              .then()
              .fadeOut(duration: 500.ms),
        ],
      ),
    );
  }

  /// Filled tray: horizontal cubes + total
  Widget _buildFilledTray(List<SelectedCube> cubes) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected cubes — horizontal scroll
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            itemCount: cubes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cube = cubes[index];
              return Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.accentDarker.withValues(alpha: 0.5),
                  border: Border.all(color: AppColors.borderGlow, width: 1),
                  boxShadow: AppColors.neonGlow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (cube.emoji != null)
                      Text(cube.emoji!, style: const TextStyle(fontSize: 16)),
                    Text(
                      cube.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyTiny(AppColors.accent).copyWith(fontSize: 8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cube.price > 0)
                      Text(
                        '+${cube.price.toStringAsFixed(0)}₽',
                        style: AppTextStyles.bodyTiny(AppColors.textSecondary).copyWith(fontSize: 7),
                      ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(begin: const Offset(0.5, 0.5), duration: 200.ms);
            },
          ),
        ),

        // Total price bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(
            children: [
              Text(
                '> ИТОГО:',
                style: AppTextStyles.bodySmall(AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                '${_totalPrice.toStringAsFixed(0)}₽',
                style: AppTextStyles.price(),
              ),
              const Spacer(),
              Text(
                '${cubes.length} МОД.',
                style: AppTextStyles.bodyTiny(AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModifierSection(ModifierScreenData screen) {
    final group = screen.group!;
    final currentSelection = _selectedModifiers[screen.key];

    // Собираем выбранные индексы (всегда как список)
    List<int> selectedIndices;
    if (currentSelection is List<int>) {
      selectedIndices = currentSelection;
    } else if (currentSelection is List) {
      selectedIndices = currentSelection.whereType<int>().toList();
    } else if (currentSelection is int) {
      selectedIndices = <int>[currentSelection];
    } else {
      selectedIndices = <int>[];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок группы
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              screen.title,
              style: AppTextStyles.h2(),
            ),
          ),
          // GridView со скроллом - все модификаторы видны, можно скроллить
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Скролл через родительский SingleChildScrollView
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: group.options.length,
            itemBuilder: (context, index) {
              final option = group.options[index];
              final isSelected = selectedIndices.contains(index);

              return ModifierCube(
                label: option.label,
                emoji: option.emoji,
                volume: option.volume,
                price: option.price,
                isSelected: isSelected,
                onTap: () => _onModifierTap(screen, index),
              )
                  .animate(delay: (index * 50).ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms);
            },
          ),
          // Отступ между группами
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}

class ModifierScreenData {
  final String title;
  final ModifierGroup? group;
  final String key;
  final bool isOptional;
  final bool isFinal;

  ModifierScreenData({
    required this.title,
    required this.group,
    required this.key,
    this.isOptional = false,
    this.isFinal = false,
  });
}

class SelectedCube {
  final String label;
  final String? emoji;
  final String? volume;
  final double price;

  SelectedCube({
    required this.label,
    this.emoji,
    this.volume,
    required this.price,
  });
}

