# MarineLink Implementation Task Breakdown

Nguồn: `MarineLink_Main_Functions_Specification_v2.docx`

Mục tiêu của file này là chia phạm vi triển khai MarineLink thành các task rõ ràng cho:

- Frontend: Flutter
- Backend: Spring Boot, Maven, Java 21
- Database: Supabase PostgreSQL

## 1. Kiến trúc triển khai

MarineLink dùng mô hình client-server:

- Flutter app gọi REST API từ Spring Boot backend.
- Spring Boot xử lý authentication, phân quyền, business logic, validation và kết nối Supabase PostgreSQL.
- Supabase đóng vai trò database chính, lưu dữ liệu users, products, orders, chat, notifications và warehouses.
- Flutter không truy cập trực tiếp bảng Supabase cho các dữ liệu cần phân quyền; app đi qua backend để đảm bảo kiểm soát role Admin, Staff và Đại lý.

## 2. Chuẩn kỹ thuật

### Frontend Flutter

- State management: Bloc/Cubit hoặc Provider theo phạm vi nhóm chọn, ưu tiên tách state khỏi UI.
- Navigation: route guard theo trạng thái đăng nhập và role.
- Networking: Dio hoặc HTTP client có interceptor token.
- Local storage: lưu token và giỏ hàng offline trước khi sync.
- UI: bám theo các màn hình demo trong file specification.

### Backend Spring Boot

- Java: 21
- Build tool: Maven
- Runtime: Spring Boot 3.x
- Modules chính:
  - Spring Web
  - Spring Validation
  - Spring Security
  - Spring Data JPA
  - PostgreSQL Driver
  - Flyway hoặc Liquibase cho migration
  - Lombok hoặc Java records tùy chuẩn code của nhóm
- Command chuẩn:
  - `mvn clean verify`
  - `mvn spring-boot:run`

### Database Supabase

- Database engine: PostgreSQL.
- Schema change phải đi qua migration SQL, không sửa tay trên production.
- Dùng UUID cho khóa chính nếu nhóm muốn dễ tích hợp Supabase/Auth về sau.
- Dùng enum hoặc check constraint cho role, order status, notification type.

## 3. Milestone triển khai

| Milestone | Mục tiêu | Kết quả cần có |
|---|---|---|
| M1 | Khởi tạo nền tảng | Supabase schema, Spring Boot project, Flutter project, env config |
| M2 | Auth + Product Catalog | Login/register, danh mục, danh sách sản phẩm, chi tiết sản phẩm |
| M3 | Cart + Checkout + Orders | Giỏ hàng local/sync, tạo đơn, xem trạng thái đơn |
| M4 | Messaging + Notifications + Map + Profile | Chat, thông báo, bản đồ kho, hồ sơ cá nhân |
| M5 | Admin Dashboard + QA | Quản trị sản phẩm, user, đơn hàng, dashboard, demo flow hoàn chỉnh |

## 4. Database Tasks - Supabase PostgreSQL

### DB-01: Tạo Supabase project và môi trường cấu hình

Checklist:

- [ ] Tạo Supabase project cho MarineLink.
- [ ] Lưu `SUPABASE_DB_URL`, `SUPABASE_DB_USER`, `SUPABASE_DB_PASSWORD` vào `.env` hoặc biến môi trường backend.
- [ ] Tạo database connection profile cho local development.
- [ ] Quy định naming convention: table snake_case, column snake_case.

Done:

- Backend Spring Boot kết nối được Supabase PostgreSQL.
- Không hardcode password trong source code.

### DB-02: Tạo schema người dùng và phân quyền

Tables:

- `users`

Fields chính:

- `user_id`
- `full_name`
- `email`
- `phone`
- `password_hash`
- `role`: `ADMIN`, `STAFF`, `DEALER`
- `status`: `PENDING`, `ACTIVE`, `BLOCKED`
- `avatar_url`
- `business_name`
- `business_address`
- `tax_code`
- `created_at`
- `updated_at`

