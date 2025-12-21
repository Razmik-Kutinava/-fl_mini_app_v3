-- SQL скрипт для создания связей между продуктами и группами модификаторов
-- Выполните этот скрипт в Supabase SQL Editor ПОСЛЕ того, как создали модификаторы

-- Этот скрипт автоматически найдет все группы модификаторов и свяжет их с продуктами

DO $$
DECLARE
  cappuccino_id UUID := '5a83c268-d7de-47cd-9464-85ad086e2266'::uuid; -- Капучино
  tea_id UUID := 'b368b7a0-26cb-4751-8746-d30025d215ed'::uuid; -- Чай
  group_record RECORD;
  link_count INTEGER;
  position_counter INTEGER := 1;
BEGIN
  -- Связываем все группы модификаторов с Капучино
  position_counter := 1;
  FOR group_record IN 
    SELECT id, name FROM "ModifierGroup" ORDER BY name
  LOOP
    -- Проверяем, есть ли уже связь (с явным приведением типов)
    SELECT COUNT(*) INTO link_count
    FROM "ProductModifierGroup"
    WHERE "productId"::uuid = cappuccino_id 
      AND "modifierGroupId"::uuid = group_record.id::uuid;
    
    -- Если связи нет, создаем
    IF link_count = 0 THEN
      INSERT INTO "ProductModifierGroup" (id, "productId", "modifierGroupId", position)
      VALUES (gen_random_uuid(), cappuccino_id, group_record.id::uuid, position_counter);
      RAISE NOTICE 'Создана связь: Капучино <-> % (position: %)', group_record.name, position_counter;
      position_counter := position_counter + 1;
    ELSE
      RAISE NOTICE 'Связь уже существует: Капучино <-> %', group_record.name;
    END IF;
  END LOOP;
  
  -- Связываем все группы модификаторов с Чай
  position_counter := 1;
  FOR group_record IN 
    SELECT id, name FROM "ModifierGroup" ORDER BY name
  LOOP
    -- Проверяем, есть ли уже связь (с явным приведением типов)
    SELECT COUNT(*) INTO link_count
    FROM "ProductModifierGroup"
    WHERE "productId"::uuid = tea_id 
      AND "modifierGroupId"::uuid = group_record.id::uuid;
    
    -- Если связи нет, создаем
    IF link_count = 0 THEN
      INSERT INTO "ProductModifierGroup" (id, "productId", "modifierGroupId", position)
      VALUES (gen_random_uuid(), tea_id, group_record.id::uuid, position_counter);
      RAISE NOTICE 'Создана связь: Чай <-> % (position: %)', group_record.name, position_counter;
      position_counter := position_counter + 1;
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
  pmg.position,
  COUNT(mo.id) as options_count
FROM "Product" p
JOIN "ProductModifierGroup" pmg ON p.id::uuid = pmg."productId"::uuid
JOIN "ModifierGroup" mg ON pmg."modifierGroupId"::uuid = mg.id::uuid
LEFT JOIN "ModifierOption" mo ON mg.id::uuid = mo."groupId"::uuid AND mo."isActive" = true
WHERE p.id::uuid IN ('5a83c268-d7de-47cd-9464-85ad086e2266'::uuid, 'b368b7a0-26cb-4751-8746-d30025d215ed'::uuid)
GROUP BY p.name, mg.name, mg.type, pmg.position
ORDER BY p.name, pmg.position;