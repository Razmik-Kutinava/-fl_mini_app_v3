import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'glowing_line.dart';

/// Верхняя панель статуса для планшетной версии
class TabletTopBar extends StatelessWidget {
  const TabletTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.topBarBackground,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(child: Container()),
              // Светящаяся линия снизу
              GlowingLine(
                height: 2,
                color: AppColors.borderGlow,
              ),
            ],
          ),
          // Контент панели
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Левая часть
              Row(
                children: [
                  Text(
                    '\$>',
                    style: AppTextStyles.command(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ПЛАНШЕТ::ЗАКАЗЫ',
                    style: AppTextStyles.bodySmall(),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    timeString,
                    style: AppTextStyles.bodyTiny(),
                  ),
                ],
              ),
              
              // Правая часть
              Row(
                children: [
                  Text(
                    'БАРИСТА: ${userProvider.userName?.toUpperCase() ?? "ГОСТЬ"}',
                    style: AppTextStyles.bodySmall(),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'СМЕНА: 042',
                    style: AppTextStyles.bodyTiny(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
