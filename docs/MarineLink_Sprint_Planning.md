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
- Hỗ trợ AI: dùng sample responses trong giai đoạn demo, chưa cần gọi model thật.
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
| Luồng mua hàng | Cart state, màn giỏ hàng, form checkout, màn đặt hàng thành công | `/api/cart/sync`, `/api/orders`, tính lại giá, validate tồn kho/min quantity | `carts`, `cart_items`, `orders`, `order_items`, rule sinh order code | Test luồng checkout thành công, case quantity sai/cart rỗng |
| Theo dõi đơn hàng | Danh sách/chi tiết đơn, status badge, timeline đơn hàng | `/api/orders`, `/api/orders/{id}`, `/api/orders/{id}/status` cho Staff/Admin | `order_status_history`, index đơn/trạng thái, liên kết notification | E2E luồng đặt hàng, test đổi trạng thái không hợp lệ |
| Thông báo | Danh sách thông báo, trạng thái đã đọc/chưa đọc, mở sang màn liên quan | `/api/notifications`, `/api/notifications/{id}/read`, tạo event từ order/chat | `notifications`, cột liên kết order/product/chat, index unread | Verify rule chỉ chủ sở hữu được mark read, dữ liệu demo notification |
| Chat/AI mẫu | UI chat, ô nhập tin nhắn, placeholder attachment, hiển thị AI sample | `/api/chat/send`, `/api/chat/{roomId}`, sample response service, validate metadata attachment | `chat_rooms`, `chat_messages`, `chat_attachments`, `complaints` | Test chặn tin nhắn rỗng, kịch bản AI sample |
| Hồ sơ cá nhân | Xem/sửa profile, phần tạm cho đổi mật khẩu và avatar | `/api/users/me`, validate cập nhật profile, cleanup logout nếu cần | Các field profile và index trong `users` đã bao phủ | Test validation profile và ownership |
| Bản đồ kho | Danh sách kho/marker bản đồ, mở Google Maps, xử lý permission nếu cần | `/api/warehouses`, filter kho đang hoạt động | `warehouses`, field tọa độ, active index, seed 2 kho | Fallback khi permission/plugin bản đồ chưa sẵn sàng |
| Dashboard Admin đầy đủ | Dashboard admin, UI CRUD sản phẩm, quản lý user/role, UI đơn/trạng thái, staff chat view | `/api/admin/dashboard`, `/api/admin/products`, `/api/admin/users`, role guard, rule service admin | Query admin trên users/products/orders/complaints/chat, rule soft delete/status | Smoke test admin bằng tài khoản ADMIN/STAFF/USER |
| Hoàn thiện demo | Loading, empty, error, validation text, polish responsive Android | Lỗi trả về thống nhất, timeout handling, sample data endpoint nếu cần | Refresh seed demo, bảo đảm không lộ test password/plain secret | Chạy thử kịch bản demo, checklist regression |

### Phân chia theo sprint và nhóm việc

| Sprint | FE Flutter | BE Spring Boot/API | DB Supabase/PostgreSQL | QA/Demo/Docs |
|---|---|---|---|---|
| Sprint 1 | Nền tảng app, màn auth, home/product list/detail bằng mock repository | API envelope, khung contract auth/product, DTO tương thích mock | Migration nền cho roles/users/catalog, seed products/categories | Smoke test Flutter, checklist validation auth/product |
| Sprint 2 | Cart, checkout, orders list/detail, điểm vào notification | Cart sync, tạo order, API query/status đơn, tạo notification | Migration cart/order/order item/status history/notification | E2E luồng mua hàng, test cart/order không hợp lệ |
| Sprint 3 | Profile, chat, warehouse map, điều hướng từ notification | API profile, chat send/history, warehouses, rule AI sample response | Field liên quan profile/chat, warehouses, complaints/attachments nếu dùng | Test fallback chat/profile/map, cập nhật dữ liệu demo |
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
| P0 | Luồng mua hàng | Cart, checkout, tạo order, clear cart sau khi đặt hàng | `/api/cart/sync`, `/api/orders`, `carts`, `cart_items`, `orders`, `order_items` | Chưa làm |
| P0 | Theo dõi đơn hàng | Danh sách đơn, chi tiết đơn, trạng thái đơn hàng | `/api/orders`, `/api/orders/{id}`, `/api/orders/{id}/status`, `notifications` | Chưa làm |
| P1 | Thông báo | Danh sách thông báo, đã đọc/chưa đọc, điều hướng sang màn liên quan | `/api/notifications`, `/api/notifications/{id}/read` | Chưa làm |
| P1 | Chat/hỗ trợ | Chat với Staff/AI, lịch sử chat, file đính kèm, chặn tin nhắn rỗng | `/api/chat/send`, `/api/chat/{roomId}`, `chat_rooms`, `chat_messages`, `chat_attachments`, `complaints` | Chưa làm |
| P1 | Hồ sơ cá nhân | Xem/sửa hồ sơ, đổi mật khẩu, logout | `/api/users/me`, `/api/auth/logout`, `users` | Chưa làm |
| P1 | Bản đồ kho | Bản đồ kho hàng, marker, mở Google Maps, xử lý quyền vị trí | `/api/warehouses`, `warehouses` | Chưa làm |
| P0 | Dashboard Admin đầy đủ | Tổng quan, quản lý sản phẩm/người dùng/role/đơn hàng, xử lý trạng thái, hỗ trợ chat | `/api/admin/dashboard`, `/api/admin/products`, `/api/admin/users` | Chưa làm |
| P1 | Hỗ trợ AI mẫu | Câu trả lời mẫu có ngữ cảnh sản phẩm, giá, tồn kho, đơn hàng cho demo | `chat_messages`, `products`, `orders` | Chưa làm |
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

