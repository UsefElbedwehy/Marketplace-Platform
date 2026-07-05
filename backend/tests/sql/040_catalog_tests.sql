-- catalog.*: public read (guest-first), cross-tenant isolation, editor-only
-- write, dependent-option composition (Model options_filtered_by Brand).

select test.act_as_anon();
select test.assert_count(
  'catalog: anon can read the seeded Cars category',
  1,
  (select count(*) from catalog.category where slug = 'cars')
);
select test.assert_count(
  'catalog: anon can read Cars'' attributes',
  10,
  (select count(*) from catalog.attribute a join catalog.attribute_group g on g.id = a.group_id where g.category_id = 'a2000000-0000-0000-0000-000000000001')
);
select test.assert_count(
  'catalog: dependent Model options are filtered by the selected Brand (BMW -> only X5)',
  1,
  (select count(*) from catalog.attribute_option where attribute_id = 'c1000000-0000-0000-0000-000000000002' and parent_option_id = 'd1000000-0000-0000-0000-000000000001')
);

select test.act_as('f0000001-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', 'buyer');
select test.assert_count(
  'catalog: client_a tenant cannot see default tenant''s Cars category',
  0,
  (select count(*) from catalog.category where slug = 'cars')
);

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');
select test.assert_raises(
  'catalog: plain buyer cannot create a category',
  $sql$ insert into catalog.category (tenant_id, parent_id, slug, name_i18n) values ('00000000-0000-0000-0000-000000000001', null, 'hack', '{"en":"Hack"}') $sql$
);

select test.act_as('f0000001-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'catalog_editor');
select test.assert_succeeds(
  'catalog: catalog_editor CAN create a category in their own tenant',
  $sql$ insert into catalog.category (tenant_id, parent_id, slug, name_i18n) values ('00000000-0000-0000-0000-000000000001', null, 'test-only-category', '{"en":"Test Only"}') $sql$
);

select test.act_as_service();
delete from catalog.category where slug = 'test-only-category';
