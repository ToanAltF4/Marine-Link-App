-- Migration V025: Curate concise product list summaries.

with short_description_seed(slug, short_description) as (
  values
    ('muc-kho-loai-1', 'Mực thân dày, size đều, vị ngọt tự nhiên; phù hợp đơn sỉ nhà hàng và đại lý đặc sản.'),
    ('hai-ma-kho', 'Hàng khô chọn lọc, đóng gói kiểm soát ẩm; phù hợp kênh đặc sản cao cấp và quà biếu.'),
    ('kho-ca-duoi', 'Thịt cá dai, vị đậm, thơm khi nướng; hợp quán nhậu, nhà hàng và đại lý phân phối.'),
    ('muc-mot-nang-loai-1', 'Mực một nắng loại 1, thịt trắng dày, cấp đông nhanh để giữ độ ngọt và độ dai.'),
    ('kho-ca-sac', 'Khô cá sặc miền Tây phơi vừa nắng, vị mặn ngọt hài hòa; dễ bán lẻ và chế biến.'),
    ('kho-ca-nhu', 'Cá nhụ thịt chắc, thơm béo tự nhiên, đóng gói theo kg cho nhà hàng và đại lý tỉnh.'),
    ('bach-tuoc-kho', 'Bạch tuộc size đều, dai thơm khi nướng; tiện làm món nướng, rim hoặc combo đặc sản.'),
    ('muc-kho-dai', 'Mực size đại, thân lớn, hình thức đẹp; phù hợp quà tặng và nhà hàng hải sản.'),
    ('kho-ca-loc', 'Khô cá lóc đồng ít xương dăm, vị đậm miền Tây; hợp quán cơm và cửa hàng đặc sản.'),
    ('muc-mot-nang', 'Mực một nắng tiêu chuẩn, mềm ngọt, nguồn hàng ổn định cho bếp nhà hàng và đơn sỉ.'),
    ('muc-kho-xe-soi', 'Mực xé sợi tiện dùng, ít vụn, vị mặn ngọt hài hòa; phù hợp bán lẻ và combo ăn liền.'),
    ('ca-moi-kho', 'Cá mối khô vị nhẹ, dễ ăn, dễ chia gói; hợp chiên giòn, nướng hoặc rim.'),
    ('tom-kho-size-vua', 'Tôm khô size vừa, màu tự nhiên, thịt chắc; phù hợp bán lẻ, chế biến và đơn đại lý.'),
    ('ca-chi-vang-kho', 'Cá chỉ vàng phổ thông, hàng đều, dễ nướng; phù hợp quán ăn và kênh phân phối sỉ.'),
    ('nuoc-mam-truyen-thong', 'Nước mắm truyền thống chai 500ml, dễ trưng bày, phù hợp bán kèm combo hải sản khô.'),
    ('ca-chi-vang-kho-loai-1', 'Cá chỉ vàng loại 1, size đẹp, thịt dày hơn; hợp nhà hàng và cửa hàng đặc sản.'),
    ('tom-kho-size-lon', 'Tôm khô size lớn Bạc Liêu, con đều, màu đỏ tự nhiên; phù hợp đơn sỉ và quà biếu.'),
    ('kho-ca-map', 'Dòng đặc sản ít phổ biến, thịt chắc, vị đậm; phù hợp đơn đặt trước và nhà hàng.'),
    ('hai-sam-kho', 'Hải sâm khô cao cấp, đóng gói kỹ, dễ lưu kho; phù hợp nhà hàng và đại lý đặc sản.'),
    ('ca-com-kho', 'Cá cơm nhỏ sạch, vị ngọt nhẹ; tiện kho rim, rang tỏi hoặc phối combo bán lẻ.'),
    ('kho-ca-du', 'Khô cá đù phơi vừa, thịt thơm, vị đậm vừa; phù hợp cửa hàng đặc sản và quán ăn.'),
    ('ca-basa-phi-le', 'Phi lê cá basa cấp đông nhanh, miếng đều, ít xương; phù hợp bếp nhà hàng và suất ăn.'),
    ('ghe-dong-lanh', 'Ghẹ sơ chế cấp đông, đóng block dễ lưu kho; tiện hấp, rang me hoặc nấu lẩu hải sản.')
)
update products p
set
  short_description = sds.short_description,
  updated_at = now()
from short_description_seed sds
where p.slug = sds.slug;
