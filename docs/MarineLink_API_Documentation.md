# MarineLink API Documentation

Nguồn: `docs/MarineLink_Main_Functions_Specification_v3.docx`, `docs/MarineLink_BE_Architecture.md`, `docs/MarineLink_FE_Architecture.md`, `docs/MarineLink_Supabase_DB_Design.md`

## 1. Mục tiêu

Tài liệu này là API contract cho MarineLink MVP. Frontend Flutter dùng tài liệu này để viết repository/DTO, backend Spring Boot dùng tài liệu này để triển khai controller/service/test, và database mapping dùng tài liệu này để đối chiếu bảng Supabase/PostgreSQL.

MVP không dùng Supabase REST trực tiếp cho dữ liệu cần phân quyền. Flutter gọi Spring Boot REST API, Spring Boot xác thực JWT, kiểm tra role, xử lý business rule, sau đó đọc/ghi Supabase PostgreSQL.

## 2. Base Contract

| Chủ đề | Quy ước |
|---|---|
| Base path | `/api` |
| Transport | HTTPS ở môi trường deploy; HTTP chỉ dùng local/dev |
| Format | JSON |
| Auth | JWT Bearer token |
| Time | ISO-8601 string, ví dụ `2026-05-28T08:30:00Z` |
| ID | UUIDv4 public ID string from database `public_id`; internal DB `id bigint` is never exposed |
| Money | number, đơn vị VND, dùng `numeric(12,2)` ở database |
| Pagination | `page`, `size`, `totalElements`, `totalPages` |
| Google login | Out of MVP; chỉ thêm sau khi có OAuth provider, callback và account linking |
| Repo contract owner | File này là contract chung cho `frontend/` Flutter và `backend/` Spring Boot |

