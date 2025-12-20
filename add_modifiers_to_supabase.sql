-- SQL скрипт для добавления модификаторов к продукту "Капучино"
-- Выполните этот скрипт в Supabase SQL Editor

-- ID продукта Капучино (из логов: 5a83c268-d7de-47cd-9464-85ad086e2266)
DO $$
DECLARE
  product_id UUID := '5a83c268-d7de-47cd-9464-85ad086e2266';
  size_group_id UUID;
  milk_group_id UUID;
  extras_group_id UUID;
BEGIN
  -- 1. Создаем группу "Размер" (обязательная, одиночный выбор)
  INSERT INTO "ModifierGroup" (id, name, required, type, "minSelect", "maxSelect", "createdAt", "updatedAt")
  VALUES (gen_random_uuid(), 'Размер', true, 'SINGLE', 1, 1, NOW(), NOW())
  RETURNING id INTO size_group_id;

  -- 2. Создаем группу "Молоко" (опциональная, одиночный выбор)
  INSERT INTO "ModifierGroup" (id, name, required, type, "minSelect", "maxSelect", "createdAt", "updatedAt")
  VALUES (gen_random_uuid(), 'Молоко', false, 'SINGLE', 0, 1, NOW(), NOW())
  RETURNING id INTO milk_group_id;

  -- 3. Создаем группу "Дополнительно" (опциональная, множественный выбор)
  INSERT INTO "ModifierGroup" (id, name, required, type, "minSelect", "maxSelect", "createdAt", "updatedAt")
  VALUES (gen_random_uuid(), 'Дополнительно', false, 'MULTIPLE', 0, 10, NOW(), NOW())
  RETURNING id INTO extras_group_id;

  -- 4. Связываем группы с продуктом
  INSERT INTO "ProductModifierGroup" (id, "productId", "modifierGroupId", "createdAt", "updatedAt")
  VALUES 
    (gen_random_uuid(), product_id, size_group_id, NOW(), NOW()),
    (gen_random_uuid(), product_id, milk_group_id, NOW(), NOW()),
    (gen_random_uuid(), product_id, extras_group_id, NOW(), NOW());

  -- 5. Создаем опции для группы "Размер"
  INSERT INTO "ModifierOption" (id, "groupId", name, description, price, emoji, "isActive", "sortOrder", "createdAt", "updatedAt")
  VALUES 
    (gen_random_uuid(), size_group_id, 'S', '250 мл', 0, NULL, true, 1, NOW(), NOW()),
    (gen_random_uuid(), size_group_id, 'M', '350 мл', 50, NULL, true, 2, NOW(), NOW()),
    (gen_random_uuid(), size_group_id, 'L', '450 мл', 100, NULL, true, 3, NOW(), NOW());

  -- 6. Создаем опции для группы "Молоко"
  INSERT INTO "ModifierOption" (id, "groupId", name, description, price, emoji, "isActive", "sortOrder", "createdAt", "updatedAt")
  VALUES 
    (gen_random_uuid(), milk_group_id, 'Обычное', NULL, 0, NULL, true, 1, NOW(), NOW()),
    (gen_random_uuid(), milk_group_id, 'Соевое', NULL, 30, NULL, true, 2, NOW(), NOW()),
    (gen_random_uuid(), milk_group_id, 'Миндальное', NULL, 40, NULL, true, 3, NOW(), NOW()),
    (gen_random_uuid(), milk_group_id, 'Кокосовое', NULL, 50, NULL, true, 4, NOW(), NOW());

  -- 7. Создаем опции для группы "Дополнительно"
  INSERT INTO "ModifierOption" (id, "groupId", name, description, price, emoji, "isActive", "sortOrder", "createdAt", "updatedAt")
  VALUES 
    (gen_random_uuid(), extras_group_id, 'Ваниль', NULL, 50, '🍦', true, 1, NOW(), NOW()),
    (gen_random_uuid(), extras_group_id, 'Карамель', NULL, 50, '🍮', true, 2, NOW(), NOW()),
    (gen_random_uuid(), extras_group_id, 'Маршмеллоу', NULL, 30, '☁️', true, 3, NOW(), NOW()),
    (gen_random_uuid(), extras_group_id, '+Шот эспрессо', NULL, 50, '🔥', true, 4, NOW(), NOW()),
    (gen_random_uuid(), extras_group_id, 'Лёд', NULL, 0, '🧊', true, 5, NOW(), NOW()),
    (gen_random_uuid(), extras_group_id, 'Сахар', NULL, 0, '🍬', true, 6, NOW(), NOW());

  RAISE NOTICE 'Модификаторы успешно созданы!';
  RAISE NOTICE 'Size Group ID: %', size_group_id;
  RAISE NOTICE 'Milk Group ID: %', milk_group_id;
  RAISE NOTICE 'Extras Group ID: %', extras_group_id;
