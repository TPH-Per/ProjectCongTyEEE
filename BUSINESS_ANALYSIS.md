# Phân tích Nghiệp vụ Hệ thống Quản lý Nhà hàng (Restaurant Booking System)

> Dự án: UI Clone & Modernization — Restaurant Booking System (SaaS)
> Ngày cập nhật phân tích: 20/06/2026
> Công nghệ: Vue 3 (Composition API), Vite, TypeScript, TailwindCSS

---

## 1. Tổng quan Hệ thống

Hệ thống là một **SaaS quản lý nhà hàng** dành cho các nhà hàng vừa và lớn, hỗ trợ quy trình từ **đặt bàn → điều phối → phục vụ → thanh toán**. Giao diện được thiết kế cho nhân viên vận hành (lễ tân, quản lý ca, phục vụ) sử dụng trên máy tính bàn/tablet.

### 1.1. Vai trò người dùng

| Vai trò | Trách nhiệm chính | Các màn hình sử dụng |
|---------|-------------------|---------------------|
| **Lễ tân / Tiếp nhận** | Nhận đặt bàn, check-in khách, gán bàn | Lịch, Danh sách, Sơ đồ bàn |
| **Quản lý ca** | Giám sát hoạt động, điều phối, xem báo cáo | Tất cả các màn hình |
| **Phục vụ / Bếp** | Ghi món, theo dõi trạng thái bàn | Chọn món |
| **Quản trị hệ thống** | Cấu hình chi nhánh, khu vực, thực đơn, tài khoản | Cấu hình (chưa phát triển) |

### 1.2. Luồng nghiệp vụ chính

```
Khách gọi điện/hệ thống đặt trước
    │
    ▼
Tiếp nhận đặt bàn (Lịch đặt bàn / Danh sách)
    │
    ▼
Gán bàn (Sơ đồ bàn)
    │
    ▼
Check-in khách (Chi tiết đặt bàn → "Đã đến")
    │
    ▼
Phục vụ / Ghi món (Chọn món)
    │
    ▼
Thanh toán (Chi tiết đặt bàn → "Thanh toán")
    │
    ▼
Kết thúc / Dọn bàn
```

---

## 2. Chi tiết nghiệp vụ theo từng màn hình

### 2.1. Màn hình Lịch đặt bàn `/` (Timeline View - `TimelineView.vue`)

**Mục đích nghiệp vụ:** Cung cấp cái nhìn trực quan về mật độ đặt bàn theo **khung giờ** và **khu vực** trong ngày.

**Nghiệp vụ chi tiết:**
- Mỗi cột dọc = 1 khung giờ (Morning: 6h-11h, Noon: 11h-14h, Afternoon: 14h-17h, Evening: 17h-22h)
- Mỗi hàng ngang = 1 khu vực (Zone A, B, VIP, Sân vườn)
- **Màu sắc thẻ đặt bàn thể hiện trạng thái:**
  - 🔶 Amber (`bg-amber-50`) → Pending (Chờ xử lý)
  - 🔵 Blue (`bg-blue-50`) → Arrived (Đã đến)
  - 🟢 Emerald (`bg-emerald-50`) → Dining (Đang dùng)
  - ⚪ Slate (`bg-slate-50`) → Completed (Hoàn tất)
  - 🔴 Rose (`bg-rose-50`) → Cancelled (Đã hủy)
- Nhân viên có thể **lọc theo khu vực** để xem chi tiết
- **Thanh tìm kiếm** cho phép tra cứu nhanh theo tên khách, SĐT, mã đặt bàn
- **Nút "Hôm nay"** để quay về ngày hiện tại (18/06/2026 trong dữ liệu mẫu)

