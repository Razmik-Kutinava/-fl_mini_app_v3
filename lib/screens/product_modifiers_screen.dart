import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_colors.dart';
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
  late PageController _pageController;
  int _currentPage = 0;
  late List<ModifierScreenData> _screens;
  late Map<String, dynamic> _selectedModifiers;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _selectedModifiers = {};
    _buildScreens();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  bool get _canProceed {
    if (_currentPage >= _screens.length) return false;
    final screen = _screens[_currentPage];
    
    if (screen.isFinal) return true;
    if (screen.isOptional) return true;
    
    // Проверяем обязательные модификаторы
    final value = _selectedModifiers[screen.key];
    if (value == null) return false;
    
    // Для single типа должно быть int, для multiple - List<int> (не пустой)
    if (screen.group!.type == 'single') {
      return value is int || (value is List<int> && value.isNotEmpty);
    } else {
      return value is List<int> && value.isNotEmpty;
    }
  }

  double get _totalPrice {
    double total = widget.product.price;

    // Добавляем цену выбранных модификаторов
    for (var screen in _screens) {
      if (screen.key == 'size' && _selectedModifiers['size'] != null) {
        final sizeValue = _selectedModifiers['size'];
        if (sizeValue is int) {
          total += screen.group!.options[sizeValue].price;
        } else if (sizeValue is List<int> && sizeValue.isNotEmpty) {
          total += screen.group!.options[sizeValue[0]].price;
        }
      } else if (screen.key == 'milk' && _selectedModifiers['milk'] != null) {
        final milkValue = _selectedModifiers['milk'];
        if (milkValue is int) {
          total += screen.group!.options[milkValue].price;
        } else if (milkValue is List<int> && milkValue.isNotEmpty) {
          total += screen.group!.options[milkValue[0]].price;
        }
      } else if (screen.key == 'extras' && _selectedModifiers['extras'] != null) {
        final extrasValue = _selectedModifiers['extras'];
        if (extrasValue is List<int>) {
          for (var idx in extrasValue) {
            total += screen.group!.options[idx].price;
          }
        } else if (extrasValue is int) {
          total += screen.group!.options[extrasValue].price;
        }
      }
    }

    return total;
  }

  List<SelectedCube> get _selectedCubes {
    final cubes = <SelectedCube>[];

    for (var screen in _screens) {
      if (screen.key == 'size' && _selectedModifiers['size'] != null) {
        final sizeValue = _selectedModifiers['size'];
        int? index;
        if (sizeValue is int) {
          index = sizeValue;
        } else if (sizeValue is List<int> && sizeValue.isNotEmpty) {
          index = sizeValue[0];
        }
        if (index != null && index < screen.group!.options.length) {
          final option = screen.group!.options[index];
          cubes.add(SelectedCube(
            label: option.label,
            volume: option.volume,
            price: option.price,
            emoji: option.emoji,
          ));
        }
      } else if (screen.key == 'milk' && _selectedModifiers['milk'] != null) {
        final milkValue = _selectedModifiers['milk'];
        int? index;
        if (milkValue is int) {
          index = milkValue;
        } else if (milkValue is List<int> && milkValue.isNotEmpty) {
          index = milkValue[0];
        }
        if (index != null && index < screen.group!.options.length) {
          final option = screen.group!.options[index];
          cubes.add(SelectedCube(
            label: option.label,
            price: option.price,
            emoji: option.emoji,
          ));
        }
      } else if (screen.key == 'extras' && _selectedModifiers['extras'] != null) {
        final extrasValue = _selectedModifiers['extras'];
        if (extrasValue is List<int>) {
          for (var idx in extrasValue) {
            if (idx < screen.group!.options.length) {
              final option = screen.group!.options[idx];
              cubes.add(SelectedCube(
                label: option.label,
                emoji: option.emoji,
                price: option.price,
              ));
            }
          }
        } else if (extrasValue is int) {
          if (extrasValue < screen.group!.options.length) {
            final option = screen.group!.options[extrasValue];
            cubes.add(SelectedCube(
              label: option.label,
              emoji: option.emoji,
              price: option.price,
            ));
          }
        }
      }
    }

    return cubes;
  }

  void _onModifierTap(ModifierScreenData screen, int index) {
    setState(() {
      if (screen.group!.type == 'single') {
        // Одиночный выбор
        _selectedModifiers[screen.key] = index;
      } else {
        // Множественный выбор
        final currentValue = _selectedModifiers[screen.key];
        List<int> current;
        
        if (currentValue is List<int>) {
          current = List<int>.from(currentValue);
        } else if (currentValue is int) {
          // Если было сохранено как int, преобразуем в список
          current = [currentValue];
        } else {
          current = [];
        }
        
        if (current.contains(index)) {
          current.remove(index);
        } else {
          current.add(index);
        }
        _selectedModifiers[screen.key] = current;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _nextPage() {
    if (_currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _addToCart();
    }
  }

  void _skipPage() {
    if (_currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
    final screenHeight = MediaQuery.of(context).size.height;
    final topHeight = screenHeight * 0.6;
    final bottomHeight = screenHeight * 0.4;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Верхняя часть (60%)
          _buildTopSection(topHeight),
          
          // Нижняя часть (40%)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomHeight,
            child: _buildBottomSection(bottomHeight),
          ),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 1.57, // Down
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

  Widget _buildTopSection(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.gradient1,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.product.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
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
                          color: Colors.white.withOpacity(0.2),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.coffee,
                            size: 80,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.coffee,
                          size: 80,
                          color: Colors.white70,
                        ),
                      ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.9, 0.9)),
            
            const SizedBox(height: 24),
            
            // Selected cubes section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Вы добавили:',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _selectedCubes.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Text(
                            'Выберите опции ниже',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white60,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _selectedCubes.map((cube) {
                            return Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (cube.emoji != null)
                                    Text(
                                      cube.emoji!,
                                      style: const TextStyle(fontSize: 20),
                                    )
                                        .animate()
                                        .scale(begin: const Offset(0.5, 0.5), duration: 200.ms),
                                  if (cube.emoji != null) const SizedBox(height: 4),
                                  Text(
                                    cube.label,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (cube.volume != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      cube.volume!,
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                  if (cube.price > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '+${cube.price.toStringAsFixed(0)}₽',
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 200.ms)
                                .scale(begin: const Offset(0.5, 0.5), duration: 200.ms)
                                .then()
                                .shake(duration: 100.ms);
                          }).toList(),
                        ),
                  if (_selectedCubes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Итого:',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_totalPrice.toStringAsFixed(0)}₽',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn()
                        .scale(begin: const Offset(0.9, 0.9)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Page indicator
          if (_screens.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _screens.length,
                  (index) => Container(
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? AppColors.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                      .animate()
                      .scale(duration: 200.ms),
                ),
              ),
            ),
          
          // Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _screens.length,
              itemBuilder: (context, index) {
                final screen = _screens[index];
                return _buildModifierGrid(screen);
              },
            ),
          ),
          
          // Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierGrid(ModifierScreenData screen) {
    if (screen.isFinal) {
      return Center(
        child: Text(
          'Готово! Нажмите "Добавить в корзину"',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final group = screen.group!;
    final isMultiple = group.type == 'multiple';
    final currentSelection = _selectedModifiers[screen.key];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            screen.title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: group.options.length,
              itemBuilder: (context, index) {
                final option = group.options[index];
                bool isSelected;
                
                if (isMultiple) {
                  if (currentSelection is List<int>) {
                    isSelected = currentSelection.contains(index);
                  } else if (currentSelection is int) {
                    // Если группа multiple, но сохранено как int (старая версия)
                    isSelected = currentSelection == index;
                  } else {
                    isSelected = false;
                  }
                } else {
                  // Одиночный выбор
                  if (currentSelection is int) {
                    isSelected = currentSelection == index;
                  } else if (currentSelection is List<int> && currentSelection.length == 1) {
                    // Если группа single, но сохранено как List (старая версия)
                    isSelected = currentSelection[0] == index;
                  } else {
                    isSelected = false;
                  }
                }

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
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final isLastPage = _currentPage >= _screens.length - 1;
    final screen = _currentPage < _screens.length ? _screens[_currentPage] : null;
    final canSkip = screen?.isOptional ?? false;

    return Column(
      children: [
        if (canSkip && !isLastPage)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton(
              onPressed: _skipPage,
              child: Text(
                'Пропустить',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: _canProceed ? AppColors.gradient1 : null,
            color: _canProceed ? null : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
            boxShadow: _canProceed
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _canProceed ? _nextPage : null,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Text(
                  isLastPage ? 'Добавить в корзину' : 'Далее',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _canProceed ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        )
            .animate(target: _canProceed ? 1 : 0)
            .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.02, 1.02)),
      ],
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

