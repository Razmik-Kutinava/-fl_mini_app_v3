import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_colors.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../widgets/modifier_cube.dart';
import '../providers/cart_provider.dart';

/// Экран выбора модификаторов с кубиками
/// Верхняя часть (60%) - выбранные кубики
/// Нижняя часть (40%) - grid кубиков для выбора
class ProductModifiersScreen extends StatefulWidget {
  final Product product;
  final List<ModifierScreen> screens;

  const ProductModifiersScreen({
    super.key,
    required this.product,
    required this.screens,
  });

  @override
  State<ProductModifiersScreen> createState() => _ProductModifiersScreenState();
}

class _ProductModifiersScreenState extends State<ProductModifiersScreen> {
  int _currentScreenIndex = 0;
  Map<String, dynamic> _selectedModifiers = {};
  int _quantity = 1;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    // Инициализируем пустые выборы для каждого экрана
    for (var screen in widget.screens) {
      if (screen.group.type == 'single') {
        _selectedModifiers[screen.groupKey] = null;
      } else {
        _selectedModifiers[screen.groupKey] = [];
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  ModifierScreen get currentScreen => widget.screens[_currentScreenIndex];

  bool get canProceed {
    final screen = currentScreen;
    if (screen.group.required) {
      if (screen.group.type == 'single') {
        return _selectedModifiers[screen.groupKey] != null;
      } else {
        final selected = _selectedModifiers[screen.groupKey] as List;
        return selected.isNotEmpty;
      }
    }
    return true; // Опциональные можно пропустить
  }

  bool get isLastScreen => _currentScreenIndex == widget.screens.length - 1;

  double get totalPrice {
    double total = widget.product.price * _quantity;

    for (var screen in widget.screens) {
      final selected = _selectedModifiers[screen.groupKey];
      if (selected != null) {
        if (screen.group.type == 'single') {
          final idx = selected as int;
          if (idx < screen.group.options.length) {
            total += screen.group.options[idx].price * _quantity;
          }
        } else {
          final indices = selected as List<int>;
          for (var idx in indices) {
            if (idx < screen.group.options.length) {
              total += screen.group.options[idx].price * _quantity;
            }
          }
        }
      }
    }

    return total;
  }

  List<SelectedModifier> get selectedModifiersList {
    final List<SelectedModifier> list = [];

    for (var screen in widget.screens) {
      final selected = _selectedModifiers[screen.groupKey];
      if (selected != null) {
        if (screen.group.type == 'single') {
          final idx = selected as int;
          if (idx < screen.group.options.length) {
            list.add(SelectedModifier(
              groupKey: screen.groupKey,
              option: screen.group.options[idx],
            ));
          }
        } else {
          final indices = selected as List<int>;
          for (var idx in indices) {
            if (idx < screen.group.options.length) {
              list.add(SelectedModifier(
                groupKey: screen.groupKey,
                option: screen.group.options[idx],
              ));
            }
          }
        }
      }
    }

    return list;
  }

  void _selectModifier(int index) {
    setState(() {
      final screen = currentScreen;
      if (screen.group.type == 'single') {
        // Одиночный выбор - заменяем предыдущий
        _selectedModifiers[screen.groupKey] = index;
        HapticFeedback.selectionClick();
      } else {
        // Множественный выбор - добавляем/убираем
        final selected = _selectedModifiers[screen.groupKey] as List<int>;
        if (selected.contains(index)) {
          selected.remove(index);
        } else {
          selected.add(index);
        }
        HapticFeedback.selectionClick();
      }
    });
  }

  void _nextScreen() {
    if (isLastScreen) {
      // Добавляем в корзину
      _addToCart();
    } else {
      setState(() {
        _currentScreenIndex++;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _addToCart() {
    HapticFeedback.mediumImpact();
    
    final cartItem = CartItem(
      product: widget.product,
      modifiers: _selectedModifiers,
      quantity: _quantity,
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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }


  void _skipScreen() {
    if (isLastScreen) {
      _nextScreen();
    } else {
      setState(() {
        _currentScreenIndex++;
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topHeight = screenHeight * 0.6;
    final bottomHeight = screenHeight * 0.4;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // ВЕРХНЯЯ ЧАСТЬ (60%)
            Container(
              height: topHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance for close button
                      ],
                    ),
                  ),

                  // Image
                  Container(
                    height: 180,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: widget.product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.product.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.coffee,
                                  size: 80,
                                  color: Colors.brown,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.coffee,
                                size: 80,
                                color: Colors.brown,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),

                  const SizedBox(height: 20),

                  // Выбранные кубики
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Вы добавили:',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: selectedModifiersList.isEmpty
                              ? Center(
                                  child: Text(
                                    'Выберите ${currentScreen.title.toLowerCase()}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: selectedModifiersList.length,
                                  itemBuilder: (context, index) {
                                    final selected = selectedModifiersList[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.gradient1,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (selected.option.emoji != null) ...[
                                              Text(
                                                selected.option.emoji!,
                                                style: const TextStyle(fontSize: 20),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  selected.option.label,
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                if (selected.option.volume != null)
                                                  Text(
                                                    selected.option.volume!,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ).animate(key: ValueKey(selected))
                                          .fadeIn(duration: 200.ms)
                                          .scale(begin: const Offset(0.8, 0.8)),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 12),
                        // Итоговая цена
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Итого:',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${totalPrice.toInt()}₽',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Разделитель
            Container(
              height: 1,
              color: Colors.grey[200],
            ),

            // НИЖНЯЯ ЧАСТЬ (40%)
            Container(
              height: bottomHeight,
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Заголовок секции
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentScreen.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!currentScreen.group.required)
                          TextButton(
                            onPressed: _skipScreen,
                            child: Text(
                              'Пропустить',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid кубиков
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: currentScreen.group.options.length,
                      itemBuilder: (context, index) {
                        final option = currentScreen.group.options[index];
                        final isSelected = currentScreen.group.type == 'single'
                            ? _selectedModifiers[currentScreen.groupKey] == index
                            : (_selectedModifiers[currentScreen.groupKey] as List<int>)
                                .contains(index);

                        return ModifierCube(
                          label: option.label,
                          emoji: option.emoji,
                          volume: option.volume,
                          price: option.price,
                          isSelected: isSelected,
                          onTap: () => _selectModifier(index),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Кнопка "Далее" или "Добавить в корзину"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: canProceed ? _nextScreen : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: canProceed ? 8 : 0,
                        ),
                        child: Text(
                          isLastScreen ? 'Добавить в корзину' : 'Далее',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Модель экрана модификаторов
class ModifierScreen {
  final String groupKey;
  final String title;
  final ModifierGroup group;

  ModifierScreen({
    required this.groupKey,
    required this.title,
    required this.group,
  });
}

/// Модель выбранного модификатора
class SelectedModifier {
  final String groupKey;
  final ModifierOption option;

  SelectedModifier({
    required this.groupKey,
    required this.option,
  });
}

