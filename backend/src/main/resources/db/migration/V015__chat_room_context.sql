-- Migration 015: Optional order/product context for staff chat rooms

alter table chat_rooms
  add column related_order_id bigint references orders(id) on delete set null,
  add column related_product_id bigint references products(id) on delete set null;

create index chat_rooms_related_order_idx
  on chat_rooms (related_order_id);

create index chat_rooms_related_product_idx
  on chat_rooms (related_product_id);
