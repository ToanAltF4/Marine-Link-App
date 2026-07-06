-- Migration V023: Add optional product short descriptions for list cards.
alter table products
  add column if not exists short_description text;
