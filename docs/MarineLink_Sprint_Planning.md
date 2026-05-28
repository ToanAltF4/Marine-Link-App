# MarineLink Sprint Planning

Nguồn: `docs/MarineLink_Main_Functions_Specification_v2.docx`

## Giả định lập kế hoạch

- Nhóm có 3 thành viên theo tài liệu: Phạm Đức Toàn, Ngô Việt Hoàng, Đặng Quốc Tâm.
- Platform chính: Flutter Android, kết nối REST API bằng JWT.
- Mục tiêu gần nhất là demo được luồng chính trong tài liệu: đăng nhập -> trang chủ -> danh sách sản phẩm -> chi tiết -> giỏ hàng -> checkout -> tạo đơn -> theo dõi đơn -> nhận thông báo hoặc chat hỗ trợ.
- Sprint length: 1 tuần/sprint.
- Capacity mặc định: 8 points/người/sprint, tổng 24 points/sprint. Mỗi sprint chỉ commit khoảng 70-80% capacity, tương đương 17-19 points, để còn buffer sửa lỗi, học framework, tích hợp API và chuẩn bị demo.
- Backend/API: dùng mock data trước, sau đó tích hợp Spring Boot REST API theo endpoint trong docx.
- State management: dùng BLoC/Cubit. Cubit dùng cho màn hình đơn giản, BLoC dùng cho flow phức tạp như authentication, checkout, orders và admin.
- Admin scope: Full Admin Dashboard là scope bắt buộc, không phải stretch.
- AI support: dùng sample responses trong giai đoạn demo, chưa cần gọi model thật.
- Status trong các bảng plan dùng các giá trị: `Chưa làm`, `Đang làm`, `Xong`, `Fail`, `Blocked`.

## Release Goal

Hoàn thành MVP MarineLink B2B cho đại lý hải sản, đủ để người dùng đăng nhập, xem sản phẩm, đặt hàng, theo dõi đơn, nhận hỗ trợ, và để Admin/Staff xử lý dữ liệu cốt lõi phục vụ demo.

## Product Backlog Theo Docx

| Priority | Epic | Scope chính | API/Data liên quan | Status |
|---|---|---|---|---|
| P0 | Project foundation | Khởi tạo Flutter app, routing, theme, API client, model cơ bản, BLoC/Cubit structure | users, roles, user_roles, products, categories, carts, orders | Chưa làm |
| P0 | Authentication | Login, register, lưu JWT, phân quyền Admin/Staff/User bằng role table | `/api/auth/login`, `/api/auth/register`, `users`, `roles`, `user_roles` | Chưa làm |
| P0 | Product browsing | Home, product list, product detail, search/filter, price tiers | `/api/products`, `/api/products/{id}`, `products`, `categories`, `product_images`, `price_tiers` | Chưa làm |
| P0 | Shopping flow | Cart, checkout, tạo order, clear cart sau khi đặt hàng | `/api/cart/sync`, `/api/orders`, `carts`, `cart_items`, `orders`, `order_items` | Chưa làm |
| P0 | Order tracking | Danh sách đơn, chi tiết đơn, trạng thái đơn hàng | `/api/orders`, `/api/orders/{id}`, `/api/orders/{id}/status`, `notifications` | Chưa làm |
| P1 | Notifications | Danh sách thông báo, đã đọc/chưa đọc, điều hướng sang màn liên quan | `/api/notifications`, `/api/notifications/{id}/read` | Chưa làm |
| P1 | Messaging | Chat với Staff/AI, lịch sử chat, file đính kèm, chặn tin nhắn rỗng | `/api/chat/send`, `/api/chat/{roomId}`, `chat_rooms`, `chat_messages`, `chat_attachments`, `complaints` | Chưa làm |
| P1 | Profile | Xem/sửa hồ sơ, đổi mật khẩu, logout | `/api/users/me`, `/api/auth/logout`, `users` | Chưa làm |
| P1 | Warehouse map | Bản đồ kho hàng, marker, mở Google Maps, xử lý quyền vị trí | `/api/warehouses`, `warehouses` | Chưa làm |
| P0 | Full Admin Dashboard | Tổng quan, quản lý sản phẩm/người dùng/role/đơn hàng, xử lý trạng thái, hỗ trợ chat | `/api/admin/dashboard`, `/api/admin/products`, `/api/admin/users` | Chưa làm |
| P1 | AI sample support | Câu trả lời mẫu có ngữ cảnh sản phẩm, giá, tồn kho, đơn hàng cho demo | `chat_messages`, `products`, `orders` | Chưa làm |
| P2 | Demo polish | Empty states, loading states, validation text, dữ liệu mẫu đẹp | Toàn bộ module | Chưa làm |

