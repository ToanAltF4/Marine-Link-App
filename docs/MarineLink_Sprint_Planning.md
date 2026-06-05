# Kế hoạch Sprint MarineLink

Nguồn: `docs/MarineLink_Main_Functions_Specification_v3.md`

## Giả định lập kế hoạch

- Nhóm có 3 thành viên theo tài liệu: Phạm Đức Toàn, Ngô Việt Hoàng, Đặng Quốc Tâm.
- Nền tảng chính: Flutter Android, kết nối REST API bằng JWT.
- Repository triển khai theo monorepo: `frontend/` cho Flutter, `backend/` cho Spring Boot, `docs/` cho contract/architecture/DB/sprint.
- Mục tiêu gần nhất là demo được luồng chính trong tài liệu: đăng nhập -> trang chủ -> danh sách sản phẩm -> chi tiết -> giỏ hàng -> checkout -> tạo đơn -> theo dõi đơn -> nhận thông báo hoặc chat hỗ trợ.
- Độ dài sprint: 1 tuần/sprint.
- Capacity mặc định: 8 points/người/sprint, tổng 24 points/sprint. Mỗi sprint chỉ commit khoảng 70-80% capacity, tương đương 17-19 points, để còn buffer sửa lỗi, học framework, tích hợp API và chuẩn bị demo.
- Backend/API: dùng mock data trước, sau đó tích hợp Spring Boot REST API theo endpoint trong docx.
- Quản lý state: dùng BLoC/Cubit. Cubit dùng cho màn hình đơn giản, BLoC dùng cho flow phức tạp như authentication, checkout, orders và admin.
- Phạm vi Admin: Dashboard Admin đầy đủ là scope bắt buộc, không phải stretch.
- Chat & Hỗ trợ: Đại lý nhắn tin và nhân viên hỗ trợ trực tiếp phản hồi.
- Trạng thái trong các bảng kế hoạch dùng các giá trị: `Chưa làm`, `Đang làm`, `Xong`, `Thất bại`, `Bị chặn`.

## Mục tiêu release

Hoàn thành MVP MarineLink B2B cho đại lý hải sản, đủ để người dùng đăng nhập, xem sản phẩm, đặt hàng, theo dõi đơn, nhận hỗ trợ, và để Admin/Staff xử lý dữ liệu cốt lõi phục vụ demo.

## Cách chia nhóm việc FE/BE/DB

Kế hoạch được chia theo 5 nhóm việc để nhóm dễ giao việc và tránh nhầm giữa màn hình, API và database:

- **FE Flutter:** màn hình, điều hướng, state BLoC/Cubit, kiểm tra form, lưu dữ liệu local, mock repository và tích hợp REST API.
- **BE Spring Boot:** REST controller, service/business rule, repository, xác thực JWT, kiểm tra role, response lỗi và contract test.
- **DB Supabase/PostgreSQL:** schema, migration, constraint, index, seed data, storage bucket/policy nếu có file upload.
- **API Contract:** DTO request/response, response envelope, phân trang, status code, rule sở hữu dữ liệu và mapping FE/BE/DB.
- **QA/Demo/Docs:** unit/integration/E2E test, dữ liệu demo, kịch bản demo, cập nhật tài liệu và kiểm tra bảo mật cơ bản.

Quy ước code chung repo:

- FE chỉ code trong `frontend/`; BE chỉ code trong `backend/`; docs và icon giữ ở root-level folder hiện có.
- FE/BE cùng dùng `docs/MarineLink_API_Documentation.md` làm contract. Không tự thêm endpoint ở FE nếu BE/API doc chưa có.
- Sprint task phải ghi rõ phần việc thuộc FE, BE, DB, API contract hay QA để tránh một người sửa lẫn boundary của stack khác.
- Build output như `build/`, `.dart_tool/`, `target/`, coverage raw và secret local không được commit.

### Ma trận phạm vi theo epic