**Quy tắc nghiệp vụ:**
- Mỗi đặt bàn chỉ xuất hiện trong đúng khung giờ và khu vực đã chọn
- Đặt bàn kéo dài qua nhiều khung giờ (VD: 11h-15h) sẽ hiển thị ở khung giờ bắt đầu
- Số lượng đặt bàn trong 1 ô = số thẻ trong ô đó, giới hạn hiển thị theo chiều cao ô
- Click vào thẻ đặt bàn sẽ điều hướng người dùng tới trang Chi tiết đặt chỗ `/order/:id`

---

### 2.2. Màn hình Danh sách `/list` (List View - `ListView.vue`)

**Mục đích nghiệp vụ:** Tra cứu và quản lý danh sách đặt bàn dạng bảng, hỗ trợ tìm kiếm và lọc nâng cao.

**Nghiệp vụ chi tiết:**
- **Bộ lọc theo trạng thái:** Tab chọn lọc nhanh (Tất cả, Chờ đến, Đã đến, Đang dùng, Hoàn tất, Đã hủy)
- **Chọn ngày:** Xem đặt bàn của ngày cụ thể thông qua bộ chọn ngày
- **Tìm kiếm:** Tra cứu theo tên khách hàng, SĐT, mã đặt chỗ
- **Bảng dữ liệu** hiển thị các cột:
  1. Checkbox (chọn nhiều)
  2. Mã đặt bàn (link → Chi tiết)
  3. Khách hàng (tên + avatar + ghi chú nếu có)
  4. Liên hệ (Số điện thoại)
  5. Giờ đến
  6. Số người (Khách)
  7. Bàn được gán
  8. Loại tiệc
  9. Nguồn khách
  10. Trạng thái (badge màu)
  11. Thao tác (xem chi tiết / chọn món)
- **Phân trang:** Phân trang dưới cùng bảng

**Quy tắc nghiệp vụ:**
- Dữ liệu mặc định là ngày 18/06/2026
- Khi chọn trạng thái "Đã đến", hệ thống gợi ý gán bàn nếu chưa có
- Có thể xuất danh sách ra file Excel (nút tính năng tương lai)

---

### 2.3. Màn hình Sơ đồ bàn `/floor-plan` (Floor Plan - `FloorPlanView.vue`)

**Mục đích nghiệp vụ:** Quản lý không gian bàn trực quan, gán khách vào bàn, theo dõi trạng thái từng bàn theo thời gian thực.

**Nghiệp vụ chi tiết:**
- **Hai chế độ xem:**
  1. **Theo ngày:** Xem trạng thái bàn trong ngày cụ thể (trạng thái động tính toán dựa trên lịch đặt chỗ)
  2. **Hiện tại (Realtime):** Xem trạng thái bàn thực tế ngay lúc này (được cập nhật liên tục)
- **Bảng khu vực (Zone panel):** Bên trái, hiển thị danh sách zone + thống kê số bàn (trống/đã đặt/đang ngồi)
- **Bản đồ bàn:** Vị trí các bàn với màu sắc trạng thái trực quan:
  - 🟢 Xanh lá → Available (Trống, sẵn sàng)
  - 🟡 Vàng → Reserved (Đã đặt, chưa check-in)
  - 🔴 Hồng → Occupied (Có khách đang ngồi)
- **Thông tin trên bàn:** Mã bàn, số lượng chỗ, trạng thái, tên khách đặt, thời gian đến, số lượng khách thực tế.
- Click vào bàn đang có khách hoặc đã đặt sẽ điều hướng đến trang Chi tiết đặt bàn `/order/:id`.

**Quy tắc nghiệp vụ:**
- Mỗi bàn có sức chứa tối đa (capacity) – không thể gán vượt quá
- Bàn "Occupied" không thể được gán cho đặt bàn khác trong cùng khung giờ
- Ưu tiên gán bàn theo khu vực phù hợp với loại khách/tiệc

---

### 2.4. Màn hình Chi tiết đặt bàn `/order/:id` (Booking Detail - `OrderDetailView.vue`)