## Sprint 1: Foundation, Auth, Product Browsing

**Dates:** Tuần 1 | **Team:** 3 members
**Sprint Goal:** Tạo nền tảng Flutter và hoàn thành luồng người dùng đăng nhập để xem danh sách/chi tiết sản phẩm bằng dữ liệu mock hoặc API đầu tiên.

### Capacity

| Person | Available Days | Allocation | Notes |
|---|---:|---:|---|
| Phạm Đức Toàn | 4/5 | 8 pts | Project setup, API/auth |
| Ngô Việt Hoàng | 4/5 | 8 pts | Home, product list |
| Đặng Quốc Tâm | 4/5 | 8 pts | Product detail, state, UI polish |
| **Total** | **12 dev-days** | **24 pts** | Commit mục tiêu 17-19 pts |

### Sprint Backlog

| Priority | Item | Estimate | Owner | Dependencies | Status |
|---|---|---:|---|---|---|
| P0 | Khởi tạo Flutter project structure, routing, theme, shared widgets | 3 pts | Toàn | None | Chưa làm |
| P0 | Tạo models cho User, Product, Category, PriceTier và API response envelope | 3 pts | Toàn | Docx database/API | Chưa làm |
| P0 | Tạo API client/mock repository, JWT storage interface, error handling cơ bản | 3 pts | Toàn | Project foundation | Chưa làm |
| P0 | Login screen: validation, gọi auth service, lưu trạng thái đăng nhập, route theo role | 4 pts | Toàn | API client | Chưa làm |
| P0 | Register screen: form đại lý, validate email/phone/password/tax code, success/error state | 3 pts | Tâm | Auth models | Chưa làm |
| P0 | Home screen: banner, categories, featured products, quick search entry | 3 pts | Hoàng | Product mock data | Chưa làm |
| P1 | BLoC/Cubit wiring cho auth/product/loading/error | 2 pts | Tâm | Foundation | Chưa làm |
| P1 | Product list: image/name/origin/price/min quantity/stock, search/filter, empty state | 4 pts | Hoàng | Product repository | Chưa làm |
| P1 | Product detail: price tiers, min quantity, stock validation, add-to-cart placeholder | 3 pts | Tâm | Product repository | Chưa làm |
| P2 | Seed data sản phẩm hải sản phục vụ demo | 2 pts | Hoàng | Product models | Chưa làm |

**Planned Capacity:** 24 pts
**Sprint Load:** 19 pts committed P0 + 11 pts stretch/backlog buffer. Nên commit P0 trước, chỉ kéo P1/P2 khi P0 ổn.

### Success Criteria

- Có app Flutter chạy được trên Android emulator/device.
- Login/register có validation và phản hồi lỗi rõ ràng.
- Sau login, user role Đại lý vào được Home.
- Home -> Product List -> Product Detail hoạt động đúng.
- Product list có search/filter và empty state.
- Code có cấu trúc đủ để mở rộng cart/order ở Sprint 2.

## Sprint 2: Cart, Checkout, Orders, Notifications

**Sprint Goal:** Hoàn thành luồng mua hàng chính từ thêm vào giỏ đến tạo đơn và theo dõi trạng thái đơn.