| Nhóm chức năng | FE Flutter | BE Spring Boot/API | DB Supabase/PostgreSQL | QA/Demo/Docs |
|---|---|---|---|---|
| Nền tảng dự án | Cấu trúc app, điều hướng, theme, shared widgets, API client interface, base BLoC/Cubit | API envelope, exception handler, cấu trúc module, health check, khung auth filter | Migration nền tảng, enum types, `roles`, `users`, seed role demo | Chạy app, smoke test điều hướng/API client, cập nhật ghi chú setup |
| Xác thực | Màn login/register, lưu token, điều hướng theo role, trạng thái logout | `/api/auth/login`, `/api/auth/register`, hash password, cấp/verify JWT, kế hoạch rate limit | `users`, `roles`, unique email/phone, tài khoản demo admin/staff/user | Unit test auth, case login thất bại, kiểm tra không commit secret |
| Duyệt sản phẩm | Home, danh mục, danh sách/chi tiết sản phẩm, search, filter nhanh, bottom sheet lọc, sort giá, UI price tier | `/api/products`, `/api/products/{id}`, filter, phân trang, product DTO | `categories`, `products`, `product_images`, `price_tiers`, index sản phẩm, seed catalog | Dữ liệu test product list/detail, trạng thái empty/loading/error |
| Luồng mua hàng | Cart state, màn giỏ hàng, form checkout, màn đặt hàng thành công | Cart API chính (`/api/cart`, `/api/cart/items`) + `/api/cart/sync` phụ để merge local/offline, `/api/orders`, tính lại giá, validate tồn kho/min quantity | `carts`, `cart_items`, `orders`, `order_items`, rule sinh order code | Test luồng checkout thành công, case quantity sai/cart rỗng |
| Theo dõi đơn hàng | Danh sách/chi tiết đơn, status badge, timeline đơn hàng | `/api/orders`, `/api/orders/{id}`, `/api/orders/{id}/status` cho Staff/Admin | `order_status_history`, index đơn/trạng thái, liên kết notification | E2E luồng đặt hàng, test đổi trạng thái không hợp lệ |
| Thông báo | Danh sách thông báo, trạng thái đã đọc/chưa đọc, mở sang màn liên quan | `/api/notifications`, `/api/notifications/{id}/read`, tạo event từ order/chat | `notifications`, cột liên kết order/product/chat, index unread | Verify rule chỉ chủ sở hữu được mark read, dữ liệu demo notification |
| Chat/Hỗ trợ | UI chat, ô nhập tin nhắn, placeholder attachment, hiển thị tin nhắn nhân viên | `/api/chat/send`, `/api/chat/{roomId}`, dịch vụ phản hồi chat, validate metadata attachment | `chat_rooms`, `chat_messages`, `chat_attachments`, `complaints` | Test chặn tin nhắn rỗng, kịch bản chat hỗ trợ |
| Hồ sơ cá nhân | Xem/sửa profile, phần tạm cho đổi mật khẩu và avatar | `/api/users/me`, validate cập nhật profile, cleanup logout nếu cần | Các field profile và index trong `users` đã bao phủ | Test validation profile và ownership |
| Bản đồ kho | Danh sách kho/marker bản đồ, mở Google Maps, xử lý permission nếu cần | `/api/warehouses`, filter kho đang hoạt động | `warehouses`, field tọa độ, active index, seed 2 kho | Fallback khi permission/plugin bản đồ chưa sẵn sàng |
| Dashboard Admin đầy đủ | Dashboard admin, UI CRUD sản phẩm, quản lý user/role, UI đơn/trạng thái, staff chat view | `/api/admin/dashboard`, `/api/admin/products`, `/api/admin/users`, role guard, rule service admin | Query admin trên users/products/orders/complaints/chat, rule soft delete/status | Smoke test admin bằng tài khoản ADMIN/STAFF/USER |
| Hoàn thiện demo | Loading, empty, error, validation text, polish responsive Android | Lỗi trả về thống nhất, timeout handling, sample data endpoint nếu cần | Refresh seed demo, bảo đảm không lộ test password/plain secret | Chạy thử kịch bản demo, checklist regression |

### Phân chia theo sprint và nhóm việc