Checklist:

- [ ] Tạo table `users`.
- [ ] Thêm unique constraint cho email và phone.
- [ ] Thêm index cho `role`, `status`.
- [ ] Seed tài khoản Admin đầu tiên.

Done:

- Đăng ký đại lý không trùng email/số điện thoại.
- Login phân biệt được Admin, Staff và Đại lý.

### DB-03: Tạo schema danh mục và sản phẩm

Tables:

- `categories`
- `products`
- `price_tiers`

Fields chính:

- `categories`: `category_id`, `name`, `description`, `icon_url`, `is_active`
- `products`: `product_id`, `category_id`, `name`, `origin`, `description`, `image_url`, `base_price`, `stock_quantity`, `min_order_quantity`, `status`
- `price_tiers`: `tier_id`, `product_id`, `min_quantity`, `max_quantity`, `price`, `discount_percent`

Checklist:

- [ ] Tạo quan hệ `categories 1-n products`.
- [ ] Tạo quan hệ `products 1-n price_tiers`.
- [ ] Seed danh mục: Mực khô, Tôm khô, Cá khô, Nước mắm.
- [ ] Seed sản phẩm mẫu đủ cho Home, Product List, Product Detail.

Done:

- Product List đọc được sản phẩm theo category.
- Product Detail đọc được giá sỉ theo số lượng.

### DB-04: Tạo schema giỏ hàng và đơn hàng

Tables:

- `cart_items`
- `orders`
- `order_items`

Fields chính:

- `cart_items`: `cart_item_id`, `user_id`, `product_id`, `quantity`, `unit_price`, `created_at`, `updated_at`
- `orders`: `order_id`, `user_id`, `recipient_name`, `recipient_phone`, `shipping_address`, `payment_method`, `status`, `total_amount`, `note`, `created_at`, `updated_at`
- `order_items`: `item_id`, `order_id`, `product_id`, `quantity`, `unit_price`, `line_total`

Order status:

- `PENDING`
- `APPROVED`
- `SHIPPING`
- `COMPLETED`
- `CANCELLED`

Checklist:

- [ ] Tạo quan hệ `users 1-n orders`.
- [ ] Tạo quan hệ `orders 1-n order_items`.
- [ ] Tạo quan hệ `products 1-n order_items`.
- [ ] Thêm index theo `orders.user_id`, `orders.status`, `orders.created_at`.

Done:

- Checkout tạo được `orders` và `order_items`.
- Orders screen lọc được theo trạng thái.
- Staff/Admin cập nhật được trạng thái đơn hàng.

### DB-05: Tạo schema chat, khiếu nại và thông báo

Tables:

- `chat_messages`
- `complaints`
- `notifications`

Fields chính:

- `chat_messages`: `message_id`, `room_id`, `user_id`, `sender_role`, `message_type`, `content`, `attachment_url`, `created_at`
- `complaints`: `complaint_id`, `user_id`, `order_id`, `message_id`, `title`, `description`, `status`, `assigned_staff_id`, `created_at`, `updated_at`
- `notifications`: `notif_id`, `user_id`, `title`, `content`, `type`, `target_type`, `target_id`, `is_read`, `created_at`

Checklist:

- [ ] Tạo quan hệ `users 1-n chat_messages`.
- [ ] Tạo quan hệ `orders 1-n complaints`.
- [ ] Tạo quan hệ `users 1-n notifications`.
- [ ] Thêm index cho `notifications.user_id`, `notifications.is_read`.

Done:

- Chat lưu lịch sử tin nhắn.
- Thông báo hiển thị theo user.
- Khi đổi trạng thái đơn, hệ thống tạo notification cho đại lý.

### DB-06: Tạo schema kho hàng và bản đồ

Tables:

- `warehouses`

Fields chính:

- `warehouse_id`
- `name`
- `address`
- `phone`
- `opening_hours`
- `latitude`
- `longitude`
- `is_active`

Checklist:

- [ ] Tạo table `warehouses`.
- [ ] Seed ít nhất 2 kho/điểm lấy hàng.
- [ ] Thêm index cho `is_active`.

Done:

- Map screen lấy được danh sách kho.
- Marker hiển thị đúng tọa độ.

### DB-07: Migration, seed và rollback

Checklist:

- [ ] Tạo migration `V1__init_schema.sql`.
- [ ] Tạo migration `V2__seed_master_data.sql`.
- [ ] Tách schema migration và seed data rõ ràng.
- [ ] Viết rollback hoặc forward-fix note cho từng migration quan trọng.

Done:

- Chạy lại database từ đầu vẫn tạo được schema và dữ liệu demo.
- Backend test chạy được trên database clean.

## 5. Backend Tasks - Spring Boot, Maven, Java 21

### BE-01: Khởi tạo Spring Boot project

Checklist:

- [ ] Tạo project Maven với Java 21.
- [ ] Thêm dependencies: Web, Validation, Security, Data JPA, PostgreSQL, Flyway/Liquibase.
- [ ] Tạo package theo domain: `auth`, `users`, `products`, `orders`, `chat`, `notifications`, `warehouses`, `admin`.
- [ ] Tạo profile `local`, `dev`, `prod`.
- [ ] Cấu hình Maven wrapper nếu cần.

Done:

- `mvn clean verify` chạy thành công.
- `mvn spring-boot:run` khởi động được app.

### BE-02: Cấu hình kết nối Supabase PostgreSQL

Checklist:

- [ ] Cấu hình `spring.datasource.url`.
- [ ] Cấu hình username/password từ environment variable.
- [ ] Cấu hình JPA naming strategy.
- [ ] Cấu hình migration tool chạy khi startup local.
- [ ] Tạo health check `/api/health`.

Done:

- Backend connect được Supabase.
- `/api/health` trả trạng thái OK.

### BE-03: Chuẩn hóa response, error và validation

Checklist:

- [ ] Tạo response envelope thống nhất: `success`, `data`, `message`, `error`, `pagination`.
- [ ] Tạo `GlobalExceptionHandler`.
- [ ] Tạo validation DTO cho request.
- [ ] Chuẩn hóa lỗi 400, 401, 403, 404, 500.

Done:

- API trả lỗi rõ ràng, không lộ stacktrace.
- Request invalid được trả lỗi theo field.

### BE-04: Authentication và Authorization

Endpoints:

- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/logout`

Checklist:

- [ ] Tạo entity/repository/service cho `users`.
- [ ] Hash password trước khi lưu.
- [ ] Implement login bằng email hoặc số điện thoại.
- [ ] Generate JWT có `user_id`, `role`.
- [ ] Implement role guard cho `ADMIN`, `STAFF`, `DEALER`.
- [ ] Register đại lý với trạng thái chờ duyệt hoặc active theo rule của nhóm.

Done:

- Login đúng role trả token hợp lệ.
- Endpoint cần quyền chặn request thiếu token.
- Đại lý không truy cập được Admin API.

### BE-05: Product Catalog API

Endpoints:

- `GET /api/products`
- `GET /api/products/:id`
- `CRUD /api/admin/products`

Checklist:

- [ ] Tạo entity `Category`, `Product`, `PriceTier`.
- [ ] Implement list product theo category, keyword, price range, stock status.
- [ ] Implement product detail kèm price tiers.
- [ ] Admin tạo/sửa/xóa hoặc ẩn sản phẩm.
- [ ] Thêm pagination cho danh sách sản phẩm.

Done:

- Product List lấy được dữ liệu cho Home và Product List.
- Product Detail có đủ thông tin giá, tồn kho, MOQ.

### BE-06: Cart Sync API

Endpoint:

- `POST /api/cart/sync`

Checklist:

- [ ] Nhận danh sách cart item từ Flutter local storage.
- [ ] Validate product tồn tại, còn hàng, quantity đạt MOQ.
- [ ] Tính lại giá server-side theo `price_tiers`.
- [ ] Lưu cart vào `cart_items`.
- [ ] Trả lại cart đã chuẩn hóa cho Flutter.

Done:

- Không tin tổng tiền do client gửi lên.
- Cart sync trả đúng quantity, price và total.

### BE-07: Checkout và Orders API

Endpoints:

- `POST /api/orders`
- `GET /api/orders`
- `PUT /api/orders/:id/status`

Checklist:

- [ ] Tạo order từ cart hoặc request checkout.
- [ ] Validate địa chỉ giao hàng, payment method, quantity, stock.
- [ ] Tạo `orders` và `order_items` trong transaction.
- [ ] Cập nhật trạng thái đơn cho Staff/Admin.
- [ ] Tạo notification khi đơn được tạo hoặc đổi trạng thái.
- [ ] Cho Đại lý chỉ xem đơn của mình.
- [ ] Cho Staff/Admin xem đơn theo role.

Done:

- Checkout tạo đơn thành công.
- Orders screen xem và lọc đơn theo trạng thái.
- Admin/Staff cập nhật trạng thái đơn.

### BE-08: Notifications API

Endpoints:

- `GET /api/notifications`
- `PUT /api/notifications/:id/read`

Checklist:

- [ ] Lấy thông báo theo user đăng nhập.
- [ ] Sort theo thời gian mới nhất.
- [ ] Đếm số notification chưa đọc.
- [ ] Mark as read một thông báo.
- [ ] Tạo notification từ order events.

Done:

- Notification screen hiển thị đúng thông báo của user.
- Người dùng đánh dấu đã đọc được.

### BE-09: Chat và hỗ trợ AI

Endpoints:

- `GET /api/chat/:roomId`
- `POST /api/chat/send`

Checklist:

- [ ] Tạo room chat theo user hoặc order.
- [ ] Lưu tin nhắn vào `chat_messages`.
- [ ] Phân biệt message từ Đại lý, Staff và AI.
- [ ] Chặn message rỗng.
- [ ] Tạo hook phát hiện nội dung khiếu nại để tạo `complaints`.
- [ ] Tạo lớp AI service dạng interface để có thể mock khi chưa có key.

Done:

- Chat screen gửi và tải lịch sử tin nhắn.
- Backend vẫn chạy được khi chưa cấu hình AI provider thật.

### BE-10: Warehouses API

Endpoint:

- `GET /api/warehouses`

Checklist:

- [ ] Trả danh sách kho đang active.
- [ ] Trả đủ latitude, longitude, address, phone, opening hours.
- [ ] Validate tọa độ khi Admin cập nhật kho trong tương lai.

Done:

- Map screen hiển thị được marker kho hàng.

### BE-11: Profile API

Endpoints:

- `GET /api/users/me`
- `PUT /api/users/me`

Checklist:

- [ ] Trả thông tin user hiện tại.
- [ ] Cho cập nhật phone, address, avatar, business info.
- [ ] Validate email/phone không trùng.
- [ ] Không cho user tự đổi role.

Done:

- Profile screen hiển thị và cập nhật được thông tin hợp lệ.

### BE-12: Admin Dashboard API

Endpoints:

- `GET /api/admin/dashboard`
- `CRUD /api/admin/users`
- `CRUD /api/admin/products`
- `PUT /api/orders/:id/status`

Checklist:

- [ ] Tính tổng đơn chờ duyệt.
- [ ] Tính doanh thu mẫu theo tháng.
- [ ] Tính số khiếu nại mới.
- [ ] Tính số đại lý hoạt động.
- [ ] Trả danh sách đơn hàng gần đây.
- [ ] Bảo vệ toàn bộ Admin API bằng role `ADMIN`.

Done:

- Admin Dashboard có dữ liệu tổng quan.
- Admin quản lý được sản phẩm, user và đơn hàng.

### BE-13: Backend testing và quality gate

Checklist:

- [ ] Unit test service auth, product, order.
- [ ] Integration test controller với database test.
- [ ] Test phân quyền Admin/Staff/Dealer.
- [ ] Test validation request.
- [ ] Chạy `mvn clean verify`.

Done:

- Test pass.
- Coverage tập trung vào logic auth, order, product price tiers.

## 6. Frontend Tasks - Flutter

### FE-01: Khởi tạo Flutter project structure

Checklist:

- [ ] Tạo cấu trúc theo feature: `auth`, `home`, `products`, `cart`, `orders`, `chat`, `notifications`, `map`, `profile`, `admin`.
- [ ] Tạo shared layer: theme, widgets, routes, api client, local storage.
- [ ] Cấu hình assets logo/icon MarineLink.
- [ ] Cấu hình env API base URL.

Done:

- App chạy được màn hình splash hoặc login.
- Không hardcode API URL trong widget.

### FE-02: Routing và Auth State

Checklist:

- [ ] Cấu hình route cho login, register, home, product list, product detail, cart, checkout, orders, chat, notifications, map, profile, admin.
- [ ] Route guard theo trạng thái đăng nhập.
- [ ] Route guard theo role Admin/Staff/Dealer.
- [ ] Lưu token vào local storage.
- [ ] Xóa token khi logout.

Done:

- Người chưa login bị đưa về Login.
- Admin vào được Dashboard.
- Đại lý không vào được Admin Dashboard.

### FE-03: API client và error handling

Checklist:

- [ ] Tạo Dio/HTTP client.
- [ ] Gắn Authorization Bearer token vào request.
- [ ] Parse response envelope từ backend.
- [ ] Chuẩn hóa loading, success, error state.
- [ ] Hiển thị lỗi thân thiện cho user.

Done:

- Các màn hình gọi API qua một client chung.
- Token hết hạn hoặc thiếu token được xử lý thống nhất.

### FE-04: Login Screen

API:

- `POST /api/auth/login`

Checklist:

- [ ] Build UI theo demo Login.
- [ ] Validate email/số điện thoại và mật khẩu.
- [ ] Gọi login API.
- [ ] Lưu token và user role.
- [ ] Điều hướng theo role sau login.
- [ ] Hiển thị lỗi login sai.

Done:

- Đại lý, Staff và Admin login vào đúng màn hình.

### FE-05: Register Screen

API:

- `POST /api/auth/register`

Checklist:

- [ ] Build UI theo demo Register.
- [ ] Validate họ tên, email, phone, password, business info.
- [ ] Gửi request đăng ký.
- [ ] Hiển thị trạng thái đăng ký thành công/chờ duyệt.
- [ ] Điều hướng về Login sau khi đăng ký thành công.

Done:

- Register tạo được tài khoản đại lý.
- Lỗi email/phone trùng hiển thị rõ.

### FE-06: Home Screen

API:

- `GET /api/products`
- `GET /api/notifications`

Checklist:

- [ ] Build Home theo demo.
- [ ] Hiển thị banner/khu nổi bật.
- [ ] Hiển thị danh mục sản phẩm.
- [ ] Hiển thị sản phẩm nổi bật.
- [ ] Hiển thị notification badge.
- [ ] Search nhanh theo keyword.

Done:

- Home có dữ liệu danh mục, sản phẩm và thông báo.

### FE-07: Product List Screen

API:

- `GET /api/products`

Checklist:

- [ ] Hiển thị danh sách sản phẩm theo category.
- [ ] Hiển thị hình ảnh, tên, xuất xứ, giá, MOQ, tồn kho.
- [ ] Implement search/filter/sort.
- [ ] Xử lý empty state.
- [ ] Điều hướng sang Product Detail.

Done:

- User lọc sản phẩm và mở chi tiết sản phẩm được.

### FE-08: Product Detail Screen

API:

- `GET /api/products/:id`

Checklist:

- [ ] Build UI theo demo Product Detail.
- [ ] Hiển thị ảnh, mô tả, xuất xứ, tồn kho, MOQ.
- [ ] Hiển thị price tiers.
- [ ] Cho chọn quantity.
- [ ] Validate quantity theo MOQ và tồn kho.
- [ ] Add to cart hoặc Buy Now.

Done:

- Product Detail thêm sản phẩm vào cart đúng quantity.

### FE-09: Shopping Cart Screen

API:

- `POST /api/cart/sync`

Checklist:

- [ ] Lưu cart local storage.
- [ ] Hiển thị item, quantity, unit price, line total.
- [ ] Tăng/giảm/xóa item.
- [ ] Tính tổng tiền local để hiển thị nhanh.
- [ ] Sync cart lên backend trước checkout.
- [ ] Xử lý cart rỗng.

Done:

- Cart cập nhật đúng và sync được với backend.

### FE-10: Checkout Screen

API:

- `POST /api/orders`

Checklist:

- [ ] Build checkout theo demo.
- [ ] Hiển thị order summary.
- [ ] Nhập/chọn recipient name, phone, address, payment method, note.
- [ ] Validate thông tin giao hàng.
- [ ] Gửi tạo order.
- [ ] Clear cart sau khi order thành công.
- [ ] Điều hướng sang Orders hoặc Order Detail.

Done:

- User đặt hàng thành công từ cart.

### FE-11: Orders Screen

API:

- `GET /api/orders`
- `PUT /api/orders/:id/status`

Checklist:

- [ ] Hiển thị danh sách đơn theo tab trạng thái.
- [ ] Hiển thị mã đơn, ngày đặt, tổng tiền, trạng thái.
- [ ] Mở chi tiết đơn hàng.
- [ ] Staff/Admin cập nhật trạng thái đơn.
- [ ] Nhận thông báo khi trạng thái đổi.

Done:

- Đại lý theo dõi đơn.
- Staff/Admin xử lý trạng thái đơn trong app.

### FE-12: Chat & AI Support Screen

API:

- `GET /api/chat/:roomId`
- `POST /api/chat/send`

Checklist:

- [ ] Build UI chat theo demo.
- [ ] Load lịch sử tin nhắn.
- [ ] Gửi tin nhắn mới.
- [ ] Phân biệt message của user, Staff và AI.
- [ ] Chặn tin nhắn rỗng.
- [ ] Hiển thị trạng thái gửi/loading/error.

Done:

- User chat với MarineLink và thấy lịch sử tin nhắn.

### FE-13: Notifications Screen

API:

- `GET /api/notifications`
- `PUT /api/notifications/:id/read`

Checklist:

- [ ] Hiển thị notification list.
- [ ] Phân biệt đã đọc/chưa đọc.
- [ ] Mark as read khi mở notification.
- [ ] Điều hướng đến màn hình liên quan theo target.
- [ ] Xử lý empty state.

Done:

- Notification hoạt động cho đơn hàng, khuyến mãi và chat.

### FE-14: Map Screen

API:

- `GET /api/warehouses`

Checklist:

- [ ] Build Map screen theo demo.
- [ ] Hiển thị marker kho hàng.
- [ ] Hiển thị thông tin kho khi chọn marker.
- [ ] Xin quyền location khi cần.
- [ ] Mở Google Maps chỉ đường.

Done:

- User xem được vị trí kho và mở chỉ đường.

### FE-15: Profile Screen

API:

- `GET /api/users/me`
- `PUT /api/users/me`
- `POST /api/auth/logout`

Checklist:

- [ ] Hiển thị thông tin profile.
- [ ] Cập nhật phone, address, avatar, business info.
- [ ] Validate input trước khi lưu.
- [ ] Logout và xóa local session.
- [ ] Hiển thị thống kê đơn hàng nếu backend trả dữ liệu.

Done:

- User xem/cập nhật hồ sơ và logout được.

### FE-16: Admin Dashboard Screen

API:

- `GET /api/admin/dashboard`
- `CRUD /api/admin/products`
- `CRUD /api/admin/users`
- `PUT /api/orders/:id/status`

Checklist:

- [ ] Build dashboard theo demo.
- [ ] Hiển thị card tổng quan.
- [ ] Hiển thị đơn hàng gần đây.
- [ ] Điều hướng đến quản lý sản phẩm.
- [ ] Điều hướng đến quản lý user/đại lý.
- [ ] Điều hướng đến quản lý đơn hàng và khiếu nại.
- [ ] Chặn truy cập nếu user không phải Admin.

Done:

- Admin xem được dashboard và thao tác quản trị chính.

### FE-17: State Management Integration

State cần có:

- Authentication State
- Product State
- Cart State
- Order State
- Notification State
- Chat State
- Profile State
- Admin State

Checklist:

- [ ] Tạo state/cubit/provider riêng theo feature.
- [ ] Không đặt business logic trực tiếp trong widget.
- [ ] Có loading, success, error, empty state.
- [ ] Đồng bộ Cart sau Product Detail.
- [ ] Đồng bộ Notification badge sau mark read.
- [ ] Đồng bộ Order status sau Staff/Admin cập nhật.

Done:

- Demo flow không cần reload app để thấy dữ liệu mới.

### FE-18: Flutter testing và demo flow

Checklist:

- [ ] Unit test cho cart calculation.
- [ ] Unit test cho auth state.
- [ ] Widget test cho Login/Register validation.
- [ ] Widget test cho Product List empty/loading state.
- [ ] Manual test luồng demo: Login -> Home -> Product List -> Product Detail -> Cart -> Checkout -> Orders -> Notifications/Chat.

Done:

- Demo flow chính chạy ổn định.

## 7. Task liên kết FE - BE - DB theo màn hình

| Màn hình | DB task | Backend task | Frontend task |
|---|---|---|---|
| Login | DB-02 | BE-04 | FE-04 |
| Register | DB-02 | BE-04 | FE-05 |
| Home | DB-03, DB-05 | BE-05, BE-08 | FE-06 |
| Product List | DB-03 | BE-05 | FE-07 |
| Product Detail | DB-03 | BE-05 | FE-08 |
| Cart | DB-04 | BE-06 | FE-09 |
| Checkout | DB-04, DB-05 | BE-07, BE-08 | FE-10 |
| Orders | DB-04, DB-05 | BE-07 | FE-11 |
| Chat & AI | DB-05 | BE-09 | FE-12 |
| Notifications | DB-05 | BE-08 | FE-13 |
| Map | DB-06 | BE-10 | FE-14 |
| Profile | DB-02 | BE-11 | FE-15 |
| Admin Dashboard | DB-02, DB-03, DB-04, DB-05 | BE-12 | FE-16 |
| State Management | All | All | FE-17 |

## 8. Thứ tự làm khuyến nghị

1. DB-01 -> DB-07: tạo schema, seed, migration.
2. BE-01 -> BE-04: khởi tạo backend, connect DB, auth.
3. FE-01 -> FE-05: khởi tạo app, routing, login/register.
4. BE-05 + FE-06 -> FE-08: catalog sản phẩm.
5. BE-06 -> BE-07 + FE-09 -> FE-11: cart, checkout, order.
6. BE-08 -> BE-11 + FE-12 -> FE-15: notification, chat, map, profile.
7. BE-12 + FE-16: admin dashboard.
8. BE-13 + FE-17 -> FE-18: test, state integration, demo.

## 9. Definition of Done toàn dự án

- [ ] Flutter app chạy được luồng demo chính.
- [ ] Backend Spring Boot chạy bằng `mvn spring-boot:run`.
- [ ] Backend build/test pass bằng `mvn clean verify`.
- [ ] Database Supabase có đủ schema, relation và seed data.
- [ ] Không hardcode secret trong Flutter hoặc Spring Boot.
- [ ] API có validation và response lỗi rõ ràng.
- [ ] Role Admin, Staff, Đại lý được kiểm soát đúng.
- [ ] DB/API trong app khớp với `MarineLink_Main_Functions_Specification_v2.docx`.
