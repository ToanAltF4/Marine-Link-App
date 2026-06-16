-- Migration V022: Enrich product detail descriptions for the catalog

with description_seed(slug, description) as (
  values
    ('muc-kho-loai-1', $desc$Mực khô loại 1 được tuyển chọn từ mực tươi vùng biển Cà Mau, phơi đủ nắng để giữ vị ngọt tự nhiên và độ dai đặc trưng.

- Thân mực dày, size đều
- Màu sáng tự nhiên, không tẩm màu
- Vị ngọt hậu, thơm rõ khi nướng
- Phù hợp cho quán ăn, nhà hàng hải sản và đại lý đặc sản

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('hai-ma-kho', $desc$Hải mã khô được chọn lọc kỹ từ nguồn hàng biển Phú Quốc, làm sạch và sấy khô kiểm soát độ ẩm để giữ chất lượng ổn định.

- Hàng khô đều, dáng đẹp
- Đóng gói kỹ, hạn chế hút ẩm
- Phù hợp dòng đặc sản cao cấp
- Thích hợp cho đại lý, cửa hàng quà biếu và nhà hàng đặt trước

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('kho-ca-duoi', $desc$Khô cá đuối được làm từ cá tươi vùng biển Vũng Tàu, sơ chế sạch và phơi theo quy trình đảm bảo vệ sinh an toàn thực phẩm.

- Thịt cá dai, thớ chắc
- Vị đậm tự nhiên, thơm khi nướng
- Dễ chế biến món nướng, gỏi hoặc rim
- Phù hợp cho quán nhậu, nhà hàng và đại lý phân phối

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('muc-mot-nang-loai-1', $desc$Mực một nắng loại 1 được tuyển chọn từ mực tươi Phan Thiết, phơi một nắng đúng độ và cấp đông nhanh để giữ độ ngọt.

- Thân mực dày, thịt trắng đẹp
- Độ dai vừa, không bị khô cứng
- Vị ngọt tự nhiên, thơm khi áp chảo hoặc nướng
- Phù hợp cho nhà hàng, quán ăn và đơn sỉ chất lượng cao

Bảo quản: Ngăn đông ở nhiệt độ ổn định
Hạn sử dụng: 12 tháng$desc$),
    ('kho-ca-sac', $desc$Khô cá sặc miền Tây được chọn từ cá tươi, làm sạch và phơi vừa nắng để giữ độ béo thơm đặc trưng.

- Con cá đều, thịt chắc
- Vị mặn ngọt hài hòa
- Dễ chế biến chiên, nướng hoặc trộn gỏi
- Phù hợp cho cửa hàng đặc sản, quán cơm và đại lý bán lẻ

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('kho-ca-nhu', $desc$Khô cá nhụ được tuyển chọn từ nguồn cá biển Nha Trang, sơ chế kỹ và phơi khô để giữ vị thơm béo tự nhiên.

- Thịt cá chắc, ít bở
- Hương vị đậm đà, thơm khi nướng
- Hàng đóng gói theo kg, dễ chia đơn
- Phù hợp cho nhà hàng, cửa hàng đặc sản và đại lý tỉnh

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('bach-tuoc-kho', $desc$Bạch tuộc khô được chọn từ bạch tuộc tươi Kiên Giang, làm sạch và phơi sấy đúng độ để giữ độ dai giòn đặc trưng.

- Size đều, màu tự nhiên
- Thịt dai, thơm rõ khi nướng
- Dễ dùng cho món nướng, rim hoặc combo đặc sản
- Phù hợp cho quán ăn, nhà hàng và đại lý phân phối

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('muc-kho-dai', $desc$Mực khô đại được tuyển chọn từ mực size lớn vùng biển Cà Mau, phơi đủ nắng để thân mực dày và vị ngọt rõ.

- Size đại, hình thức đẹp
- Thân mực dày, ít vụn
- Mùi thơm tự nhiên, lên màu đẹp khi nướng
- Phù hợp cho quà tặng, nhà hàng hải sản và đại lý đặc sản

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('kho-ca-loc', $desc$Khô cá lóc đồng Đồng Tháp được làm từ cá tươi, sơ chế sạch và phơi vừa nắng để giữ vị ngọt thịt.

- Thịt cá chắc, ít xương dăm
- Vị đậm đà, thơm đặc trưng miền Tây
- Dễ chế biến chiên, nướng hoặc làm gỏi
- Phù hợp cho đại lý đặc sản, quán cơm và nhà hàng món Việt

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('muc-mot-nang', $desc$Mực một nắng tiêu chuẩn được chọn từ mực tươi Phan Thiết, phơi đúng một nắng và cấp đông để giữ độ mềm ngọt.

- Thịt mực mềm, dai vừa
- Vị ngọt tự nhiên, dễ chế biến
- Nguồn hàng ổn định cho đơn sỉ
- Phù hợp cho nhà hàng, quán ăn và bếp suất ăn hải sản

Bảo quản: Ngăn đông ở nhiệt độ ổn định
Hạn sử dụng: 12 tháng$desc$),
    ('muc-kho-xe-soi', $desc$Mực khô xé sợi được làm từ mực khô chọn lọc, xé sẵn tiện dùng và đóng gói phù hợp cho kênh bán lẻ.

- Sợi mực đều, ít vụn
- Vị ngọt mặn hài hòa
- Tiện dùng cho ăn liền, rim me hoặc phối combo
- Phù hợp cho cửa hàng tiện lợi, đại lý đặc sản và quán ăn

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('ca-moi-kho', $desc$Cá mối khô được tuyển chọn từ cá tươi Bình Thuận, làm sạch và phơi khô để giữ vị nhẹ, dễ ăn.

- Thịt cá mềm, vị thanh
- Hàng sạch, dễ chia gói bán lẻ
- Phù hợp chế biến chiên giòn, nướng hoặc rim
- Thích hợp cho combo đặc sản, đại lý và quán ăn gia đình

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('tom-kho-size-vua', $desc$Tôm khô size vừa được chọn từ tôm tươi Bạc Liêu, luộc và sấy khô theo quy trình đảm bảo vệ sinh an toàn thực phẩm.

- Màu đỏ cam tự nhiên
- Thịt tôm chắc, vị ngọt đậm
- Size vừa, dễ bán lẻ và chế biến
- Phù hợp cho chợ đặc sản, quán ăn, nhà hàng và đại lý phân phối

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('ca-chi-vang-kho', $desc$Cá chỉ vàng khô được tuyển chọn từ cá tươi tự nhiên, làm sạch và phơi theo quy trình đảm bảo vệ sinh an toàn thực phẩm.

- Thịt mỏng vừa, dễ nướng
- Màu vàng tự nhiên
- Vị ngọt, thơm đặc trưng
- Phù hợp cho quán ăn, nhà hàng và đại lý phân phối

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('nuoc-mam-truyen-thong', $desc$Nước mắm truyền thống Phú Quốc được ủ chượp từ cá cơm, phù hợp bán kèm combo hải sản khô và kênh đặc sản.

- Hương thơm mắm truyền thống
- Vị mặn ngọt hài hòa, hậu vị rõ
- Chai 500ml dễ trưng bày và bán lẻ
- Phù hợp cho cửa hàng đặc sản, đại lý và nhà hàng món Việt

Bảo quản: Nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp
Hạn sử dụng: 12 tháng$desc$),
    ('ca-chi-vang-kho-loai-1', $desc$Cá chỉ vàng khô loại 1 được tuyển chọn từ cá tươi tự nhiên, phơi theo quy trình đảm bảo vệ sinh an toàn thực phẩm.

- Thịt dày, ít xương
- Màu vàng tự nhiên
- Vị ngọt, thơm đặc trưng
- Phù hợp cho quán ăn, nhà hàng và đại lý phân phối

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('tom-kho-size-lon', $desc$Tôm khô size lớn Bạc Liêu được tuyển chọn từ tôm tươi, sấy khô đúng độ để giữ màu tự nhiên và độ ngọt thịt.

- Size lớn, con đều đẹp
- Màu đỏ tự nhiên, không tẩm màu
- Thịt chắc, vị ngọt đậm
- Phù hợp cho nhà hàng, cửa hàng đặc sản và đại lý đơn sỉ

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('kho-ca-map', $desc$Khô cá mập được chọn lọc từ nguồn cá biển Quảng Ngãi, sơ chế sạch và phơi khô để giữ thớ thịt chắc.

- Thịt chắc, vị đậm
- Dòng đặc sản ít phổ biến, dễ tạo khác biệt
- Phù hợp chế biến nướng, rim hoặc món nhậu
- Thích hợp cho đơn đặt trước, đại lý đặc sản và nhà hàng

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('hai-sam-kho', $desc$Hải sâm khô cao cấp được tuyển chọn từ nguồn hàng Khánh Hòa, làm sạch và sấy khô kỹ để giữ chất lượng ổn định.

- Hàng khô đều, đóng gói chắc
- Dòng giá trị cao, phù hợp kênh đặc sản
- Dễ lưu kho khi bảo quản đúng cách
- Phù hợp cho nhà hàng, đại lý cao cấp và đơn quà biếu

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('ca-com-kho', $desc$Cá cơm khô Phan Rang được chọn từ cá cơm nhỏ, làm sạch và phơi khô để giữ vị ngọt tự nhiên.

- Cá nhỏ đều, sạch
- Vị ngọt nhẹ, dễ chế biến
- Phù hợp kho rim, rang tỏi hoặc trộn gỏi
- Thích hợp cho cửa hàng thực phẩm, quán ăn và đại lý phân phối

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('kho-ca-du', $desc$Khô cá đù Bến Tre được chọn từ cá tươi, sơ chế sạch và phơi vừa nắng để giữ mùi thơm tự nhiên.

- Thịt cá thơm, vị đậm vừa
- Size phù hợp bán lẻ và đơn sỉ
- Dễ chế biến chiên, nướng hoặc rim
- Phù hợp cho cửa hàng đặc sản, quán ăn và đại lý phân phối

Bảo quản: Nơi khô ráo, thoáng mát hoặc ngăn đông
Hạn sử dụng: 12 tháng$desc$),
    ('ca-basa-phi-le', $desc$Cá basa phi lê đông lạnh được tuyển chọn từ nguồn cá An Giang, sơ chế sạch và cấp đông nhanh để giữ độ tươi.

- Miếng phi lê đều, ít xương
- Thịt trắng, mềm, dễ chế biến
- Tiện bảo quản và vận chuyển xa
- Phù hợp cho bếp nhà hàng, suất ăn công nghiệp và đại lý thực phẩm đông lạnh

Bảo quản: Ngăn đông ở nhiệt độ ổn định
Hạn sử dụng: 12 tháng$desc$),
    ('ghe-dong-lanh', $desc$Ghẹ đông lạnh Phú Quốc được sơ chế và đóng block để giữ chất lượng trong quá trình vận chuyển.

- Ghẹ được cấp đông nhanh
- Đóng block dễ lưu kho
- Phù hợp chế biến hấp, rang me hoặc lẩu hải sản
- Thích hợp cho nhà hàng, quán ăn và đại lý thực phẩm đông lạnh

Bảo quản: Ngăn đông ở nhiệt độ ổn định
Hạn sử dụng: 12 tháng$desc$)
)
update products p
set
  description = ds.description,
  updated_at = now()
from description_seed ds
where p.slug = ds.slug;
