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
| 200 | GET/PUT thành công |
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
| `status` | `ACTIVE`, `OUT_OF_STOCK`, `DISABLED` | Public chỉ nên thấy active/out-of-stock nếu business cho phép |
| `featured` | boolean | Home featured products |
| `sort` | string | Ví dụ `name`, `price`, `-createdAt`, `-featured` |

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
| GET | `/api/products` | All roles |
| GET | `/api/products/{id}` | All roles |
| POST | `/api/cart/sync` | USER |
| POST | `/api/orders` | USER |
| GET | `/api/orders` | All roles |
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
| PUT | `/api/admin/users/{id}/roles` | ADMIN |

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

## 10. Product APIs

### GET `/api/products`

Query params: `page`, `size`, `q`, `categoryId`, `status`, `featured`, `sort`.

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

### POST `/api/cart/sync`

Đồng bộ cart local của Flutter lên backend trước checkout.

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
    "items": [
      {
        "productId": "550e8400-e29b-41d4-a716-446655440003",
        "productName": "Muc kho loai 1",
        "quantity": 10,
        "selectedPriceTierId": "550e8400-e29b-41d4-a716-446655440007",
        "unitPrice": 420000,
        "lineTotal": 4200000,
        "selected": true
      }
    ],
    "subtotalAmount": 4200000
  }
}
```

Rules:

- Backend không tin tổng tiền client gửi lên.
- Backend tính lại price tier theo `quantity`.
- Reject nếu product không tồn tại, disabled, hết hàng, hoặc quantity dưới `minOrderQuantity`.
- Mỗi user có một active cart trong MVP.

## 12. Order APIs

### POST `/api/orders`

Tạo đơn hàng từ cart đã sync hoặc request checkout.

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

- Cart không rỗng.
- Product còn hàng và quantity hợp lệ.
- Snapshot `productName`, `unit`, `unitPrice` vào `order_items`.
- Tạo notification khi order được tạo hoặc đổi trạng thái.
- Clear `cart_items` sau khi checkout thành công nếu business chọn flow đó.

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
| PUT | `/api/admin/users/{id}/roles` | Replace or update user roles |

Update user request:

```json
{
  "status": "ACTIVE",
  "fullName": "Nguyen Van A",
  "phone": "0912345678",
  "businessAddress": "Can Tho"
}
```

Update roles request:

```json
{
  "roles": ["USER"]
}
```

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
| `GET /api/products` | `products`, `categories`, `price_tiers` |
| `GET /api/products/{id}` | `products`, `categories`, `price_tiers`, `product_images` |
| `POST /api/cart/sync` | `carts`, `cart_items`, `products`, `price_tiers` |
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
- Product list supports pagination/filter/search.
- Product detail returns images and price tiers.
- Cart sync recalculates price server-side.
- Checkout rejects empty cart and invalid quantity.
- Create order stores price snapshot.
- User cannot read another user's order.
- User cannot update order status.
- Staff/Admin can update order status.
- Notification created on order status change.
- Only notification owner can mark read.
- Admin dashboard returns overview.
- Response envelope matches Flutter DTO.