| Sprint | FE Flutter | BE Spring Boot/API | DB Supabase/PostgreSQL | QA/Demo/Docs |
|---|---|---|---|---|
| Sprint 1 | Nền tảng app, màn auth, home/product list/detail bằng mock repository | API envelope, khung contract auth/product, DTO tương thích mock | Migration nền cho roles/users/catalog, seed products/categories | Smoke test Flutter, checklist validation auth/product |
| Sprint 2 | Cart, checkout, orders list/detail, điểm vào notification | Cart API add/update/remove/clear là luồng chính, `/api/cart/sync` chỉ để merge local/offline, tạo order, API query/status đơn, tạo notification | Migration cart/order/order item/status history/notification | E2E luồng mua hàng, test cart/order không hợp lệ |
| Sprint 3 | Profile, chat, warehouse map, điều hướng từ notification | API profile, chat send/history, warehouses, dịch vụ phản hồi chat | Field liên quan profile/chat, warehouses, complaints/attachments nếu dùng | Test fallback chat/profile/map, cập nhật dữ liệu demo |
| Sprint 4 | Màn Full Admin/Staff Dashboard và các luồng quản lý | Service dashboard/product/user/order/chat cho admin và role guard | Index phục vụ query admin, constraint soft-delete/status, seed case admin | Smoke test role admin, regression phân quyền |
| Sprint 5 | Đổi mock repository sang REST thật và polish trạng thái UI | Hoàn tất tích hợp endpoint, harden xử lý lỗi, ổn định auth/session | Seed data cuối, verify migrations/indexes, checklist backup env | Chạy thử full demo, `flutter test --coverage`, backend `mvn clean verify` nếu backend đã scaffold |

### Gợi ý chia người phụ trách

| Nhóm việc | Người phụ trách chính | Hỗ trợ | Ghi chú |
|---|---|---|---|
| FE Flutter | Ngô Việt Hoàng | Đặng Quốc Tâm | Tập trung UI, BLoC/Cubit, mock-to-API repository |
| BE/API | Phạm Đức Toàn | Ngô Việt Hoàng | Tập trung Spring Boot contract, auth, rule service |
| DB/Supabase | Phạm Đức Toàn | Đặng Quốc Tâm | Tập trung migration, constraint, seed data, index |
| QA/Demo/Docs | Đặng Quốc Tâm | Cả nhóm | Tập trung test case, kịch bản demo, cập nhật tài liệu |

## Backlog sản phẩm theo docx

| Ưu tiên | Nhóm chức năng | Phạm vi chính | API/Data liên quan | Trạng thái |
|---|---|---|---|---|
| P0 | Nền tảng dự án | Khởi tạo Flutter app, routing, theme, API client, model cơ bản, cấu trúc BLoC/Cubit | users, roles, products, categories, carts, orders | Xong |
| P0 | Xác thực | Login, register, lưu JWT, phân quyền Admin/Staff/User bằng role table | `/api/auth/login`, `/api/auth/register`, `users`, `roles` | Xong |
| P0 | Duyệt sản phẩm | Home, product list, product detail, search/filter/sort, price tiers | `/api/products`, `/api/products/{id}`, `products`, `categories`, `product_images`, `price_tiers` | Xong |
| P0 | Luồng mua hàng | Cart, checkout, tạo order, clear cart sau khi đặt hàng | Cart API chính (`/api/cart`, `/api/cart/items`) + `/api/cart/sync` phụ, `/api/orders`, `carts`, `cart_items`, `orders`, `order_items` | Đang làm - FE cart/checkout local xong; BE/cart remote/orders list chưa |
| P0 | Theo dõi đơn hàng | Danh sách đơn, chi tiết đơn, trạng thái đơn hàng | `/api/orders`, `/api/orders/{id}`, `/api/orders/{id}/status`, `notifications` | Chưa làm |
| P1 | Thông báo | Danh sách thông báo, đã đọc/chưa đọc, điều hướng sang màn liên quan | `/api/notifications`, `/api/notifications/{id}/read` | Chưa làm |
| P1 | Chat/hỗ trợ | Chat với Nhân viên, lịch sử chat, file đính kèm, chặn tin nhắn rỗng | `/api/chat/send`, `/api/chat/{roomId}`, `chat_rooms`, `chat_messages`, `chat_attachments`, `complaints` | Chưa làm |
| P1 | Hồ sơ cá nhân | Xem/sửa hồ sơ, đổi mật khẩu, logout | `/api/users/me`, `/api/auth/logout`, `users` | Chưa làm |
| P1 | Bản đồ kho | Bản đồ kho hàng, marker, mở Google Maps, xử lý quyền vị trí | `/api/warehouses`, `warehouses` | Chưa làm |
| P0 | Dashboard Admin đầy đủ | Tổng quan, quản lý sản phẩm/người dùng/role/đơn hàng, xử lý trạng thái, hỗ trợ chat | `/api/admin/dashboard`, `/api/admin/products`, `/api/admin/users` | Chưa làm |
| P1 | Phản hồi từ nhân viên | Hỗ trợ phản hồi nhanh từ nhân viên hỗ trợ có ngữ cảnh sản phẩm, giá, tồn kho | `chat_messages`, `products`, `orders` | Chưa làm |
| P2 | Hoàn thiện demo | Empty states, loading states, validation text, dữ liệu mẫu đẹp | Toàn bộ module | Chưa làm |


