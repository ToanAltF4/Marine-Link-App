-- Migration 008: Seed demo catalog for product browsing P0

insert into categories (public_id, name, slug, description, image_url, display_order, is_active)
select
  '550e8400-e29b-41d4-a716-446655440101'::uuid,
  'Muc kho',
  'muc-kho',
  'Muc kho chat luong cho dai ly va nha hang',
  null,
  1,
  true
where not exists (select 1 from categories where slug = 'muc-kho');

insert into categories (public_id, name, slug, description, image_url, display_order, is_active)
select
  '550e8400-e29b-41d4-a716-446655440102'::uuid,
  'Tom kho',
  'tom-kho',
  'Tom kho size lon phuc vu don si',
  null,
  2,
  true
where not exists (select 1 from categories where slug = 'tom-kho');

insert into categories (public_id, name, slug, description, image_url, display_order, is_active)
select
  '550e8400-e29b-41d4-a716-446655440103'::uuid,
  'Ca dong lanh',
  'ca-dong-lanh',
  'Ca dong lanh cho kenh nha hang va dai ly',
  null,
  3,
  true
where not exists (select 1 from categories where slug = 'ca-dong-lanh');

insert into products (
  public_id,
  category_id,
  name,
  slug,
  description,
  origin,
  image_url,
  base_price,
  unit,
  min_order_quantity,
  stock_quantity,
  status,
  is_featured
)
select
  '550e8400-e29b-41d4-a716-446655440111'::uuid,
  c.id,
  'Muc kho loai 1',
  'muc-kho-loai-1',
  'Muc kho loai 1 tu Ca Mau, phu hop don si nha hang.',
  'Ca Mau',
  'https://images.unsplash.com/photo-1510130387422-82bed34b37e9?auto=format&fit=crop&w=1200&q=80',
  450000,
  'kg',
  2,
  120,
  'ACTIVE',
  true
from categories c
where c.slug = 'muc-kho'
  and not exists (select 1 from products where slug = 'muc-kho-loai-1');

insert into products (
  public_id,
  category_id,
  name,
  slug,
  description,
  origin,
  image_url,
  base_price,
  unit,
  min_order_quantity,
  stock_quantity,
  status,
  is_featured
)
select
  '550e8400-e29b-41d4-a716-446655440112'::uuid,
  c.id,
  'Tom kho size lon',
  'tom-kho-size-lon',
  'Tom kho size lon Bac Lieu, mau do tu nhien, thit chac.',
  'Bac Lieu',
  'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?auto=format&fit=crop&w=1200&q=80',
  680000,
  'kg',
  1,
  80,
  'ACTIVE',
  true
from categories c
where c.slug = 'tom-kho'
  and not exists (select 1 from products where slug = 'tom-kho-size-lon');

insert into products (
  public_id,
  category_id,
  name,
  slug,
  description,
  origin,
  image_url,
  base_price,
  unit,
  min_order_quantity,
  stock_quantity,
  status,
  is_featured
)
select
  '550e8400-e29b-41d4-a716-446655440113'::uuid,
  c.id,
  'Ca basa phi le',
  'ca-basa-phi-le',
  'Ca basa phi le dong lanh, de bao quan va van chuyen.',
  'An Giang',
  'https://images.unsplash.com/photo-1544943910-4c1dc44aab44?auto=format&fit=crop&w=1200&q=80',
  95000,
  'kg',
  10,
  500,
  'ACTIVE',
  true
from categories c
where c.slug = 'ca-dong-lanh'
  and not exists (select 1 from products where slug = 'ca-basa-phi-le');

insert into products (
  public_id,
  category_id,
  name,
  slug,
  description,
  origin,
  image_url,
  base_price,
  unit,
  min_order_quantity,
  stock_quantity,
  status,
  is_featured
)
select
  '550e8400-e29b-41d4-a716-446655440114'::uuid,
  c.id,
  'Ghe dong lanh',
  'ghe-dong-lanh',
  'Ghe dong lanh dong block, phu hop don nha hang.',
  'Phu Quoc',
  'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?auto=format&fit=crop&w=1200&q=80',
  250000,
  'kg',
  5,
  0,
  'OUT_OF_STOCK',
  false
