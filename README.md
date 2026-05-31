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
  icon/                     # Brand and app icons
```

Frontend code must live under `frontend/`; backend code must live under `backend/`. Shared behavior is documented through `docs/MarineLink_API_Documentation.md`, not duplicated as ad hoc constants in both stacks.

## Product Image Assets

Demo product photography lives in `frontend/assets/product_images/`. Each subfolder contains a `screen.png` for that product category:

| Folder | Product |
|---|---|
| `professional_high_quality_studio_photography_of_premium_dried_shrimp_t_m_kh` | Tôm khô |
| `professional_high_quality_studio_photography_of_premium_dried_squid_m_c_kh` | Mực khô |
| `professional_high_quality_studio_photography_of_premium_dried_yellowstripe_scad` | Cá sọc vàng khô |
| `professional_high_quality_studio_photography_of_premium_semi_dried_squid_m_c_m` | Mực mềm (semi-dried) |

These images are used for database seeding and local UI development only. Production images are served from Supabase Storage.

## Code Requirements

- Flutter implements feature-first modules, BLoC/Cubit state, repository interfaces, mock repositories first, then remote repositories against Spring Boot.
- Spring Boot implements controllers, services, repositories, DTOs, validation, JWT security, and contract tests matching the API documentation.
- The root repo should keep generated build outputs ignored; commit source, tests, docs, migrations, and seed scripts only.
- Before demo or PR, run Flutter tests from `frontend/` and backend verification from `backend/`.

## Demo Accounts

> [!NOTE]
> Các tài khoản dưới đây chỉ hoạt động với **mock repository** (Sprint 1–4). Khi tích hợp Spring Boot thật ở Sprint 5, cần seed vào DB với password hash tương ứng.

| Role | Tên hiển thị | Email | Số điện thoại | Mật khẩu | Phạm vi truy cập |
|---|---|---|---|---|---|
| `ADMIN` | MarineLink Admin | `admin@marinelink.demo` | `0900000000` | `Admin@123` | Toàn bộ: dashboard, sản phẩm, người dùng, đơn hàng, chat |
| `STAFF` | Nhân viên Demo | `staff@marinelink.demo` | `0900000001` | `Staff@123` | Xử lý đơn hàng, hỗ trợ chat |
| `USER` | Đại lý Nguyễn Văn A | `daily-a@marinelink.demo` | `0912345678` | `Daily@123` | Duyệt sản phẩm, đặt hàng, theo dõi đơn, chat |

**Đăng nhập bằng email hoặc số điện thoại** đều được. Tài khoản `USER` có thêm thông tin cửa hàng: **Hải Sản A Cần Thơ** (Cần Thơ, MST: 0312345678).

Source: [`frontend/lib/features/auth/data/auth_mock_repository.dart`](frontend/lib/features/auth/data/auth_mock_repository.dart)



## Security Notes

- Do not commit Supabase keys, JWT secrets, API keys, database passwords, or demo plaintext passwords.
- Flutter must not call protected Supabase tables directly in the MVP; authorization is enforced through Spring Boot services.
- Demo users should be seeded with password hashes only.
