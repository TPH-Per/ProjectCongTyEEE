# Tài liệu Phân tích Hệ thống Quản lý Đặt bàn & Nhà hàng (SaaS)

## 1. Tổng quan Dự án (Project Overview)
- **Tên dự án:** UI Clone & Modernization - Restaurant Booking System.
- **Vai trò:** Senior Product Designer, Senior Frontend Architect, UX Analyst.
- **Mục tiêu:** Tái cấu trúc hệ thống quản lý đặt bàn hiện tại sang kiến trúc hiện đại (Next.js, TailwindCSS, shadcn/ui), tối ưu UX/UI và khả năng mở rộng.

---

## 2. Bản đồ Luồng Người dùng (User Journey Map)

| Giai đoạn | Hành động của Người dùng | Màn hình tương ứng |
| :--- | :--- | :--- |
| **1. Theo dõi** | Xem tổng quan mật độ đặt bàn trong ngày/tuần. | Timeline View (Lịch) |
| **2. Tra cứu** | Tìm kiếm thông tin khách hàng hoặc lọc danh sách đặt chỗ. | List View (Danh sách) |
| **3. Tiếp nhận** | Xem chi tiết thông tin khách, ghi chú đặc biệt, loại tiệc. | Detail View (Chi tiết đặt) |
| **4. Điều phối** | Gán khách vào vị trí bàn cụ thể trong không gian nhà hàng. | Floor Plan (Sơ đồ bàn) |
| **5. Vận hành** | Check-in cho khách đến, theo dõi khách sắp đến/hủy. | Real-time View (Hiện tại) |
| **6. Phục vụ** | Ghi nhận các gói dịch vụ, món ăn khách đã chọn/đặt trước. | Ordering View (Chọn món) |
| **7. Quản trị** | Thiết lập chính sách, xem báo cáo, cấu hình hệ thống. | System Menu (Cấu hình) |

---

## 3. Kiến trúc Frontend Đề xuất (Frontend Architecture)

- **Framework:** Next.js 14+ (App Router).
- **Ngôn ngữ:** TypeScript.
- **Styling:** TailwindCSS + shadcn/ui.
- **State Management:** 
    - `Zustand`: Global state (Sidebar, User session, Cart).
    - `TanStack Query (React Query)`: Server state (Booking data, Table status).
- **Thư viện bổ trợ:** 
    - `TanStack Table`: Xử lý Grid dữ liệu phức tạp.
    - `React Hook Form` + `Zod`: Validate form đặt bàn.
    - `Lucide React`: Icon system.

---

## 4. Thực thể Dữ liệu (Database Mapping)

### Entities chính:
- **`Branch`**: Chi nhánh nhà hàng.
- **`Zone`**: Khu vực trong nhà hàng (Vip, Sân vườn, Tầng 1...).
- **`Table`**: Thông tin bàn (Mã, Số chỗ, Trạng thái).
- **`Customer`**: CRM khách hàng (Tên, SĐT, Email, Lịch sử tiêu dùng).
- **`Reservation`**: Thông tin đặt chỗ (Ngày, giờ, số người, trạng thái).
- **`Product/Menu`**: Danh mục món ăn và dịch vụ.
- **`Order`**: Đơn hàng liên kết với Reservation.

---

## 5. Danh mục Component cần xây dựng (Component Library)

### Nguyên tử (Atoms):
- `Button`, `Input`, `Badge`, `Select`, `Checkbox`, `Avatar`.
- `StatusIndicator` (Thanh màu trạng thái).

### Phân tử (Molecules):
- `BookingCard`: Thẻ hiển thị tóm tắt thông tin đặt bàn.
- `NumberStepper`: Bộ tăng giảm số lượng người/bàn.
- `TagGroup`: Nhóm các tag lựa chọn (Nguồn khách, Loại tiệc).
- `TableNode`: Đại diện cho 1 bàn trên sơ đồ.

### Tổ hợp (Organisms):
- `TimelineGrid`: Lưới hiển thị thời gian dọc.
- `DataTable`: Bảng danh sách đặt chỗ chuyên sâu.
- `OrderCart`: Giỏ hàng chọn món.
- `FloorPlanCanvas`: Sơ đồ mặt bằng tương tác.

---

## 6. Danh sách Khảo sát Nghiệp vụ (Research Checklist)
*Đây là các câu hỏi cần làm rõ tại thực tế để hoàn thiện Logic.*

- [ ] **Nút "Đã đến":** Có bắt buộc gán bàn trước khi nhấn không? Có tự mở Sơ đồ bàn không?
- [ ] **Nút "Thanh toán":** Có kết nối máy in hóa đơn không? Trạng thái bàn sau thanh toán?
- [ ] **Nút "Khóa giờ":** Ảnh hưởng đến App đặt bàn bên ngoài như thế nào?
- [ ] **Mở bàn (Walk-in):** Luồng nhập liệu có khác gì so với khách đặt trước?
- [ ] **Chỉnh sửa:** Tại sao một số bản ghi bị "Không cho phép chỉnh sửa"?
- [ ] **In ấn:** Có hỗ trợ in phiếu đặt bàn tại quầy không?
- [ ] **Tìm kiếm:** Có hỗ trợ Live search (tìm khi đang gõ) không?

---

## 7. Đề xuất Cải tiến UI/UX (Modernization)

1. **Responsive Design:** Chuyển đổi sang giao diện 1 cột cho Tablet/Mobile, ưu tiên thao tác chạm.
2. **Interactive Floor Plan:** Sử dụng kéo thả (Drag & Drop) để gán khách vào bàn.
3. **Visual Hierarchy:** Giảm bớt các màu sắc rực rỡ không cần thiết, tập trung vào các thông tin quan trọng (Giờ, Số người).
4. **Real-time Updates:** Sử dụng WebSockets để cập nhật trạng thái bàn/booking ngay lập tức giữa các máy tính.
5. **Dark Mode:** Hỗ trợ làm việc trong môi trường ánh sáng yếu (buổi tối tại nhà hàng).
