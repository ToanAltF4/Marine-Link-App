-- Sửa toạ độ kho cho khớp với địa chỉ thật.
--
-- Toạ độ seed ở V014 chỉ là điểm "đại khái" giữa thành phố, không trùng địa chỉ:
-- vd toạ độ cũ của Kho Cà Mau (9.1768, 105.1524) rơi vào khu Tỉnh uỷ Cà Mau
-- (107 Phan Ngọc Hiển) chứ không phải 45 Lý Thường Kiệt. Vì nút "Chỉ đường"
-- dùng đúng toạ độ này nên Google Maps dẫn tới sai chỗ.
--
-- Toạ độ mới lấy trực tiếp từ Google Maps tại đúng địa chỉ của từng kho.
-- Cột là numeric(10,7) nên giữ 7 chữ số thập phân (~1cm).

-- Kho Cần Thơ — 123 Trần Hưng Đạo, Ninh Kiều, Cần Thơ
update warehouses
set latitude  = 10.0358368,
    longitude = 105.7762727
where public_id = '550e8400-e29b-41d4-a716-446655460001'::uuid;

-- Kho Cà Mau — 45 Lý Thường Kiệt, Phường 6, Cà Mau
update warehouses
set latitude  = 9.1771859,
    longitude = 105.1497994
where public_id = '550e8400-e29b-41d4-a716-446655460002'::uuid;
