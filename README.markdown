# README - Hướng dẫn cài đặt và sử dụng ứng dụng Android

## Mô tả

Đây là tài liệu hướng dẫn cài đặt và sử dụng một ứng dụng Android được phát triển bằng Android Studio. Ứng dụng cung cấp các tính năng cơ bản như định vị GPS và đăng ký tài khoản.

## Tổng Quan

**Ứng Dụng Chia Sẻ Vị Trí Thời Gian Thực** là một phần mềm di động được phát triển để hỗ trợ các nhóm bạn chia sẻ vị trí và hành trình của mình theo thời gian thực. Ứng dụng giúp phối hợp hiệu quả trong các hoạt động nhóm như du lịch, gặp gỡ hoặc tổ chức sự kiện, với giao diện thân thiện và hiệu năng cao. Được xây dựng cho cả iOS và Android, ứng dụng sử dụng các công nghệ hiện đại như GPS, WebSocket và Google Maps API để đảm bảo chia sẻ vị trí chính xác, bảo mật và mượt mà.

## Tính Năng

- **Xác Thực Người Dùng**: Đăng nhập/đăng ký an toàn qua email, số điện thoại hoặc tài khoản Google/Facebook sử dụng OAuth 2.0.
- **Quản Lý Nhóm**: Tạo, mời bạn bè và quản lý các nhóm chia sẻ vị trí.
- **Chia Sẻ Vị Trí Thời Gian Thực**: Bật/tắt chia sẻ vị trí với nhóm hoặc cá nhân.
- **Theo Dõi Hành Trình**: Hiển thị lộ trình di chuyển của các thành viên trên bản đồ.
- **Thông Báo**: Nhận thông báo khi thành viên đến hoặc rời khỏi một địa điểm cụ thể.
- **Trò Chuyện Nhóm**: Tích hợp nhắn tin trong ứng dụng để giao tiếp nhóm.
- **Chế Độ Ẩn Danh**: Tạm ẩn vị trí khi cần thiết.
- **Lịch Sử Hành Trình**: Xem lại lộ trình di chuyển trong khoảng thời gian nhất định.

## Yêu cầu hệ thống

- Android Studio 4.0 trở lên
- Thiết bị Android với hệ điều hành 5.0 (Lollipop) trở lên
- Kết nối Internet ổn định
- Quyền truy cập GPS

## Hướng dẫn cài đặt APK

1. Tải file APK từ thư mục dự án: `app/build/outputs/apk/debug/app-debug.apk`
2. Trên thiết bị Android, vào **Cài đặt &gt; Bảo mật**, kích hoạt tùy chọn "Nguồn không rõ ràng" (Unknown Sources).
3. Sao chép file APK vào thiết bị qua USB hoặc tải trực tiếp.
4. Sử dụng trình quản lý file để tìm và cài đặt file APK.

## Hướng dẫn tạo tài khoản

1. Mở ứng dụng sau khi cài đặt thành công.
2. Nhấn vào nút **Đăng ký**.
3. Nhập thông tin:
   - Tên đầy đủ
   - Địa chỉ email
   - Mật khẩu (ít nhất 6 ký tự)
4. Nhấn **Xác nhận** để nhận mã OTP qua email.
5. Nhập mã OTP và hoàn tất đăng ký.

## Ghi chú quan trọng

- Đảm bảo cấp quyền truy cập GPS và Internet trong lần đầu sử dụng.
- Kiểm tra kết nối mạng trước khi sử dụng tính năng định vị.
- Nếu gặp lỗi, kiểm tra file `AndroidManifest.xml` để đảm bảo quyền cần thiết đã được khai báo.

## Liên hệ

Nếu có thắc mắc, vui lòng liên hệ qua email: support@example.com.