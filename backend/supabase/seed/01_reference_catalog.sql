-- Default reference marketplace: the golden-path category tree.
--
-- Installs the 11 top-level categories from the project foundation, with
-- Vehicles > Cars, Real Estate > Apartments, and Electronics > Phones fully
-- modeled (per docs/planning/05-dynamic-schema-engine.md §9 — the exit
-- criterion for the Dynamic Category & Attribute Engine phase), and lighter
-- schemas for the remaining subcategories to prove the mechanism generalizes
-- beyond the three golden-path verticals. All rows belong to the "default"
-- tenant seeded in 00_reference_config.sql.
--
-- Applied only against the "default" tenant — client_a is a white-label
-- override proof (branding/config), not a second full catalog.

do $$
declare
  v_tenant uuid := '00000000-0000-0000-0000-000000000001';
begin

-- === Top-level categories (11) ============================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a1000000-0000-0000-0000-000000000001', v_tenant, null, 'vehicles',    '{"en":"Vehicles","ar":"مركبات"}', false, 1),
  ('a1000000-0000-0000-0000-000000000002', v_tenant, null, 'real-estate','{"en":"Real Estate","ar":"عقارات"}', false, 2),
  ('a1000000-0000-0000-0000-000000000003', v_tenant, null, 'electronics','{"en":"Electronics","ar":"إلكترونيات"}', false, 3),
  ('a1000000-0000-0000-0000-000000000004', v_tenant, null, 'jobs',       '{"en":"Jobs","ar":"وظائف"}', false, 4),
  ('a1000000-0000-0000-0000-000000000005', v_tenant, null, 'services',   '{"en":"Services","ar":"خدمات"}', false, 5),
  ('a1000000-0000-0000-0000-000000000006', v_tenant, null, 'fashion',    '{"en":"Fashion","ar":"أزياء"}', false, 6),
  ('a1000000-0000-0000-0000-000000000007', v_tenant, null, 'furniture',  '{"en":"Furniture","ar":"أثاث"}', false, 7),
  ('a1000000-0000-0000-0000-000000000008', v_tenant, null, 'pets',       '{"en":"Pets","ar":"حيوانات أليفة"}', false, 8),
  ('a1000000-0000-0000-0000-000000000009', v_tenant, null, 'business',   '{"en":"Business","ar":"أعمال"}', false, 9),
  ('a1000000-0000-0000-0000-000000000010', v_tenant, null, 'community',  '{"en":"Community","ar":"مجتمع"}', false, 10),
  ('a1000000-0000-0000-0000-000000000011', v_tenant, null, 'other',      '{"en":"Other","ar":"أخرى"}', false, 11);

-- === Vehicles > Cars (fully modeled) =======================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000001', v_tenant, 'a1000000-0000-0000-0000-000000000001', 'cars', '{"en":"Cars","ar":"سيارات"}', true, 1);

insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', '{"en":"Details","ar":"التفاصيل"}', 1);

insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, is_searchable, unit, validation, sort_order) values
  ('c1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'brand',        '{"en":"Brand","ar":"الماركة"}',                'option', 'dropdown', true,  true,  true,  null,  '{}'::jsonb, 1),
  ('c1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'model',        '{"en":"Model","ar":"الموديل"}',                'option', 'dropdown', true,  true,  true,  null,  '{}'::jsonb, 2),
  ('c1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'year',         '{"en":"Year","ar":"سنة الصنع"}',                'number', 'stepper',  true,  true,  false, null,  '{"min":1970,"max":2027}'::jsonb, 3),
  ('c1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001', 'mileage',      '{"en":"Mileage","ar":"المسافة المقطوعة"}',      'number', 'stepper',  true,  true,  false, 'km',  '{"min":0,"max":2000000}'::jsonb, 4),
  ('c1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000001', 'transmission', '{"en":"Transmission","ar":"ناقل الحركة"}',      'option', 'dropdown', true,  true,  false, null,  '{}'::jsonb, 5),
  ('c1000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000001', 'fuelType',     '{"en":"Fuel Type","ar":"نوع الوقود"}',          'option', 'dropdown', true,  true,  false, null,  '{}'::jsonb, 6),
  ('c1000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000001', 'color',        '{"en":"Color","ar":"اللون"}',                   'option', 'dropdown', false, true,  false, null,  '{}'::jsonb, 7),
  ('c1000000-0000-0000-0000-000000000008', 'b1000000-0000-0000-0000-000000000001', 'engineSize',   '{"en":"Engine Size","ar":"سعة المحرك"}',        'number', 'stepper',  false, false, false, 'L',   '{"min":0,"max":10}'::jsonb, 8),
  ('c1000000-0000-0000-0000-000000000009', 'b1000000-0000-0000-0000-000000000001', 'vin',          '{"en":"VIN","ar":"رقم الهيكل"}',                'text',   'textfield',false, false, true,  null,  '{"maxLength":17}'::jsonb, 9),
  ('c1000000-0000-0000-0000-000000000010', 'b1000000-0000-0000-0000-000000000001', 'condition',    '{"en":"Condition","ar":"الحالة"}',              'option', 'dropdown', true,  true,  false, null,  '{}'::jsonb, 10);

insert into catalog.attribute_option (id, attribute_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'bmw',     '{"en":"BMW","ar":"بي إم دبليو"}', 1),
  ('d1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 'toyota',  '{"en":"Toyota","ar":"تويوتا"}', 2),
  ('d1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000001', 'mercedes','{"en":"Mercedes-Benz","ar":"مرسيدس"}', 3),
  ('d1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000001', 'ford',    '{"en":"Ford","ar":"فورد"}', 4),
  ('d1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000001', 'honda',   '{"en":"Honda","ar":"هوندا"}', 5);

insert into catalog.attribute_option (id, attribute_id, parent_option_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000006', 'c1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000001', 'x5',      '{"en":"X5","ar":"إكس 5"}', 1),
  ('d1000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000002', 'corolla', '{"en":"Corolla","ar":"كورولا"}', 2),
  ('d1000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000003', 'c-class', '{"en":"C-Class","ar":"الفئة سي"}', 3);

insert into catalog.attribute_option (id, attribute_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000009', 'c1000000-0000-0000-0000-000000000005', 'automatic', '{"en":"Automatic","ar":"أوتوماتيك"}', 1),
  ('d1000000-0000-0000-0000-000000000010', 'c1000000-0000-0000-0000-000000000005', 'manual',    '{"en":"Manual","ar":"يدوي"}', 2),
  ('d1000000-0000-0000-0000-000000000011', 'c1000000-0000-0000-0000-000000000006', 'petrol',    '{"en":"Petrol","ar":"بنزين"}', 1),
  ('d1000000-0000-0000-0000-000000000012', 'c1000000-0000-0000-0000-000000000006', 'diesel',    '{"en":"Diesel","ar":"ديزل"}', 2),
  ('d1000000-0000-0000-0000-000000000013', 'c1000000-0000-0000-0000-000000000006', 'electric',  '{"en":"Electric","ar":"كهربائي"}', 3),
  ('d1000000-0000-0000-0000-000000000014', 'c1000000-0000-0000-0000-000000000006', 'hybrid',    '{"en":"Hybrid","ar":"هجين"}', 4),
  ('d1000000-0000-0000-0000-000000000015', 'c1000000-0000-0000-0000-000000000007', 'white',     '{"en":"White","ar":"أبيض"}', 1),
  ('d1000000-0000-0000-0000-000000000016', 'c1000000-0000-0000-0000-000000000007', 'black',     '{"en":"Black","ar":"أسود"}', 2),
  ('d1000000-0000-0000-0000-000000000017', 'c1000000-0000-0000-0000-000000000007', 'silver',    '{"en":"Silver","ar":"فضي"}', 3),
  ('d1000000-0000-0000-0000-000000000018', 'c1000000-0000-0000-0000-000000000007', 'red',       '{"en":"Red","ar":"أحمر"}', 4),
  ('d1000000-0000-0000-0000-000000000019', 'c1000000-0000-0000-0000-000000000010', 'new',       '{"en":"New","ar":"جديد"}', 1),
  ('d1000000-0000-0000-0000-000000000020', 'c1000000-0000-0000-0000-000000000010', 'used',      '{"en":"Used","ar":"مستعمل"}', 2);

insert into catalog.attribute_dependency (attribute_id, depends_on_id, rule) values
  ('c1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 'options_filtered_by');

-- === Vehicles > Motorcycles (light) ========================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000002', v_tenant, 'a1000000-0000-0000-0000-000000000001', 'motorcycles', '{"en":"Motorcycles","ar":"دراجات نارية"}', true, 2);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000002', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, sort_order) values
  ('c1000000-0000-0000-0000-000000000011', 'b1000000-0000-0000-0000-000000000002', 'brand', '{"en":"Brand","ar":"الماركة"}', 'option', 'dropdown', true, true, 1),
  ('c1000000-0000-0000-0000-000000000012', 'b1000000-0000-0000-0000-000000000002', 'year',  '{"en":"Year","ar":"سنة الصنع"}', 'number', 'stepper', true, true, 2);
insert into catalog.attribute_option (id, attribute_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000021', 'c1000000-0000-0000-0000-000000000011', 'yamaha', '{"en":"Yamaha","ar":"ياماها"}', 1),
  ('d1000000-0000-0000-0000-000000000022', 'c1000000-0000-0000-0000-000000000011', 'harley-davidson', '{"en":"Harley-Davidson","ar":"هارلي ديفيدسون"}', 2);

-- === Real Estate > Apartments (fully modeled) ==============================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000003', v_tenant, 'a1000000-0000-0000-0000-000000000002', 'apartments', '{"en":"Apartments","ar":"شقق"}', true, 1);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000003', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, unit, validation, sort_order) values
  ('c1000000-0000-0000-0000-000000000013', 'b1000000-0000-0000-0000-000000000003', 'bedrooms',    '{"en":"Bedrooms","ar":"غرف النوم"}',   'number', 'stepper', true,  true, null,   '{"min":0,"max":20}'::jsonb, 1),
  ('c1000000-0000-0000-0000-000000000014', 'b1000000-0000-0000-0000-000000000003', 'bathrooms',   '{"en":"Bathrooms","ar":"الحمامات"}',   'number', 'stepper', true,  true, null,   '{"min":0,"max":20}'::jsonb, 2),
  ('c1000000-0000-0000-0000-000000000015', 'b1000000-0000-0000-0000-000000000003', 'area',        '{"en":"Area","ar":"المساحة"}',         'number', 'stepper', true,  true, 'm²',  '{"min":0,"max":10000}'::jsonb, 3),
  ('c1000000-0000-0000-0000-000000000016', 'b1000000-0000-0000-0000-000000000003', 'floor',       '{"en":"Floor","ar":"الطابق"}',         'number', 'stepper', false, false, null,  '{"min":0,"max":200}'::jsonb, 4),
  ('c1000000-0000-0000-0000-000000000017', 'b1000000-0000-0000-0000-000000000003', 'furnished',   '{"en":"Furnished","ar":"مفروشة"}',     'bool',   'switch',  false, true, null,   '{}'::jsonb, 5),
  ('c1000000-0000-0000-0000-000000000018', 'b1000000-0000-0000-0000-000000000003', 'parking',     '{"en":"Parking","ar":"موقف سيارات"}', 'bool',   'switch',  false, true, null,   '{}'::jsonb, 6),
  ('c1000000-0000-0000-0000-000000000019', 'b1000000-0000-0000-0000-000000000003', 'propertyAge', '{"en":"Property Age","ar":"عمر العقار"}', 'number', 'stepper', false, true, 'years', '{"min":0,"max":100}'::jsonb, 7);

-- === Real Estate > Villas (light) ===========================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000004', v_tenant, 'a1000000-0000-0000-0000-000000000002', 'villas', '{"en":"Villas","ar":"فلل"}', true, 2);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000004', 'a2000000-0000-0000-0000-000000000004', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, unit, sort_order) values
  ('c1000000-0000-0000-0000-000000000020', 'b1000000-0000-0000-0000-000000000004', 'bedrooms', '{"en":"Bedrooms","ar":"غرف النوم"}', 'number', 'stepper', true, true, null, 1),
  ('c1000000-0000-0000-0000-000000000021', 'b1000000-0000-0000-0000-000000000004', 'area',     '{"en":"Area","ar":"المساحة"}',       'number', 'stepper', true, true, 'm²', 2);

-- === Electronics > Phones (fully modeled) ==================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000005', v_tenant, 'a1000000-0000-0000-0000-000000000003', 'phones', '{"en":"Phones","ar":"هواتف"}', true, 1);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000005', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, sort_order) values
  ('c1000000-0000-0000-0000-000000000022', 'b1000000-0000-0000-0000-000000000005', 'brand',         '{"en":"Brand","ar":"الماركة"}',           'option', 'dropdown', true,  true, 1),
  ('c1000000-0000-0000-0000-000000000023', 'b1000000-0000-0000-0000-000000000005', 'model',         '{"en":"Model","ar":"الموديل"}',           'option', 'dropdown', true,  true, 2),
  ('c1000000-0000-0000-0000-000000000024', 'b1000000-0000-0000-0000-000000000005', 'storage',       '{"en":"Storage","ar":"سعة التخزين"}',    'option', 'dropdown', true,  true, 3),
  ('c1000000-0000-0000-0000-000000000025', 'b1000000-0000-0000-0000-000000000005', 'ram',           '{"en":"RAM","ar":"الرام"}',               'option', 'dropdown', false, true, 4),
  ('c1000000-0000-0000-0000-000000000026', 'b1000000-0000-0000-0000-000000000005', 'batteryHealth', '{"en":"Battery Health","ar":"حالة البطارية"}', 'number', 'stepper', false, false, 5),
  ('c1000000-0000-0000-0000-000000000027', 'b1000000-0000-0000-0000-000000000005', 'condition',     '{"en":"Condition","ar":"الحالة"}',        'option', 'dropdown', true,  true, 6),
  ('c1000000-0000-0000-0000-000000000028', 'b1000000-0000-0000-0000-000000000005', 'color',         '{"en":"Color","ar":"اللون"}',              'option', 'dropdown', false, false, 7);

insert into catalog.attribute_option (id, attribute_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000023', 'c1000000-0000-0000-0000-000000000022', 'apple',   '{"en":"Apple","ar":"آبل"}', 1),
  ('d1000000-0000-0000-0000-000000000024', 'c1000000-0000-0000-0000-000000000022', 'samsung', '{"en":"Samsung","ar":"سامسونج"}', 2),
  ('d1000000-0000-0000-0000-000000000025', 'c1000000-0000-0000-0000-000000000022', 'google',  '{"en":"Google","ar":"جوجل"}', 3);

insert into catalog.attribute_option (id, attribute_id, parent_option_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000026', 'c1000000-0000-0000-0000-000000000023', 'd1000000-0000-0000-0000-000000000023', 'iphone-15',   '{"en":"iPhone 15","ar":"آيفون 15"}', 1),
  ('d1000000-0000-0000-0000-000000000027', 'c1000000-0000-0000-0000-000000000023', 'd1000000-0000-0000-0000-000000000024', 'galaxy-s24',  '{"en":"Galaxy S24","ar":"جالكسي إس 24"}', 2);

insert into catalog.attribute_option (id, attribute_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000028', 'c1000000-0000-0000-0000-000000000024', '64gb',  '{"en":"64GB","ar":"64 جيجا"}', 1),
  ('d1000000-0000-0000-0000-000000000029', 'c1000000-0000-0000-0000-000000000024', '128gb', '{"en":"128GB","ar":"128 جيجا"}', 2),
  ('d1000000-0000-0000-0000-000000000030', 'c1000000-0000-0000-0000-000000000024', '256gb', '{"en":"256GB","ar":"256 جيجا"}', 3),
  ('d1000000-0000-0000-0000-000000000031', 'c1000000-0000-0000-0000-000000000024', '512gb', '{"en":"512GB","ar":"512 جيجا"}', 4),
  ('d1000000-0000-0000-0000-000000000032', 'c1000000-0000-0000-0000-000000000025', '4gb',   '{"en":"4GB","ar":"4 جيجا"}', 1),
  ('d1000000-0000-0000-0000-000000000033', 'c1000000-0000-0000-0000-000000000025', '6gb',   '{"en":"6GB","ar":"6 جيجا"}', 2),
  ('d1000000-0000-0000-0000-000000000034', 'c1000000-0000-0000-0000-000000000025', '8gb',   '{"en":"8GB","ar":"8 جيجا"}', 3),
  ('d1000000-0000-0000-0000-000000000035', 'c1000000-0000-0000-0000-000000000025', '12gb',  '{"en":"12GB","ar":"12 جيجا"}', 4),
  ('d1000000-0000-0000-0000-000000000036', 'c1000000-0000-0000-0000-000000000027', 'new',   '{"en":"New","ar":"جديد"}', 1),
  ('d1000000-0000-0000-0000-000000000037', 'c1000000-0000-0000-0000-000000000027', 'used',  '{"en":"Used","ar":"مستعمل"}', 2),
  ('d1000000-0000-0000-0000-000000000038', 'c1000000-0000-0000-0000-000000000028', 'black', '{"en":"Black","ar":"أسود"}', 1),
  ('d1000000-0000-0000-0000-000000000039', 'c1000000-0000-0000-0000-000000000028', 'white', '{"en":"White","ar":"أبيض"}', 2),
  ('d1000000-0000-0000-0000-000000000040', 'c1000000-0000-0000-0000-000000000028', 'blue',  '{"en":"Blue","ar":"أزرق"}', 3);

insert into catalog.attribute_dependency (attribute_id, depends_on_id, rule) values
  ('c1000000-0000-0000-0000-000000000023', 'c1000000-0000-0000-0000-000000000022', 'options_filtered_by');

-- === Electronics > Laptops (light) ==========================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000006', v_tenant, 'a1000000-0000-0000-0000-000000000003', 'laptops', '{"en":"Laptops","ar":"حواسيب محمولة"}', true, 2);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000006', 'a2000000-0000-0000-0000-000000000006', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, sort_order) values
  ('c1000000-0000-0000-0000-000000000030', 'b1000000-0000-0000-0000-000000000006', 'brand', '{"en":"Brand","ar":"الماركة"}', 'option', 'dropdown', true, true, 1),
  ('c1000000-0000-0000-0000-000000000031', 'b1000000-0000-0000-0000-000000000006', 'ram',   '{"en":"RAM","ar":"الرام"}',     'number', 'stepper',  false, true, 2);
insert into catalog.attribute_option (id, attribute_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000041', 'c1000000-0000-0000-0000-000000000030', 'dell',  '{"en":"Dell","ar":"ديل"}', 1),
  ('d1000000-0000-0000-0000-000000000042', 'c1000000-0000-0000-0000-000000000030', 'hp',    '{"en":"HP","ar":"إتش بي"}', 2),
  ('d1000000-0000-0000-0000-000000000043', 'c1000000-0000-0000-0000-000000000030', 'apple', '{"en":"Apple","ar":"آبل"}', 3);

-- === Jobs > Full-Time (light) ================================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000007', v_tenant, 'a1000000-0000-0000-0000-000000000004', 'full-time', '{"en":"Full-Time","ar":"دوام كامل"}', true, 1);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000007', 'a2000000-0000-0000-0000-000000000007', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, sort_order) values
  ('c1000000-0000-0000-0000-000000000032', 'b1000000-0000-0000-0000-000000000007', 'jobTitle', '{"en":"Job Title","ar":"المسمى الوظيفي"}', 'text',   'textfield', true, false, 1),
  ('c1000000-0000-0000-0000-000000000033', 'b1000000-0000-0000-0000-000000000007', 'salary',   '{"en":"Salary","ar":"الراتب"}',            'number', 'stepper',   false, true, 2),
  ('c1000000-0000-0000-0000-000000000034', 'b1000000-0000-0000-0000-000000000007', 'experienceLevel', '{"en":"Experience Level","ar":"مستوى الخبرة"}', 'option', 'dropdown', true, true, 3);
insert into catalog.attribute_option (id, attribute_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000044', 'c1000000-0000-0000-0000-000000000034', 'entry',  '{"en":"Entry","ar":"مبتدئ"}', 1),
  ('d1000000-0000-0000-0000-000000000045', 'c1000000-0000-0000-0000-000000000034', 'mid',    '{"en":"Mid","ar":"متوسط"}', 2),
  ('d1000000-0000-0000-0000-000000000046', 'c1000000-0000-0000-0000-000000000034', 'senior', '{"en":"Senior","ar":"خبير"}', 3);

-- === Services > Home Services (light) =======================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000008', v_tenant, 'a1000000-0000-0000-0000-000000000005', 'home-services', '{"en":"Home Services","ar":"خدمات منزلية"}', true, 1);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000008', 'a2000000-0000-0000-0000-000000000008', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, sort_order) values
  ('c1000000-0000-0000-0000-000000000035', 'b1000000-0000-0000-0000-000000000008', 'serviceType', '{"en":"Service Type","ar":"نوع الخدمة"}', 'text',   'textfield', true, false, 1),
  ('c1000000-0000-0000-0000-000000000036', 'b1000000-0000-0000-0000-000000000008', 'hourlyRate',  '{"en":"Hourly Rate","ar":"السعر بالساعة"}', 'number', 'stepper',   false, true, 2);

-- === Fashion > Clothing (light) ==============================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000009', v_tenant, 'a1000000-0000-0000-0000-000000000006', 'clothing', '{"en":"Clothing","ar":"ملابس"}', true, 1);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000009', 'a2000000-0000-0000-0000-000000000009', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, sort_order) values
  ('c1000000-0000-0000-0000-000000000037', 'b1000000-0000-0000-0000-000000000009', 'size',      '{"en":"Size","ar":"المقاس"}',   'option', 'dropdown', true, true, 1),
  ('c1000000-0000-0000-0000-000000000038', 'b1000000-0000-0000-0000-000000000009', 'condition', '{"en":"Condition","ar":"الحالة"}', 'option', 'dropdown', true, true, 2);
insert into catalog.attribute_option (id, attribute_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000047', 'c1000000-0000-0000-0000-000000000037', 's',  '{"en":"S","ar":"صغير"}', 1),
  ('d1000000-0000-0000-0000-000000000048', 'c1000000-0000-0000-0000-000000000037', 'm',  '{"en":"M","ar":"متوسط"}', 2),
  ('d1000000-0000-0000-0000-000000000049', 'c1000000-0000-0000-0000-000000000037', 'l',  '{"en":"L","ar":"كبير"}', 3),
  ('d1000000-0000-0000-0000-000000000050', 'c1000000-0000-0000-0000-000000000037', 'xl', '{"en":"XL","ar":"كبير جدا"}', 4),
  ('d1000000-0000-0000-0000-000000000051', 'c1000000-0000-0000-0000-000000000038', 'new',  '{"en":"New","ar":"جديد"}', 1),
  ('d1000000-0000-0000-0000-000000000052', 'c1000000-0000-0000-0000-000000000038', 'used', '{"en":"Used","ar":"مستعمل"}', 2);

-- === Furniture > Home Furniture (light) =====================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000010', v_tenant, 'a1000000-0000-0000-0000-000000000007', 'home-furniture', '{"en":"Home Furniture","ar":"أثاث منزلي"}', true, 1);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000010', 'a2000000-0000-0000-0000-000000000010', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, sort_order) values
  ('c1000000-0000-0000-0000-000000000039', 'b1000000-0000-0000-0000-000000000010', 'material',  '{"en":"Material","ar":"الخامة"}', 'text',   'textfield', false, false, 1),
  ('c1000000-0000-0000-0000-000000000040', 'b1000000-0000-0000-0000-000000000010', 'condition', '{"en":"Condition","ar":"الحالة"}', 'option', 'dropdown', true, true, 2);
insert into catalog.attribute_option (id, attribute_id, value, label_i18n, sort_order) values
  ('d1000000-0000-0000-0000-000000000053', 'c1000000-0000-0000-0000-000000000040', 'new',  '{"en":"New","ar":"جديد"}', 1),
  ('d1000000-0000-0000-0000-000000000054', 'c1000000-0000-0000-0000-000000000040', 'used', '{"en":"Used","ar":"مستعمل"}', 2);

-- === Pets > Dogs (light) ======================================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000011', v_tenant, 'a1000000-0000-0000-0000-000000000008', 'dogs', '{"en":"Dogs","ar":"كلاب"}', true, 1);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000011', 'a2000000-0000-0000-0000-000000000011', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, sort_order) values
  ('c1000000-0000-0000-0000-000000000041', 'b1000000-0000-0000-0000-000000000011', 'breed', '{"en":"Breed","ar":"السلالة"}', 'text',   'textfield', true, false, 1),
  ('c1000000-0000-0000-0000-000000000042', 'b1000000-0000-0000-0000-000000000011', 'age',   '{"en":"Age","ar":"العمر"}',     'number', 'stepper',   false, true, 2);

-- === Business > Business For Sale (light) ===================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000012', v_tenant, 'a1000000-0000-0000-0000-000000000009', 'business-for-sale', '{"en":"Business For Sale","ar":"أعمال للبيع"}', true, 1);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000012', 'a2000000-0000-0000-0000-000000000012', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, is_filterable, sort_order) values
  ('c1000000-0000-0000-0000-000000000043', 'b1000000-0000-0000-0000-000000000012', 'industry',     '{"en":"Industry","ar":"القطاع"}',        'text',   'textfield', true, false, 1),
  ('c1000000-0000-0000-0000-000000000044', 'b1000000-0000-0000-0000-000000000012', 'askingPrice',  '{"en":"Asking Price","ar":"السعر المطلوب"}', 'number', 'stepper',   false, true, 2);

-- === Community > Events (light) ==============================================

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000013', v_tenant, 'a1000000-0000-0000-0000-000000000010', 'events', '{"en":"Events","ar":"فعاليات"}', true, 1);
insert into catalog.attribute_group (id, category_id, name_i18n, sort_order) values
  ('b1000000-0000-0000-0000-000000000013', 'a2000000-0000-0000-0000-000000000013', '{"en":"Details","ar":"التفاصيل"}', 1);
insert into catalog.attribute (id, group_id, key, label_i18n, data_type, input_type, is_required, sort_order) values
  ('c1000000-0000-0000-0000-000000000045', 'b1000000-0000-0000-0000-000000000013', 'eventDate', '{"en":"Event Date","ar":"تاريخ الفعالية"}', 'date', 'datepicker', true, 1);

-- === Other > Miscellaneous ====================================================
-- Deliberately has NO attribute group — proves the engine degrades gracefully
-- to "just title/description/price/media" when a category defines no custom
-- schema at all.

insert into catalog.category (id, tenant_id, parent_id, slug, name_i18n, is_leaf, sort_order) values
  ('a2000000-0000-0000-0000-000000000014', v_tenant, 'a1000000-0000-0000-0000-000000000011', 'miscellaneous', '{"en":"Miscellaneous","ar":"متنوع"}', true, 1);

end $$;
