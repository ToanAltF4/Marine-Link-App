# Đăng nhập Google (ML-62) — Hướng dẫn cấu hình

Tài liệu này hướng dẫn PM hoàn tất phần **cấu hình Google Cloud** để nút "Đăng nhập
với Google" hoạt động thật. Code FE + BE đã xong; chỉ cần các OAuth Client ID và
biến môi trường dưới đây.

## Tổng quan luồng

```
Flutter (google_sign_in) → lấy Google ID token
   → POST /api/auth/google { idToken }
   → BE verify token với Google (tokeninfo), kiểm tra audience = client ID của ta
   → tạo/đăng nhập user (email Google đã verified) → trả JWT app + user
```

- User Google mới → tạo tài khoản role **USER**, trạng thái **ACTIVE** (email đã được
  Google xác thực), `phone` để trống (user bổ sung trong hồ sơ sau).
- User đã tồn tại (trùng email) → đăng nhập luôn; nếu đang `PENDING_VERIFICATION`
  thì tự kích hoạt; `DISABLED`/`PENDING_APPROVAL` thì bị chặn.

## Bước 1 — Tạo OAuth consent screen
1. Vào https://console.cloud.google.com → chọn/ tạo project (vd `MarineLink`).
2. **APIs & Services → OAuth consent screen** → User type **External** → điền tên app,
   email hỗ trợ, scopes mặc định (`email`, `profile`, `openid`). Lưu.

## Bước 2 — Tạo OAuth Client IDs
**APIs & Services → Credentials → Create Credentials → OAuth client ID.**

1. **Web application** (BẮT BUỘC — dùng làm `serverClientId` để lấy idToken):
   - Tên: `MarineLink Web`.
   - Ghi lại **Client ID** dạng `xxxxxxxx.apps.googleusercontent.com` → đây là
     **`GOOGLE_WEB_CLIENT_ID`** dùng cho cả FE (`serverClientId`) và BE (audience).

2. **Android** (cho app Android thật):
   - Package name: lấy `applicationId` trong `frontend/android/app/build.gradle`
     (vd `com.marinelink.app`).
   - SHA-1: chạy
     ```powershell
     cd frontend/android ; ./gradlew signingReport
     ```
     lấy SHA1 của `debug` (và `release` khi phát hành). Dán vào client Android.
   - Không cần copy client ID Android vào code — Google liên kết tự động qua
     package + SHA-1; idToken vẫn mang audience = Web client ID.

3. (Tùy chọn) **iOS** nếu chạy iOS.

## Bước 3 — Cấu hình biến môi trường

### Backend (`backend/.env`, KHÔNG commit)
```
GOOGLE_CLIENT_IDS=<GOOGLE_WEB_CLIENT_ID>
```
Có thể liệt kê nhiều audience, ngăn cách bằng dấu phẩy (vd thêm iOS client ID).

### Frontend (khi chạy/đóng gói)
```powershell
flutter run --dart-define=USE_REMOTE_REPOSITORIES=true \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<GOOGLE_WEB_CLIENT_ID>
```
> Mock mode (không có dart-define) vẫn chạy: nút Google trả về user demo để test UI.

## Bước 4 — Kiểm thử thật
1. BE: `cd backend ; mvn spring-boot:run` (đã có `GOOGLE_CLIENT_IDS` trong `.env`).
2. FE: chạy lệnh `flutter run` ở Bước 3 trên thiết bị/emulator có Google Play.
3. Bấm **Đăng nhập với Google** → chọn tài khoản → vào thẳng Home (role USER).

## Lưu ý
- idToken **phải** có `aud` = `GOOGLE_WEB_CLIENT_ID`; nếu không khớp BE trả 401
  "Token Google không hợp lệ". Đây là lý do phải truyền đúng `serverClientId`.
- Nếu `GOOGLE_CLIENT_IDS` rỗng, BE trả lỗi 500 "Đăng nhập Google chưa được cấu hình".
- BE xác thực qua `https://oauth2.googleapis.com/tokeninfo` (không cần thêm thư viện).