## Sprint 1: Nền tảng, xác thực, duyệt sản phẩm

**Thời gian:** Tuần 1 | **Nhóm:** 3 thành viên
**Mục tiêu sprint:** Tạo nền tảng Flutter và hoàn thành luồng người dùng đăng nhập để xem danh sách/chi tiết sản phẩm bằng dữ liệu mock hoặc API đầu tiên.

### Năng lực

| Thành viên | Số ngày khả dụng | Phân bổ | Ghi chú |
|---|---:|---:|---|
| Phạm Đức Toàn | 4/5 | 8 pts | Setup dự án, API/auth |
| Ngô Việt Hoàng | 4/5 | 8 pts | Home, product list |
| Đặng Quốc Tâm | 4/5 | 8 pts | Product detail, state, UI polish |
| **Tổng** | **12 dev-days** | **24 pts** | Commit mục tiêu 17-19 pts |

### Backlog sprint

| Mã | Ưu tiên | FE | BE/API | DB | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---|---|---:|---|---|
| S1-01 | P0 | Khởi tạo Flutter project trong `frontend/`, routing, theme, shared widgets, app shell | Không đổi | Không đổi | 3 pts | Không có | Xong |
| S1-02 | P0 | Tạo domain models `User`, `Product`, `Category`, `PriceTier`, API response envelope phía Flutter | Chuẩn hóa response envelope/DTO contract cho auth/product | Đối chiếu `users`, `roles`, `products`, `categories`, `price_tiers` với docx | 3 pts | Docx database/API | Xong |
| S1-03 | P0 | Tạo API client, mock repositories, JWT storage interface, error mapping cơ bản | Không đổi ngoài contract auth/product hiện có | Không đổi | 3 pts | Nền tảng dự án | Xong |
| S1-04 | P0 | Màn login, form validation, gọi auth repository, lưu token, route theo role | Implement/verify `/api/auth/login`, JWT issuing, `/api/auth/me` nếu dùng remote | `users`, `roles`, unique email/phone, seed user demo | 4 pts | API client | Xong |
| S1-05 | P0 | Màn register đại lý, validate email/phone/password/tax code, success/error state | Implement/verify `/api/auth/register`, hash password, validate duplicate email/phone | `users`, `roles`, constraint unique, role USER mặc định | 3 pts | Auth models | Xong |
| S1-06 | P0 | Home screen: banner, categories, featured products, quick search entry | Cung cấp product/category mock hoặc endpoint list nếu remote sẵn | Seed categories/products featured phục vụ demo | 3 pts | Product mock data | Xong |
| S1-07 | P1 | Wiring BLoC/Cubit cho auth/product/loading/error | Không đổi | Không đổi | 2 pts | Nền tảng | Xong |
| S1-08 | P1 | Product list: image/name/origin/price/min quantity/stock, search, category chips, stock filter, price sort, empty/reset state | Implement/verify `/api/products` filter/search/sort/pagination contract | Index product/category/status/price phục vụ query, seed catalog | 4 pts | Product repository | Xong |
| S1-09 | P1 | Product detail: price tiers, min quantity, stock validation, add-to-cart tạm | Implement/verify `/api/products/{id}` detail response gồm images/priceTiers | `product_images`, `price_tiers`, stock/min quantity seed | 3 pts | Product repository | Xong |
| S1-10 | P2 | Hiển thị asset/mock data sản phẩm hải sản trong UI demo | Không đổi | Seed sản phẩm hải sản, category, price tiers, tồn kho | 2 pts | Product models | Xong |

**Năng lực dự kiến:** 24 pts
**Tải sprint:** 19 pts P0 đã commit + 11 pts buffer/stretch backlog. Nên commit P0 trước, chỉ kéo P1/P2 khi P0 ổn.

### Tiêu chí hoàn thành sprint

- Có app Flutter chạy được trên Android emulator/device.
- Login/register có validation và phản hồi lỗi rõ ràng.
- Sau login, user role Đại lý vào được Home.
- Home -> Product List -> Product Detail hoạt động đúng.
- Product list có search, lọc danh mục, lọc tồn kho, sort giá, empty state và xóa lọc.
- Code có cấu trúc đủ để mở rộng cart/order ở Sprint 2.

