# Marine-Link-App

MarineLink is a Flutter Android MVP for B2B seafood ordering. The repository contains source code, documentation, and product image assets.

## Documentation Map

Read these files in order:

1. `docs/MarineLink_Main_Functions_Specification_v3.md` - product scope and main user flows.
2. `docs/MarineLink_API_Documentation.md` - REST API contract, request/response examples, roles, errors, and API-to-table mapping.
3. `docs/MarineLink_FE_Architecture.md` - Flutter architecture, state management, API integration, and test strategy.
4. `docs/MarineLink_BE_Architecture.md` - Spring Boot REST API architecture, authorization, business rules, and backend test strategy.
5. `docs/MarineLink_Supabase_DB_Design.md` - Supabase/PostgreSQL schema, storage, RLS notes, migration plan, and API-to-table mapping.
6. `docs/MarineLink_Sprint_Planning.md` - sprint breakdown, capacity assumptions, risks, and Definition of Done.

## MVP Stack

- Frontend: Flutter Android with BLoC/Cubit.
- Backend: Spring Boot REST API with JWT Bearer authentication.
- Database: Supabase PostgreSQL accessed through the backend in the MVP.
- Storage: Supabase Storage for product images, avatars, and chat attachments when file upload is needed.

## Repository Structure

```text
Marine-Link-App/
  frontend/                 # Flutter Android app
    pubspec.yaml
    lib/
    test/
    integration_test/
    android/
    assets/
      product_images/       # Demo product photography for seeding and UI development
  backend/                  # Spring Boot REST API
    pom.xml
    src/main/java/com/marinelink/
    src/main/resources/
    src/test/java/com/marinelink/
  docs/                     # Product, API, architecture, DB, sprint docs
  dried_seafood_products/   # Source product photos used to seed Supabase Storage
  icon/                     # Brand and app icons
```

Frontend code must live under `frontend/`; backend code must live under `backend/`. Shared behavior is documented through `docs/MarineLink_API_Documentation.md`, not duplicated as ad hoc constants in both stacks.

## Product Image Assets

Real dried-seafood product photography lives in `dried_seafood_products/`. Use only the top-level product folders for seed data; the nested `stitch_marinelink_b2b_seafood_ui_kit/` folder is a duplicate UI-kit export.

The current Supabase seed uploads 21 product images to bucket `product-images` under `products/dried-seafood/<product-slug>.png`. `V010__seed_dried_seafood_catalog.sql` stores those public URLs in `products.image_url` and `product_images.image_url`.

Legacy mock product thumbnails live in `frontend/assets/products/` and are used only when remote repositories are disabled.

## Running Against Spring Boot

Mock repositories remain the default for fast local widget tests. To test with real backend/Supabase data, run the backend first, then run Flutter with `USE_REMOTE_REPOSITORIES=true`.

Use PowerShell for the commands below. Start backend and frontend in separate terminals. Restart the backend after changing any `VNPAY_*` environment variable.

### Backend

Run this when the frontend is Flutter web on the Windows host:

```powershell
cd backend
$env:VNPAY_RETURN_URL="http://localhost:8080/api/payments/vnpay/return"
$env:VNPAY_FRONTEND_RETURN_URL="http://localhost:3000/payments/vnpay/result"
mvn spring-boot:run
```

Run this when the frontend is an Android emulator:

```powershell
cd backend
$env:VNPAY_RETURN_URL="http://10.0.2.2:8080/api/payments/vnpay/return"
$env:VNPAY_FRONTEND_RETURN_URL="marinelink:///payments/vnpay/result"
mvn spring-boot:run
```

`VNPAY_RETURN_URL` is the backend callback that VNPAY returns to. `VNPAY_FRONTEND_RETURN_URL` is the fallback route shown to the user after the backend validates the payment. On web, the backend also signs the active browser origin and returns to that same frontend route.

### Frontend Web / Chrome

Use this mode when running Flutter in Chrome on the Windows host:

```powershell
cd frontend
flutter run -d chrome --web-port=3000 --dart-define=USE_REMOTE_REPOSITORIES=true --dart-define=API_BASE_URL=http://localhost:8080
```

Optional Google Sign-In web run:

```powershell
cd frontend
flutter run -d chrome --web-port=3000 --dart-define=USE_REMOTE_REPOSITORIES=true --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=GOOGLE_SERVER_CLIENT_ID=119084335388-i2er0h3h7b7jnret4ul95n6aa50a8if2.apps.googleusercontent.com
```

