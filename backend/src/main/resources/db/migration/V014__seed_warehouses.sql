-- Seed active warehouse points for the MVP warehouse map/list.

insert into warehouses (
  public_id,
  name,
  address,
  phone,
  opening_hours,
  latitude,
  longitude,
  is_active
) values
  (
    '550e8400-e29b-41d4-a716-446655460001'::uuid,
    'Kho Can Tho',
    '123 Tran Hung Dao, Ninh Kieu, Can Tho',
    '0292000000',
    '08:00-17:00',
    10.0452000,
    105.7469000,
    true
  ),
  (
    '550e8400-e29b-41d4-a716-446655460002'::uuid,
    'Kho Ca Mau',
    '45 Ly Thuong Kiet, Phuong 6, Ca Mau',
    '0290000000',
    '07:30-16:30',
    9.1768000,
    105.1524000,
    true
  )
on conflict (public_id) do update set
  name = excluded.name,
  address = excluded.address,
  phone = excluded.phone,
  opening_hours = excluded.opening_hours,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  is_active = excluded.is_active;