## Sprint 2: Giỏ hàng, checkout, đơn hàng, thông báo

**Mục tiêu sprint:** Hoàn thành luồng mua hàng chính từ thêm vào giỏ đến tạo đơn và theo dõi trạng thái đơn.

| Mã | Ưu tiên | FE | BE/API | DB | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---|---|---:|---|---|
| S2-01 | P0 | `CartCubit` + domain `Cart/CartItem`: add/update/remove/clear, selected items, tổng tiền, tổng số lượng, cart rỗng, unit test | Không đổi, chưa sync server | Không đổi | 4 pts | Product detail | Xong FE local |
| S2-02 | P0 | Cart screen: list item, tăng/giảm số lượng, xóa item, selected item, empty state, tổng tiền, nút checkout disabled khi rỗng | Không đổi | Không đổi | 3 pts | Cart state | Xong FE local |
| S2-03 | P0 | Checkout screen: form người nhận, số điện thoại, địa chỉ, payment method, ghi chú, validation client, summary selected cart items, empty cart state | Contract đã dùng `POST /api/orders`; không đổi request body | Không đổi | 4 pts | Cart state | Xong FE local |
| S2-04 | P0 | `CheckoutBloc` + `CheckoutRepository`: validate cart active local/UI cache, gọi adapter tạo order, clear cart UI cache, màn success/error | `POST /api/orders`: tạo order từ active server-side cart hoặc request `items` fallback, tính lại giá, validate stock/min quantity, trả order code | `orders`, `order_items`, `order_status_history`, rule sinh order code, transaction clear cart items nếu dùng server cart | 4 pts | Checkout | Xong FE + API thật |
| S2-05 | P0 | Orders list/detail cho Đại lý: status badge, timeline, empty/loading/error | `GET /api/orders`, `GET /api/orders/{id}` chỉ trả đơn của user hiện tại | Index `orders(user_id, created_at)`, `order_status_history(order_id, created_at)` | 4 pts | Order model/repository | Xong FE + API thật |
| S2-06 | P1 | Notification list: đã đọc/chưa đọc, mở order/product/chat liên quan | `GET /api/notifications`, `PUT /api/notifications/{id}/read`, tạo notification từ order event | `notifications` với owner/link target, index unread | 3 pts | Order events | Chưa làm |
| S2-07 | P1 | Staff/Admin UI tối thiểu để đổi status đơn, guard theo role | `PUT /api/orders/{id}/status`, validate transition, role STAFF/ADMIN | Ghi `order_status_history`, cập nhật timestamp trạng thái trên `orders` | 3 pts | Role routing | Xong FE + API thật |
| S2-08 | P0 | Cart remote repository gọi Cart API thật: load cart, add/update/remove/clear item, update selected; `/api/cart/sync` chỉ dùng merge local/offline/pre-login | Cart API BE: `GET /api/cart`, `POST /api/cart/items`, `PATCH /api/cart/items/{productId}`, `DELETE /api/cart/items/{productId}`, `DELETE /api/cart/items` là luồng chính; `POST /api/cart/sync` đã có để sync local cart trước checkout; BE tính lại totals và price tier | `carts`, `cart_items`, FK `price_tier_id`, unique `(cart_id, product_id)`, active cart theo user | 5 pts | Cart state + cart DB migration | Đang làm - `/api/cart/sync` xong, Cart API chính chưa |

Ghi chú S2-01/S2-08: FE đã có `CartCubit` và domain `Cart/CartItem` cho add/update/remove/clear, selected items, tổng tiền, tổng số lượng, empty cart và tính lại price tier khi đổi số lượng. BE đã có `/api/cart/sync` để merge local cart lên server-side cart trước checkout; các endpoint Cart API chính load/add/update/remove/clear vẫn thuộc phần còn lại của S2-08.

Ghi chú S2-02: FE đã có `CartScreen` nối route `/cart`, hiển thị danh sách item, tăng/giảm số lượng theo min/stock, toggle selected, xóa item, empty state, tổng selected amount và nút checkout disabled khi cart không có item selected. UI cart đã đồng bộ radius/card với hệ thống, ảnh sản phẩm trong cart được clip bo góc riêng và bottom nav quay lại tab cũ bằng stack thay vì reload route. Màn này vẫn dùng `CartCubit` local/UI cache; Cart remote repository và server-side source of truth thuộc S2-08.

