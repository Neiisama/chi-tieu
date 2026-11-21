# Chi tiêu – Quản lý chi tiêu cá nhân (Flutter, offline)

Ứng dụng Android ghi chép thu/chi, lập ngân sách theo tháng, sao lưu/khôi phục thủ công. Dữ liệu lưu bằng SQLite trên máy, không cần tài khoản hay mạng.

## Chạy thử trên máy

```bash
flutter create --platforms=android --project-name spending_tracker --org com.example.spendingtracker .
flutter pub get
flutter run
```

Lệnh `flutter create .` chỉ cần chạy **một lần** để sinh thư mục `android/` (không ghi đè code trong `lib/`). Hãy commit thư mục `android/` đó. Nếu bạn quên, GitHub Actions sẽ tự tạo khi build.

## Đẩy lên GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<tên-bạn>/<tên-repo>.git
git push -u origin main
```

## Tải file APK

1. Vào repo trên GitHub → tab **Actions** → chọn lần chạy **Build APK** mới nhất (có thể bấm **Run workflow** để chạy thủ công).
2. Đợi dấu ✅, kéo xuống mục **Artifacts** → tải `spending-tracker-apk` (file zip chứa `app-release.apk`).
3. Giải nén, chép `app-release.apk` vào điện thoại và cài (cho phép "Cài app từ nguồn không xác định").

> APK được ký bằng khóa debug mặc định, phù hợp dùng cá nhân. Muốn phát hành lên Google Play cần cấu hình keystore riêng.

## Sao lưu

**Cài đặt → Xuất sao lưu (JSON)** rồi lưu vào Drive/Zalo/máy. Khi đổi máy: **Khôi phục từ file JSON**. CSV chỉ dùng để xem/phân tích, không dùng để khôi phục.
