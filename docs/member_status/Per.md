# Báo Cáo Công Việc Hàng Ngày - Per

**Ngày báo cáo:** 06/07/2026

## Các chức năng và công việc đã hoàn thành

1. **Quản lý Role CRM (Backend & Edge Functions)**
   - Cập nhật cơ sở dữ liệu (`user_role` enum) qua migration mới nhất để bổ sung 2 role: `crm` và `crm_manager`.
   - Cập nhật và **deploy lại Edge Function** `admin-user-manager` để cho phép tạo/sửa các role CRM, khắc phục hoàn toàn lỗi trả về mã "non-2xx" (400 Bad Request) khi Admin gán quyền.
   - Bổ sung `crm_manager` vào danh sách định tuyến (route fallback) để user đăng nhập không bị văng lại trang login.
   - Sửa tên hiển thị role thành "CRM Branch" trong Admin Accounts để dễ nhận diện.

2. **Giao Diện CRM (UI/UX Luxury Theme - Mobile First)**
   - Áp dụng giao diện **Ngưu Cát Luxury** (màu đen tối giản kết hợp điểm nhấn màu vàng đồng - Gold/Gradient) cho toàn bộ ứng dụng CRM (`CRMLayout`, `CRMDashboardView`, `CRMServingTablesView`).
   - Thiết kế chuẩn tối ưu hóa cho màn hình điện thoại (`max-w-md`), dễ dàng thao tác bằng một tay dành cho quản lý và nhân viên CRM.

3. **Quản lý Trạng Thái Pinia (State Management)**
   - Khởi tạo và liên kết `crmStore.ts` (Pinia) để quản lý đồng bộ dữ liệu cho màn hình CRM (dashboard stats, danh sách bàn, khảo sát), thay thế cho các composables cũ.
   - Tích hợp gọi RPC `get_crm_dashboard_stats` vào store để lấy số liệu thống kê realtime cho CRM Dashboard.

4. **Chuyển Ngữ (i18n)**
   - Bổ sung toàn bộ các khóa dịch thuật (`crm:...`) vào 3 file ngôn ngữ: **Tiếng Việt (vi.ts), Tiếng Anh (en.ts), Tiếng Nhật (ja.ts)**. Màn hình CRM hiện tại đã hỗ trợ chuyển đổi đầy đủ ngôn ngữ không còn lỗi.

---

**Ngày báo cáo:** 26/06/2026

## Các chức năng và công việc đã hoàn thành

1. **Sửa Giao Diện (UI/UX)**
   - Khắc phục các lỗi layout bị vỡ trên toàn bộ header của hệ thống (`AdminLayout`, `ManagerLayout`, `StaffLayout`, v.v.).
   - Đã xử lý triệt để việc hiển thị User Avatar ở dạng sticker (ảnh hoạt hình sinh động), không dùng các chữ/chữ số khô khan ở header nữa.
   - Sửa giao diện hiển thị các bảng logs trong hệ thống để tự động gói gọn nội dung (word-wrap), không bị tràn bề ngang.

2. **Hoàn thiện API và Chức năng Backend**
   - Đã build và hoàn thiện API (Supabase Edge Functions & Queries) cho toàn bộ các chức năng. Tất cả các dữ liệu hiển thị hiện tại đều được lấy từ cơ sở dữ liệu thực.

3. **Chuyển Ngữ (i18n)**
   - Đã xử lý xong hoàn toàn 100% các ngôn ngữ: **Tiếng Việt (vi), Tiếng Anh (en), Tiếng Nhật (ja)**.
   - Khắc phục các lỗi khi build do script dịch tự động sinh ra các đoạn mã không đúng cú pháp.

## Thông tin Triển Khai (Deployment)

Dự án đã được deploy lên Firebase Hosting (quản lý qua tài khoản Google Workspace).

- **Domain truy cập chính thức:** 
  - `https://nguucat-qvn.web.app`
  - `https://nguucat-qvn.firebaseapp.com`

- **Tài khoản Google Workspace / Firebase:**
  - Dự án được deploy thẳng lên project `nguucat-qvn` thông qua CLI.
  - *Lưu ý:* Mật khẩu tài khoản Google Workspace là bảo mật cá nhân của bạn nên hệ thống không lưu trữ hay xuất ra đây được. Bạn có thể sử dụng chính tài khoản Google đã login vào máy để quản lý Firebase.

- **Tài khoản Đăng nhập (Demo trên hệ thống Ngưu Cát):**
  - **Email:** `admin@nguucat.vn`
  - **Mật khẩu:** `admin123`

## Github
- Toàn bộ code đã được hoàn thiện, build thành công và chuẩn bị push lên nhánh `main` của Github để lưu trữ.