| Mã | Ưu tiên | Hạng mục | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---:|---|---|
| S1-01 | P0 | Khởi tạo cấu trúc Flutter project, routing, theme, shared widgets | 3 pts | Không có | Xong |
| S1-02 | P0 | Tạo models cho User, Product, Category, PriceTier và API response envelope | 3 pts | Docx database/API | Xong |
| S1-03 | P0 | Tạo API client/mock repository, JWT storage interface, error handling cơ bản | 3 pts | Nền tảng dự án | Xong |
| S1-04 | P0 | Màn login: validation, gọi auth service, lưu trạng thái đăng nhập, route theo role | 4 pts | API client | Xong |
| S1-05 | P0 | Màn register: form đại lý, validate email/phone/password/tax code, success/error state | 3 pts | Auth models | Xong |
| S1-06 | P0 | Màn home: banner, categories, featured products, quick search entry | 3 pts | Product mock data | Xong |
| S1-07 | P1 | Wiring BLoC/Cubit cho auth/product/loading/error | 2 pts | Nền tảng | Xong |
| S1-08 | P1 | Product list: image/name/origin/price/min quantity/stock, search, category chips, stock filter, price sort, empty state/reset filter | 4 pts | Product repository | Xong |
| S1-09 | P1 | Product detail: price tiers, min quantity, stock validation, add-to-cart tạm | 3 pts | Product repository | Xong |
| S1-10 | P2 | Seed data sản phẩm hải sản phục vụ demo | 2 pts | Product models | Xong |

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

| Mã | Ưu tiên | Hạng mục | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---:|---|---|
| S2-01 | P0 | Cart state: thêm/sửa/xóa item, tính tổng tiền, xử lý cart rỗng | 4 pts | Product detail | Chưa làm |
| S2-02 | P0 | Cart screen: danh sách sản phẩm, tăng/giảm số lượng, xóa item | 3 pts | Cart state | Chưa làm |
| S2-03 | P0 | Checkout screen: thông tin nhận hàng, phương thức thanh toán, ghi chú | 4 pts | Cart state | Chưa làm |
| S2-04 | P0 | Luồng tạo order: validate, tạo order, clear cart, màn thành công | 4 pts | Checkout | Chưa làm |
| S2-05 | P0 | Orders list/detail cho Đại lý: trạng thái chờ duyệt/xác nhận/đang giao/hoàn tất/hủy | 4 pts | Order model/repository | Chưa làm |
| S2-06 | P1 | Danh sách notification: đã đọc/chưa đọc, mở màn liên quan | 3 pts | Order events | Chưa làm |
| S2-07 | P1 | Staff/Admin cập nhật trạng thái đơn ở mức tối thiểu | 3 pts | Role routing | Chưa làm |
| S2-08 | P2 | Sync cart lên server khi có API thật | 3 pts | `/api/cart/sync` | Chưa làm |

**Tải khuyến nghị:** 19-20 pts P0, kéo P1 nếu còn thời gian.

## Sprint 3: Chat, hồ sơ, bản đồ

**Mục tiêu sprint:** Bổ sung các chức năng hỗ trợ sau bán hàng: chat, hồ sơ cá nhân, kho hàng và điều hướng thông báo.

| Mã | Ưu tiên | Hạng mục | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---:|---|---|
| S3-01 | P0 | Màn profile: xem/sửa số điện thoại, địa chỉ, avatar tạm | 4 pts | Auth state | Chưa làm |
| S3-02 | P0 | Luồng logout/đổi mật khẩu tạm | 2 pts | Profile | Chưa làm |
| S3-03 | P0 | Chat screen: gửi tin nhắn, lịch sử, phân biệt user/staff/AI, timestamp | 5 pts | Chat model/repository | Chưa làm |
| S3-04 | P0 | Chặn tin nhắn rỗng, loading/error state cho chat | 2 pts | Chat screen | Chưa làm |
| S3-05 | P1 | AI/sample reply flow cho câu hỏi đơn giản về sản phẩm, giá, tồn kho, đơn hàng | 4 pts | Product/order data | Chưa làm |
| S3-06 | P1 | Bản đồ kho: marker, thông tin kho, mở Google Maps | 4 pts | Warehouse data | Chưa làm |
| S3-07 | P1 | Xử lý quyền vị trí nếu dùng current location | 3 pts | Map plugin | Chưa làm |
| S3-08 | P2 | Deep link từ notification sang order/product/chat | 3 pts | Notifications | Chưa làm |

