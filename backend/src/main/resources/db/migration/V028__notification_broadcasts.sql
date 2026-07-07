-- Migration 028: admin/staff broadcast notifications (ML-67)
--
-- A broadcast is fanned out as one per-user notification row for each dealer.
-- Rows of the same broadcast share broadcast_id (grouping for history/delete)
-- and created_by (the admin/staff public_id who sent it). Both are nullable so
-- existing event-driven notifications are unaffected.

alter table notifications add column if not exists broadcast_id uuid;
alter table notifications add column if not exists created_by uuid;

create index if not exists notifications_broadcast_idx
  on notifications (broadcast_id);
