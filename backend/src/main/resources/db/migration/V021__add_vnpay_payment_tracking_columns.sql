-- Migration V021: Add merchant transaction tracking fields for VNPAY callbacks

alter table payments add column if not exists txn_ref text;
alter table payments add column if not exists response_code text;
alter table payments add column if not exists paid_at timestamptz;

update payments
set txn_ref = replace(public_id::text, '-', '')
where txn_ref is null;

alter table payments alter column txn_ref set not null;

create unique index if not exists payments_txn_ref_idx on payments (txn_ref);
create index if not exists payments_order_idx on payments (order_id, created_at desc);
