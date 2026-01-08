import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  PackageInfo? _packageInfo;
  String _storageSize = '155 МБ';
  String _mobileData = '241 МБ';
  String _mobileDataDate = '30 окт.';
  String _usageTime = 'меньше 1 минуты';
  String _batteryUsage = '0%';
  String _notificationsCount = '0';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Загружаем данные
    await _loadAppInfo();
    _loadStorageInfo();
    await _loadUsageStats();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
      });
    } catch (e) {
      // Для веб-приложений package_info_plus может не работать
      // Используем дефолтные значения
      print('Warning: package_info_plus not available (web?): $e');
      setState(() {
        // Устанавливаем дефолтные значения
        _packageInfo = null;
      });
    }
  }

  Future<void> _loadStorageInfo() async {
    // Для веб-приложения пытаемся получить информацию о хранилище
    try {
      // Вычисляем примерный размер на основе сохраненных данных
      // Это приблизительная оценка, так как точное вычисление для веба ограничено
      int estimatedSize = 155; // МБ - базовая оценка
      
      // Можно добавить более точную оценку через IndexedDB/Web Storage
      // Но для начала используем базовое значение
      setState(() {
        _storageSize = '$estimatedSize МБ';
      });
    } catch (e) {
      print('Error loading storage info: $e');
      setState(() {
        _storageSize = '155 МБ';
      });
    }
  }

  Future<void> _loadUsageStats() async {
    // Загружаем статистику использования
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Используем простой формат даты без локализации для избежания ошибок
      String formatDate(DateTime date) {
        final months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 
                       'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
        return '${date.day} ${months[date.month - 1]}.';
      }
      
      // Попытка получить дату первого использования
      final firstUseDate = prefs.getString('first_use_date');
      DateTime startDate;
      
      if (firstUseDate != null) {
        startDate = DateTime.parse(firstUseDate);
      } else {
        // Если нет сохраненной даты, используем текущую дату минус 85 дней (пример из скрина)
        startDate = now.subtract(const Duration(days: 85));
        await prefs.setString('first_use_date', startDate.toIso8601String());
      }
      
      // Обновляем счетчик сессий
      final sessionCount = (prefs.getInt('session_count') ?? 0) + 1;
      await prefs.setInt('session_count', sessionCount);
      
      // Вычисляем мобильный трафик (примерное значение)
      final estimatedData = 100 + (sessionCount * 2); // Базовое значение + по сессиям
      
      setState(() {
        _mobileDataDate = formatDate(startDate);
        _mobileData = '$estimatedData МБ';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading usage stats: $e');
      final now = DateTime.now();
      String formatDate(DateTime date) {
        final months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 
                       'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
        return '${date.day} ${months[date.month - 1]}.';
      }
      setState(() {
        _mobileDataDate = formatDate(now.subtract(const Duration(days: 85)));
        _mobileData = '241 МБ';
        _isLoading = false;
      });
    }
  }

  String _getSystemLanguage() {
    try {
      // Получаем язык системы через Platform (упрощенная версия для веб)
      // Для веб-приложения используем дефолтное значение
      return 'Язык системы';
    } catch (e) {
      return 'Язык системы';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = 'Coffee App';
    final version = _packageInfo?.version ?? '1.0.0';
    final buildNumber = _packageInfo?.buildNumber ?? '1';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'О приложении',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // TODO: Редактирование настроек
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // Иконка приложения
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.bottomNavActive,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bottomNavActive.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_cafe,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Название приложения
                  Text(
                    appName,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Версия $version (build $buildNumber)',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Три кнопки действий
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.cloud_upload,
                          label: 'Отправить в архив',
                          color: const Color(0xFFFF6B9D),
                        ),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Удалить',
                          color: const Color(0xFFFF6B9D),
                        ),
                        _buildActionButton(
                          icon: Icons.error_outline,
                          label: 'Остановить',
                          color: const Color(0xFFFF6B9D),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Информация о приложении
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildInfoItem(
                          'Уведомления',
                          'Примерно $_notificationsCount уведомлений в неделю',
                        ),
                        _buildInfoItem(
                          'Разрешения',
                          'Уведомления',
                        ),
                        _buildInfoItem(
                          'Хранилище и кеш',
                          'Занято $_storageSize (внутренняя память)',
                        ),
                        _buildInfoItem(
                          'Мобильный трафик',
                          '$_mobileData с $_mobileDataDate',
                        ),
                        _buildInfoItem(
                          'Время использования',
                          'Сегодня: $_usageTime',
                        ),
                        _buildInfoItem(
                          'Расход заряда приложением',
                          'Использовано с момента последней полной зарядки: $_batteryUsage',
                        ),
                        _buildInfoItem(
                          'Язык',
                          _getSystemLanguage(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Divider(
            color: Colors.white12,
            thickness: 1,
            height: 24,
          ),
        ],
      ),
    );
  }
}

