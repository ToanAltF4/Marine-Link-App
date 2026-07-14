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

Mô tả cấu trúc cơ sở dữ liệu và API phục vụ ứng dụng MarineLink (B2B đặt hải sản khô cho đại lý). Hệ thống dùng **REST API** kết nối Flutter frontend với backend **Spring Boot**, dữ liệu lưu trên **PostgreSQL (Supabase)**, schema quản lý bằng **Flyway** (30 migration: V001–V030). Realtime chat dùng thêm **WebSocket (STOMP)**.

**Quy ước chung của toàn bộ schema**

| | |
| --- | --- |
| **Hạng mục** | **Quy ước** |
| ID strategy | Mỗi bảng có `id` (bigint, khóa chính nội bộ) và `public_id` (UUID) — **chỉ `public_id` được lộ ra API**, tránh đoán ID tuần tự. |
| Xóa dữ liệu | **Soft delete** bằng cột `deleted_at` (sản phẩm, người dùng, địa chỉ) — dữ liệu lịch sử (đơn hàng) không bị mất. |
| Thời gian | `created_at`, `updated_at` kiểu `timestamptz` (UTC); frontend quy đổi sang giờ Việt Nam (GMT+7) khi hiển thị. |
| Kiểu liệt kê | 8 ENUM ở tầng DB: `user_status`, `product_status`, `order_status`, `payment_status`, `payment_method`, `notification_type`, `chat_sender_type`, `complaint_status`. |
| Xác thực | **JWT Bearer token** gửi kèm header `Authorization` ở mọi request cần đăng nhập. |

**Ánh xạ nhóm dữ liệu yêu cầu sang bảng thực tế của MarineLink**

| | |
| --- | --- |
| **Nhóm dữ liệu** | **Bảng trong hệ thống** |
| User / Customer | `users`, `roles`, `shipping_addresses`, `email_otp` |
| Product | `products`, `product_images`, `price_tiers` |
| Category / Brand | `categories` (có `parent_id` → danh mục phân cấp) |
| Cart | `carts`, `cart_items` |
| Order | `orders`, `order_items`, `order_status_history`, `payments`, `payment_methods` |
| Notification | `notifications` (gom nhóm broadcast qua `broadcast_id`) |
| Store Location | `warehouses` |
| Message / Chat | `chat_rooms`, `chat_messages`, `chat_attachments`, `complaints` |

**Các bảng dữ liệu (21 bảng)**

