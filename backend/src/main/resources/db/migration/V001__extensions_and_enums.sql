-- Migration 001: Extensions and Enum Types
-- Run this first before any table creation.

-- Enable pgcrypto for gen_random_uuid() support on older Postgres versions.
-- On Postgres 13+ gen_random_uuid() is built-in but extension is harmless.
create extension if not exists pgcrypto;

-- ── Enum Types ────────────────────────────────────────────────────────────────

create type user_status as enum ('PENDING_APPROVAL', 'ACTIVE', 'DISABLED');
create type product_status as enum ('ACTIVE', 'OUT_OF_STOCK', 'DISABLED');
create type order_status as enum ('PENDING', 'CONFIRMED', 'SHIPPING', 'COMPLETED', 'CANCELLED');
create type payment_method as enum ('COD', 'BANK_TRANSFER');
create type payment_status as enum ('UNPAID', 'PENDING', 'PAID', 'FAILED', 'REFUNDED');
create type notification_type as enum ('PROMOTION', 'PRODUCT', 'ORDER', 'CHAT', 'SYSTEM');
create type chat_sender_type as enum ('USER', 'STAFF', 'AI_SAMPLE');
create type complaint_status as enum ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED');