Ghi chú S2-03/S2-04/S2-05: FE đã có `CheckoutScreen`, `CheckoutBloc`, `CheckoutRepository` adapter qua `OrderRepository`, client validation, payment method, success/error state và clear `CartCubit` sau khi tạo đơn thành công. Order API thật đã có `POST /api/orders`, `GET /api/orders`, `GET /api/orders/{id}` và `PUT /api/orders/{id}/status`; checkout remote hiện gọi `/api/cart/sync` best-effort trước `POST /api/orders` và gửi thêm selected `items` để tránh lỗi server cart rỗng khi Cart API chính chưa làm source of truth.

Ghi chú S2-07: FE đã có `AdminDashboardScreen`, route `/admin/orders` và `/admin/orders/:id` dùng `AdminRoleGuard` theo `AuthBloc` để chỉ Staff/Admin xem được khu quản trị. Staff/Admin có thể mở chi tiết đơn, chọn transition hợp lệ từ `OrderStatus.allowedTransitions`, nhập ghi chú nội bộ và gọi `OrderRepository.updateOrderStatus` tới `PUT /api/orders/{id}/status`; sau khi cập nhật, detail refetch để hiển thị transition tiếp theo. BE đã có guard STAFF/ADMIN, validate transition và ghi `order_status_history`.

**Tải khuyến nghị:** 19-20 pts P0, kéo P1 nếu còn thời gian.

## Sprint 3: Chat, hồ sơ, bản đồ

**Mục tiêu sprint:** Bổ sung các chức năng hỗ trợ sau bán hàng: chat, hồ sơ cá nhân, kho hàng và điều hướng thông báo.

| Mã | Ưu tiên | FE | BE/API | DB | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---|---|---:|---|---|
| S3-01 | P0 | Profile screen: xem/sửa số điện thoại, địa chỉ, avatar tạm, validation, loading/error | `GET /api/users/me`, `PUT /api/users/me`, validate ownership và field profile | Cột profile trong `users`, index email/phone giữ unique | 4 pts | Auth state | Chưa làm |
| S3-02 | P0 | Logout flow, clear token/session local, đổi mật khẩu tạm nếu có UI | `POST /api/auth/logout` nếu cần, `POST /api/auth/change-password` hoặc giữ mock nếu chưa có | Không đổi, trừ khi lưu token/session server-side | 2 pts | Profile | Chưa làm |
| S3-03 | P0 | Chat screen: gửi tin nhắn, lịch sử, phân biệt user/staff, timestamp, scroll state | `POST /api/chat/send`, `GET /api/chat/{roomId}`, tạo/lấy room theo user | `chat_rooms`, `chat_messages`, `chat_attachments` nếu có metadata file | 5 pts | Chat model/repository | Chưa làm |
| S3-04 | P0 | Client validation chặn tin nhắn rỗng, loading/error/retry cho chat | Server validation chặn content rỗng, response lỗi dễ hiểu | Check constraint/rule message content nếu áp dụng | 2 pts | Chat screen | Chưa làm |
| S3-05 | P1 | Staff reply UI hoặc quick reply view có ngữ cảnh sản phẩm/đơn | API staff reply, lookup product/order context theo quyền | Query `chat_messages`, `products`, `orders`, liên kết `complaints` nếu tạo ticket | 4 pts | Product/order data | Chưa làm |
| S3-06 | P1 | Warehouse map/list: marker, thông tin kho, mở Google Maps | `GET /api/warehouses`, filter kho active | `warehouses`, tọa độ lat/lng, seed kho demo, active index | 4 pts | Warehouse data | Chưa làm |
| S3-07 | P1 | Permission flow vị trí hiện tại nếu dùng, fallback khi bị từ chối | Không đổi | Không đổi | 3 pts | Map plugin | Chưa làm |
| S3-08 | P2 | Deep link/router từ notification sang order/product/chat, preserve back stack | Notification payload contract có `targetType`, `targetId`, ownership check | `notifications` lưu target type/id và read state | 3 pts | Notifications | Chưa làm |

**Tải khuyến nghị:** 18-20 pts, tránh kéo cả phần tích hợp phức tạp và permission nâng cao nếu map/chat chưa ổn.

## Sprint 4: Dashboard Admin đầy đủ