| | | | |
| --- | --- | --- | --- |
| **Bảng** | **Mô tả** | **Cột chính** | **Liên kết / Quan hệ** |
| roles | Vai trò hệ thống: ADMIN, STAFF, USER. | `code`, `name`, `is_system` | 1-n `users` |
| users | Tài khoản người dùng (đại lý, nhân viên, quản trị). Lưu thông tin doanh nghiệp của đại lý. | `full_name`, `email`, `phone`, `password_hash`, `status`, `store_name`, `business_address`, `tax_code`, `avatar_url`, `role_id` (FK) | n-1 `roles`; 1-n `orders`, `carts`, `chat_rooms`, `notifications`, `shipping_addresses` |
| email_otp | Mã OTP 6 số gửi qua email (xác thực đăng ký, quên mật khẩu). | `email`, `otp_code`, `expires_at`, `used` | Độc lập, đối chiếu theo `email` |
| shipping_addresses | Sổ địa chỉ giao hàng của đại lý. | `label`, `receiver_name`, `receiver_phone`, `address_line`, `is_default`, `user_id` (FK) | n-1 `users` |
| categories | Danh mục sản phẩm, **có phân cấp** qua `parent_id`. | `name`, `slug`, `display_order`, `is_active`, `parent_id` (FK tự trỏ) | Tự tham chiếu (cha–con); 1-n `products` |
| products | Sản phẩm hải sản khô/nước mắm. | `name`, `slug`, `description`, `origin`, `image_url`, `base_price`, `unit`, `min_order_quantity`, `stock_quantity`, `status`, `is_featured`, `category_id` (FK) | n-1 `categories`; 1-n `product_images`, `price_tiers`, `cart_items`, `order_items` |
| product_images | Ảnh phụ (gallery) của sản phẩm. | `image_url`, `alt_text`, `display_order`, `product_id` (FK) | n-1 `products` |
| price_tiers | Bậc giá sỉ theo số lượng của **từng sản phẩm**. | `min_quantity`, `max_quantity`, `unit_price`, `product_id` (FK) | n-1 `products`; 1-n `cart_items` |
| carts | Giỏ hàng đang hoạt động của đại lý (mỗi user 1 giỏ). | `user_id` (FK, unique) | 1-1 `users`; 1-n `cart_items` |
| cart_items | Dòng sản phẩm trong giỏ, ghi nhớ bậc giá đã chọn. | `quantity`, `is_selected`, `cart_id` (FK), `product_id` (FK), `price_tier_id` (FK, ON DELETE SET NULL) | n-1 `carts`, `products`, `price_tiers` |
| orders | Đơn hàng sỉ. Lưu mốc thời gian từng trạng thái. | `order_code`, `status`, `payment_status`, `subtotal_amount`, `discount_amount`, `shipping_fee`, `total_amount`, `receiver_name`, `receiver_phone`, `shipping_address`, `confirmed_at`, `shipped_at`, `completed_at`, `cancelled_at`, `user_id` (FK), `payment_method_id` (FK) | n-1 `users`, `payment_methods`; 1-n `order_items`, `order_status_history`, `payments` |
| order_items | Chi tiết đơn — **snapshot** tên/giá tại thời điểm đặt (không đổi khi sản phẩm bị sửa sau này). | `product_name_snapshot`, `product_unit_snapshot`, `unit_price`, `quantity`, `line_total`, `order_id` (FK), `product_id` (FK) | n-1 `orders`, `products` |
| order_status_history | Nhật ký chuyển trạng thái đơn (ai đổi, khi nào, ghi chú). | `from_status`, `to_status`, `note`, `order_id` (FK), `changed_by` (FK users) | n-1 `orders`, `users` |
| payment_methods | Danh mục phương thức thanh toán: COD, VNPAY, BANK_TRANSFER. | `code`, `name`, `is_active` | 1-n `orders`, `payments` |
| payments | Giao dịch thanh toán của đơn (đặc biệt cho VNPAY). | `amount`, `status`, `txn_ref`, `transaction_code`, `bank_code`, `response_code`, `raw_response`, `order_id` (FK), `payment_method_id` (FK) | n-1 `orders`, `payment_methods` |
| notifications | Thông báo in-app/push cho từng người dùng. Thông báo phát cho toàn bộ đại lý (broadcast) được nhân bản mỗi user 1 dòng, gom nhóm qua `broadcast_id`. | `type`, `title`, `body`, `is_read`, `broadcast_id`, `user_id` (FK), `related_order_id` (FK), `related_product_id` (FK), `related_chat_room_id` | n-1 `users`; tham chiếu tùy chọn tới `orders`, `products`, `chat_rooms` |
| warehouses | Kho hàng / điểm nhận hàng, có **tọa độ** để hiển thị bản đồ. | `name`, `address`, `phone`, `opening_hours`, `latitude`, `longitude` (numeric(10,7)), `is_active` | Độc lập; dùng cho màn Bản đồ kho |
| chat_rooms | Phòng chat giữa đại lý và nhân viên; có thể gắn với 1 đơn hàng. | `status` (OPEN/CLOSED), `user_id` (FK), `assigned_staff_id` (FK users), `order_id` (FK) | n-1 `users` (đại lý), `users` (staff), `orders`; 1-n `chat_messages` |
| chat_messages | Tin nhắn trong phòng chat. | `sender_type`, `content`, `is_read`, `chat_room_id` (FK), `sender_id` (FK users) | n-1 `chat_rooms`, `users`; 1-n `chat_attachments` |
| chat_attachments | File/ảnh đính kèm tin nhắn (URL lưu trên Supabase Storage). | `file_url`, `file_name`, `file_type`, `chat_message_id` (FK), `uploaded_by` (FK users) | n-1 `chat_messages`, `users` |
| complaints | Khiếu nại của đại lý, phát sinh từ đơn hàng hoặc tin nhắn chat. | `title`, `content`, `status`, `user_id` (FK), `order_id` (FK), `chat_room_id` (FK), `chat_message_id` (FK) | n-1 `users`, `orders`, `chat_rooms`, `chat_messages` |

