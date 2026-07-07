-- Migration 027: Organize flat demo catalog categories into parent groups

with root_seed(public_id, name, slug, description, display_order, is_active) as (
  values
    ('550e8400-e29b-41d4-a716-446655460101'::uuid, 'Cá', 'ca', 'Nhóm sản phẩm cá theo trạng thái bảo quản và chế biến.', 1, true),
    ('550e8400-e29b-41d4-a716-446655460102'::uuid, 'Tôm', 'tom', 'Nhóm sản phẩm tôm khô, đông lạnh và chế biến.', 2, true),
    ('550e8400-e29b-41d4-a716-446655460103'::uuid, 'Mực', 'muc', 'Nhóm sản phẩm mực khô, một nắng và đông lạnh.', 3, true),
    ('550e8400-e29b-41d4-a716-446655460104'::uuid, 'Hải sản', 'hai-san', 'Nhóm hải sản khô và đặc sản giá trị cao.', 4, true),
    ('550e8400-e29b-41d4-a716-446655460105'::uuid, 'Gia vị', 'gia-vi', 'Nước chấm và gia vị dùng kèm hải sản.', 5, true)
)
insert into categories (public_id, name, slug, description, display_order, is_active)
select public_id, name, slug, description, display_order, is_active
from root_seed
on conflict (slug) do update
set
  name = excluded.name,
  description = excluded.description,
  display_order = excluded.display_order,
  is_active = excluded.is_active,
  parent_id = null,
  updated_at = now();

with child_seed(public_id, name, slug, description, parent_slug, display_order, is_active) as (
  values
    ('550e8400-e29b-41d4-a716-446655450103'::uuid, 'Cá khô', 'ca-kho', 'Các dòng cá khô phổ biến cho kênh bán lẻ và nhà hàng.', 'ca', 1, true),
    ('550e8400-e29b-41d4-a716-446655440103'::uuid, 'Cá đông lạnh', 'ca-dong-lanh', 'Cá đông lạnh cho kênh nhà hàng và đại lý.', 'ca', 2, true),
    ('550e8400-e29b-41d4-a716-446655450102'::uuid, 'Tôm khô', 'tom-kho', 'Tôm khô nhiều size, đóng gói phục vụ đơn sỉ.', 'tom', 1, true),
    ('550e8400-e29b-41d4-a716-446655460202'::uuid, 'Tôm đông lạnh', 'tom-dong-lanh', 'Tôm đông lạnh cho đơn sỉ nhà hàng và đại lý.', 'tom', 2, true),
    ('550e8400-e29b-41d4-a716-446655450101'::uuid, 'Mực khô', 'muc-kho', 'Mực khô và mực một nắng cho đại lý, nhà hàng.', 'muc', 1, true),
    ('550e8400-e29b-41d4-a716-446655460203'::uuid, 'Mực đông lạnh', 'muc-dong-lanh', 'Mực đông lạnh và sơ chế cho đơn sỉ.', 'muc', 2, true),
    ('550e8400-e29b-41d4-a716-446655450104'::uuid, 'Hải sản khô cao cấp', 'hai-san-kho-cao-cap', 'Hải sản khô giá trị cao như hải sâm, hải mã, bạch tuộc.', 'hai-san', 1, true),
    ('550e8400-e29b-41d4-a716-446655450105'::uuid, 'Nước mắm', 'nuoc-mam', 'Nước mắm truyền thống phục vụ đại lý và cửa hàng đặc sản.', 'gia-vi', 1, true)
)
insert into categories (public_id, name, slug, description, parent_id, display_order, is_active)
select
  child.public_id,
  child.name,
  child.slug,
  child.description,
  parent.id,
  child.display_order,
  child.is_active
from child_seed child
join categories parent on parent.slug = child.parent_slug
on conflict (slug) do update
set
  name = excluded.name,
  description = excluded.description,
  parent_id = excluded.parent_id,
  display_order = excluded.display_order,
  is_active = excluded.is_active,
  image_url = coalesce(categories.image_url, excluded.image_url),
  updated_at = now();