Header mặc định:

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <jwt>
```

Public endpoint không cần `Authorization`.

ID rule:

- Every resource returned by API uses the database `public_id` UUIDv4 as its JSON `id`.
- Request fields such as `productId`, `orderId`, `roomId`, `notificationId`, `categoryId` are also public UUIDv4 values.
- Backend resolves public UUIDv4 IDs to internal `bigint id` before joining/querying tables.
- Never return internal `bigint id` to Flutter.

Monorepo rule:

- Flutter chỉ gọi Spring Boot qua endpoint trong tài liệu này.
- Spring Boot phải có controller/DTO/test tương ứng trước khi FE đổi mock repository sang remote repository.
- Khi đổi endpoint, request/response field, role rule hoặc status code, cập nhật tài liệu này trước rồi mới sửa code FE/BE.

## 3. Roles

| Role | Ý nghĩa | Quyền chính |
|---|---|---|
| `USER` | Đại lý mua hàng | Xem sản phẩm, cart, checkout, xem đơn của mình, chat, notifications, profile |
| `STAFF` | Nhân viên xử lý vận hành | Xem/cập nhật đơn được giao, phản hồi chat, xử lý complaint |
| `ADMIN` | Quản trị hệ thống | Full dashboard, quản lý sản phẩm, user/role, đơn hàng |

Authorization rules:

- User chỉ được xem/sửa dữ liệu của chính mình.
- Staff không tự động có toàn quyền admin.
- Admin có quyền quản lý dashboard, sản phẩm, user, role, đơn hàng.
- Role lấy trực tiếp từ bảng `users` qua cột `role_id` liên kết với `roles`, không dùng bảng trung gian hay cột string `users.role`.

## 4. Response Envelope

Success response:

```json
{
  "success": true,
  "data": {},
  "message": "OK",
  "pagination": {
    "page": 0,
    "size": 20,
    "totalElements": 100,
    "totalPages": 5
  }
}
```

Nếu endpoint không phân trang, `pagination` có thể là `null` hoặc không trả về.

Error response:

```json
{
  "success": false,
  "data": null,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Email không hợp lệ"
    }
  ]
}
```

## 5. HTTP Status Codes

| Code | Dùng khi |
|---:|---|
| 200 | GET/PUT/PATCH/DELETE thành công |
| 201 | POST tạo resource thành công |
| 204 | Logout hoặc delete/soft delete thành công và không cần body |
| 400 | Request sai format hoặc thiếu field bắt buộc |
| 401 | Thiếu token hoặc token không hợp lệ |
| 403 | Có token nhưng không đủ quyền |
| 404 | Không tìm thấy resource hoặc resource không thuộc quyền truy cập |
| 409 | Conflict như email/phone/order state bị trùng hoặc không hợp lệ |
| 422 | Dữ liệu đúng JSON nhưng vi phạm business rule |
| 429 | Login/register bị rate limit |
| 500 | Lỗi hệ thống, không trả stack trace cho client |

## 6. Common Query Params

Pagination:

| Param | Type | Default | Note |
|---|---|---:|---|
| `page` | int | 0 | Trang bắt đầu từ 0 |
| `size` | int | 20 | Nên giới hạn tối đa 100 |

Product list:

| Param | Type | Note |
|---|---|---|
| `q` | string | Search theo name/origin/description |
| `categoryId` | uuid | Lọc theo category |
| `status` | `ACTIVE`, `OUT_OF_STOCK`, `DISABLED` | Public MVP mặc định gửi `ACTIVE`; chỉ expose `OUT_OF_STOCK` nếu business cho phép |
| `featured` | boolean | Home featured products |
| `sort` | string | Whitelist: `newest`, `price_asc`, `price_desc`, `name_asc`, `name_desc` |

Product list MVP dùng `q`, `categoryId`, `status`, `featured`, `sort`. UI có thể lọc `Còn hàng`/`Sắp hết` từ `status`, `stockQuantity`, `minOrderQuantity` của response hiện tại. Các query params mở rộng như `minPrice`, `maxPrice`, `minOrderQuantity`, `origin` chưa thuộc contract MVP; nếu thêm phải cập nhật tài liệu này, `marinelink_openapi.json`, backend query, DB index và test contract.

Orders:

| Param | Type | Note |
|---|---|---|
| `status` | `PENDING`, `CONFIRMED`, `SHIPPING`, `COMPLETED`, `CANCELLED` | Lọc trạng thái |
| `fromDate` | ISO date | Lọc từ ngày |
| `toDate` | ISO date | Lọc đến ngày |

## 7. Endpoint Summary

| Method | Endpoint | Role |
|---|---|---|
| POST | `/api/auth/login` | Public |
| POST | `/api/auth/register` | Public |
| POST | `/api/auth/logout` | Authenticated |
| GET | `/api/users/me` | Authenticated |
| PUT | `/api/users/me` | Authenticated |
| GET | `/api/users/me/shipping-addresses` | USER |
| POST | `/api/users/me/shipping-addresses` | USER |
| PUT | `/api/users/me/shipping-addresses/{id}` | USER owner |
| DELETE | `/api/users/me/shipping-addresses/{id}` | USER owner |
| GET | `/api/products` | All roles |
| GET | `/api/products/{id}` | All roles |
| GET | `/api/cart` | USER |
| POST | `/api/cart/items` | USER |
| PATCH | `/api/cart/items/{productId}` | USER |
| DELETE | `/api/cart/items/{productId}` | USER |
| DELETE | `/api/cart/items` | USER |
| POST | `/api/cart/sync` | USER |
| POST | `/api/orders` | USER |
| GET | `/api/orders` | USER own orders, STAFF, ADMIN |
| GET | `/api/orders/{id}` | Owner, STAFF, ADMIN |
| PUT | `/api/orders/{id}/status` | STAFF, ADMIN |
| POST | `/api/chat/send` | All roles |
| GET | `/api/chat/{roomId}` | Participant, STAFF, ADMIN |
| GET | `/api/notifications` | Authenticated |
| PUT | `/api/notifications/{id}/read` | Owner |
| GET | `/api/warehouses` | All roles |
| GET | `/api/admin/dashboard` | ADMIN |
| GET | `/api/admin/products` | ADMIN |
| POST | `/api/admin/products` | ADMIN |
| GET | `/api/admin/products/{id}` | ADMIN |
| PUT | `/api/admin/products/{id}` | ADMIN |
| DELETE | `/api/admin/products/{id}` | ADMIN |
| GET | `/api/admin/users` | ADMIN |
| GET | `/api/admin/users/{id}` | ADMIN |
| PUT | `/api/admin/users/{id}` | ADMIN |
| PUT | `/api/admin/users/{id}/role` | ADMIN |

## 8. Auth APIs

### POST `/api/auth/login`

Đăng nhập bằng email hoặc số điện thoại.

Request:

```json
{
  "emailOrPhone": "admin@marinelink.demo",
  "password": "demo-password"
}
```

Response `200`:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "jwt-token",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "fullName": "MarineLink Admin",
      "email": "admin@marinelink.demo",
      "phone": "0900000000",
      "status": "ACTIVE",
      "roles": ["ADMIN"]
    }
  }
}
```