**Sơ đồ quan hệ (ERD rút gọn)**

```
roles ──1:n──> users ──1:1──> carts ──1:n──> cart_items ──n:1──> products
                 │                               └──n:1──> price_tiers
                 ├──1:n──> shipping_addresses
                 ├──1:n──> orders ──1:n──> order_items ──n:1──> products
                 │            ├──1:n──> order_status_history
                 │            ├──1:n──> payments ──n:1──> payment_methods
                 │            └──n:1──> payment_methods
                 ├──1:n──> notifications ──(tùy chọn)──> orders / products / chat_rooms
                 ├──1:n──> chat_rooms ──1:n──> chat_messages ──1:n──> chat_attachments
                 └──1:n──> complaints ──(nguồn)──> orders / chat_messages

categories ──tự tham chiếu (parent_id)──> categories
categories ──1:n──> products ──1:n──> product_images
                             └──1:n──> price_tiers

warehouses  (bảng độc lập — dữ liệu cho bản đồ)
email_otp   (bảng độc lập — đối chiếu theo email)
```

**Quan hệ giữa các bảng**

| | | | |
| --- | --- | --- | --- |
| **Bảng nguồn** | **Quan hệ** | **Bảng đích** | **Ý nghĩa** |
| roles | 1-n | users | Một vai trò gán cho nhiều người dùng. |
| users | 1-1 | carts | Mỗi đại lý có một giỏ hàng đang hoạt động. |
| users | 1-n | shipping_addresses | Một đại lý lưu nhiều địa chỉ giao hàng. |
| users | 1-n | orders | Một đại lý tạo nhiều đơn hàng. |
| users | 1-n | notifications | Mỗi người dùng nhận nhiều thông báo. |
| categories | 1-n | categories | Danh mục cha chứa nhiều danh mục con (`parent_id`). |
| categories | 1-n | products | Một danh mục có nhiều sản phẩm. |
| products | 1-n | product_images | Một sản phẩm có nhiều ảnh. |
| products | 1-n | price_tiers | Một sản phẩm có nhiều bậc giá sỉ theo số lượng. |
| carts | 1-n | cart_items | Một giỏ hàng gồm nhiều dòng sản phẩm. |
| price_tiers | 1-n | cart_items | Bậc giá được chọn cho dòng giỏ hàng (xóa bậc giá → `price_tier_id` về NULL, giỏ hàng không hỏng). |
| orders | 1-n | order_items | Một đơn gồm nhiều dòng sản phẩm (snapshot giá). |
| orders | 1-n | order_status_history | Một đơn có nhiều lần đổi trạng thái. |
| orders | 1-n | payments | Một đơn có thể có nhiều lần giao dịch thanh toán (retry VNPAY). |
| payment_methods | 1-n | orders / payments | Một phương thức dùng cho nhiều đơn/giao dịch. |
| chat_rooms | 1-n | chat_messages | Một phòng chat có nhiều tin nhắn. |
| chat_messages | 1-n | chat_attachments | Một tin nhắn có thể kèm nhiều file. |
| orders / chat_messages | 1-n | complaints | Khiếu nại phát sinh từ đơn hàng hoặc tin nhắn. |

**API endpoints (REST — 64 endpoint)**

*Xác thực & tài khoản*