**Mục đích nghiệp vụ:** Xem và thao tác toàn bộ thông tin của một đặt bàn cụ thể, quản lý gọi món và thanh toán.

**Nghiệp vụ chi tiết:**

#### 2.4.1. Tab "TT-Đặt chỗ" (Thông tin đặt chỗ)
- Thông tin cơ bản: Mã đặt bàn, ngày giờ, số người, khu vực, bàn
- **Trạng thái hiện tại** và luồng thay đổi trạng thái
- **Ghi chú** của khách / ghi chú nội bộ
- Thông tin khách hàng: Tên, SĐT, email, số lần đến, tổng chi tiêu

#### 2.4.2. Tab "TT-Mở rộng" (Thông tin mở rộng)
- Thông tin thanh toán: Hình thức, đặt cọc
- Yêu cầu đặc biệt: Trang trí, bánh sinh nhật, dịp kỷ niệm
- Thông tin quản trị: Người tạo, ngày tạo, chi nhánh, kênh tiếp nhận

#### 2.4.3. Tab "Người tiếp nhận" (Receiver)
- **Nhân viên phụ trách:** Ai tiếp nhận đặt bàn, ai xác nhận đặt bàn, ai phụ trách phục vụ bàn

#### 2.4.4. Tab "Lịch sử thao tác" (Operations History)
- Timeline chi tiết các hành động trên bản ghi để tiện theo dõi: tạo mới, phân bàn, check-in...

#### 2.4.5. Tab "Lịch sử tiêu dùng" (Consumption History)
- Bảng danh sách món đã gọi: Tên món, số lượng, đơn giá, thành tiền
- Tổng cộng: Tạm tính → Thuế (VAT 10%) → Tổng thanh toán
- Trạng thái đơn hàng: Đang chuẩn bị / Đang phục vụ / Đã thanh toán
- Các nút tương tác: "In hóa đơn", "Đã đến", "Lưu", "Sửa"

**Quy tắc nghiệp vụ:**
- Không thể chỉnh sửa đặt bàn đã "Hoàn tất" hoặc "Đã hủy"
- **Nút "Đã đến"** chuyển trạng thái từ Pending → Arrived
- **Nút "Lưu" & "Sửa"** dùng để cập nhật thông tin đơn hàng và đặt chỗ.

---

## 3. Mô hình Dữ liệu & Quan hệ

```
Branch (Chi nhánh)
  ├── Zone (Khu vực)
  │     └── Table (Bàn)
  ├── Customer (Khách hàng)
  │     └── Reservation (Đặt bàn)
  │           ├── Table (Bàn được gán)
  │           ├── Order (Đơn hàng)
  │           │     └── OrderItem (Chi tiết món)
  │           └── StaffLog (Lịch sử thao tác)
  └── MenuItem (Thực đơn)
```

### 3.1. Thực thể & Thuộc tính

| Entity | Key Attributes | Ghi chú |
|--------|---------------|---------|
| **Branch** | `id`, `name`, `address`, `phone` | Cấu hình đa chi nhánh |
| **Zone** | `id`, `name`, `branchId`, `color` | Phân loại khu vực |
| **Table** | `id`, `code`, `zoneId`, `capacity`, `status`, `shape`, `posX`, `posY` | Tọa độ cho sơ đồ |
| **Customer** | `id`, `name`, `phone`, `email`, `totalVisits`, `totalSpent`, `note` | Quản lý khách hàng |
| **Reservation** | `id`, `customerId`, `customerName`, `customerPhone`, `date`, `time`, `guests`, `status`, `tables`, `note`, `source`, `type`, `createdAt` | Thông tin lịch đặt |
| **MenuItem** | `id`, `name`, `category`, `price`, `unit`, `description` | Menu món ăn |
| **Order** | `id`, `reservationId`, `items`, `subtotal`, `vat`, `total`, `status`, `createdAt` | Hóa đơn gọi món |
| **OrderItem** | `menuItemId`, `name`, `price`, `quantity` | Món đã gọi trong hóa đơn |