| Priority | Item | Estimate | Owner | Dependencies | Status |
|---|---|---:|---|---|---|
| P0 | Cart state: thêm/sửa/xóa item, tính tổng tiền, xử lý cart rỗng | 4 pts | Tâm | Product detail | Chưa làm |
| P0 | Cart screen: danh sách sản phẩm, tăng/giảm số lượng, xóa item | 3 pts | Tâm | Cart state | Chưa làm |
| P0 | Checkout screen: thông tin nhận hàng, phương thức thanh toán, ghi chú | 4 pts | Hoàng | Cart state | Chưa làm |
| P0 | Create order flow: validate, tạo order, clear cart, success screen | 4 pts | Hoàng | Checkout | Chưa làm |
| P0 | Orders list/detail cho Đại lý: trạng thái chờ duyệt/xác nhận/đang giao/hoàn tất/hủy | 4 pts | Toàn | Order model/repository | Chưa làm |
| P1 | Notifications list: đã đọc/chưa đọc, mở màn liên quan | 3 pts | Toàn | Order events | Chưa làm |
| P1 | Staff/Admin cập nhật trạng thái đơn ở mức tối thiểu | 3 pts | Toàn | Role routing | Chưa làm |
| P2 | Sync cart lên server khi có API thật | 3 pts | Tâm | `/api/cart/sync` | Chưa làm |

**Recommended Load:** 19-20 pts P0, P1 nếu còn thời gian.

## Sprint 3: Messaging, Profile, Map

**Sprint Goal:** Bổ sung các chức năng hỗ trợ sau bán hàng: chat, hồ sơ cá nhân, kho hàng và điều hướng thông báo.

| Priority | Item | Estimate | Owner | Dependencies | Status |
|---|---|---:|---|---|---|
| P0 | Profile screen: xem/sửa số điện thoại, địa chỉ, avatar placeholder | 4 pts | Tâm | Auth state | Chưa làm |
| P0 | Logout/change password placeholder flow | 2 pts | Tâm | Profile | Chưa làm |
| P0 | Chat screen: gửi tin nhắn, lịch sử, phân biệt user/staff/AI, timestamp | 5 pts | Hoàng | Chat model/repository | Chưa làm |
| P0 | Chặn tin nhắn rỗng, loading/error state cho chat | 2 pts | Hoàng | Chat screen | Chưa làm |
| P1 | AI/sample reply flow cho câu hỏi đơn giản về sản phẩm, giá, tồn kho, đơn hàng | 4 pts | Hoàng | Product/order data | Chưa làm |
| P1 | Warehouse map: marker, thông tin kho, mở Google Maps | 4 pts | Toàn | Warehouse data | Chưa làm |
| P1 | Xử lý quyền vị trí nếu dùng current location | 3 pts | Toàn | Map plugin | Chưa làm |
| P2 | Deep link từ notification sang order/product/chat | 3 pts | Toàn | Notifications | Chưa làm |

**Recommended Load:** 18-20 pts, tránh kéo cả AI polish và permission nâng cao nếu map/chat chưa ổn.

## Sprint 4: Full Admin Dashboard

**Sprint Goal:** Hoàn thiện khu vực Admin/Staff đầy đủ theo docx để quản lý dashboard, sản phẩm, người dùng, đơn hàng và hỗ trợ chat.

| Priority | Item | Estimate | Owner | Dependencies | Status |
|---|---|---:|---|---|---|
| P0 | Admin/Staff route guard theo role | 3 pts | Toàn | Auth role | Chưa làm |
| P0 | Admin dashboard overview: orders, revenue sample, products, users | 4 pts | Toàn | Admin data | Chưa làm |
| P0 | Product management: list/create/update/delete, stock/status | 5 pts | Hoàng | Product repository | Chưa làm |
| P0 | Order status management cho Staff/Admin | 4 pts | Tâm | Orders | Chưa làm |
| P0 | User management: danh sách user, duyệt đại lý, phân biệt role | 4 pts | Toàn | Users API/mock | Chưa làm |
| P0 | Staff chat response view và complaint handoff cơ bản | 4 pts | Hoàng | Messaging | Chưa làm |
| P1 | Admin dashboard loading/error/empty states | 3 pts | Cả nhóm | Admin screens | Chưa làm |

