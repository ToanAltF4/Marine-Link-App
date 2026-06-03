-- Migration 012: Localize legacy demo catalog labels to Vietnamese with accents

update categories
set
  name = 'Cá đông lạnh',
  description = 'Cá đông lạnh cho kênh nhà hàng và đại lý',
  updated_at = now()
where slug = 'ca-dong-lanh';

update categories
set
  name = 'Mực khô',
  description = 'Mực khô chất lượng cho đại lý và nhà hàng',
  updated_at = now()
where slug = 'muc-kho';

update categories
set
  name = 'Tôm khô',
  description = 'Tôm khô size lớn phục vụ đơn sỉ',
  updated_at = now()
where slug = 'tom-kho';

update products
set
  name = 'Cá basa phi lê',
  description = 'Cá basa phi lê đông lạnh, dễ bảo quản và vận chuyển.',
  updated_at = now()
where slug = 'ca-basa-phi-le';

update products
set
  name = 'Ghẹ đông lạnh',
  description = 'Ghẹ đông lạnh đóng block, phù hợp đơn nhà hàng.',
  origin = 'Phú Quốc',
  updated_at = now()
where slug = 'ghe-dong-lanh';

update product_images pi
set alt_text = 'Cá basa phi lê'
from products p
where pi.product_id = p.id
  and p.slug = 'ca-basa-phi-le';