Validation/business rules:

- Password được verify bằng BCrypt hash.
- User `DISABLED` không được đăng nhập.
- User `PENDING_APPROVAL` có thể bị chặn hoặc chỉ vào màn hình chờ duyệt tùy rule triển khai.
- Login/register nên có rate limit.

### POST `/api/auth/register`

Đăng ký đại lý mới.

Request:

```json
{
  "fullName": "Nguyen Van A",
  "email": "daily-a@example.com",
  "phone": "0912345678",
  "password": "StrongPassword123",
  "storeName": "Hai San A",
  "businessAddress": "Can Tho",
  "taxCode": "0312345678"
}
```

Response `201`:

```json
{
  "success": true,
  "message": "Register successful",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "status": "PENDING_APPROVAL",
    "roles": ["USER"]
  }
}
```

Validation/business rules:

- `email` và `phone` phải unique theo user chưa soft delete.
- Password không trả về response.
- Backend gán role mặc định `USER` qua cột `role_id` của `users`.

### POST `/api/auth/logout`

Logout user hiện tại.

Response `204`: không body.

Nếu MVP chỉ dùng stateless JWT, frontend xóa token local. Nếu backend có refresh token hoặc denylist, endpoint này xử lý cleanup server-side.

## 9. Profile APIs

### GET `/api/users/me`

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "fullName": "Nguyen Van A",
    "email": "daily-a@example.com",
    "phone": "0912345678",
    "status": "ACTIVE",
    "storeName": "Hai San A",
    "businessAddress": "Can Tho",
    "taxCode": "0312345678",
    "avatarUrl": "https://example.com/avatar.png",
    "roles": ["USER"]
  }
}
```

### PUT `/api/users/me`

Request:

```json
{
  "fullName": "Nguyen Van A",
  "phone": "0912345678",
  "businessAddress": "Can Tho",
  "avatarUrl": "https://example.com/avatar.png"
}
```

Response `200`: trả profile mới.

Rules:

- User không được tự đổi role/status.
- Không trả `passwordHash`.

### Shipping address APIs

Shipping addresses are stored per current user and reused by checkout. Orders still snapshot
`receiverName`, `receiverPhone`, and `shippingAddress` so old orders are not changed when a
saved address is edited later.

#### GET `/api/users/me/shipping-addresses`

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440071",
      "label": "Kho Can Tho",
      "receiverName": "Nguyen Van A",
      "receiverPhone": "0912345678",
      "addressLine": "123 Tran Hung Dao, Can Tho",
      "default": true,
      "createdAt": "2026-06-04T01:00:00Z",
      "updatedAt": "2026-06-04T01:00:00Z"
    }
  ]
}
```

#### POST `/api/users/me/shipping-addresses`

Request:

```json
{
  "label": "Kho Can Tho",
  "receiverName": "Nguyen Van A",
  "receiverPhone": "0912345678",
  "addressLine": "123 Tran Hung Dao, Can Tho",
  "default": false
}
```

