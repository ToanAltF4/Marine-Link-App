-- Migration 018: Add VNPAY to payment_method enum
-- PostgreSQL ALTER TYPE ADD VALUE is transactional-safe (only add, no rename/remove).
alter type payment_method add value if not exists 'VNPAY';