**Recommended Load:** 24 pts P0. Nếu thiếu thời gian, giảm độ sâu UI polish nhưng không cắt các module Admin chính.

## Sprint 5: Spring Boot API Integration, Demo Hardening

**Sprint Goal:** Đổi mock repository sang Spring Boot REST API, kiểm thử luồng demo end-to-end và ổn định app trước khi trình bày.

| Priority | Item | Estimate | Owner | Dependencies | Status |
|---|---|---:|---|---|---|
| P0 | API integration pass: đổi mock repository sang Spring Boot REST endpoints chính | 6 pts | Cả nhóm | Backend availability | Chưa làm |
| P0 | Auth integration: login/register/JWT storage/role routing với Spring Boot | 4 pts | Toàn | Auth API | Chưa làm |
| P0 | Product/order integration: products, cart sync, checkout, orders | 5 pts | Hoàng | Product/order API | Chưa làm |
| P1 | Admin integration: dashboard, products, users, order status | 5 pts | Tâm | Admin API | Chưa làm |
| P0 | End-to-end demo test: login -> browse -> cart -> checkout -> order -> notification/chat -> admin update | 5 pts | Cả nhóm | Full flow | Chưa làm |
| P1 | UI polish, loading/error/empty states, fix responsive Android screens | 4 pts | Cả nhóm | Full app | Chưa làm |
| P2 | Replace sample AI response rules with API-backed response later if backend supports it | 3 pts | Hoàng | AI/API availability | Chưa làm |

**Recommended Load:** 20 pts P0. Nếu Spring Boot API chưa sẵn sàng, giữ mock implementation nhưng hoàn thiện demo script và test data. Admin integration và UI polish là P1 hardening nếu P0 đã ổn.

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| API/backend chưa sẵn sàng | Flutter team bị chặn ở auth, products, orders | Dùng repository interface + mock data ngay từ Sprint 1; đổi implementation sang REST sau |
| Scope quá rộng cho 3 người | Không demo được luồng chính | Ưu tiên P0 theo flow mua hàng và Full Admin Dashboard; AI thật và map nâng cao để sau demo |
| State management không thống nhất | Dễ lỗi cart/order/auth khi tích hợp | Dùng BLoC/Cubit từ đầu: Cubit cho screen đơn giản, BLoC cho auth/checkout/orders/admin |
| Role Admin/Staff/User phức tạp | Sai route hoặc lộ màn quản trị | Route guard theo role, test riêng login từng role |
| Map/permission tốn thời gian | Chậm tiến độ core commerce flow | Map chỉ cần marker + open Google Maps cho MVP; current location là stretch |
| AI support không có backend/LLM | Không hoàn thành đúng kỳ vọng | Dùng sample responses theo rule cho demo phase; AI thật là scope sau |

## Definition of Done

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

## Suggested Demo Script

1. Đăng nhập bằng tài khoản Đại lý.
2. Vào Home, xem category và sản phẩm nổi bật.
3. Tìm/lọc sản phẩm trong Product List.
4. Mở Product Detail, xem giá sỉ và số lượng tối thiểu.
5. Thêm sản phẩm vào Cart, chỉnh số lượng.
6. Checkout, nhập địa chỉ, chọn thanh toán, tạo order.
7. Xem Orders và trạng thái đơn.
8. Nhận notification hoặc mở chat hỗ trợ.
9. Đăng nhập Admin/Staff, xem dashboard và cập nhật trạng thái đơn.

## Decisions

| Topic | Decision |
|---|---|
| Sprint duration | 1 tuần/sprint |
| Backend/API | Mock data trước, sau đó tích hợp Spring Boot REST API |
| State management | BLoC/Cubit: Cubit cho màn hình đơn giản, BLoC cho flow phức tạp |
| Admin scope | Full Admin Dashboard |
| AI support | Sample responses cho demo phase |
