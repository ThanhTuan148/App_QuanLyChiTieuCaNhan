# Hướng dẫn Cấu hình Flutter trên Windows

## Vấn đề: Flutter không được nhận diện trong PowerShell

### Giải pháp nhanh (Tạm thời cho session hiện tại)

Nếu bạn đã cài đặt Flutter, chạy lệnh sau trong PowerShell:

```powershell
# Thay thế đường dẫn bằng đường dẫn thực tế của Flutter trên máy bạn
$env:Path += ";C:\src\flutter\bin"
# Hoặc
$env:Path += ";D:\flutter\bin"
# Hoặc đường dẫn khác nơi bạn đã cài Flutter

# Sau đó chạy
cd quanlychitieu
flutter pub get
```

### Giải pháp vĩnh viễn

#### Cách 1: Sử dụng script tự động

Chạy script PowerShell đã được tạo:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_flutter_path.ps1
```

Script sẽ:
- Tự động tìm Flutter trên hệ thống
- Hỏi bạn có muốn thêm vào PATH không
- Hướng dẫn các bước tiếp theo

#### Cách 2: Thêm thủ công vào PATH

1. **Tìm đường dẫn Flutter:**
   - Thường ở: `C:\src\flutter\bin` hoặc `D:\flutter\bin`
   - Hoặc tìm thư mục chứa file `flutter.bat`

2. **Thêm vào PATH:**
   - Mở **System Properties**:
     - Nhấn `Win + R`
     - Gõ `sysdm.cpl` và Enter
   - Chọn tab **Advanced** > **Environment Variables**
   - Trong **User variables**, chọn **Path** > **Edit**
   - Click **New** và thêm đường dẫn đến thư mục `bin` của Flutter
     - Ví dụ: `C:\src\flutter\bin`
   - Click **OK** để lưu

3. **Khởi động lại PowerShell** để PATH có hiệu lực

#### Cách 3: Kiểm tra Flutter đã cài đặt chưa

Chạy lệnh sau để tìm Flutter:

```powershell
# Tìm trong các vị trí thông thường
$paths = @(
    "$env:LOCALAPPDATA\Android\flutter\bin",
    "C:\src\flutter\bin",
    "C:\flutter\bin",
    "D:\flutter\bin"
)

foreach ($p in $paths) {
    if (Test-Path "$p\flutter.bat") {
        Write-Host "Found Flutter at: $p" -ForegroundColor Green
        & "$p\flutter.bat" --version
    }
}
```

### Nếu chưa cài đặt Flutter

1. **Tải Flutter SDK:**
   - Truy cập: https://docs.flutter.dev/get-started/install/windows
   - Tải file ZIP Flutter SDK

2. **Giải nén:**
   - Giải nén vào thư mục (ví dụ: `C:\src\flutter`)
   - **KHÔNG** giải nén vào `C:\Program Files\` (cần quyền admin)

3. **Thêm vào PATH:**
   - Làm theo Cách 2 ở trên
   - Thêm đường dẫn: `C:\src\flutter\bin`

4. **Kiểm tra:**
   ```powershell
   flutter doctor
   ```

### Sau khi cấu hình xong

Chạy các lệnh sau để cài đặt dependencies:

```powershell
cd quanlychitieu
flutter pub get
flutter doctor
```

### Troubleshooting

**Lỗi: "flutter is not recognized"**
- Đảm bảo đã thêm Flutter vào PATH
- Đóng và mở lại PowerShell
- Kiểm tra đường dẫn có đúng không

**Lỗi: "Execution Policy"**
- Chạy PowerShell với quyền Administrator
- Hoặc chạy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Không tìm thấy Flutter**
- Kiểm tra xem Flutter đã được cài đặt chưa
- Tìm thủ công bằng File Explorer
- Chạy script `setup_flutter_path.ps1` để tìm tự động

