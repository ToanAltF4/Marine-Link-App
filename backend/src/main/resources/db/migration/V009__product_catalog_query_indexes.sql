-- Migration 009: Product catalog query indexes for Product List filtering/sorting

create index if not exists products_status_base_price_idx
  on products (status, base_price);
