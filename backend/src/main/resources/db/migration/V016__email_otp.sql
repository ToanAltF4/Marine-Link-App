-- Migration 016: Email OTP verification support
-- Adds PENDING_VERIFICATION to user_status and creates the email_otp table.

-- Add new enum value to user_status (Postgres ALTER TYPE ... ADD VALUE is transactional-safe)
ALTER TYPE user_status ADD VALUE IF NOT EXISTS 'PENDING_VERIFICATION' BEFORE 'PENDING_APPROVAL';

-- ── email_otp ──────────────────────────────────────────────────────────────────
-- Stores one-time passwords for email verification.
-- Rows are soft-invalidated via the `used` flag; old rows are cleaned up on resend.

CREATE TABLE IF NOT EXISTS email_otp (
    id          BIGSERIAL    PRIMARY KEY,
    email       VARCHAR(255) NOT NULL,
    otp_code    VARCHAR(6)   NOT NULL,
    expires_at  TIMESTAMPTZ  NOT NULL,
    used        BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_email_otp_email ON email_otp(email);