END $$;

-- Также добавим модификаторы для продукта "Чай" (id: b368b7a0-26cb-4751-8746-d30025d215ed)
DO $$
DECLARE
  product_id UUID := 'b368b7a0-26cb-4751-8746-d30025d215ed';
  tea_type_group_id UUID;
  tea_extras_group_id UUID;
BEGIN
  -- 1. Группа "Тип чая" (обязательная)
  INSERT INTO "ModifierGroup" (id, name, required, type, "minSelect", "maxSelect", "createdAt", "updatedAt")
  VALUES (gen_random_uuid(), 'Тип чая', true, 'SINGLE', 1, 1, NOW(), NOW())
  RETURNING id INTO tea_type_group_id;

  -- 2. Группа "Добавки" (опциональная, множественный выбор)
  INSERT INTO "ModifierGroup" (id, name, required, type, "minSelect", "maxSelect", "createdAt", "updatedAt")
  VALUES (gen_random_uuid(), 'Добавки', false, 'MULTIPLE', 0, 10, NOW(), NOW())
  RETURNING id INTO tea_extras_group_id;

  -- 3. Связываем с продуктом
  INSERT INTO "ProductModifierGroup" (id, "productId", "modifierGroupId", "createdAt", "updatedAt")
  VALUES 
    (gen_random_uuid(), product_id, tea_type_group_id, NOW(), NOW()),
    (gen_random_uuid(), product_id, tea_extras_group_id, NOW(), NOW());

  -- 4. Опции для типа чая
  INSERT INTO "ModifierOption" (id, "groupId", name, description, price, emoji, "isActive", "sortOrder", "createdAt", "updatedAt")
  VALUES 
    (gen_random_uuid(), tea_type_group_id, 'Зелёный', NULL, 150, NULL, true, 1, NOW(), NOW()),
    (gen_random_uuid(), tea_type_group_id, 'Чёрный', NULL, 150, NULL, true, 2, NOW(), NOW()),
    (gen_random_uuid(), tea_type_group_id, 'Травяной', NULL, 180, NULL, true, 3, NOW(), NOW()),
    (gen_random_uuid(), tea_type_group_id, 'Фруктовый', NULL, 200, NULL, true, 4, NOW(), NOW());

  -- 5. Опции для добавок
  INSERT INTO "ModifierOption" (id, "groupId", name, description, price, emoji, "isActive", "sortOrder", "createdAt", "updatedAt")
  VALUES 
    (gen_random_uuid(), tea_extras_group_id, 'Мёд', NULL, 30, '🍯', true, 1, NOW(), NOW()),
    (gen_random_uuid(), tea_extras_group_id, 'Лимон', NULL, 20, '🍋', true, 2, NOW(), NOW()),
    (gen_random_uuid(), tea_extras_group_id, 'Имбирь', NULL, 30, '🫚', true, 3, NOW(), NOW()),
    (gen_random_uuid(), tea_extras_group_id, 'Мята', NULL, 20, '🌿', true, 4, NOW(), NOW());

  RAISE NOTICE 'Модификаторы для чая успешно созданы!';
END $$;

