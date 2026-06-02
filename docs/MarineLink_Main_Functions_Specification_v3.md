![MarineLink Logo](data:image/png;base64...)

**MARINELINK**

KẾT NỐI HẢI SẢN - VƯƠN TẦM THỊ TRƯỜNG

**TÀI LIỆU ĐẶC TẢ CHỨC NĂNG CHÍNH**

*Main Functions Specification*

### Course: PRM393 – Mobile Programming Platform: Flutter (Android)

### Group 5 (3 Members)

Phạm Đức Toàn – SE180165

Ngô Việt Hoàng – SE172524

Đặng Quốc Tâm – SE171713

**Date:** May 2025

# MỤC LỤC

**1. Cấu trúc Database / API**

**2. Đăng nhập (Login)**

**3. Đăng ký tài khoản (Register)**

**4. Trang chủ (Home)**

**5. Danh sách sản phẩm (Product List)**

**6. Chi tiết sản phẩm (Product Detail)**

**7. Giỏ hàng (Shopping Cart)**

**8. Đặt hàng & Thanh toán (Checkout)**

**9. Quản lý đơn hàng (Orders)**

**10. Chat & Hỗ trợ (Messaging)**

**11. Thông báo (Notifications)**

**12. Bản đồ kho hàng (Map)**

**13. Hồ sơ cá nhân (Profile)**

**14. Admin Dashboard**

**15. Quản lý trạng thái (State Management)**

# 1. Cấu trúc Database / API

**Mục đích**

Mô tả cấu trúc cơ sở dữ liệu và API phục vụ ứng dụng MarineLink B2B. Hệ thống sử dụng REST API để kết nối giữa Flutter frontend và backend server. Dữ liệu được lưu trữ trên cloud database.

**Các bảng dữ liệu chính**

|  |  |  |  |
| --- | --- | --- | --- |
| **Bảng** | **Mô tả** | **Khóa chính / ID strategy** | **Liên kết/Quan hệ** |
| users | Thông tin tài khoản người dùng, liên kết trực tiếp với bảng roles qua cột role\_id. | id (PK nội bộ), public\_id (UUIDv4 API), role\_id (FK) | n-1 role, 1-n orders, 1-n carts, 1-n chat\_rooms, 1-n chat\_messages, 1-n complaints, 1-n notifications |
| roles | Danh sách vai trò mặc định và mở rộng như ADMIN, STAFF, USER. | id (PK nội bộ), public\_id (UUIDv4 API) | 1-n users |
| categories | Danh mục: Mực khô, Tôm khô, Cá khô, Nước mắm. | id (PK nội bộ), public\_id (UUIDv4 API) | 1-n products |
| products | Sản phẩm hải sản khô/nước mắm. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 categories, 1-n product\_images, 1-n price\_tiers, 1-n cart\_items, 1-n order\_items |
| product\_images | Ảnh phụ hoặc gallery của sản phẩm. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 products |
| price\_tiers | Bảng giá sỉ theo số lượng. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 products, 1-n cart\_items qua selected\_price |
| carts | Giỏ hàng hiện tại của từng đại lý. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 users, 1-n cart\_items |
| cart\_items | Sản phẩm trong giỏ hàng, có thể lưu mức giá đã chọn. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 carts, n-1 products, n-1 price\_tiers |
| orders | Đơn hàng sỉ của đại lý. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 users, 1-n order\_items, 1-n order\_status\_history, 1-n complaints, 1-n notifications |
| order\_items | Chi tiết từng sản phẩm trong đơn, có snapshot giá. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 orders, n-1 products |
| order\_status\_history | Lịch sử thay đổi trạng thái đơn hàng. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 orders, n-1 users qua changed\_by |
| chat\_rooms | Phòng chat giữa đại lý và Staff. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 users, n-1 users qua assigned\_staff\_id, 1-n chat\_messages |
| chat\_messages | Lịch sử chat giữa Đại lý và Nhân viên hỗ trợ. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 chat\_rooms, n-1 users qua sender\_id, 1-n chat\_attachments, 1-n complaints |
| chat\_attachments | Metadata file đính kèm của tin nhắn chat. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 chat\_messages, n-1 users qua uploaded\_by |
| complaints | Khiếu nại từ đại lý, phát sinh từ đơn hàng hoặc chat message. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 users, n-1 orders, n-1 chat\_rooms, n-1 chat\_messages |
| notifications | Thông báo push/in-app cho người dùng. | id (PK nội bộ), public\_id (UUIDv4 API) | n-1 users, có thể liên kết orders/products/chat\_rooms |
| warehouses | Kho hàng và điểm lấy hàng. | id (PK nội bộ), public\_id (UUIDv4 API) | Độc lập; dùng cho Map |