**Mục tiêu sprint:** Hoàn thiện khu vực Admin/Staff đầy đủ theo docx để quản lý dashboard, sản phẩm, người dùng, đơn hàng và hỗ trợ chat.

| Mã | Ưu tiên | FE | BE/API | DB | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---|---|---:|---|---|
| S4-01 | P0 | Admin/Staff route guard theo role, layout shell admin, fallback unauthorized | Role guard middleware/filter cho ADMIN/STAFF, `/api/auth/me` trả role chính xác | `users.role_id -> roles.id`; MVP giữ 1 user 1 role, không dùng `user_roles` | 3 pts | Auth role | Chưa làm |
| S4-02 | P0 | Admin dashboard overview: cards orders/revenue/products/users, charts/list tối thiểu | `GET /api/admin/dashboard` tổng hợp metrics, chỉ ADMIN/STAFF | Query aggregate từ `orders`, `order_items`, `products`, `users` | 4 pts | Admin data | Chưa làm |
| S4-03 | P0 | Product management UI: list/create/update/delete, stock/status, image field | `/api/admin/products` CRUD, validate product/category/price tiers, role guard | `products`, `product_images`, `price_tiers`, soft delete/status, indexes | 5 pts | Product repository | Chưa làm |
| S4-04 | P0 | Order status management UI cho Staff/Admin, status filter, action buttons | `PUT /api/orders/{id}/status`, transition rules, audit changed_by | `orders`, `order_status_history`, notification event khi status đổi | 4 pts | Orders | Chưa làm |
| S4-05 | P0 | User management UI: danh sách user, duyệt đại lý, phân biệt role/status | `/api/admin/users`, update status/role, validate không tự khóa admin | `users`, `roles`, status index, role mapping | 4 pts | Users API/mock | Chưa làm |
| S4-06 | P0 | Staff chat view, reply thread, chuyển complaint cơ bản | Staff chat endpoints, create complaint/ticket từ chat message | `chat_rooms`, `chat_messages`, `complaints`, FK `chat_message_id` | 4 pts | Messaging | Chưa làm |
| S4-07 | P1 | Loading/error/empty states cho toàn bộ admin screens, responsive Android | Chuẩn hóa error envelope admin endpoints | Không đổi | 3 pts | Admin screens | Chưa làm |

**Tải khuyến nghị:** 24 pts P0. Nếu thiếu thời gian, giảm độ sâu UI polish nhưng không cắt các module Admin chính.

## Sprint 5: Tích hợp Spring Boot API, hardening demo

**Mục tiêu sprint:** Đổi mock repository sang Spring Boot REST API, kiểm thử luồng demo end-to-end và ổn định app trước khi trình bày.

| Mã | Ưu tiên | FE | BE/API | DB | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---|---|---:|---|---|
| S5-01 | P0 | Đổi repository mock sang remote theo feature flag/config, map DTO lỗi/loading cho auth/product/cart/order chính | Đảm bảo endpoint chính chạy ổn, response envelope thống nhất, CORS/JWT filter đúng | Verify migration đã apply, seed demo đủ cho full flow | 6 pts | Backend sẵn sàng | Đang làm - Auth/Product remote đã có |
| S5-02 | P0 | Auth remote: login/register/me/logout, secure token storage, route theo role từ API thật | Harden auth endpoints, `/api/auth/me`, token expiry/unauthorized response | Verify users/roles demo admin/staff/user, unique constraints | 4 pts | Auth API | Xong phần login/register/me |
| S5-03 | P0 | Product remote đã có; bổ sung Cart API remote, checkout/order repository, orders list/detail | Implement/complete Cart API chính (`GET /api/cart`, item add/update/remove/clear); `/api/cart/sync` đã có cho merge local/offline trước checkout; order endpoints đã có `/api/orders`, `/api/orders/{id}` và validate cart/order server-side | Verify `carts`, `cart_items`, `orders`, `order_items`, status history, price tier FK | 5 pts | Product/order API | Đang làm - Product/order/cart sync xong, Cart API chính chưa |
| S5-04 | P1 | Admin remote repositories/screens cho dashboard, products, users, order status | Implement/complete admin endpoints và role guard | Verify indexes/seed phục vụ dashboard/admin list | 5 pts | Admin API | Chưa làm |
| S5-05 | P0 | E2E/manual demo path: login -> browse -> cart -> checkout -> order -> notification/chat -> admin update | Backend smoke/full-flow test, fix endpoint contract mismatch | Reset/seed demo data trước khi chạy demo | 5 pts | Full flow | Chưa làm |
| S5-06 | P1 | UI polish toàn app: loading/error/empty states, responsive Android, text tiếng Việt nhất quán | Chuẩn hóa error message và timeout handling từ API | Không đổi, trừ khi cần seed thêm case empty/error | 4 pts | Full app | Chưa làm |
| S5-07 | P2 | Đổi chat mock sang remote hoàn chỉnh, retry/offline fallback nếu cần | Complete chat send/history/staff reply API sau khi backend hỗ trợ | Verify `chat_rooms`, `chat_messages`, `chat_attachments`, `complaints` | 3 pts | API sẵn sàng | Chưa làm |

