-- Migration 010: Seed real dried seafood catalog with Supabase Storage images

with category_seed(public_id, name, slug, description, image_url, display_order, is_active) as (
  values
    ('550e8400-e29b-41d4-a716-446655450101'::uuid, 'Mực khô', 'muc-kho', 'Mực khô và mực một nắng cho đại lý, nhà hàng.', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-kho-loai-1.png', 1, true),
    ('550e8400-e29b-41d4-a716-446655450102'::uuid, 'Tôm khô', 'tom-kho', 'Tôm khô nhiều size, đóng gói phục vụ đơn sỉ.', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/tom-kho-size-lon.png', 2, true),
    ('550e8400-e29b-41d4-a716-446655450103'::uuid, 'Cá khô', 'ca-kho', 'Các dòng cá khô phổ biến cho kênh bán lẻ và nhà hàng.', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/ca-chi-vang-kho-loai-1.png', 3, true),
    ('550e8400-e29b-41d4-a716-446655450104'::uuid, 'Hải sản khô cao cấp', 'hai-san-kho-cao-cap', 'Hải sản khô giá trị cao như hải sâm, hải mã, bạch tuộc.', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/hai-sam-kho.png', 4, true),
    ('550e8400-e29b-41d4-a716-446655450105'::uuid, 'Nước mắm', 'nuoc-mam', 'Nước mắm truyền thống phục vụ đại lý và cửa hàng đặc sản.', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/nuoc-mam-truyen-thong.png', 5, true)
)
insert into categories (public_id, name, slug, description, image_url, display_order, is_active)
select public_id, name, slug, description, image_url, display_order, is_active
from category_seed
on conflict (slug) do update
set
  name = excluded.name,
  description = excluded.description,
  image_url = excluded.image_url,
  display_order = excluded.display_order,
  is_active = excluded.is_active,
  updated_at = now();

with product_seed(
  public_id,
  category_slug,
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
) as (
  values
    ('550e8400-e29b-41d4-a716-446655450201'::uuid, 'muc-kho', 'Mực khô loại 1', 'muc-kho-loai-1', 'Mực khô loại 1, thân dày, vị ngọt tự nhiên, phù hợp đơn sỉ nhà hàng và đại lý.', 'Cà Mau', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-kho-loai-1.png', 450000, 'kg', 2, 120, 'ACTIVE', true),
    ('550e8400-e29b-41d4-a716-446655450202'::uuid, 'hai-san-kho-cao-cap', 'Hải mã khô', 'hai-ma-kho', 'Hải mã khô chọn lọc, đóng gói kiểm soát ẩm cho kênh đặc sản cao cấp.', 'Phú Quốc', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/hai-ma-kho.png', 1500000, 'kg', 1, 25, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450203'::uuid, 'ca-kho', 'Khô cá đuối', 'kho-ca-duoi', 'Khô cá đuối phơi chuẩn, vị đậm, phù hợp chế biến món nướng và gỏi.', 'Vũng Tàu', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-duoi.png', 260000, 'kg', 3, 90, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450204'::uuid, 'muc-kho', 'Mực một nắng loại 1', 'muc-mot-nang-loai-1', 'Mực một nắng loại 1, cấp đông nhanh sau phơi, giữ độ ngọt và độ dai.', 'Phan Thiết', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-mot-nang-loai-1.png', 380000, 'kg', 2, 95, 'ACTIVE', true),
    ('550e8400-e29b-41d4-a716-446655450205'::uuid, 'ca-kho', 'Khô cá sặc', 'kho-ca-sac', 'Khô cá sặc miền Tây, phơi vừa, thích hợp bán lẻ và bếp nhà hàng.', 'Cần Thơ', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-sac.png', 280000, 'kg', 3, 110, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450206'::uuid, 'ca-kho', 'Khô cá nhụ', 'kho-ca-nhu', 'Khô cá nhụ thịt chắc, đóng gói theo kg, phù hợp đơn sỉ tỉnh.', 'Nha Trang', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-nhu.png', 320000, 'kg', 3, 75, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450207'::uuid, 'hai-san-kho-cao-cap', 'Bạch tuộc khô', 'bach-tuoc-kho', 'Bạch tuộc khô size đều, dùng cho món nướng và combo đặc sản.', 'Kiên Giang', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/bach-tuoc-kho.png', 420000, 'kg', 2, 55, 'ACTIVE', true),
    ('550e8400-e29b-41d4-a716-446655450208'::uuid, 'muc-kho', 'Mực khô đại', 'muc-kho-dai', 'Mực khô size đại, thân lớn, phù hợp quà tặng và nhà hàng hải sản.', 'Cà Mau', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-kho-dai.png', 520000, 'kg', 2, 70, 'ACTIVE', true),
    ('550e8400-e29b-41d4-a716-446655450209'::uuid, 'ca-kho', 'Khô cá lóc', 'kho-ca-loc', 'Khô cá lóc đồng, ít xương dăm, phù hợp đại lý đặc sản miền Tây.', 'Đồng Tháp', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-loc.png', 300000, 'kg', 3, 100, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450210'::uuid, 'muc-kho', 'Mực một nắng', 'muc-mot-nang', 'Mực một nắng tiêu chuẩn, nguồn hàng ổn định cho kênh nhà hàng.', 'Phan Thiết', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-mot-nang.png', 350000, 'kg', 2, 130, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450211'::uuid, 'muc-kho', 'Mực khô xé sợi', 'muc-kho-xe-soi', 'Mực khô xé sợi tiện dùng, đóng gói cho cửa hàng và kênh bán lẻ.', 'Khánh Hòa', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-kho-xe-soi.png', 390000, 'kg', 2, 85, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450212'::uuid, 'ca-kho', 'Cá mối khô', 'ca-moi-kho', 'Cá mối khô làm sạch, vị nhẹ, dễ bán theo combo đặc sản.', 'Bình Thuận', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/ca-moi-kho.png', 210000, 'kg', 5, 160, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450213'::uuid, 'tom-kho', 'Tôm khô size vừa', 'tom-kho-size-vua', 'Tôm khô size vừa, màu tự nhiên, phù hợp bán lẻ và chế biến.', 'Bạc Liêu', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/tom-kho-size-vua.png', 560000, 'kg', 1, 100, 'ACTIVE', true),
    ('550e8400-e29b-41d4-a716-446655450214'::uuid, 'ca-kho', 'Cá chỉ vàng khô', 'ca-chi-vang-kho', 'Cá chỉ vàng khô phổ thông, hàng đều, hợp đơn sỉ đại lý.', 'Nha Trang', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/ca-chi-vang-kho.png', 220000, 'kg', 5, 180, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450215'::uuid, 'nuoc-mam', 'Nước mắm truyền thống', 'nuoc-mam-truyen-thong', 'Nước mắm truyền thống chai 500ml, thích hợp bán kèm combo hải sản khô.', 'Phú Quốc', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/nuoc-mam-truyen-thong.png', 125000, 'chai', 12, 240, 'ACTIVE', true),
    ('550e8400-e29b-41d4-a716-446655450216'::uuid, 'ca-kho', 'Cá chỉ vàng khô loại 1', 'ca-chi-vang-kho-loai-1', 'Cá chỉ vàng khô loại 1, size đẹp, phù hợp nhà hàng và cửa hàng đặc sản.', 'Nha Trang', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/ca-chi-vang-kho-loai-1.png', 260000, 'kg', 5, 140, 'ACTIVE', true),
    ('550e8400-e29b-41d4-a716-446655450217'::uuid, 'tom-kho', 'Tôm khô size lớn', 'tom-kho-size-lon', 'Tôm khô size lớn Bạc Liêu, màu đỏ tự nhiên, thịt chắc, phù hợp đơn sỉ.', 'Bạc Liêu', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/tom-kho-size-lon.png', 680000, 'kg', 1, 80, 'ACTIVE', true),
    ('550e8400-e29b-41d4-a716-446655450218'::uuid, 'ca-kho', 'Khô cá mập', 'kho-ca-map', 'Khô cá mập chọn lọc, dòng đặc sản ít phổ biến cho đơn đặt trước.', 'Quảng Ngãi', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-map.png', 350000, 'kg', 2, 40, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450219'::uuid, 'hai-san-kho-cao-cap', 'Hải sâm khô', 'hai-sam-kho', 'Hải sâm khô cao cấp, đóng gói kỹ, phục vụ nhà hàng và đại lý đặc sản.', 'Khánh Hòa', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/hai-sam-kho.png', 1200000, 'kg', 1, 30, 'ACTIVE', true),
    ('550e8400-e29b-41d4-a716-446655450220'::uuid, 'ca-kho', 'Cá cơm khô', 'ca-com-kho', 'Cá cơm khô nhỏ, sạch, phù hợp chế biến kho rim và bán theo combo.', 'Phan Rang', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/ca-com-kho.png', 180000, 'kg', 5, 220, 'ACTIVE', false),
    ('550e8400-e29b-41d4-a716-446655450221'::uuid, 'ca-kho', 'Khô cá đù', 'kho-ca-du', 'Khô cá đù phơi vừa, thịt thơm, phù hợp đơn sỉ cửa hàng đặc sản.', 'Bến Tre', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-du.png', 240000, 'kg', 3, 115, 'ACTIVE', false)
)
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
  ps.public_id,
  c.id,
  ps.name,
  ps.slug,
  ps.description,
  ps.origin,
  ps.image_url,
  ps.base_price,
  ps.unit,
  ps.min_order_quantity,
  ps.stock_quantity,
  ps.status::product_status,
  ps.is_featured
from product_seed ps
join categories c on c.slug = ps.category_slug
on conflict (slug) do update
set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  origin = excluded.origin,
  image_url = excluded.image_url,
  base_price = excluded.base_price,
  unit = excluded.unit,
  min_order_quantity = excluded.min_order_quantity,
  stock_quantity = excluded.stock_quantity,
  status = excluded.status,
  is_featured = excluded.is_featured,
  deleted_at = null,
  updated_at = now();

delete from price_tiers
where public_id in (
  '550e8400-e29b-41d4-a716-446655440121'::uuid,
  '550e8400-e29b-41d4-a716-446655440122'::uuid,
  '550e8400-e29b-41d4-a716-446655440123'::uuid,
  '550e8400-e29b-41d4-a716-446655440124'::uuid
);

with tier_seed(public_id, product_slug, min_quantity, max_quantity, unit_price) as (
  values
    ('550e8400-e29b-41d4-a716-446655450301'::uuid, 'muc-kho-loai-1', 2, 9, 450000),
    ('550e8400-e29b-41d4-a716-446655450302'::uuid, 'muc-kho-loai-1', 10, null, 420000),
    ('550e8400-e29b-41d4-a716-446655450303'::uuid, 'hai-ma-kho', 1, 2, 1500000),
    ('550e8400-e29b-41d4-a716-446655450304'::uuid, 'hai-ma-kho', 3, null, 1420000),
    ('550e8400-e29b-41d4-a716-446655450305'::uuid, 'kho-ca-duoi', 3, 9, 260000),
    ('550e8400-e29b-41d4-a716-446655450306'::uuid, 'kho-ca-duoi', 10, null, 245000),
    ('550e8400-e29b-41d4-a716-446655450307'::uuid, 'muc-mot-nang-loai-1', 2, 9, 380000),
    ('550e8400-e29b-41d4-a716-446655450308'::uuid, 'muc-mot-nang-loai-1', 10, null, 355000),
    ('550e8400-e29b-41d4-a716-446655450309'::uuid, 'kho-ca-sac', 3, 9, 280000),
    ('550e8400-e29b-41d4-a716-446655450310'::uuid, 'kho-ca-sac', 10, null, 260000),
    ('550e8400-e29b-41d4-a716-446655450311'::uuid, 'kho-ca-nhu', 3, 9, 320000),
    ('550e8400-e29b-41d4-a716-446655450312'::uuid, 'kho-ca-nhu', 10, null, 300000),
    ('550e8400-e29b-41d4-a716-446655450313'::uuid, 'bach-tuoc-kho', 2, 5, 420000),
    ('550e8400-e29b-41d4-a716-446655450314'::uuid, 'bach-tuoc-kho', 6, null, 395000),
    ('550e8400-e29b-41d4-a716-446655450315'::uuid, 'muc-kho-dai', 2, 9, 520000),
    ('550e8400-e29b-41d4-a716-446655450316'::uuid, 'muc-kho-dai', 10, null, 490000),
    ('550e8400-e29b-41d4-a716-446655450317'::uuid, 'kho-ca-loc', 3, 9, 300000),
    ('550e8400-e29b-41d4-a716-446655450318'::uuid, 'kho-ca-loc', 10, null, 280000),
    ('550e8400-e29b-41d4-a716-446655450319'::uuid, 'muc-mot-nang', 2, 9, 350000),
    ('550e8400-e29b-41d4-a716-446655450320'::uuid, 'muc-mot-nang', 10, null, 328000),
    ('550e8400-e29b-41d4-a716-446655450321'::uuid, 'muc-kho-xe-soi', 2, 9, 390000),
    ('550e8400-e29b-41d4-a716-446655450322'::uuid, 'muc-kho-xe-soi', 10, null, 365000),
    ('550e8400-e29b-41d4-a716-446655450323'::uuid, 'ca-moi-kho', 5, 19, 210000),
    ('550e8400-e29b-41d4-a716-446655450324'::uuid, 'ca-moi-kho', 20, null, 195000),
    ('550e8400-e29b-41d4-a716-446655450325'::uuid, 'tom-kho-size-vua', 1, 4, 560000),
    ('550e8400-e29b-41d4-a716-446655450326'::uuid, 'tom-kho-size-vua', 5, null, 530000),
    ('550e8400-e29b-41d4-a716-446655450327'::uuid, 'ca-chi-vang-kho', 5, 19, 220000),
    ('550e8400-e29b-41d4-a716-446655450328'::uuid, 'ca-chi-vang-kho', 20, null, 205000),
    ('550e8400-e29b-41d4-a716-446655450329'::uuid, 'nuoc-mam-truyen-thong', 12, 59, 125000),
    ('550e8400-e29b-41d4-a716-446655450330'::uuid, 'nuoc-mam-truyen-thong', 60, null, 116000),
    ('550e8400-e29b-41d4-a716-446655450331'::uuid, 'ca-chi-vang-kho-loai-1', 5, 19, 260000),
    ('550e8400-e29b-41d4-a716-446655450332'::uuid, 'ca-chi-vang-kho-loai-1', 20, null, 242000),
    ('550e8400-e29b-41d4-a716-446655450333'::uuid, 'tom-kho-size-lon', 1, 4, 680000),
    ('550e8400-e29b-41d4-a716-446655450334'::uuid, 'tom-kho-size-lon', 5, null, 650000),
    ('550e8400-e29b-41d4-a716-446655450335'::uuid, 'kho-ca-map', 2, 5, 350000),
    ('550e8400-e29b-41d4-a716-446655450336'::uuid, 'kho-ca-map', 6, null, 328000),
    ('550e8400-e29b-41d4-a716-446655450337'::uuid, 'hai-sam-kho', 1, 2, 1200000),
    ('550e8400-e29b-41d4-a716-446655450338'::uuid, 'hai-sam-kho', 3, null, 1120000),
    ('550e8400-e29b-41d4-a716-446655450339'::uuid, 'ca-com-kho', 5, 19, 180000),
    ('550e8400-e29b-41d4-a716-446655450340'::uuid, 'ca-com-kho', 20, null, 168000),
    ('550e8400-e29b-41d4-a716-446655450341'::uuid, 'kho-ca-du', 3, 9, 240000),
    ('550e8400-e29b-41d4-a716-446655450342'::uuid, 'kho-ca-du', 10, null, 225000)
)
insert into price_tiers (public_id, product_id, min_quantity, max_quantity, unit_price)
select ts.public_id, p.id, ts.min_quantity, ts.max_quantity, ts.unit_price
from tier_seed ts
join products p on p.slug = ts.product_slug
on conflict (public_id) do update
set
  product_id = excluded.product_id,
  min_quantity = excluded.min_quantity,
  max_quantity = excluded.max_quantity,
  unit_price = excluded.unit_price,
  updated_at = now();

delete from product_images pi
using products p
where pi.product_id = p.id
  and p.slug in (
    'muc-kho-loai-1',
    'hai-ma-kho',
    'kho-ca-duoi',
    'muc-mot-nang-loai-1',
    'kho-ca-sac',
    'kho-ca-nhu',
    'bach-tuoc-kho',
    'muc-kho-dai',
    'kho-ca-loc',
    'muc-mot-nang',
    'muc-kho-xe-soi',
    'ca-moi-kho',
    'tom-kho-size-vua',
    'ca-chi-vang-kho',
    'nuoc-mam-truyen-thong',
    'ca-chi-vang-kho-loai-1',
    'tom-kho-size-lon',
    'kho-ca-map',
    'hai-sam-kho',
    'ca-com-kho',
    'kho-ca-du'
  )
  and (
    pi.public_id in (
      '550e8400-e29b-41d4-a716-446655440131'::uuid,
      '550e8400-e29b-41d4-a716-446655440132'::uuid,
      '550e8400-e29b-41d4-a716-446655440133'::uuid
    )
    or pi.image_url like 'https://images.unsplash.com/%'
  );

with image_seed(public_id, product_slug, image_url, alt_text, display_order) as (
  values
    ('550e8400-e29b-41d4-a716-446655450401'::uuid, 'muc-kho-loai-1', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-kho-loai-1.png', 'Mực khô loại 1', 0),
    ('550e8400-e29b-41d4-a716-446655450402'::uuid, 'hai-ma-kho', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/hai-ma-kho.png', 'Hải mã khô', 0),
    ('550e8400-e29b-41d4-a716-446655450403'::uuid, 'kho-ca-duoi', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-duoi.png', 'Khô cá đuối', 0),
    ('550e8400-e29b-41d4-a716-446655450404'::uuid, 'muc-mot-nang-loai-1', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-mot-nang-loai-1.png', 'Mực một nắng loại 1', 0),
    ('550e8400-e29b-41d4-a716-446655450405'::uuid, 'kho-ca-sac', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-sac.png', 'Khô cá sặc', 0),
    ('550e8400-e29b-41d4-a716-446655450406'::uuid, 'kho-ca-nhu', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-nhu.png', 'Khô cá nhụ', 0),
    ('550e8400-e29b-41d4-a716-446655450407'::uuid, 'bach-tuoc-kho', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/bach-tuoc-kho.png', 'Bạch tuộc khô', 0),
    ('550e8400-e29b-41d4-a716-446655450408'::uuid, 'muc-kho-dai', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-kho-dai.png', 'Mực khô đại', 0),
    ('550e8400-e29b-41d4-a716-446655450409'::uuid, 'kho-ca-loc', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-loc.png', 'Khô cá lóc', 0),
    ('550e8400-e29b-41d4-a716-446655450410'::uuid, 'muc-mot-nang', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-mot-nang.png', 'Mực một nắng', 0),
    ('550e8400-e29b-41d4-a716-446655450411'::uuid, 'muc-kho-xe-soi', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/muc-kho-xe-soi.png', 'Mực khô xé sợi', 0),
    ('550e8400-e29b-41d4-a716-446655450412'::uuid, 'ca-moi-kho', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/ca-moi-kho.png', 'Cá mối khô', 0),
    ('550e8400-e29b-41d4-a716-446655450413'::uuid, 'tom-kho-size-vua', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/tom-kho-size-vua.png', 'Tôm khô size vừa', 0),
    ('550e8400-e29b-41d4-a716-446655450414'::uuid, 'ca-chi-vang-kho', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/ca-chi-vang-kho.png', 'Cá chỉ vàng khô', 0),
    ('550e8400-e29b-41d4-a716-446655450415'::uuid, 'nuoc-mam-truyen-thong', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/nuoc-mam-truyen-thong.png', 'Nước mắm truyền thống', 0),
    ('550e8400-e29b-41d4-a716-446655450416'::uuid, 'ca-chi-vang-kho-loai-1', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/ca-chi-vang-kho-loai-1.png', 'Cá chỉ vàng khô loại 1', 0),
    ('550e8400-e29b-41d4-a716-446655450417'::uuid, 'tom-kho-size-lon', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/tom-kho-size-lon.png', 'Tôm khô size lớn', 0),
    ('550e8400-e29b-41d4-a716-446655450418'::uuid, 'kho-ca-map', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-map.png', 'Khô cá mập', 0),
    ('550e8400-e29b-41d4-a716-446655450419'::uuid, 'hai-sam-kho', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/hai-sam-kho.png', 'Hải sâm khô', 0),
    ('550e8400-e29b-41d4-a716-446655450420'::uuid, 'ca-com-kho', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/ca-com-kho.png', 'Cá cơm khô', 0),
    ('550e8400-e29b-41d4-a716-446655450421'::uuid, 'kho-ca-du', 'https://kpmxyzvlnvjdiaiutnhe.supabase.co/storage/v1/object/public/product-images/products/dried-seafood/kho-ca-du.png', 'Khô cá đù', 0)
)
insert into product_images (public_id, product_id, image_url, alt_text, display_order)
select iseed.public_id, p.id, iseed.image_url, iseed.alt_text, iseed.display_order
from image_seed iseed
join products p on p.slug = iseed.product_slug
on conflict (public_id) do update
set
  product_id = excluded.product_id,
  image_url = excluded.image_url,
  alt_text = excluded.alt_text,
  display_order = excluded.display_order;