**API endpoints chính**

|  |  |  |  |
| --- | --- | --- | --- |
| **Phương thức** | **Endpoint** | **Mô tả** | **Phân quyền** |
| POST | /api/auth/logout | Logout hoặc token cleanup nếu backend lưu refresh token/denylist. | Authenticated |
| POST | /api/auth/login | Đăng nhập, trả JWT kèm roles của user. | Công khai |
| POST | /api/auth/register | Đăng ký đại lý và gán role USER mặc định. | Công khai |
| GET | /api/products | Lấy danh sách sản phẩm, tìm kiếm, lọc, sắp xếp. | Tất cả role |
| GET | /api/products/{id} | Chi tiết sản phẩm + ảnh + giá sỉ. | Tất cả role |
| POST | /api/cart/sync | Đồng bộ giỏ hàng từ local storage lên carts/cart\_items. | Đại lý |
| GET | /api/orders/{id} | Chi tiết đơn hàng, items và lịch sử trạng thái. | Owner, Staff, Admin |
| POST | /api/orders | Tạo đơn hàng mới từ cart\_items. | Đại lý |
| GET | /api/orders | Danh sách đơn hàng theo role/trạng thái. | Tất cả role |
| PUT | /api/orders/{id}/status | Cập nhật trạng thái đơn hàng và ghi order\_status\_history. | Admin, Staff |
| POST | /api/chat/send | Gửi tin nhắn chat, có thể kèm metadata file đính kèm. | Tất cả role |
| PUT | /api/notifications/{id}/read | Đánh dấu thông báo đã đọc. | Owner |
| GET | /api/chat/{roomId} | Lấy lịch sử chat, bao gồm chat\_attachments. | Participant, Staff, Admin |
| GET/PUT | /api/users/me | Xem và cập nhật hồ sơ hiện tại. | Authenticated |
| GET | /api/notifications | Lấy thông báo. | Tất cả role |
| GET | /api/warehouses | Danh sách kho hàng. | Tất cả role |
| GET | /api/admin/dashboard | Thống kê tổng quan. | Admin |
| CRUD | /api/admin/products | Quản lý sản phẩm, ảnh, tồn kho, giá sỉ. | Admin |
| CRUD | /api/admin/users | Quản lý tài khoản và vai trò. | Admin |

**Quan hệ giữa các bảng/collection**

|  |  |  |  |
| --- | --- | --- | --- |
| **Bảng nguồn** | **Quan hệ** | **Bảng đích** | **Ý nghĩa** |
| users | 1-n | orders | Một đại lý có thể tạo nhiều đơn hàng. |
| users | 1-n | carts | Mỗi user có một cart active trong MVP. |
| categories | 1-n | products | Một danh mục có nhiều sản phẩm. |
| products | 1-n | product\_images | Một sản phẩm có nhiều ảnh. |
| products | 1-n | price\_tiers | Một sản phẩm có nhiều mức giá sỉ theo số lượng. |
| carts | 1-n | cart\_items | Một giỏ hàng gồm nhiều dòng sản phẩm. |
| products | 1-n | cart\_items | Một sản phẩm có thể nằm trong nhiều giỏ hàng. |
| orders | 1-n | order\_items | Một đơn hàng gồm nhiều dòng sản phẩm. |
| orders | 1-n | order\_status\_history | Một đơn hàng có nhiều lần thay đổi trạng thái. |
| users | 1-n | notifications | Mỗi người dùng nhận nhiều thông báo. |
| orders | 1-n | complaints | Một đơn hàng có thể phát sinh nhiều khiếu nại. |
| chat\_rooms | 1-n | chat\_messages | Một phòng chat có nhiều tin nhắn. |
| chat\_messages | 1-n | chat\_attachments | Một tin nhắn có thể có nhiều file đính kèm. |
| price\_tiers | 1-n | cart\_items | Một mức giá có thể được chọn bởi nhiều cart item sau khi validate số lượng. |
| chat\_messages | 1-n | complaints | Một tin nhắn chat có thể phát sinh khiếu nại. |

**CRUD/API theo từng màn hình**