Keep `--web-port=3000` unless you also change `VNPAY_FRONTEND_RETURN_URL`. VNPAY opens in the same browser tab and should return to:

```text
http://localhost:3000/payments/vnpay/result
```

### Frontend Android App / Emulator

Use this mode when running Flutter on an Android emulator. Android cannot call the host backend through `localhost`, so use `10.0.2.2`:

```powershell
cd frontend
flutter devices
flutter run -d emulator-5554 --dart-define=USE_REMOTE_REPOSITORIES=true --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Optional Google Sign-In Android run:

```powershell
cd frontend
flutter run -d emulator-5554 --dart-define=USE_REMOTE_REPOSITORIES=true --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=GOOGLE_SERVER_CLIENT_ID=119084335388-i2er0h3h7b7jnret4ul95n6aa50a8if2.apps.googleusercontent.com
```

If your emulator id is different, replace `emulator-5554` with the id shown by `flutter devices`. After VNPAY returns to the backend, Android should open the app deep link:

```text
marinelink:///payments/vnpay/result
```

### Smoke Test API Thật

Sau khi backend chạy ở `http://localhost:8080`, kiểm tra product thật:

```powershell
Invoke-RestMethod "http://localhost:8080/api/products?size=5"
```

Kiểm tra login tài khoản đã seed trong Supabase:

```powershell
$body = @{ emailOrPhone = "daily-a@marinelink.demo"; password = "Daily@123" } | ConvertTo-Json
$login = Invoke-RestMethod -Method Post -Uri "http://localhost:8080/api/auth/login" -ContentType "application/json" -Body $body
$login.data.user
```

Kiểm tra JWT gọi profile hiện tại:

```powershell
$token = $login.data.token
Invoke-RestMethod -Method Get -Uri "http://localhost:8080/api/users/me" -Headers @{ Authorization = "Bearer $token" }
```

### Test Commands

Backend:

```powershell
cd backend
mvn test
mvn -DskipTests compile
```

Frontend:

```powershell
cd frontend
flutter analyze
flutter test
flutter test --coverage
```

## Code Requirements

- Flutter implements feature-first modules, BLoC/Cubit state, repository interfaces, mock repositories first, then remote repositories against Spring Boot.
- Spring Boot implements controllers, services, repositories, DTOs, validation, JWT security, and contract tests matching the API documentation.
- The root repo should keep generated build outputs ignored; commit source, tests, docs, migrations, and seed scripts only.
- Before demo or PR, run Flutter tests from `frontend/` and backend verification from `backend/`.

## Demo Accounts

> [!NOTE]
> Các tài khoản dưới đây là credential test dùng cho mock repository và đã được seed vào Supabase thật bằng BCrypt hash trong `V011__seed_demo_users.sql`. Không dùng các password này cho production.

| Role | Tên hiển thị | Email | Số điện thoại | Mật khẩu | Phạm vi truy cập |
|---|---|---|---|---|---|
| `ADMIN` | MarineLink Admin | `admin@marinelink.demo` | `0900000000` | `Admin@123` | Dashboard quản trị, quản lý sản phẩm, quản lý người dùng, giám sát đơn hàng; vẫn có quyền cập nhật trạng thái khi cần |
| `STAFF` | Nhân viên Demo | `staff@marinelink.demo` | `0900000001` | `Staff@123` | Dashboard công việc riêng, mở danh sách đơn và cập nhật trạng thái đơn là luồng xử lý chính, hỗ trợ chat |
| `USER` | Đại lý Nguyễn Văn A | `daily-a@marinelink.demo` | `0912345678` | `Daily@123` | Duyệt sản phẩm, đặt hàng, theo dõi đơn, chat |

**Đăng nhập bằng email hoặc số điện thoại** đều được. Tài khoản `USER` có thêm thông tin cửa hàng: **Hải Sản A Cần Thơ** (Cần Thơ, MST: 0312345678).

Sources: [`frontend/lib/features/auth/data/auth_mock_repository.dart`](frontend/lib/features/auth/data/auth_mock_repository.dart), [`backend/src/main/resources/db/migration/V011__seed_demo_users.sql`](backend/src/main/resources/db/migration/V011__seed_demo_users.sql)



## Security Notes

- Do not commit Supabase keys, JWT secrets, API keys, database passwords, or real user passwords.
- The demo passwords in the table above are fixed test credentials only; real user passwords must never be committed.
- Flutter must not call protected Supabase tables directly in the MVP; authorization is enforced through Spring Boot services.
- Demo users should be seeded with password hashes only.
