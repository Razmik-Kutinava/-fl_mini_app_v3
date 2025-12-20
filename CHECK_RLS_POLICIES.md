# 🔒 Проверка RLS политик для ProductModifierGroup

## Проблема
Таблица `ProductModifierGroup` возвращает пустой результат, хотя данные должны быть там.

## Причина
Скорее всего, **RLS (Row Level Security) политики блокируют доступ** к таблице `ProductModifierGroup`.

## ✅ Решение

### Шаг 1: Проверьте RLS политики

1. Откройте **Supabase Dashboard** → **Database** → **Tables** → **ProductModifierGroup**
2. Перейдите на вкладку **"Policies"**
3. Проверьте, есть ли политика для **SELECT** операций

### Шаг 2: Создайте RLS политику (если её нет)

Выполните этот SQL в **SQL Editor**:

```sql
-- Включаем RLS для таблицы
ALTER TABLE "ProductModifierGroup" ENABLE ROW LEVEL SECURITY;

-- Создаем политику для SELECT (чтение) - разрешаем всем
CREATE POLICY "Allow public read access" 
ON "ProductModifierGroup"
FOR SELECT
USING (true);

-- Создаем политику для INSERT (создание) - разрешаем всем
CREATE POLICY "Allow public insert access" 
ON "ProductModifierGroup"
FOR INSERT
WITH CHECK (true);
```

### Шаг 3: Проверьте существующие политики

Если политики уже есть, но не работают, удалите их и создайте заново:

```sql
-- Удаляем все существующие политики
DROP POLICY IF EXISTS "Allow public read access" ON "ProductModifierGroup";
DROP POLICY IF EXISTS "Allow public insert access" ON "ProductModifierGroup";

-- Создаем новые политики
CREATE POLICY "Allow public read access" 
ON "ProductModifierGroup"
FOR SELECT
USING (true);

CREATE POLICY "Allow public insert access" 
ON "ProductModifierGroup"
FOR INSERT
WITH CHECK (true);
```

### Шаг 4: Проверьте данные

После создания политик проверьте, что данные есть:

```sql
-- Проверка количества записей
SELECT COUNT(*) FROM "ProductModifierGroup";

-- Проверка связей для конкретного продукта
SELECT 
  p.name as product_name,
  mg.name as modifier_group_name
FROM "ProductModifierGroup" pmg
JOIN "Product" p ON pmg."productId" = p.id
JOIN "ModifierGroup" mg ON pmg."modifierGroupId" = mg.id
WHERE p.id = '5a83c268-d7de-47cd-9464-85ad086e2266';
```

### Шаг 5: Если данных нет - создайте их

Если запрос выше вернул 0 записей, выполните скрипт `create_product_modifier_links.sql`.

## 🔍 Альтернативная проверка

Попробуйте выполнить запрос напрямую в Supabase SQL Editor:

```sql
-- Этот запрос должен вернуть данные, если они есть и RLS разрешает
SELECT * FROM "ProductModifierGroup" LIMIT 10;
```

Если этот запрос возвращает данные, но приложение их не видит - проблема в RLS политиках для anon роли.

## 📋 Быстрое решение (если ничего не помогает)

Временно отключите RLS для тестирования (НЕ рекомендуется для продакшена):

```sql
ALTER TABLE "ProductModifierGroup" DISABLE ROW LEVEL SECURITY;
```

**ВНИМАНИЕ:** Это отключает безопасность! Используйте только для тестирования.