Các thao tác đọc, ghi, cập nhật và xóa dữ liệu được gom theo từng màn hình để dễ đối chiếu với quá trình triển khai Flutter.

|  |  |  |  |
| --- | --- | --- | --- |
| **Màn hình** | **Đọc dữ liệu (Read)** | **Ghi/Cập nhật/Xóa** | **Dữ liệu sử dụng** |
| Đăng nhập | - | POST /api/auth/login | users, roles, JWT token |
| Đăng ký | - | POST /api/auth/register | users, roles |
| Trang chủ | GET /api/products, GET /api/notifications | - | categories, products, product\_images, price\_tiers, notifications |
| Danh sách sản phẩm | GET /api/products | - | products, categories, product\_images, price\_tiers |
| Chi tiết sản phẩm | GET /api/products/{id} | - | products, product\_images, price\_tiers |
| Giỏ hàng | Local storage + POST /api/cart/sync | Thêm/sửa/xóa item local trước khi sync; backend lưu carts/cart\_items | carts, cart\_items, products, price\_tiers |
| Checkout | - | POST /api/orders | carts, cart\_items, orders, order\_items, users, products |
| Orders | GET /api/orders | PUT /api/orders/{id}/status | orders, order\_items, order\_status\_history, notifications |
| Chat & Hỗ trợ | GET /api/chat/{roomId} | POST /api/chat/send | chat\_rooms, chat\_messages, chat\_attachments, complaints |
| Thông báo | GET /api/notifications | PUT /api/notifications/{id}/read | notifications |
| Bản đồ kho hàng | GET /api/warehouses | - | warehouses |
| Hồ sơ cá nhân | GET /api/users/me | PUT /api/users/me, POST /api/auth/logout | users, roles |
| Admin Dashboard | GET /api/admin/dashboard | CRUD /api/admin/products, CRUD /api/admin/users, PUT /api/orders/{id}/status | users, roles, products, product\_images, price\_tiers, orders, complaints |

**3 role mặc định: Admin (quản lý toàn bộ), Staff/Nhân viên (xử lý đơn, chat, khiếu nại), User/Đại lý (đặt hàng, xem sản phẩm, chat). Role được liên kết trực tiếp với bảng users qua cột role\_id.**

Hệ thống sử dụng JWT token để xác thực. Mọi request API đều cần gửi kèm Bearer token trong header.

## 2. Đăng nhập (Login)

Chức năng này cho phép Đại lý, Nhân viên và Admin đăng nhập vào MarineLink để sử dụng đúng phần việc của mình.

**Mục đích**

Đảm bảo chỉ tài khoản hợp lệ được sử dụng các chức năng cá nhân như đặt hàng, xem đơn hàng, chat hỗ trợ, nhận thông báo hoặc quản trị hệ thống.

**Mô tả xử lý**

Người dùng nhập email hoặc số điện thoại và mật khẩu, sau đó bấm Login.

Ứng dụng kiểm tra thông tin đã nhập đủ chưa, tài khoản có tồn tại không và mật khẩu có đúng không.

Nếu đăng nhập thành công, ứng dụng chuyển người dùng đến màn hình phù hợp với vai trò: Đại lý vào trang mua hàng, Nhân viên vào màn hình xử lý hỗ trợ, Admin vào dashboard quản trị.

Nếu đăng nhập thất bại, ứng dụng hiển thị thông báo lỗi rõ ràng để người dùng biết cần sửa thông tin nào.

**Input**

Email hoặc số điện thoại.

Mật khẩu.

Đăng nhập Google không thuộc MVP; chỉ thêm sau nếu có OAuth provider, callback và account linking rõ ràng.

**Output**

Người dùng đăng nhập thành công và vào đúng màn hình.

Ứng dụng ghi nhớ trạng thái đăng nhập.

Thông báo lỗi khi tài khoản hoặc mật khẩu không đúng.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có kiểm tra dữ liệu nhập vào.

Có thông báo lỗi khi đăng nhập sai.

Có lưu trạng thái đăng nhập.

Có phân quyền giao diện theo vai trò người dùng.

Giao diện dễ hiểu và dễ thao tác.

**Giao diện minh họa**

![Dang nhap (Login)](data:image/png;base64...)

## 3. Đăng ký tài khoản (Register)

Chức năng này cho phép đại lý mới đăng ký tài khoản để bắt đầu sử dụng MarineLink.

**Mục đích**