| | | | |
| --- | --- | --- | --- |
| **Phương thức** | **Endpoint** | **Mô tả** | **Phân quyền** |
| POST | /api/auth/register | Đăng ký đại lý, gửi OTP về email, trạng thái PENDING_VERIFICATION. | Công khai |
| POST | /api/auth/verify-email | Xác thực OTP → chuyển sang PENDING_APPROVAL (chờ admin duyệt). | Công khai |
| POST | /api/auth/resend-otp | Gửi lại mã OTP. | Công khai |
| POST | /api/auth/login | Đăng nhập, trả JWT + thông tin user/role. | Công khai |
| POST | /api/auth/google | Đăng nhập bằng Google (xác thực idToken, kiểm tra audience). | Công khai |
| POST | /api/auth/forgot-password | Gửi OTP đặt lại mật khẩu về email. | Công khai |
| POST | /api/auth/reset-password | Đặt lại mật khẩu bằng OTP. | Công khai |
| POST | /api/auth/change-password | Đổi mật khẩu (biết mật khẩu cũ). | Đã đăng nhập |
| POST | /api/auth/logout | Đăng xuất (client xóa token). | Đã đăng nhập |
| GET | /api/auth/email-availability | Kiểm tra email đã tồn tại (validate realtime lúc đăng ký). | Công khai |
| GET | /api/auth/phone-availability | Kiểm tra số điện thoại đã tồn tại. | Công khai |
| GET / PUT | /api/users/me | Xem / cập nhật hồ sơ cá nhân. | Đã đăng nhập |
| GET / POST | /api/users/me/shipping-addresses | Xem / thêm địa chỉ giao hàng. | Đại lý |
| PUT / DELETE | /api/users/me/shipping-addresses/{id} | Sửa / xóa địa chỉ giao hàng. | Đại lý |

*Sản phẩm & danh mục*

| | | | |
| --- | --- | --- | --- |
| **Phương thức** | **Endpoint** | **Mô tả** | **Phân quyền** |
| GET | /api/products | Danh sách sản phẩm: tìm kiếm, lọc danh mục/trạng thái, phân trang. | Tất cả role |
| GET | /api/products/{id} | Chi tiết sản phẩm + ảnh + bậc giá sỉ. | Tất cả role |
| GET | /api/products/categories | Cây danh mục (cha–con). | Tất cả role |

*Giỏ hàng*

| | | | |
| --- | --- | --- | --- |
| **Phương thức** | **Endpoint** | **Mô tả** | **Phân quyền** |
| GET | /api/cart | Lấy giỏ hàng hiện tại (server là nguồn dữ liệu chính). | Đại lý |
| POST | /api/cart/items | Thêm / cộng dồn sản phẩm vào giỏ. | Đại lý |
| PATCH | /api/cart/items/{productId} | Cập nhật số lượng hoặc trạng thái chọn của một dòng. | Đại lý |
| DELETE | /api/cart/items/{productId} | Xóa một sản phẩm khỏi giỏ. | Đại lý |
| DELETE | /api/cart/items | Xóa toàn bộ giỏ hàng. | Đại lý |
| POST | /api/cart/sync | Gộp giỏ hàng local (thao tác khi chưa đăng nhập) lên server. | Đại lý |

*Đơn hàng & thanh toán*