from categories c
where c.slug = 'ca-dong-lanh'
  and not exists (select 1 from products where slug = 'ghe-dong-lanh');

insert into price_tiers (public_id, product_id, min_quantity, max_quantity, unit_price)
select
  '550e8400-e29b-41d4-a716-446655440121'::uuid,
  p.id,
  2,
  9,
  450000
from products p
where p.slug = 'muc-kho-loai-1'
  and not exists (select 1 from price_tiers where public_id = '550e8400-e29b-41d4-a716-446655440121'::uuid);

insert into price_tiers (public_id, product_id, min_quantity, max_quantity, unit_price)
select
  '550e8400-e29b-41d4-a716-446655440122'::uuid,
  p.id,
  10,
  null,
  420000
from products p
where p.slug = 'muc-kho-loai-1'
  and not exists (select 1 from price_tiers where public_id = '550e8400-e29b-41d4-a716-446655440122'::uuid);

insert into price_tiers (public_id, product_id, min_quantity, max_quantity, unit_price)
select
  '550e8400-e29b-41d4-a716-446655440123'::uuid,
  p.id,
  1,
  4,
  680000
from products p
where p.slug = 'tom-kho-size-lon'
  and not exists (select 1 from price_tiers where public_id = '550e8400-e29b-41d4-a716-446655440123'::uuid);

insert into price_tiers (public_id, product_id, min_quantity, max_quantity, unit_price)
select
  '550e8400-e29b-41d4-a716-446655440124'::uuid,
  p.id,
  5,
  null,
  650000
from products p
where p.slug = 'tom-kho-size-lon'
  and not exists (select 1 from price_tiers where public_id = '550e8400-e29b-41d4-a716-446655440124'::uuid);

insert into price_tiers (public_id, product_id, min_quantity, max_quantity, unit_price)
select
  '550e8400-e29b-41d4-a716-446655440125'::uuid,
  p.id,
  10,
  49,
  95000
from products p
where p.slug = 'ca-basa-phi-le'
  and not exists (select 1 from price_tiers where public_id = '550e8400-e29b-41d4-a716-446655440125'::uuid);

insert into price_tiers (public_id, product_id, min_quantity, max_quantity, unit_price)
select
  '550e8400-e29b-41d4-a716-446655440126'::uuid,
  p.id,
  50,
  null,
  88000
from products p
where p.slug = 'ca-basa-phi-le'
  and not exists (select 1 from price_tiers where public_id = '550e8400-e29b-41d4-a716-446655440126'::uuid);

insert into product_images (public_id, product_id, image_url, alt_text, display_order)
select
  '550e8400-e29b-41d4-a716-446655440131'::uuid,
  p.id,
  'https://images.unsplash.com/photo-1510130387422-82bed34b37e9?auto=format&fit=crop&w=1200&q=80',
  'Muc kho loai 1',
  0
from products p
where p.slug = 'muc-kho-loai-1'
  and not exists (select 1 from product_images where public_id = '550e8400-e29b-41d4-a716-446655440131'::uuid);

insert into product_images (public_id, product_id, image_url, alt_text, display_order)
select
  '550e8400-e29b-41d4-a716-446655440132'::uuid,
  p.id,
  'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?auto=format&fit=crop&w=1200&q=80',
  'Tom kho size lon',
  0
from products p
where p.slug = 'tom-kho-size-lon'
  and not exists (select 1 from product_images where public_id = '550e8400-e29b-41d4-a716-446655440132'::uuid);

insert into product_images (public_id, product_id, image_url, alt_text, display_order)
select
  '550e8400-e29b-41d4-a716-446655440133'::uuid,
  p.id,
  'https://images.unsplash.com/photo-1544943910-4c1dc44aab44?auto=format&fit=crop&w=1200&q=80',
  'Ca basa phi le',
  0
from products p
where p.slug = 'ca-basa-phi-le'
  and not exists (select 1 from product_images where public_id = '550e8400-e29b-41d4-a716-446655440133'::uuid);