Thu thập thông tin cơ bản của đại lý và tạo tài khoản chờ xác nhận, giúp MarineLink quản lý khách hàng B2B rõ ràng hơn.

**Mô tả xử lý**

Người dùng nhập họ tên, email, số điện thoại, mật khẩu, tên cửa hàng hoặc địa chỉ kinh doanh.

Ứng dụng kiểm tra các thông tin bắt buộc, định dạng email, số điện thoại và độ mạnh tối thiểu của mật khẩu.

Sau khi thông tin hợp lệ, tài khoản được tạo và chuyển sang trạng thái chờ duyệt hoặc chờ xác nhận.

Nếu thông tin bị thiếu hoặc trùng, ứng dụng hiển thị lỗi ngay tại trường cần sửa.

**Input**

Họ tên người đăng ký.

Email, số điện thoại và mật khẩu.

Thông tin cửa hàng hoặc địa chỉ kinh doanh.

Mã số thuế của đại lý.

**Output**

Tài khoản mới được tạo.

Người dùng được chuyển về màn hình đăng nhập hoặc màn hình chờ duyệt.

Thông báo lỗi nếu dữ liệu không hợp lệ.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có form đăng ký đầy đủ thông tin cần thiết.

Có kiểm tra email, số điện thoại và mật khẩu.

Có xử lý trường hợp email/số điện thoại đã tồn tại.

Có thông báo đăng ký thành công.

Luồng đăng ký phù hợp với ứng dụng B2B.

**Giao diện minh họa**

![Dang ky tai khoan (Register)](data:image/png;base64...)

## 4. Trang chủ (Home)

Trang chủ là màn hình đầu tiên sau khi đăng nhập, giúp đại lý xem nhanh thông tin nổi bật của MarineLink.

**Mục đích**

Giúp người dùng nhanh chóng tìm sản phẩm, xem danh mục hải sản, chương trình khuyến mãi và các thông tin quan trọng trong ngày.

**Mô tả xử lý**

Khi mở trang chủ, ứng dụng hiển thị banner, danh mục sản phẩm, sản phẩm nổi bật và thông báo mới.

Người dùng chọn danh mục như mực khô, tôm khô, cá khô hoặc nước mắm để xem danh sách sản phẩm tương ứng.

Thanh tìm kiếm cho phép người dùng tìm nhanh sản phẩm theo tên hoặc loại sản phẩm.

Khuyến mãi và sản phẩm bán chạy được hiển thị nổi bật để người dùng dễ nhận biết.

**Input**

Thông tin người dùng đã đăng nhập.

Danh mục sản phẩm.

Sản phẩm nổi bật, banner và thông báo.

**Output**

Trang chủ hiển thị dữ liệu tổng quan.

Người dùng chuyển sang danh sách sản phẩm, thông báo hoặc giỏ hàng.

Kết quả tìm kiếm nhanh nếu người dùng nhập từ khóa.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Trang chủ load dữ liệu đầy đủ.

Có banner hoặc khu vực thông tin nổi bật.

Có danh mục sản phẩm rõ ràng.

Có tìm kiếm nhanh.

Có điều hướng đến các màn hình chính.

**Giao diện minh họa**

![Trang chu (Home)](data:image/png;base64...)

## 5. Danh sách sản phẩm (Product List)

Chức năng này hiển thị danh sách sản phẩm hải sản đang được bán trên MarineLink.

**Mục đích**

Giúp đại lý xem các sản phẩm hiện có, tìm sản phẩm phù hợp và chọn sản phẩm để xem chi tiết trước khi đặt hàng.

**Mô tả xử lý**

Ứng dụng hiển thị sản phẩm theo danh mục hoặc theo kết quả tìm kiếm. Thanh tìm kiếm nằm ở phần đầu màn hình để đại lý tìm theo tên sản phẩm, danh mục hoặc xuất xứ.

Mỗi sản phẩm hiển thị hình ảnh, tên sản phẩm, xuất xứ, giá, số lượng đặt tối thiểu và trạng thái còn hàng.

Người dùng lọc nhanh bằng chip `Tất cả`, danh mục, `Còn hàng`, `Sắp hết`; các điều kiện nâng cao như trạng thái tồn kho và sắp xếp giá nằm trong bottom sheet `Lọc`.

MVP dùng contract `GET /api/products` với `q`, `categoryId`, `status`, `featured`, `sort`. Bộ lọc `Sắp hết` có thể tính từ `stockQuantity <= minOrderQuantity * 6` trên dữ liệu trả về. Các bộ lọc khoảng giá, MOQ và xuất xứ là mở rộng sau; nếu bật phải cập nhật API contract, OpenAPI, backend query và index DB trước khi triển khai.