| | | | |
| --- | --- | --- | --- |
| **Phương thức** | **Endpoint** | **Mô tả** | **Phân quyền** |
| POST | /api/orders | Tạo đơn từ giỏ hàng (tính bậc giá + chiết khấu số lượng, sinh mã đơn). | Đại lý |
| GET | /api/orders | Danh sách đơn theo role (đại lý chỉ thấy đơn của mình). | Đại lý, Staff, Admin |
| GET | /api/orders/{id} | Chi tiết đơn: items, thanh toán, lịch sử trạng thái. | Chủ đơn, Staff, Admin |
| PUT | /api/orders/{id}/status | Đổi trạng thái đơn; **duyệt đơn (CONFIRMED) sẽ trừ tồn kho**; ghi lịch sử; gửi thông báo. | Staff, Admin |
| PUT | /api/orders/{id}/payment-status | Cập nhật trạng thái thanh toán của đơn. | Staff, Admin |
| POST | /api/payments/vnpay/payment-url | Sinh link thanh toán VNPAY đã ký (HMAC-SHA512) cho đơn. | Đại lý |
| POST | /api/payments/vnpay/cancel | Hủy giao dịch VNPAY đang chờ. | Đại lý |
| GET | /api/payments/vnpay/return | VNPAY chuyển hướng về sau thanh toán; verify chữ ký, cập nhật đơn. | Công khai (VNPAY gọi) |
| GET | /api/payments/vnpay/ipn | VNPAY gọi server-to-server xác nhận kết quả. | Công khai (VNPAY gọi) |

*Chat & khiếu nại*

| | | | |
| --- | --- | --- | --- |
| **Phương thức** | **Endpoint** | **Mô tả** | **Phân quyền** |
| GET | /api/chat/rooms | Danh sách phòng chat của người dùng. | Đại lý |
| POST | /api/chat/rooms | Tạo phòng chat mới. | Đại lý |
| GET | /api/chat/room | Lấy/khởi tạo phòng chat hỗ trợ chung. | Đại lý |
| GET | /api/chat/orders/{orderId}/room | Phòng chat gắn với một đơn hàng. | Chủ đơn, Staff |
| GET | /api/chat/{roomId} | Lịch sử tin nhắn của phòng. | Thành viên phòng, Staff, Admin |
| POST | /api/chat/send | Gửi tin nhắn (đẩy realtime qua WebSocket). | Tất cả role |
| GET | /api/staff/chat/rooms | Danh sách phòng chat cần xử lý. | Staff, Admin |
| PUT | /api/staff/chat/rooms/{roomId}/status | Đánh dấu phòng đã xử lý / mở lại. | Staff, Admin |
| POST | /api/staff/chat/rooms/{roomId}/complaints | Tạo khiếu nại từ phòng chat. | Staff, Admin |

*Thông báo, kho hàng, lưu trữ*

| | | | |
| --- | --- | --- | --- |
| **Phương thức** | **Endpoint** | **Mô tả** | **Phân quyền** |
| GET | /api/notifications | Thông báo của người dùng đang đăng nhập. | Đã đăng nhập |
| PUT | /api/notifications/{id}/read | Đánh dấu đã đọc. | Chủ thông báo |
| POST | /api/notifications | Gửi thông báo hàng loạt tới toàn bộ đại lý (kèm push OneSignal). | Staff, Admin |
| GET | /api/notifications/broadcasts | Lịch sử thông báo đã gửi. | Staff, Admin |
| DELETE | /api/notifications/broadcasts/{broadcastId} | Thu hồi/xóa một broadcast. | Staff, Admin |
| GET | /api/warehouses | Danh sách kho kèm tọa độ (cho bản đồ). | Tất cả role |
| POST | /api/storage/upload | Upload ảnh (multipart) lên Supabase Storage, trả về URL công khai. | Đã đăng nhập |
| GET | /api/health | Kiểm tra tình trạng server. | Công khai |

*Quản trị (Admin)*

| | | | |
| --- | --- | --- | --- |
| **Phương thức** | **Endpoint** | **Mô tả** | **Phân quyền** |
| GET | /api/admin/dashboard | Số liệu tổng quan (doanh thu tháng, đơn chờ, tồn kho thấp, số đại lý). | Admin |
| GET | /api/admin/revenue | Báo cáo doanh thu theo khoảng ngày + top sản phẩm bán chạy. | Admin |
| GET / POST | /api/admin/products | Danh sách / tạo sản phẩm. | Admin |
| GET / PUT / DELETE | /api/admin/products/{id} | Chi tiết / sửa / xóa mềm sản phẩm (kèm bậc giá). | Admin |
| GET / POST | /api/admin/users | Danh sách / **tạo tài khoản nhân viên** (kích hoạt sẵn). | Admin |
| GET / PUT | /api/admin/users/{id} | Chi tiết / cập nhật (duyệt, khóa/mở khóa) tài khoản. | Admin |
| PUT | /api/admin/users/{id}/role | Đổi vai trò người dùng. | Admin |