Response `201`: saved address. If this is the first address for the user, backend sets
`default = true` even when the request sends `false`.

#### PUT `/api/users/me/shipping-addresses/{id}`

Updates one saved address owned by the current user. If `default = true`, backend clears the
previous default address for that user.

#### DELETE `/api/users/me/shipping-addresses/{id}`

Soft deletes one saved address owned by the current user. If the deleted address was default,
backend promotes another active address when one exists.

## 10. Product APIs

### GET `/api/products`

Query params: `page`, `size`, `q`, `categoryId`, `status`, `featured`, `sort`.

Frontend Product List gửi `status=ACTIVE` cho catalog đại lý trong MVP. `sort=price_asc` là giá tăng dần, `sort=price_desc` là giá giảm dần; backend cũng hỗ trợ `newest`, `name_asc`, `name_desc`. Backend phải validate `sort` theo whitelist để tránh truyền trực tiếp field tùy ý vào query.

Demo data hiện tại được seed bởi `V010__seed_dried_seafood_catalog.sql`: 21 sản phẩm đồ khô, mỗi sản phẩm có ảnh public trong Supabase Storage bucket `product-images`.

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "name": "Muc kho loai 1",
      "slug": "muc-kho-loai-1",
      "origin": "Ca Mau",
      "imageUrl": "https://example.com/product.png",
      "basePrice": 450000,
      "unit": "kg",
      "minOrderQuantity": 2,
      "stockQuantity": 120,
      "status": "ACTIVE",
      "isFeatured": true,
      "category": {
        "id": "550e8400-e29b-41d4-a716-446655440004",
        "name": "Muc kho"
      }
    }
  ],
  "pagination": {
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1
  }
}
```

### GET `/api/products/{id}`

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440003",
    "name": "Muc kho loai 1",
    "description": "Muc kho phu hop don si",
    "origin": "Ca Mau",
    "basePrice": 450000,
    "unit": "kg",
    "minOrderQuantity": 2,
    "stockQuantity": 120,
    "status": "ACTIVE",
    "category": {
      "id": "550e8400-e29b-41d4-a716-446655440004",
      "name": "Muc kho"
    },
    "images": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440005",
        "imageUrl": "https://example.com/product.png",
        "altText": "Muc kho loai 1",
        "displayOrder": 0
      }
    ],
    "priceTiers": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440006",
        "minQuantity": 2,
        "maxQuantity": 9,
        "unitPrice": 450000
      },
      {
        "id": "550e8400-e29b-41d4-a716-446655440007",
        "minQuantity": 10,
        "maxQuantity": null,
        "unitPrice": 420000
      }
    ]
  }
}
```

## 11. Cart API

Cart API lưu active cart theo user hiện tại. Khi user đã đăng nhập, backend là source of truth để đổi thiết bị vẫn thấy giỏ hàng. FE vẫn có thể dùng `CartCubit` làm UI cache/optimistic state, nhưng thao tác cart chính phải gọi `GET /api/cart`, `POST /api/cart/items`, `PATCH /api/cart/items/{productId}`, `DELETE /api/cart/items/{productId}` và `DELETE /api/cart/items`.

`POST /api/cart/sync` là endpoint phụ, chỉ dùng để merge/sync cart local trước login, offline fallback hoặc migration demo; không dùng làm luồng cart chính hằng ngày.

Cart response chuẩn:

```json
{
  "success": true,
  "message": "Cart loaded",
  "data": {
    "cartId": "550e8400-e29b-41d4-a716-446655440008",
    "isEmpty": false,
    "items": [
      {
        "productId": "550e8400-e29b-41d4-a716-446655440003",
        "productName": "Muc kho loai 1",
        "productImageUrl": "https://example.com/products/muc-kho.png",
        "unit": "kg",
        "quantity": 10,
        "selected": true,
        "selectedPriceTierId": "550e8400-e29b-41d4-a716-446655440007",
        "unitPrice": 420000,
        "lineTotal": 4200000
      }
    ],
    "totalItemCount": 10,
    "totalSelectedItemCount": 10,
    "subtotalAmount": 4200000
  }
}
```

