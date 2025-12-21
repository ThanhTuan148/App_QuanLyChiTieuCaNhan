# Hướng dẫn Nhanh - Flutter đã được cấu hình

## ✅ Flutter đã được thêm vào PATH

Flutter đã được cấu hình tại: `D:\thanhtuan\flutter_windows_3.38.5-stable\flutter\bin`

## 📝 Lưu ý quan trọng

**Nếu mở PowerShell mới và gặp lỗi "flutter is not recognized":**

1. **Giải pháp tạm thời (cho session hiện tại):**
   ```powershell
   $env:Path += ";D:\thanhtuan\flutter_windows_3.38.5-stable\flutter\bin"
   ```

2. **Giải pháp vĩnh viễn:**
   - Đã được thêm vào User PATH
   - **Đóng và mở lại PowerShell** để PATH có hiệu lực
   - Hoặc khởi động lại máy tính

## 🚀 Các lệnh bạn có thể chạy

```powershell
# Kiểm tra Flutter
flutter --version

# Kiểm tra môi trường
flutter doctor

# Vào thư mục project
cd quanlychitieu

# Cài đặt dependencies (đã chạy rồi)
flutter pub get

# Chạy app
flutter run

# Build app cho Android
flutter build apk

# Build app cho Windows
flutter build windows
```

## 📦 Dependencies đã được cài đặt

Tất cả dependencies đã được cài đặt thành công, bao gồm:
- Firebase packages
- Payment integration packages (http, url_launcher, crypto)
- AI packages (tflite_flutter)
- UI packages (fluttertoast)
- Và các packages khác

## ⚠️ Cảnh báo từ flutter doctor

- **Android toolchain**: Cần cài đặt Android Studio nếu muốn build Android app
- **Developer Mode**: Cần bật Developer Mode nếu muốn build Windows app (không bắt buộc)

## 🎯 Bước tiếp theo

1. **Test app:**
   ```powershell
   cd quanlychitieu
   flutter run
   ```

2. **Cấu hình API keys** (xem `INTEGRATION_GUIDE.md`):
   - MoMo API credentials
   - ZaloPay API credentials  
   - Grok AI API key

3. **Train TensorFlow Lite model** (nếu cần):
   - Train model với Python
   - Đặt file `.tflite` vào `assets/`

## 📚 Tài liệu tham khảo

- `INTEGRATION_GUIDE.md` - Hướng dẫn tích hợp các tính năng mới
- `FLUTTER_SETUP.md` - Hướng dẫn cài đặt Flutter chi tiết