**Kênh realtime (WebSocket)**

| | |
| --- | --- |
| **Thành phần** | **Mô tả** |
| Handshake | `/ws` (STOMP over WebSocket). |
| Kênh nhận tin | `/topic/chat.{roomPublicId}` — client subscribe để nhận tin nhắn mới ngay lập tức. |
| Cách dùng | Tin nhắn vẫn **gửi qua REST** (`POST /api/chat/send`) để đảm bảo lưu DB; server đẩy bản sao qua WebSocket cho các thành viên đang mở phòng. |

**Cách ứng dụng đọc, ghi, cập nhật và xóa dữ liệu**

| | |
| --- | --- |
| **Bước** | **Mô tả** |
| 1. Tầng giao diện | Màn hình (Screen) chỉ hiển thị; mọi thao tác phát sự kiện tới **Bloc/Cubit** tương ứng. |
| 2. Tầng nghiệp vụ | Bloc/Cubit gọi **Repository** (interface trong `domain/`). |
| 3. Tầng dữ liệu | Repository có 2 bản cài đặt: **RemoteRepository** (gọi REST API thật) và **MockRepository** (dữ liệu giả, chạy offline khi demo). Chọn bản nào do cờ `USE_REMOTE_REPOSITORIES` lúc build. |
| 4. Gọi HTTP | `ApiClient` (dựa trên **Dio**) tự đính kèm `Authorization: Bearer <JWT>`, xử lý timeout và chuyển lỗi backend thành thông báo tiếng Việt. |
| 5. Chuyển đổi dữ liệu | **DTO** (`data/*_dto.dart`) parse JSON → **Entity** (`domain/`) để tầng giao diện không phụ thuộc định dạng API. |
| 6. Phản hồi | Repository trả `ApiResponse<T>` (`success`, `message`, `data`); Bloc/Cubit đổi trạng thái → giao diện vẽ lại. |

Quy ước thao tác dữ liệu:

* **Đọc (Read)** — `GET`, ví dụ `GET /api/products`, `GET /api/orders`. Danh sách dài dùng phân trang (`page`, `size`).
* **Ghi (Create)** — `POST`, ví dụ `POST /api/orders` (đặt hàng), `POST /api/cart/items` (thêm giỏ).
* **Cập nhật (Update)** — `PUT` khi thay toàn bộ (`PUT /api/admin/products/{id}`), `PATCH` khi sửa một phần (`PATCH /api/cart/items/{productId}`).
* **Xóa (Delete)** — `DELETE`. Sản phẩm/người dùng dùng **xóa mềm** (`deleted_at`) để không phá vỡ đơn hàng đã phát sinh; dòng giỏ hàng thì xóa thật.
* **Giao dịch (Transaction)** — các thao tác nhiều bước (tạo đơn, duyệt đơn + trừ tồn kho, sửa bậc giá) chạy trong **một transaction** ở backend; gửi email/push chạy **nền (@Async)** nên không làm chậm request.

**CRUD / API theo từng màn hình**

