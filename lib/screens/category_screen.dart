import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../utils/responsive.dart';

/// Экран категории с товарами - full-screen страница
class CategoryScreen extends StatelessWidget {
  final Category category;
  final List<Product> products;
  final VoidCallback? onBack;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.products,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = Responsive.responsiveCrossAxisCount(context);
    final padding = Responsive.responsiveSize(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          category.name,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.responsiveSize(
              context,
              mobile: 20.0,
              tablet: 22.0,
              desktop: 24.0,
            ),
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'В этой категории пока нет товаров',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // TODO: Добавить refresh логику если нужно
                await Future.delayed(const Duration(seconds: 1));
              },
              child: CustomScrollView(
                slivers: [
                  // GridView товаров
                  SliverPadding(
                    padding: EdgeInsets.all(padding),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return ProductCard(product: product)
                              .animate(delay: Duration(milliseconds: 50 * index))
                              .fadeIn()
                              .scale(begin: const Offset(0.9, 0.9));
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