Nếu không có sản phẩm phù hợp, màn hình hiển thị empty state và nút `Xóa lọc` để quay lại toàn bộ danh sách.

Khi chọn một sản phẩm, ứng dụng chuyển sang màn hình chi tiết sản phẩm.

**Input**

Danh sách sản phẩm.

Danh mục đang chọn.

Từ khóa tìm kiếm hoặc điều kiện lọc.

Trạng thái tồn kho và lựa chọn sắp xếp.

**Output**

Danh sách sản phẩm được hiển thị.

Danh sách sau khi tìm kiếm hoặc lọc.

Trạng thái empty khi không có kết quả và hành động xóa lọc.

Điều hướng sang màn hình chi tiết sản phẩm.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có hiển thị dữ liệu sản phẩm thật hoặc dữ liệu mẫu rõ ràng.

Có hình ảnh, tên, giá và trạng thái sản phẩm.

Có tìm kiếm, lọc nhanh, bottom sheet lọc nâng cao và sắp xếp giá.

Có xử lý khi không có sản phẩm.

Có thể xóa lọc để quay lại danh sách ban đầu.

Có điều hướng sang chi tiết sản phẩm.

**Giao diện minh họa**

![Danh sach san pham (Product List)](data:image/png;base64...)

## 6. Chi tiết sản phẩm (Product Detail)

Chức năng này hiển thị thông tin chi tiết của sản phẩm hải sản mà đại lý chọn từ danh sách.

**Mục đích**

Giúp đại lý hiểu rõ sản phẩm trước khi quyết định thêm vào giỏ hàng hoặc đặt mua ngay.

**Mô tả xử lý**

Màn hình hiển thị hình ảnh lớn, tên sản phẩm, loại sản phẩm, xuất xứ, mô tả, giá bán và trạng thái tồn kho.

Nếu sản phẩm có giá theo số lượng, ứng dụng hiển thị thông tin này ở mức dễ hiểu, ví dụ mua nhiều sẽ có mức giá tốt hơn.

Người dùng chọn số lượng muốn mua. Ứng dụng kiểm tra số lượng tối thiểu và số lượng còn hàng.

Khi dữ liệu hợp lệ, người dùng thêm sản phẩm vào giỏ hàng hoặc chuyển sang đặt hàng ngay.

**Input**

Sản phẩm được chọn.

Số lượng người dùng muốn mua.

**Output**

Thông tin chi tiết sản phẩm được hiển thị.

Sản phẩm được thêm vào giỏ hàng nếu hợp lệ.

Thông báo lỗi nếu số lượng không hợp lệ hoặc sản phẩm hết hàng.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có hiển thị đầy đủ thông tin sản phẩm.

Có thông tin giá và số lượng đặt tối thiểu.

Có kiểm tra tồn kho/số lượng.

Có nút thêm vào giỏ hàng hoặc mua ngay.

Có thông báo phản hồi cho người dùng.

**Giao diện minh họa**

![Chi tiet san pham (Product Detail)](data:image/png;base64...)

## 7. Giỏ hàng (Shopping Cart)

Giỏ hàng cho phép đại lý xem lại các sản phẩm đã chọn trước khi đặt hàng.

**Mục đích**

Giúp người dùng kiểm tra sản phẩm, số lượng và tổng tiền để tránh sai sót trước khi checkout.

**Mô tả xử lý**

Ứng dụng hiển thị từng sản phẩm trong giỏ gồm tên, hình ảnh, giá, số lượng và thành tiền.

Người dùng tăng/giảm số lượng hoặc xóa sản phẩm khỏi giỏ.

Khi số lượng thay đổi, tổng tiền được tính lại tự động.

Nếu giỏ hàng trống, ứng dụng hiển thị thông báo phù hợp và gợi ý người dùng quay lại danh sách sản phẩm.

**Input**

Danh sách sản phẩm trong giỏ.

Thao tác tăng/giảm số lượng.

Thao tác xóa sản phẩm.

Thao tác bấm Checkout.

**Output**

Giỏ hàng được cập nhật.

Tổng tiền được tính lại.

Người dùng chuyển sang màn hình checkout.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có hiển thị đúng sản phẩm đã thêm.

Có cập nhật số lượng.

