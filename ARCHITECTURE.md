# Архитектура синхронизации Telegram Bot ↔ Flutter Mini App

## 🏗 Общая схема

```
┌──────────────────────────────────────────────────────────────────┐
│                         ПОЛЬЗОВАТЕЛЬ                              │
│                    (Telegram пользователь)                        │
└────────────────┬─────────────────────────────────┬────────────────┘
                 │                                 │
                 │ Взаимодействие                  │ Взаимодействие
                 ↓                                 ↓
┌────────────────────────────────┐  ┌──────────────────────────────┐
│      TELEGRAM BOT              │  │     FLUTTER MINI APP         │
│   (test.tg_mini_app_v1)        │  │    (fl_mini_app_v3)          │
│                                │  │                              │
│  - Python + python-telegram    │  │  - Flutter/Dart              │
│  - Кнопка "📦 Открыть каталог" │  │  - Web приложение            │
│  - Читает preferredLocationId │←─┼──→ Пишет preferredLocationId│
│  - Формирует URL с location_id │  │  - Автовыбор локации         │
└────────────┬───────────────────┘  └──────────┬───────────────────┘
             │                                 │
             │ Чтение/Запись                   │ Чтение/Запись
             ↓                                 ↓
┌────────────────────────────────────────────────────────────────────┐
│                          SUPABASE DATABASE                          │
│                         (PostgreSQL Cloud)                          │
│                                                                     │
│  Table: User                                                        │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ id (UUID)                    - Первичный ключ                 │ │
│  │ telegram_user_id (String)    - ID из Telegram                 │ │
│  │ telegramId (BigInt)          - ID из Telegram (альт)          │ │
│  │ preferredLocationId (UUID)   - ⭐ КЛЮЧЕВОЕ ПОЛЕ               │ │
│  │ username (String)            - Username из Telegram           │ │
│  │ first_name (String)          - Имя из Telegram                │ │
│  │ createdAt, updatedAt         - Временные метки                │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  Table: Location                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ id (UUID)                    - Первичный ключ                 │ │
│  │ name (String)                - Название локации               │ │
│  │ latitude, longitude (Float)  - Координаты                     │ │
│  │ address (String)             - Адрес                          │ │
│  │ status (String)              - active/inactive                │ │
│  │ isAcceptingOrders (Boolean)  - Принимает ли заказы           │ │
│  └──────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Поток данных: ПЕРВЫЙ ВХОД

```
1️⃣ Пользователь открывает бота
   │
   ↓
2️⃣ Бот: /start или нажатие "📦 Открыть каталог"
   │
   ↓
3️⃣ Бот → Supabase: Ищет/создает пользователя
   │
   ├─→ SELECT * FROM "User" WHERE telegram_user_id = '123456789'
   │
   └─→ INSERT INTO "User" (id, telegram_user_id, ...) VALUES (...)
   │
   ↓
4️⃣ Бот: Проверяет preferredLocationId
   │
   └─→ preferredLocationId = NULL (первый вход)
   │
   ↓
5️⃣ Бот: Формирует URL для WebApp
   │
   └─→ https://fl-mini-app-v3.onrender.com
   │   (без параметров, так как локации нет)
   │
   ↓
6️⃣ Пользователь видит PermissionsScreen
   │
   ↓
7️⃣ Пользователь выбирает локацию
   │
   ↓
8️⃣ Flutter: LocationProvider.selectLocation(location)
   │
   ├─→ Сохраняет в локальное хранилище (SharedPreferences)
   │
   └─→ ⭐ Сохраняет в Supabase:
       │
       └─→ UPDATE "User"
           SET preferredLocationId = 'xxx-xxx-xxx'
           WHERE id = 'user-uuid'
   │
   ↓
9️⃣ Пользователь попадает в MainScreen (главное меню)

✅ РЕЗУЛЬТАТ: preferredLocationId сохранен в БД!
```

---

## 🔄 Поток данных: ВТОРОЙ ВХОД (КЛЮЧЕВОЕ ИЗМЕНЕНИЕ)

```
1️⃣ Пользователь снова открывает бота
   │
   ↓
2️⃣ Бот: Нажатие "📦 Открыть каталог"
   │
   ↓
3️⃣ Бот → Supabase: Получает пользователя
   │
   └─→ SELECT * FROM "User" WHERE telegram_user_id = '123456789'
   │
   ↓