**Tải khuyến nghị:** 20 pts P0. Nếu Spring Boot API chưa sẵn sàng, giữ mock implementation nhưng hoàn thiện kịch bản demo và dữ liệu test. Admin integration và UI polish là phần hardening P1 nếu P0 đã ổn.

## Rủi ro

| Rủi ro | Ảnh hưởng | Cách xử lý |
|---|---|---|
| API/backend chưa sẵn sàng | Flutter team bị chặn ở auth, products, orders | Dùng repository interface + mock data ngay từ Sprint 1; đổi implementation sang REST sau |
| Scope quá rộng cho 3 người | Không demo được luồng chính | Ưu tiên P0 theo flow mua hàng và Dashboard Admin đầy đủ; các tính năng nâng cao để sau demo |
| Quản lý state không thống nhất | Dễ lỗi cart/order/auth khi tích hợp | Dùng BLoC/Cubit từ đầu: Cubit cho screen đơn giản, BLoC cho auth/checkout/orders/admin |
| Role Admin/Staff/User phức tạp | Sai route hoặc lộ màn quản trị | Route guard theo role, test riêng login từng role |
| Map/permission tốn thời gian | Chậm tiến độ core commerce flow | Map chỉ cần marker + open Google Maps cho MVP; current location là stretch |
| Hệ thống chat chưa tích hợp Socket | Giới hạn realtime | Sử dụng HTTP pooling hoặc REST API cơ bản để gửi nhận tin nhắn |

## Definition of Done (định nghĩa hoàn thành)

- Code chạy được trên Android emulator/device.
- Mỗi màn hình có loading, success, empty và error state tối thiểu.
- Form có validation tại client; lỗi hiển thị rõ ràng.
- Không hardcode secret/API key trong source code.
- API/repository có xử lý lỗi và timeout cơ bản.
- Luồng demo chính chạy liên tục không crash.
- Có dữ liệu mẫu đủ đẹp cho sản phẩm, đơn hàng, thông báo, chat và kho hàng.
- Code đã được review nội bộ trước khi demo.
- Test pass cho phần đã implement: Flutter `flutter test --coverage`; backend `mvn clean verify` và coverage report nếu backend đã được scaffold.
- Coverage mục tiêu tối thiểu 80% cho code đã implement. Nếu chưa đạt trong sprint đầu, phải ghi rõ module thiếu coverage, rủi ro, owner và ngày xử lý.

## Kịch bản demo gợi ý

1. Đăng nhập bằng tài khoản Đại lý.
2. Vào Home, xem category và sản phẩm nổi bật.
3. Tìm sản phẩm trong Product List, lọc `Sắp hết`, sort giá và xóa lọc.
4. Mở Product Detail, xem giá sỉ và số lượng tối thiểu.
5. Thêm sản phẩm vào Cart, chỉnh số lượng.
6. Checkout, nhập địa chỉ, chọn thanh toán, tạo order.
7. Xem Orders và trạng thái đơn.
8. Nhận notification hoặc mở chat hỗ trợ.
9. Đăng nhập Admin/Staff, xem dashboard và cập nhật trạng thái đơn.

## Quyết định đã chốt

| Chủ đề | Quyết định |
|---|---|
| Độ dài sprint | 1 tuần/sprint |
| Backend/API | Mock data trước, sau đó tích hợp Spring Boot REST API |
| Quản lý state | BLoC/Cubit: Cubit cho màn hình đơn giản, BLoC cho flow phức tạp |
| Phạm vi Admin | Dashboard Admin đầy đủ |
| Hỗ trợ chat | Hỗ trợ chat trực tiếp với nhân viên |