Có xóa sản phẩm khỏi giỏ.

Có tính tổng tiền chính xác.

Có xử lý giỏ hàng rỗng.

Có điều hướng sang checkout.

**Giao diện minh họa**

![Gio hang (Shopping Cart)](data:image/png;base64...)

## 8. Đặt hàng & Thanh toán (Checkout)

Chức năng này cho phép đại lý xác nhận thông tin đơn hàng và gửi yêu cầu đặt mua sản phẩm.

**Mục đích**

Hoàn tất quá trình mua hàng bằng cách xác nhận sản phẩm, địa chỉ giao hàng, phương thức thanh toán và ghi chú đơn hàng.

**Mô tả xử lý**

Ứng dụng hiển thị lại danh sách sản phẩm, số lượng, tổng tiền hàng và tổng tiền cần thanh toán.

Người dùng nhập hoặc chọn địa chỉ giao hàng, số điện thoại nhận hàng và ghi chú đơn hàng.

Người dùng chọn phương thức thanh toán như thanh toán khi nhận hàng hoặc chuyển khoản.

Khi bấm Confirm Order, ứng dụng kiểm tra thông tin và tạo đơn hàng mới nếu dữ liệu hợp lệ.

Sau khi đặt hàng thành công, giỏ hàng được làm trống và người dùng nhận thông báo xác nhận.

**Input**

Sản phẩm trong giỏ hàng.

Thông tin người nhận.

Địa chỉ giao hàng.

Phương thức thanh toán.

Ghi chú đơn hàng.

**Output**

Đơn hàng mới được tạo.

Giỏ hàng được làm trống.

Thông báo đặt hàng thành công.

Người dùng xem lại đơn hàng vừa tạo.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có hiển thị tóm tắt đơn hàng.

Có kiểm tra thông tin giao hàng.

Có chọn phương thức thanh toán.

Có tạo đơn hàng.

Có làm trống giỏ hàng sau khi đặt thành công.

Có thông báo kết quả cho người dùng.

**Giao diện minh họa**

![Dat hang & Thanh toan (Checkout)](data:image/png;base64...)

## 9. Quản lý đơn hàng (Orders)

Chức năng này cho phép đại lý theo dõi đơn hàng đã đặt và cho phép nhân viên/admin xử lý trạng thái đơn hàng.

**Mục đích**

Giúp người dùng biết đơn hàng đang ở bước nào, đồng thời giúp MarineLink quản lý quy trình duyệt, giao và hoàn tất đơn hàng.

**Mô tả xử lý**

Đại lý xem danh sách đơn hàng, chi tiết từng đơn và trạng thái hiện tại.

Trạng thái đơn hàng gồm chờ duyệt, đã xác nhận, đang giao, hoàn tất hoặc đã hủy.

Nhân viên hoặc Admin xem đơn mới và cập nhật trạng thái xử lý.

Khi trạng thái thay đổi, người dùng nhận thông báo để theo dõi đơn hàng.

**Input**

Danh sách đơn hàng của người dùng.

Bộ lọc trạng thái đơn hàng.

Thao tác xem chi tiết hoặc cập nhật trạng thái.

**Output**

Danh sách đơn hàng được hiển thị.

Chi tiết đơn hàng được mở khi người dùng chọn.

Trạng thái đơn hàng được cập nhật.

Thông báo gửi đến người dùng khi có thay đổi.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có danh sách đơn hàng.

Có xem chi tiết đơn hàng.

Có hiển thị trạng thái rõ ràng.

Có cập nhật trạng thái cho nhân viên/admin.

Có thông báo khi trạng thái thay đổi.

**Giao diện minh họa**

![Quan ly don hang (Orders)](data:image/png;base64...)

## 10. Chat & Hỗ trợ (Messaging)

Chức năng này cho phép đại lý nhắn tin với MarineLink để hỏi về sản phẩm, giá, tồn kho hoặc tình trạng đơn hàng.

**Mục đích**

Tạo kênh hỗ trợ nhanh trong ứng dụng, giúp đại lý nhận phản hồi kịp thời từ nhân viên hỗ trợ và giảm thao tác liên hệ bên ngoài.

**Mô tả xử lý**

Người dùng mở màn hình chat và nhập nội dung cần hỏi.

Tin nhắn được hiển thị trong khung hội thoại và lưu lại thành lịch sử chat.

Nhân viên hỗ trợ phản hồi trực tiếp các câu hỏi của đại lý.

