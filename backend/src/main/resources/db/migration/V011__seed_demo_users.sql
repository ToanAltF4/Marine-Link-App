-- Migration 011: Seed demo accounts with BCrypt password hashes

with user_seed(
  public_id,
  role_code,
  full_name,
  email,
  phone,
  password_hash,
  status,
  store_name,
  business_address,
  tax_code,
  avatar_url
) as (
  values
    (
      '550e8400-e29b-41d4-a716-446655440001'::uuid,
      'ADMIN',
      'MarineLink Admin',
      'admin@marinelink.demo',
      '0900000000',
      '$2a$10$SwiBRWdMzK4OgosPjCCoEu/P50xNapEuDDRCwNAzowIbkFdaKcsRm',
      'ACTIVE',
      null,
      null,
      null,
      null
    ),
    (
      '550e8400-e29b-41d4-a716-446655440002'::uuid,
      'STAFF',
      'Nhân viên Demo',
      'staff@marinelink.demo',
      '0900000001',
      '$2a$10$.Bfv5dpR0TVHCtBghNASoeM6pPDk9oGETD/uzG2XINbm3IqaKYCx2',
      'ACTIVE',
      null,
      null,
      null,
      null
    ),
    (
      '550e8400-e29b-41d4-a716-446655440003'::uuid,
      'USER',
      'Đại lý Nguyễn Văn A',
      'daily-a@marinelink.demo',
      '0912345678',
      '$2a$10$pSzsdVOcWmDNxHnamACPAO78feFPTTBCqwtuhLSNa5IU51RATT.Lu',
      'ACTIVE',
      'Hải Sản A Cần Thơ',
      'Cần Thơ',
      '0312345678',
      null
    )
)
update users u
set
  role_id = r.id,
  full_name = s.full_name,
  phone = s.phone,
  password_hash = s.password_hash,
  status = s.status::user_status,
  store_name = s.store_name,
  business_address = s.business_address,
  tax_code = s.tax_code,
  avatar_url = s.avatar_url,
  updated_at = now()
from user_seed s
join roles r on r.code = s.role_code
where lower(u.email) = lower(s.email)
  and u.deleted_at is null;

with user_seed(
  public_id,
  role_code,
  full_name,
  email,
  phone,
  password_hash,
  status,
  store_name,
  business_address,
  tax_code,
  avatar_url
) as (
  values
    (
      '550e8400-e29b-41d4-a716-446655440001'::uuid,
      'ADMIN',
      'MarineLink Admin',
      'admin@marinelink.demo',
      '0900000000',
      '$2a$10$SwiBRWdMzK4OgosPjCCoEu/P50xNapEuDDRCwNAzowIbkFdaKcsRm',
      'ACTIVE',
      null,
      null,
      null,
      null
    ),
    (
      '550e8400-e29b-41d4-a716-446655440002'::uuid,
      'STAFF',
      'Nhân viên Demo',
      'staff@marinelink.demo',
      '0900000001',
      '$2a$10$.Bfv5dpR0TVHCtBghNASoeM6pPDk9oGETD/uzG2XINbm3IqaKYCx2',
      'ACTIVE',
      null,
      null,
      null,
      null
    ),
    (
      '550e8400-e29b-41d4-a716-446655440003'::uuid,
      'USER',
      'Đại lý Nguyễn Văn A',
      'daily-a@marinelink.demo',
      '0912345678',
      '$2a$10$pSzsdVOcWmDNxHnamACPAO78feFPTTBCqwtuhLSNa5IU51RATT.Lu',
      'ACTIVE',
      'Hải Sản A Cần Thơ',
      'Cần Thơ',
      '0312345678',
      null
    )
)
insert into users (
  public_id,
  role_id,
  full_name,
  email,
  phone,
  password_hash,
  status,
  store_name,
  business_address,
  tax_code,
  avatar_url
)
select
  s.public_id,
  r.id,
  s.full_name,
  s.email,
  s.phone,
  s.password_hash,
  s.status::user_status,
  s.store_name,
  s.business_address,
  s.tax_code,
  s.avatar_url
from user_seed s
join roles r on r.code = s.role_code
where not exists (
  select 1
  from users u
  where lower(u.email) = lower(s.email)
    and u.deleted_at is null
);
