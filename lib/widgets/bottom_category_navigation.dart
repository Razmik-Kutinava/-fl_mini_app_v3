import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/category.dart' as models;

class BottomCategoryNavigation extends StatelessWidget {
  final List<models.Category> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;
  final bool showAll;

  const BottomCategoryNavigation({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.bottomNavBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: categories.length + (showAll ? 1 : 0),
          itemBuilder: (context, index) {
            if (showAll && index == 0) {
              final isSelected = selectedCategoryId == null;
              return _CategoryTab(
                label: 'для тебя',
                emoji: '🎁',
                isSelected: isSelected,
                onTap: () => onCategorySelected(null),
              );
            }

            final categoryIndex = showAll ? index - 1 : index;
            final category = categories[categoryIndex];
            final isSelected = selectedCategoryId == category.id;

            return _CategoryTab(
              label: category.name,
              emoji: category.emoji,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category.id),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.gradient1 : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: isSelected
              ? null
              : Border.all(
                  color: AppColors.bottomNavInactive.withOpacity(0.3),
                  width: 1,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.bottomNavActive.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected
                    ? Colors.white
                    : AppColors.bottomNavInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