Ứng dụng phân biệt tin nhắn của người dùng và nhân viên.

Ứng dụng chặn tin nhắn rỗng trước khi gửi.

**Input**

Nội dung tin nhắn.

Thông tin người gửi.

Hình ảnh hoặc file đính kèm.

**Output**

Tin nhắn hiển thị trên màn hình.

Lịch sử chat được lưu lại.

Người dùng nhận phản hồi trực tiếp từ nhân viên hỗ trợ.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có giao diện chat rõ ràng.

Có gửi và hiển thị tin nhắn.

Có lưu lịch sử chat.

Có phân biệt người gửi.

Có hiển thị thời gian gửi.

Có xử lý tin nhắn rỗng.

Nhân viên hỗ trợ phản hồi đúng trọng tâm câu hỏi.

**Giao diện minh họa**

![Chat & Ho tro (Messaging)](data:image/png;base64...)

## 11. Thông báo (Notifications)

Chức năng này hiển thị các thông báo liên quan đến sản phẩm, khuyến mãi, đơn hàng và tin nhắn hỗ trợ.

**Mục đích**

Giúp người dùng không bỏ lỡ thông tin quan trọng từ MarineLink.

**Mô tả xử lý**

Ứng dụng hiển thị danh sách thông báo theo thời gian mới nhất.

Thông báo gồm khuyến mãi, sản phẩm mới, đơn hàng được xác nhận, đơn hàng đang giao, đơn hàng hoàn tất hoặc phản hồi chat.

Mỗi thông báo hiển thị tiêu đề, nội dung ngắn, thời gian gửi và trạng thái đã đọc/chưa đọc.

Khi người dùng bấm vào thông báo, ứng dụng mở màn hình liên quan như chi tiết đơn hàng, sản phẩm hoặc chat.

**Input**

Danh sách thông báo.

Thao tác chọn thông báo.

Thao tác đánh dấu đã đọc.

**Output**

Thông báo được hiển thị.

Thông báo được đánh dấu đã đọc.

Người dùng được chuyển đến màn hình liên quan.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có danh sách thông báo.

Có tiêu đề, nội dung và thời gian.

Có phân biệt đã đọc/chưa đọc.

Có xử lý khi không có thông báo.

Có mở chi tiết hoặc điều hướng liên quan.

**Giao diện minh họa**

![Thong bao (Notifications)](data:image/png;base64...)

## 12. Bản đồ kho hàng (Map)

Chức năng này hiển thị vị trí kho hàng, cửa hàng hoặc điểm giao nhận của MarineLink trên bản đồ.

**Mục đích**

Giúp đại lý biết địa chỉ liên hệ, xem vị trí trên bản đồ và mở chỉ đường khi cần.

**Mô tả xử lý**

Ứng dụng hiển thị bản đồ cùng marker vị trí của kho hàng hoặc cửa hàng MarineLink.

Thông tin hiển thị gồm tên địa điểm, địa chỉ, số điện thoại liên hệ và giờ làm việc.

Người dùng bấm vào marker để xem thông tin chi tiết.

Ứng dụng mở Google Maps để chỉ đường từ vị trí hiện tại của người dùng.

Nếu dùng vị trí hiện tại, ứng dụng cần xin quyền truy cập vị trí và xử lý trường hợp người dùng từ chối.

**Input**

Tọa độ kho hàng hoặc cửa hàng.

Thông tin địa chỉ và liên hệ.

Vị trí hiện tại của người dùng.

**Output**

Bản đồ hiển thị vị trí MarineLink.

Marker và thông tin địa điểm.

Tùy chọn mở chỉ đường.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có hiển thị bản đồ.

Có marker vị trí.

Có thông tin địa chỉ/liên hệ.

Giao diện dễ hiểu.

Có xử lý quyền vị trí nếu dùng vị trí hiện tại.

**Giao diện minh họa**

![Ban do kho hang (Map)](data:image/png;base64...)

## 13. Hồ sơ cá nhân (Profile)

Chức năng này cho phép người dùng xem và cập nhật thông tin cá nhân hoặc thông tin đại lý của mình.

**Mục đích**

Giúp người dùng quản lý tài khoản, địa chỉ giao hàng và các thông tin cần thiết cho việc đặt hàng.

**Mô tả xử lý**

Người dùng mở màn hình hồ sơ để xem họ tên, email, số điện thoại, địa chỉ và vai trò tài khoản.

