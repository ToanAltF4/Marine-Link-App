-- Migration 029: cart_items.price_tier_id -> ON DELETE SET NULL
--
-- V004 tạo khoá ngoại cart_items.price_tier_id -> price_tiers(id) mà không có
-- ON DELETE. Khi admin sửa sản phẩm và bỏ bớt một mức giá sỉ đang được giỏ hàng
-- của khách tham chiếu, việc xoá dòng price_tiers sẽ vi phạm khoá ngoại (500).
-- Đổi sang ON DELETE SET NULL: giỏ hàng chỉ mất tham chiếu mức giá (rơi về giá
-- gốc) thay vì làm hỏng thao tác cập nhật sản phẩm.
--
-- Tên constraint do Postgres tự sinh nên có thể khác nhau giữa các môi trường:
-- xoá theo tên quy ước trước, sau đó quét pg_constraint để bắt mọi tên khác.

alter table cart_items drop constraint if exists cart_items_price_tier_id_fkey;

do $$
declare
  existing_constraint text;
begin
  for existing_constraint in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_class frel on frel.oid = con.confrelid
    where con.contype = 'f'
      and rel.relname = 'cart_items'
      and frel.relname = 'price_tiers'
  loop
    execute format('alter table cart_items drop constraint %I', existing_constraint);
  end loop;
end $$;

alter table cart_items
  add constraint cart_items_price_tier_id_fkey
  foreign key (price_tier_id) references price_tiers (id) on delete set null;