| | | | |
| --- | --- | --- | --- |
| **Màn hình** | **Đọc (Read)** | **Ghi / Cập nhật / Xóa** | **Dữ liệu sử dụng** |
| Đăng nhập | — | POST /api/auth/login, POST /api/auth/google | users, roles, JWT |
| Đăng ký | GET /api/auth/email-availability, /phone-availability | POST /api/auth/register | users, roles, email_otp |
| Nhập OTP | — | POST /api/auth/verify-email, POST /api/auth/resend-otp | email_otp, users |
| Quên mật khẩu | — | POST /api/auth/forgot-password | email_otp, users |
| Đặt lại mật khẩu | — | POST /api/auth/reset-password | email_otp, users |
| Đổi mật khẩu | — | POST /api/auth/change-password | users |
| Trang chủ | GET /api/products (nổi bật), GET /api/products/categories | — | products, categories, price_tiers |
| Danh sách sản phẩm | GET /api/products (tìm kiếm, lọc, phân trang) | — | products, categories, price_tiers |
| Chi tiết sản phẩm | GET /api/products/{id} | POST /api/cart/items | products, product_images, price_tiers, cart_items |
| Giỏ hàng | GET /api/cart | PATCH/DELETE /api/cart/items, POST /api/cart/sync | carts, cart_items, products, price_tiers |
| Thanh toán (Checkout) | GET /api/users/me/shipping-addresses | POST /api/orders, POST /api/payments/vnpay/payment-url | orders, order_items, payments, payment_methods, shipping_addresses |
| Kết quả VNPAY | GET /api/orders/{id} | POST /api/payments/vnpay/cancel | orders, payments |
| Danh sách đơn hàng | GET /api/orders | — | orders, order_items |
| Chi tiết đơn hàng | GET /api/orders/{id} | PUT /api/orders/{id}/status *(Staff/Admin)* | orders, order_items, order_status_history, payments |
| Chat (đại lý) | GET /api/chat/rooms, GET /api/chat/{roomId}, WebSocket `/topic/chat.{id}` | POST /api/chat/send, POST /api/chat/rooms | chat_rooms, chat_messages, chat_attachments |
| Quản lý chat (Staff) | GET /api/staff/chat/rooms, GET /api/chat/{roomId} | POST /api/chat/send, PUT /api/staff/chat/rooms/{id}/status, POST .../complaints | chat_rooms, chat_messages, complaints |
| Thông báo | GET /api/notifications, GET /api/notifications/broadcasts | PUT /api/notifications/{id}/read, POST /api/notifications, DELETE /api/notifications/broadcasts/{id} | notifications |
| Bản đồ kho hàng | GET /api/warehouses | — *(mở Google Maps chỉ đường bằng tọa độ)* | warehouses |
| Hồ sơ cá nhân | GET /api/users/me, GET /api/users/me/shipping-addresses | PUT /api/users/me, POST/PUT/DELETE địa chỉ, POST /api/auth/logout | users, roles, shipping_addresses |
| Dashboard Admin | GET /api/admin/dashboard | — | orders, products, users |
| Doanh thu (Admin) | GET /api/admin/revenue | — | orders, order_items, products |
| Quản lý sản phẩm (Admin) | GET /api/admin/products, GET /api/admin/products/{id}, GET /api/products/categories | POST/PUT/DELETE /api/admin/products, POST /api/storage/upload | products, product_images, price_tiers, categories |
| Quản lý tài khoản (Admin) | GET /api/admin/users, GET /api/admin/users/{id} | POST /api/admin/users, PUT /api/admin/users/{id}, PUT .../role | users, roles |
| Dashboard Staff | GET /api/orders, GET /api/staff/chat/rooms | PUT /api/orders/{id}/status | orders, chat_rooms |

**Phân quyền**

Ba vai trò: **Admin** (toàn quyền: sản phẩm, tài khoản, doanh thu, thông báo), **Staff** (xử lý đơn, chat, khiếu nại), **User/Đại lý** (xem sản phẩm, đặt hàng, chat, theo dõi đơn). Vai trò gắn với `users.role_id`; backend chặn ở tầng `SecurityConfig` (theo đường dẫn) và frontend chặn bằng route guard (`AdminRoleGuard`, `StaffRoleGuard`).

Trạng thái tài khoản quyết định quyền xem giá: đại lý ở trạng thái `PENDING_APPROVAL` **đăng nhập và xem sản phẩm được nhưng không thấy giá và không đặt hàng được**, cho tới khi Admin duyệt (`ACTIVE`).

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