**Tải khuyến nghị:** 18-20 pts, tránh kéo cả AI polish và permission nâng cao nếu map/chat chưa ổn.

## Sprint 4: Dashboard Admin đầy đủ

**Mục tiêu sprint:** Hoàn thiện khu vực Admin/Staff đầy đủ theo docx để quản lý dashboard, sản phẩm, người dùng, đơn hàng và hỗ trợ chat.

| Mã | Ưu tiên | Hạng mục | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---:|---|---|
| S4-01 | P0 | Admin/Staff route guard theo role | 3 pts | Auth role | Chưa làm |
| S4-02 | P0 | Admin dashboard overview: orders, revenue sample, products, users | 4 pts | Admin data | Chưa làm |
| S4-03 | P0 | Product management: list/create/update/delete, stock/status | 5 pts | Product repository | Chưa làm |
| S4-04 | P0 | Order status management cho Staff/Admin | 4 pts | Orders | Chưa làm |
| S4-05 | P0 | User management: danh sách user, duyệt đại lý, phân biệt role | 4 pts | Users API/mock | Chưa làm |
| S4-06 | P0 | Màn staff phản hồi chat và chuyển complaint cơ bản | 4 pts | Messaging | Chưa làm |
| S4-07 | P1 | Admin dashboard loading/error/empty states | 3 pts | Admin screens | Chưa làm |

**Tải khuyến nghị:** 24 pts P0. Nếu thiếu thời gian, giảm độ sâu UI polish nhưng không cắt các module Admin chính.

## Sprint 5: Tích hợp Spring Boot API, hardening demo

**Mục tiêu sprint:** Đổi mock repository sang Spring Boot REST API, kiểm thử luồng demo end-to-end và ổn định app trước khi trình bày.

| Mã | Ưu tiên | Hạng mục | Ước lượng | Phụ thuộc | Trạng thái |
|---|---|---|---:|---|---|
| S5-01 | P0 | Pass tích hợp API: đổi mock repository sang Spring Boot REST endpoints chính | 6 pts | Backend sẵn sàng | Đang làm - Auth/Product remote đã có |
| S5-02 | P0 | Tích hợp auth: login/register/JWT storage/role routing với Spring Boot | 4 pts | Auth API | Xong phần login/register/me |
| S5-03 | P0 | Tích hợp product/order: products, cart sync, checkout, orders | 5 pts | Product/order API | Đang làm - Product remote xong, cart/order chưa |
| S5-04 | P1 | Tích hợp admin: dashboard, products, users, order status | 5 pts | Admin API | Chưa làm |
| S5-05 | P0 | Test demo end-to-end: login -> browse -> cart -> checkout -> order -> notification/chat -> admin update | 5 pts | Full flow | Chưa làm |
| S5-06 | P1 | UI polish, loading/error/empty states, fix responsive Android screens | 4 pts | Full app | Chưa làm |
| S5-07 | P2 | Đổi rule AI sample sang response qua API sau này nếu backend hỗ trợ | 3 pts | AI/API sẵn sàng | Chưa làm |

**Tải khuyến nghị:** 20 pts P0. Nếu Spring Boot API chưa sẵn sàng, giữ mock implementation nhưng hoàn thiện kịch bản demo và dữ liệu test. Admin integration và UI polish là phần hardening P1 nếu P0 đã ổn.

## Rủi ro

| Rủi ro | Ảnh hưởng | Cách xử lý |
|---|---|---|
| API/backend chưa sẵn sàng | Flutter team bị chặn ở auth, products, orders | Dùng repository interface + mock data ngay từ Sprint 1; đổi implementation sang REST sau |
| Scope quá rộng cho 3 người | Không demo được luồng chính | Ưu tiên P0 theo flow mua hàng và Dashboard Admin đầy đủ; AI thật và map nâng cao để sau demo |
| Quản lý state không thống nhất | Dễ lỗi cart/order/auth khi tích hợp | Dùng BLoC/Cubit từ đầu: Cubit cho screen đơn giản, BLoC cho auth/checkout/orders/admin |
| Role Admin/Staff/User phức tạp | Sai route hoặc lộ màn quản trị | Route guard theo role, test riêng login từng role |
| Map/permission tốn thời gian | Chậm tiến độ core commerce flow | Map chỉ cần marker + open Google Maps cho MVP; current location là stretch |
| Hỗ trợ AI không có backend/LLM | Không hoàn thành đúng kỳ vọng | Dùng sample responses theo rule cho demo phase; AI thật là scope sau |

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
| Hỗ trợ AI | Sample responses cho demo phase |