4️⃣ Бот: Проверяет preferredLocationId
   │
   └─→ ⭐ preferredLocationId = 'xxx-xxx-xxx' (есть!)
   │
   ↓
5️⃣ Бот → Supabase: Получает локацию
   │
   └─→ SELECT * FROM "Location" WHERE id = 'xxx-xxx-xxx'
   │
   ↓
6️⃣ Бот: Формирует URL с location_id в hash
   │
   └─→ https://fl-mini-app-v3.onrender.com#location_id=xxx-xxx-xxx
   │
   ↓
7️⃣ Flutter: Парсит hash параметры
   │
   └─→ getLocationIdFromHashWithRetry()
       │
       └─→ Находит location_id = 'xxx-xxx-xxx'
   │
   ↓
8️⃣ Flutter: Автоматически выбирает локацию
   │
   └─→ locationProvider.selectLocation(targetLocation)
   │
   ↓
9️⃣ ⭐ Пользователь СРАЗУ попадает в MainScreen!
   │
   └─→ БЕЗ PermissionsScreen!
   └─→ БЕЗ выбора локации!

✅ РЕЗУЛЬТАТ: Пользователь попал в главное меню за секунду!
```

---

## 📂 Ключевые компоненты

### 1. SupabaseService (Flutter)
**Файл:** `lib/services/supabase_service.dart`

```dart
class SupabaseService {
  // Читает preferredLocationId из БД
  static Future<String?> getUserPreferredLocationId(String telegramId)

  // ⭐ НОВЫЙ МЕТОД: Пишет preferredLocationId в БД
  static Future<bool> updateUserPreferredLocation({
    required String userId,
    required String locationId,
  })

  // Получает локацию из последнего заказа
  static Future<String?> getUserLastOrderLocationId(String visitorId)

  // Создает/получает пользователя
  static Future<Map<String, dynamic>?> getOrCreateUser(...)
}
```

### 2. LocationProvider (Flutter)
**Файл:** `lib/providers/location_provider.dart`

```dart
class LocationProvider with ChangeNotifier {
  String? _userId;  // ⭐ НОВОЕ ПОЛЕ

  // ⭐ НОВЫЙ МЕТОД: Устанавливает userId
  void setUserId(String? userId) {
    _userId = userId;
  }

  // ⭐ ОБНОВЛЕННЫЙ МЕТОД: Теперь сохраняет в БД
  Future<void> selectLocation(Location location) async {
    _selectedLocation = location;

    // Сохраняем локально
    await _saveLastLocation(location.id);

    // ⭐ НОВОЕ: Сохраняем в БД
    if (_userId != null) {
      await SupabaseService.updateUserPreferredLocation(
        userId: _userId!,
        locationId: location.id,
      );
    }
  }
}
```

### 3. AppInitializer (Flutter)
**Файл:** `lib/main.dart`

```dart
class _AppInitializerState extends State<AppInitializer> {
  Future<void> _initializeUser() async {
    // 1. Получаем пользователя из БД
    final user = await SupabaseService.getOrCreateUser(...);

    // 2. ⭐ НОВОЕ: Устанавливаем userId в LocationProvider
    locationProvider.setUserId(user['id'] as String);

    // 3. Загружаем локации
    // 4. Восстанавливаем локацию (4 приоритета)
    // 5. ⭐ Автоматически сохраняем в БД через selectLocation()
    await locationProvider.selectLocation(targetLocation);
  }
}
```

### 4. Telegram Bot
**Файл:** `../test.tg_mini_app_v1/bot.py`

```python
def get_user_location_context(user_id: int) -> Optional[Dict]:
    """Определяет последнюю локацию пользователя"""
    # 1. Ищет пользователя в БД
    user_resp = supabase.table("User").select("*").eq("telegramId", user_id)

    # 2. Получает preferredLocationId
    preferred_location_id = user_row.get("preferredLocationId")

    # 3. Если есть - получает данные локации
    if preferred_location_id:
        loc_resp = supabase.table("Location").select("*").eq("id", preferred_location_id)
        return {
            "location_id": loc.get("id"),
            "lat": loc.get("latitude"),
            "lon": loc.get("longitude"),
            "name": loc.get("name")
        }
