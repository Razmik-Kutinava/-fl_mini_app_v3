-- SQL скрипт для создания связей между продуктами и группами модификаторов
-- Выполните этот скрипт в Supabase SQL Editor ПОСЛЕ того, как создали модификаторы

-- Этот скрипт автоматически найдет все группы модификаторов и свяжет их с продуктами

DO $$
DECLARE
  cappuccino_id UUID := '5a83c268-d7de-47cd-9464-85ad086e2266'; -- Капучино
  tea_id UUID := 'b368b7a0-26cb-4751-8746-d30025d215ed'; -- Чай
  group_record RECORD;
  link_count INTEGER;
BEGIN
  -- Связываем все группы модификаторов с Капучино
  FOR group_record IN 
    SELECT id, name FROM "ModifierGroup"
  LOOP
    -- Проверяем, есть ли уже связь
    SELECT COUNT(*) INTO link_count
    FROM "ProductModifierGroup"
    WHERE "productId" = cappuccino_id 
      AND "modifierGroupId" = group_record.id;
    
    -- Если связи нет, создаем
    IF link_count = 0 THEN
      INSERT INTO "ProductModifierGroup" (id, "productId", "modifierGroupId", "createdAt", "updatedAt")
      VALUES (gen_random_uuid(), cappuccino_id, group_record.id, NOW(), NOW());
      RAISE NOTICE 'Создана связь: Капучино <-> %', group_record.name;
    ELSE
      RAISE NOTICE 'Связь уже существует: Капучино <-> %', group_record.name;
    END IF;
  END LOOP;
  
  -- Связываем все группы модификаторов с Чай
  FOR group_record IN 
    SELECT id, name FROM "ModifierGroup"
  LOOP
    -- Проверяем, есть ли уже связь
    SELECT COUNT(*) INTO link_count
    FROM "ProductModifierGroup"
    WHERE "productId" = tea_id 
      AND "modifierGroupId" = group_record.id;
    
    -- Если связи нет, создаем
    IF link_count = 0 THEN
      INSERT INTO "ProductModifierGroup" (id, "productId", "modifierGroupId", "createdAt", "updatedAt")
      VALUES (gen_random_uuid(), tea_id, group_record.id, NOW(), NOW());
      RAISE NOTICE 'Создана связь: Чай <-> %', group_record.name;
    ELSE
      RAISE NOTICE 'Связь уже существует: Чай <-> %', group_record.name;
    END IF;
  END LOOP;
  
  RAISE NOTICE '✅ Все связи созданы успешно!';
END $$;

-- Проверка результата
SELECT 
  p.name as product_name,
  mg.name as modifier_group_name,
  mg.type as group_type,
  COUNT(mo.id) as options_count
FROM "Product" p
JOIN "ProductModifierGroup" pmg ON p.id = pmg."productId"
JOIN "ModifierGroup" mg ON pmg."modifierGroupId" = mg.id
LEFT JOIN "ModifierOption" mo ON mg.id = mo."groupId" AND mo."isActive" = true
WHERE p.id IN ('5a83c268-d7de-47cd-9464-85ad086e2266', 'b368b7a0-26cb-4751-8746-d30025d215ed')
GROUP BY p.name, mg.name, mg.type
ORDER BY p.name, mg.name;