### 3.2. Enum/Trạng thái

**ReservationStatus:**
```
Pending (Chờ đến) → Arrived (Đã đến) → Dining (Đang dùng) → Completed (Hoàn tất)
                                                           ↘ Cancelled (Đã hủy)
```

**TableStatus:**
```
available (Trống) | reserved (Đã đặt) | occupied (Đang ngồi)
```

**OrderStatus:**
```
Pending (Chờ xử lý) → Preparing (Đang chế biến) → Served (Đã phục vụ) → Paid (Đã thanh toán)
```

---

## 4. Quy tắc Nghiệp vụ (Business Rules)

### 4.1. Quy tắc về Đặt bàn

1. **Mỗi đặt bàn phải có** tối thiểu: tên khách, SĐT, ngày giờ, số người
2. **Số người không được vượt quá** tổng sức chứa các bàn được gán
3. **Một bàn không thể được gán** cho hai đặt bàn cùng khung giờ
4. Đặt bàn từ **hệ thống online** được tạo tự động với trạng thái `Pending`
5. Khách **Walk-in** tạo đặt bàn với trạng thái `Arrived` và cần gán bàn ngay

### 4.2. Quy tắc về Check-in / Check-out

1. **"Đã đến" (Arrived):** Chỉ được chuyển khi khách có mặt tại nhà hàng.
2. **"Đang dùng" (Dining):** Chuyển trạng thái khi khách đã bắt đầu dùng bữa.
3. **"Hoàn tất" (Completed):** Chỉ chuyển sau khi thanh toán hóa đơn. Các bàn liên kết sẽ tự động giải phóng sang trạng thái `available` (Trống).
4. **Hủy đặt bàn:** Nếu khách không đến hoặc báo hủy, bản ghi chuyển sang trạng thái `Cancelled`, giải phóng bàn đã gán.

---

## 5. Kiến trúc Component Vue 3 (Đã phân tích)

```
App.vue (Mount point)
  └── DashboardLayout (src/layouts/DashboardLayout.vue - Sidebar & Header)
        ├── Sidebar (Brand, Navigation Links: Lịch, Danh sách, Sơ đồ bàn, Chọn món)
        ├── Header (Branch Selector, Search Input, Notification, User Profile)
        └── RouterView
              ├── TimelineView (src/views/TimelineView.vue - Lịch đặt bàn)
              ├── ListView (src/views/ListView.vue - Danh sách đặt bàn)
              ├── FloorPlanView (src/views/FloorPlanView.vue - Sơ đồ bàn canvas)
              └── OrderDetailView (src/views/OrderDetailView.vue - Chi tiết đặt chỗ & Chọn món)
```

---

## 6. Ràng buộc Kỹ thuật & Gợi ý Triển khai Production

### 6.1. Hiện tại (Client-side & Mock Data)
- Sử dụng **Vite** làm bundler và build tool chính.
- Toàn bộ dữ liệu được mock tĩnh tại [mock-data.ts](file:///e:/Công ty/Task/260/Product/src/lib/mock-data.ts).
- Quản lý trạng thái thông qua hệ thống Reactive (`ref`, `computed`, `reactive`) của Vue 3.

### 6.2. Kiến trúc Đề xuất cho Production

```
Client (Vue 3 + Vite) 
    │
    ├── Pinia: Quản lý trạng thái UI toàn cục (sidebar, ca làm việc, chi nhánh)
    ├── TanStack Query (Vue Query): Quản lý trạng thái server (lịch đặt bàn, trạng thái bàn)
    │     └── REST API / GraphQL → Backend Node.js / .NET
    ├── Zod: Validate dữ liệu đầu vào của các form đặt bàn/chọn món
    └── WebSocket: Đồng bộ hóa trạng thái bàn thời gian thực (Real-time table mapping)
```