```

---

## 🎯 Приоритеты восстановления локации

```
ПРИОРИТЕТ 0 (Высший)
┌─────────────────────────────────────────────┐
│  location_id из hash параметров URL         │
│  Источник: Telegram Bot                     │
│  Формат: #location_id=xxx-xxx-xxx           │
│  Когда: Бот знает последнюю локацию         │
└─────────────────────────────────────────────┘
                    ↓ Если нет
ПРИОРИТЕТ 1
┌─────────────────────────────────────────────┐
│  preferredLocationId из Supabase            │
│  Источник: База данных                      │
│  Таблица: User                              │
│  Когда: Пользователь раньше выбирал локацию │
└─────────────────────────────────────────────┘
                    ↓ Если нет
ПРИОРИТЕТ 2
┌─────────────────────────────────────────────┐
│  Локация из локального хранилища            │
│  Источник: SharedPreferences                │
│  Когда: Второй заход без БД                 │
└─────────────────────────────────────────────┘
                    ↓ Если нет
ПРИОРИТЕТ 3 (Низший)
┌─────────────────────────────────────────────┐
│  Первая доступная локация                   │
│  Источник: Список активных локаций          │
│  Когда: Совсем новый пользователь           │
└─────────────────────────────────────────────┘
```

---

## 🔐 Безопасность и RLS

**Supabase Row Level Security (RLS):**

```sql
-- Пользователи могут читать только свои данные
CREATE POLICY "Users can read own data"
ON "User"
FOR SELECT
USING (auth.uid()::text = id::text);

-- Пользователи могут обновлять только свои данные
CREATE POLICY "Users can update own data"
ON "User"
FOR UPDATE
USING (auth.uid()::text = id::text);

-- Все могут читать активные локации
CREATE POLICY "Anyone can read active locations"
ON "Location"
FOR SELECT
USING (status = 'active');
```

---

## 📊 Мониторинг и метрики

**Ключевые метрики для отслеживания:**

```
1. Процент пользователей с заполненным preferredLocationId
   → Цель: > 95%

2. Время до попадания в главное меню при повторном входе
   → Цель: < 2 секунды

3. Количество ошибок обновления preferredLocationId
   → Цель: < 0.1%

4. Процент пользователей, попадающих сразу в MainScreen
   → Цель: > 90% (после первого входа)
```

---

## 🐛 Отладка

**Где искать проблемы:**

### 1. Локация не сохраняется в БД
```
Проверить:
- userId установлен в LocationProvider? (lib/main.dart:163)
- Метод updateUserPreferredLocation вызывается? (логи в консоли)
- RLS политики разрешают UPDATE? (Supabase Dashboard)
- Правильный ли userId передается?
```

### 2. При втором входе показывается стартовый экран
```
Проверить:
- preferredLocationId заполнен в БД? (Supabase Table Editor)
- Бот читает правильный telegram_user_id?
- Hash параметры передаются в URL? (проверить URL в браузере)
- Location с таким id существует в БД?
```

### 3. Бот не находит локацию
```
Проверить:
- Бот подключен к той же БД что и Flutter?
- В логах бота есть "Found preferredLocationId"?
- Location.status = 'active'?
- Location.isAcceptingOrders = true?
```

---

## 🔧 Конфигурация

**Переменные окружения:**

```bash
# Supabase (одинаковые для бота и Flutter)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...

# Telegram Bot
BOT_TOKEN=7969044420:AAE...
WEB_APP_URL=https://fl-mini-app-v3.onrender.com
```

**Важно:**
- Оба приложения ДОЛЖНЫ использовать одну и ту же БД
- ANON_KEY должен быть одинаковым
- WEB_APP_URL в боте должен совпадать с деплоем Flutter

---

## 📝 Чеклист развертывания

- [ ] Flutter приложение собрано и задеплоено
- [ ] Telegram бот запущен и работает
- [ ] Оба подключены к одной БД Supabase
- [ ] RLS политики настроены корректно
- [ ] Тестовый пользователь может войти и выбрать локацию
- [ ] При втором входе пользователь попадает в главное меню
- [ ] Логи показывают сохранение preferredLocationId
- [ ] Документация обновлена

---

**Дата:** 25.12.2024
**Версия:** 3.1
**Статус:** ✅ Production Ready
