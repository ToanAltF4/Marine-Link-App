-- Migration 017: allow NULL phone for Google sign-up accounts
--
-- Google sign-in does not provide a phone number; such accounts complete their
-- profile (phone) later. The partial unique index on phone (where deleted_at is
-- null) keeps working because Postgres treats NULLs as distinct.

alter table users alter column phone drop not null;
