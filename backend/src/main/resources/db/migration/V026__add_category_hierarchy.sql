-- Migration 026: Add parent-child support for catalog categories

alter table categories
  add column parent_id bigint references categories(id);

alter table categories
  add constraint categories_parent_not_self
  check (parent_id is null or parent_id <> id);

create index categories_parent_order_idx
  on categories (parent_id, display_order, name);