Với cart rỗng, `items` là `[]`, `isEmpty` là `true`, `totalItemCount`, `totalSelectedItemCount`, `subtotalAmount` đều bằng `0`.

### GET `/api/cart`

Lấy active cart của user hiện tại. Nếu user chưa có cart, backend tạo hoặc trả cart rỗng tùy implementation, nhưng response phải giữ shape `Cart response chuẩn`.

### POST `/api/cart/items`

Thêm item vào cart. Nếu product đã có trong cart, backend cộng dồn số lượng rồi tính lại price tier.

Request:

```json
{
  "productId": "550e8400-e29b-41d4-a716-446655440003",
  "quantity": 2,
  "selected": true
}
```

Response `200`: `Cart response chuẩn`.

### PATCH `/api/cart/items/{productId}`

Cập nhật số lượng hoặc trạng thái selected của một item. FE dùng endpoint này cho tăng/giảm số lượng và chọn/bỏ chọn item.

Request:

```json
{
  "quantity": 5,
  "selected": true
}
```

Response `200`: `Cart response chuẩn`.

### DELETE `/api/cart/items/{productId}`

Xóa một item khỏi cart.

Response `200`: `Cart response chuẩn`.

### DELETE `/api/cart/items`

Clear toàn bộ cart của user hiện tại.

Response `200`: `Cart response chuẩn` với cart rỗng.

### POST `/api/cart/sync`

Endpoint phụ để đồng bộ cart local của Flutter lên backend. Dùng khi user thêm sản phẩm trước login rồi đăng nhập, hoặc app có cache/offline cart cần merge vào server cart.

Luồng chính sau khi user đã đăng nhập vẫn là Cart API theo từng thao tác: load, add, update selected/quantity, remove và clear.

Request:

```json
{
  "items": [
    {
      "productId": "550e8400-e29b-41d4-a716-446655440003",
      "quantity": 10,
      "selected": true
    }
  ]
}
```

Response `200`:

```json
{
  "success": true,
  "message": "Cart synced",
  "data": {
    "cartId": "550e8400-e29b-41d4-a716-446655440008",
    "isEmpty": false,
    "items": [
      {
        "productId": "550e8400-e29b-41d4-a716-446655440003",
        "productName": "Muc kho loai 1",
        "productImageUrl": "https://example.com/products/muc-kho.png",
        "unit": "kg",
        "quantity": 10,
        "selected": true,
        "selectedPriceTierId": "550e8400-e29b-41d4-a716-446655440007",
        "unitPrice": 420000,
        "lineTotal": 4200000
      }
    ],
    "totalItemCount": 10,
    "totalSelectedItemCount": 10,
    "subtotalAmount": 4200000
  }
}
```

Rules:

- Backend không tin tổng tiền client gửi lên.
- Backend tính lại price tier theo `quantity`.
- Backend tính `lineTotal`, `totalItemCount`, `totalSelectedItemCount`, `subtotalAmount`; client không gửi các field này.
- `subtotalAmount` chỉ tính các item có `selected = true`; item không selected vẫn còn trong cart nhưng không tính vào checkout total.
- Cart API chính và `/api/cart/sync` đều trả về cùng một shape cart để FE cập nhật state thống nhất.
- Reject nếu product không tồn tại, disabled, hết hàng, hoặc quantity dưới `minOrderQuantity`.
- Mỗi user có một active cart trong MVP.

## 12. Order APIs

### POST `/api/orders`

Tạo đơn hàng từ active server-side cart của user hiện tại. Nếu FE có cart local/offline/pre-login thì gọi `POST /api/cart/sync` để merge trước; order endpoint không nhận line items và không tin tổng tiền client trong MVP.

Request:

```json
{
  "receiverName": "Nguyen Van A",
  "receiverPhone": "0912345678",
  "shippingAddress": "Can Tho",
  "paymentMethod": "COD",
  "note": "Giao buoi sang"
}
```

Response `201`:

```json
{
  "success": true,
  "message": "Order created",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440009",
    "orderCode": "ML-20260528-0001",
    "status": "PENDING",
    "paymentMethod": "COD",
    "paymentStatus": "UNPAID",
    "subtotalAmount": 4200000,
    "shippingFee": 0,
    "discountAmount": 0,
    "totalAmount": 4200000,
    "createdAt": "2026-05-28T08:30:00Z"
  }
}
```

Rules:

- Active server-side cart không rỗng và có ít nhất một item `selected = true`.
- Product còn hàng và quantity hợp lệ.
- Snapshot `productName`, `unit`, `unitPrice` vào `order_items`.
- Tạo notification khi order được tạo hoặc đổi trạng thái.
- Clear `cart_items` trong cùng transaction sau khi checkout thành công.

### GET `/api/orders`

Query params: `page`, `size`, `status`, `fromDate`, `toDate`.

Role behavior:

- USER chỉ thấy đơn của mình.
- STAFF thấy đơn mới/đơn được giao theo rule backend.
- ADMIN thấy toàn bộ.

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440009",
      "orderCode": "ML-20260528-0001",
      "status": "PENDING",
      "totalAmount": 4200000,
      "createdAt": "2026-05-28T08:30:00Z"
    }
  ],
  "pagination": {
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1
  }
}
```

### GET `/api/orders/{id}`

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440009",
    "orderCode": "ML-20260528-0001",
    "status": "PENDING",
    "receiverName": "Nguyen Van A",
    "receiverPhone": "0912345678",
    "shippingAddress": "Can Tho",
    "items": [
      {
        "productId": "550e8400-e29b-41d4-a716-446655440003",
        "productNameSnapshot": "Muc kho loai 1",
        "productUnitSnapshot": "kg",
        "unitPrice": 420000,
        "quantity": 10,
        "lineTotal": 4200000
      }
    ],
    "statusHistory": [
      {
        "fromStatus": null,
        "toStatus": "PENDING",
        "note": "Order created",
        "createdAt": "2026-05-28T08:30:00Z"
      }
    ]
  }
}
```

### PUT `/api/orders/{id}/status`

Staff/Admin cập nhật trạng thái đơn.

Request:

```json
{
  "status": "CONFIRMED",
  "note": "Da xac nhan hang"
}
```

Response `200`:

```json
{
  "success": true,
  "message": "Order status updated",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440009",
    "status": "CONFIRMED"
  }
}
```

Allowed transitions:

| From | To |
|---|---|
| `PENDING` | `CONFIRMED`, `CANCELLED` |
| `CONFIRMED` | `SHIPPING`, `CANCELLED` |
| `SHIPPING` | `COMPLETED` |
| `COMPLETED` | Không đổi |
| `CANCELLED` | Không đổi |

Invalid transition trả `409` hoặc `422`.

## 13. Messaging APIs

### POST `/api/chat/send`

Request:

```json
{
  "roomId": "550e8400-e29b-41d4-a716-44665544000a",
  "content": "Cho toi hoi don ML-20260528-0001 khi nao giao?",
  "attachments": [
    {
      "storageBucket": "chat-attachments",
      "storagePath": "rooms/36fbde33/file.png",
      "fileName": "file.png",
      "mimeType": "image/png",
      "fileSizeBytes": 102400
    }
  ]
}
```

Response `201`:

```json
{
  "success": true,
  "message": "Message sent",
  "data": {
    "id": "550e8400-e29b-41d4-a716-44665544000b",
    "roomId": "550e8400-e29b-41d4-a716-44665544000a",
    "senderType": "USER",
    "content": "Cho toi hoi don ML-20260528-0001 khi nao giao?",
    "createdAt": "2026-05-28T08:30:00Z"
  }
}
```

Rules:

- Chặn message rỗng.
- `senderType` là `USER`, `STAFF`, hoặc `AI_SAMPLE`.
- Demo phase dùng sample response theo keyword, chưa gọi LLM thật.

### GET `/api/chat/{roomId}`

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "roomId": "550e8400-e29b-41d4-a716-44665544000a",
    "isClosed": false,
    "messages": [
      {
        "id": "550e8400-e29b-41d4-a716-44665544000b",
        "senderType": "USER",
        "content": "Cho toi hoi don ML-20260528-0001 khi nao giao?",
        "createdAt": "2026-05-28T08:30:00Z",
        "attachments": []
      }
    ]
  }
}
```

## 14. Notification APIs

### GET `/api/notifications`

Query params: `page`, `size`, `isRead`.

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-44665544000c",
      "type": "ORDER",
      "title": "Don hang da xac nhan",
      "body": "Don ML-20260528-0001 da duoc xac nhan",
      "relatedOrderId": "550e8400-e29b-41d4-a716-446655440009",
      "relatedProductId": null,
      "relatedChatRoomId": null,
      "isRead": false,
      "createdAt": "2026-05-28T08:30:00Z"
    }
  ]
}
```

### PUT `/api/notifications/{id}/read`

Response `200`:

```json
{
  "success": true,
  "message": "Notification marked as read",
  "data": {
    "id": "550e8400-e29b-41d4-a716-44665544000c",
    "isRead": true,
    "readAt": "2026-05-28T08:31:00Z"
  }
}
```

Only owner can mark notification read.

## 15. Warehouse API

### GET `/api/warehouses`

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-44665544000d",
      "name": "Kho Can Tho",
      "address": "Can Tho",
      "phone": "0292000000",
      "openingHours": "08:00-17:00",
      "latitude": 10.0452000,
      "longitude": 105.7469000,
      "isActive": true
    }
  ]
}
```

## 16. Admin APIs

### GET `/api/admin/dashboard`

Response `200`:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "pendingOrders": 5,
    "monthlyRevenue": 125000000,
    "newComplaints": 2,
    "activeUsers": 18,
    "lowStockProducts": 3,
    "recentOrders": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440009",
        "orderCode": "ML-20260528-0001",
        "status": "PENDING",
        "totalAmount": 4200000
      }
    ]
  }
}
```

### Product management

The architecture docs summarize this area as `CRUD /api/admin/products`. Implement concrete endpoints as:

| Method | Endpoint | Use |
|---|---|---|
| GET | `/api/admin/products` | Admin product list with filters |
| POST | `/api/admin/products` | Create product |
| GET | `/api/admin/products/{id}` | Admin product detail |
| PUT | `/api/admin/products/{id}` | Update product |
| DELETE | `/api/admin/products/{id}` | Soft delete/disable product |

Create/update request:

```json
{
  "categoryId": "550e8400-e29b-41d4-a716-446655440004",
  "name": "Muc kho loai 1",
  "slug": "muc-kho-loai-1",
  "description": "Muc kho phu hop don si",
  "origin": "Ca Mau",
  "basePrice": 450000,
  "unit": "kg",
  "minOrderQuantity": 2,
  "stockQuantity": 120,
  "status": "ACTIVE",
  "isFeatured": true,
  "priceTiers": [
    {
      "minQuantity": 2,
      "maxQuantity": 9,
      "unitPrice": 450000
    },
    {
      "minQuantity": 10,
      "maxQuantity": null,
      "unitPrice": 420000
    }
  ]
}
```

Rules:

- Không hard delete product đã có `order_items`.
- Dùng soft delete/status nếu product đã từng được đặt hàng.
- Không để price tiers cùng product overlap.
- Admin product update phải audit nếu ảnh hưởng stock/status.

### User management

The architecture docs summarize this area as `CRUD /api/admin/users`. Implement concrete endpoints as:

| Method | Endpoint | Use |
|---|---|---|
| GET | `/api/admin/users` | List/filter users |
| GET | `/api/admin/users/{id}` | User detail |
| PUT | `/api/admin/users/{id}` | Update user status/profile admin fields |
| PUT | `/api/admin/users/{id}/role` | Replace the user's single role |

Update user request:

```json
{
  "status": "ACTIVE",
  "fullName": "Nguyen Van A",
  "phone": "0912345678",
  "businessAddress": "Can Tho"
}
```

Update role request:

```json
{
  "roleCode": "USER"
}
```

MVP giữ một user chỉ thuộc một role thông qua `users.role_id -> roles.id`. Các response auth vẫn có thể trả `roles: ["USER"]` để tương thích JWT/client guard, nhưng admin update role dùng một `roleCode`, không dùng mảng role.

Rules:

- Admin không được vô tình xóa role cuối cùng của user.
- Không trả password hash.
- Ghi audit cho thay đổi role/status nếu backend có audit module.

## 17. API To Database Mapping

| API | Tables chính |
|---|---|
| `POST /api/auth/login` | `users`, `roles` |
| `POST /api/auth/register` | `users`, `roles` |
| `POST /api/auth/logout` | Token/session cleanup nếu backend lưu refresh token hoặc denylist |
| `GET /api/users/me` | `users`, `roles` |
| `PUT /api/users/me` | `users` |
| Shipping address APIs | `shipping_addresses`, `users` |
| `GET /api/products` | `products`, `categories`, `price_tiers` |
| `GET /api/products/{id}` | `products`, `categories`, `price_tiers`, `product_images` |
| Cart APIs: `GET /api/cart`, `/api/cart/items`, `/api/cart/sync` | `carts`, `cart_items`, `products`, `price_tiers` |
| `POST /api/orders` | `orders`, `order_items`, `products`, `notifications` |
| `GET /api/orders` | `orders`, `order_items`, `products` |
| `GET /api/orders/{id}` | `orders`, `order_items`, `products`, `order_status_history` |
| `PUT /api/orders/{id}/status` | `orders`, `order_status_history`, `notifications` |
| `POST /api/chat/send` | `chat_rooms`, `chat_messages`, `chat_attachments`, `notifications` |
| `GET /api/chat/{roomId}` | `chat_rooms`, `chat_messages`, `chat_attachments` |
| `GET /api/notifications` | `notifications` |
| `PUT /api/notifications/{id}/read` | `notifications` |
| `GET /api/warehouses` | `warehouses` |
| `GET /api/admin/dashboard` | `users`, `roles`, `products`, `orders`, `complaints`, `chat_messages`, `chat_attachments` |
| `CRUD /api/admin/products` | `products`, `categories`, `price_tiers`, `product_images` |
| `CRUD /api/admin/users` | `users`, `roles` |

## 18. Security Checklist

- Không hardcode JWT secret, DB password, Supabase service role key hoặc API key trong source.
- Không trả `passwordHash`, stack trace, SQL error raw, hoặc internal exception class cho client.
- Validate input bằng DTO/schema ở controller boundary.
- Check ownership cho `/api/orders/{id}`, `/api/notifications/{id}/read`, `/api/chat/{roomId}`.
- Rate limit `/api/auth/login` và `/api/auth/register`.
- File chat attachment chỉ dùng bucket private hoặc signed URL/backend proxy.
- Admin endpoints phải require role `ADMIN`; Staff không được truy cập nhầm full admin CRUD.

## 19. Contract Test Checklist

- Login success/failure.
- Register duplicate email/phone.
- Product list supports pagination/search/category/status/featured/sort.
- Product detail returns images and price tiers.
- Cart APIs recalculate price, selected totals, and empty-cart state server-side.
- Checkout rejects empty cart and invalid quantity.
- Create order stores price snapshot.
- User cannot read another user's order.
- User cannot update order status.
- Staff/Admin can update order status.
- Notification created on order status change.
- Only notification owner can mark read.
- Admin dashboard returns overview.
- Response envelope matches Flutter DTO.