Người dùng chỉnh sửa các thông tin được phép thay đổi như số điện thoại, địa chỉ hoặc ảnh đại diện.

Ứng dụng kiểm tra dữ liệu trước khi lưu thay đổi.

Màn hình hồ sơ hỗ trợ đổi mật khẩu và đăng xuất.

**Input**

Thông tin tài khoản hiện tại.

Thông tin người dùng muốn cập nhật.

Thao tác đổi mật khẩu hoặc đăng xuất.

**Output**

Thông tin hồ sơ được hiển thị.

Thông tin được cập nhật khi hợp lệ.

Người dùng đăng xuất khỏi ứng dụng nếu chọn Logout.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có hiển thị thông tin người dùng.

Có cập nhật thông tin hợp lệ.

Có kiểm tra dữ liệu trước khi lưu.

Có chức năng đổi mật khẩu hoặc đăng xuất.

Giao diện rõ ràng và dễ thao tác.

**Giao diện minh họa**

![Ho so ca nhan (Profile)](data:image/png;base64...)

## 14. Admin Dashboard

Admin Dashboard là khu vực dành cho Admin hoặc Nhân viên để quản lý hoạt động chính của MarineLink.

**Mục đích**

Giúp MarineLink theo dõi sản phẩm, đơn hàng, người dùng và các yêu cầu hỗ trợ trong một khu vực quản trị tập trung.

**Mô tả xử lý**

Admin xem tổng quan số lượng đơn hàng, doanh thu mẫu, sản phẩm và người dùng.

Admin hoặc Nhân viên quản lý sản phẩm, cập nhật tồn kho, xem đơn hàng mới và xử lý trạng thái đơn.

Khu vực quản trị hỗ trợ xem tin nhắn của đại lý và phản hồi khi cần.

Chỉ tài khoản có quyền phù hợp mới được vào màn hình này.

**Input**

Tài khoản Admin hoặc Nhân viên.

Dữ liệu sản phẩm, đơn hàng, người dùng và tin nhắn.

Thao tác thêm/sửa/xóa hoặc cập nhật trạng thái.

**Output**

Dashboard hiển thị số liệu tổng quan.

Danh sách sản phẩm, đơn hàng hoặc người dùng được quản lý.

Trạng thái đơn hàng hoặc thông tin sản phẩm được cập nhật.

Tiêu chí hoàn thành

Chức năng được hoàn thành khi đáp ứng các tiêu chí sau:

Có phân quyền vào dashboard.

Có hiển thị thông tin tổng quan.

Có quản lý sản phẩm hoặc đơn hàng.

Có cập nhật trạng thái đơn hàng.

Có giao diện phù hợp cho người quản trị.

**Giao diện minh họa**

![Admin Dashboard](data:image/png;base64...)

## 15. Quản lý trạng thái (State Management)

**State cần quản lý**

|  |  |
| --- | --- |
| **State cần quản lý** | **Mô tả** |
| Authentication State | Quản lý trạng thái đăng nhập, đăng xuất và vai trò người dùng. |
| Product State | Quản lý danh sách sản phẩm, chi tiết sản phẩm, tìm kiếm, danh mục, trạng thái tồn kho, sắp xếp và trạng thái tải dữ liệu. |
| Cart State | Quản lý sản phẩm trong giỏ hàng, số lượng và tổng tiền. |
| Order State | Quản lý quá trình tạo đơn, danh sách đơn hàng và trạng thái xử lý đơn. |
| Notification State | Quản lý thông báo mới, thông báo đã đọc và số lượng thông báo chưa đọc. |
| Chat State | Quản lý nội dung tin nhắn, lịch sử chat và trạng thái gửi tin nhắn. |
| Profile State | Quản lý thông tin tài khoản, địa chỉ và trạng thái cập nhật hồ sơ. |
| Admin State | Quản lý dữ liệu dashboard, sản phẩm, đơn hàng và người dùng trong khu vực quản trị. |

Trong buổi demo, nhóm cần chứng minh được luồng chính:

Đăng nhập → Xem trang chủ → Xem danh sách sản phẩm → Xem chi tiết → Thêm vào giỏ hàng → Checkout → Tạo đơn hàng → Theo dõi đơn hàng → Nhận thông báo hoặc chat hỗ trợ.

Dataset demo thật hiện có 21 sản phẩm đồ khô được seed bằng V010, ảnh lưu trong Supabase Storage bucket `product-images`, và 3 tài khoản demo được seed bằng V011.
