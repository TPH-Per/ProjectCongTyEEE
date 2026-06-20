# Phân tích Nghiệp vụ Hệ thống Quản lý Nhà hàng (Restaurant Booking System)

> Dự án: UI Clone & Modernization — Restaurant Booking System (SaaS)
> Ngày phân tích: 20/06/2026
> Công nghệ: Next.js 14 (App Router), TypeScript, TailwindCSS, shadcn/ui

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

### 2.1. Màn hình Lịch đặt bàn `/` (Timeline View)

**Mục đích nghiệp vụ:** Cung cấp cái nhìn trực quan về mật độ đặt bàn theo **khung giờ** và **khu vực** trong ngày.

**Nghiệp vụ chi tiết:**
- Mỗi cột dọc = 1 khu vực (Zone A, B, VIP, Sân vườn)
- Mỗi hàng ngang = 1 khung giờ (Morning: 7h-11h, Noon: 11h-14h, Afternoon: 14h-17h, Evening: 17h-22h)
- **Màu sắc thẻ đặt bàn thể hiện trạng thái:**
  - 🔶 Amber (`bg-amber-50`) → Pending (Chờ xử lý)
  - 🔵 Blue (`bg-blue-50`) → Arrived (Đã đến)
  - 🟢 Emerald (`bg-emerald-50`) → Dining (Đang dùng)
  - ⚪ Slate (`bg-slate-50`) → Completed (Hoàn tất)
  - 🔴 Rose (`bg-rose-50`) → Cancelled (Đã hủy)
- Nhân viên có thể **lọc theo khu vực** để xem chi tiết
- **Thanh tìm kiếm** cho phép tra cứu nhanh theo tên khách, SĐT, mã đặt bàn
- **Nút "Hôm nay"** để quay về ngày hiện tại

**Quy tắc nghiệp vụ:**
- Mỗi đặt bàn chỉ xuất hiện trong đúng khung giờ và khu vực đã chọn
- Đặt bàn kéo dài qua nhiều khung giờ (VD: 11h-15h) sẽ hiển thị ở khung giờ bắt đầu
- Số lượng đặt bàn trong 1 ô = số thẻ trong ô đó, giới hạn hiển thị theo chiều cao ô

---

### 2.2. Màn hình Danh sách `/list` (List View)

**Mục đích nghiệp vụ:** Tra cứu và quản lý danh sách đặt bàn dạng bảng, hỗ trợ tìm kiếm và lọc nâng cao.

**Nghiệp vụ chi tiết:**
- **Bộ lọc theo trạng thái:** Tab chọn lọc nhanh (Tất cả, Chờ, Đã đến, Đang dùng, Hoàn tất, Đã hủy)
- **Chọn ngày:** Xem đặt bàn của ngày cụ thể
- **Tìm kiếm:** Tra cứu theo tên khách hàng
- **Bảng dữ liệu** hiển thị các cột:
  1. Checkbox (chọn nhiều)
  2. Mã đặt bàn (link → Chi tiết)
  3. Khách hàng (tên + avatar)
  4. Số điện thoại
  5. Giờ đến
  6. Số người
  7. Bàn được gán
  8. Loại tiệc
  9. Nguồn khách
  10. Trạng thái (badge màu)
  11. Thao tác (xem chi tiết, chỉnh sửa, hủy)
- **Phân trang:** 10, 20, 50 bản ghi/trang

**Quy tắc nghiệp vụ:**
- Dữ liệu mặc định là ngày hôm nay
- Khi chọn trạng thái "Đã đến", hệ thống gợi ý gán bàn nếu chưa có
- Có thể xuất danh sách ra file (tính năng tương lai)

---

### 2.3. Màn hình Sơ đồ bàn `/floor-plan` (Floor Plan)

**Mục đích nghiệp vụ:** Quản lý không gian bàn trực quan, gán khách vào bàn, theo dõi trạng thái từng bàn theo thời gian thực.

**Nghiệp vụ chi tiết:**
- **Hai chế độ xem:**
  1. **Theo ngày:** Xem trạng thái bàn trong ngày cụ thể
  2. **Hiện tại (Realtime):** Xem trạng thái bàn thực tế ngay lúc này
- **Bảng khu vực (Zone panel):** Bên trái, hiển thị danh sách zone + thống kê số bàn (trống/đã đặt/có khách)
- **Bản đồ bàn:** Vị trí các bàn được sắp xếp theo tọa độ (x, y) với màu sắc trạng thái:
  - 🟢 Xanh lá → Available (Trống, sẵn sàng)
  - 🟡 Vàng → Reserved (Đã đặt, chưa check-in)
  - 🔴 Hồng → Occupied (Có khách đang dùng)
- **Popover hover:** Xem nhanh thông tin (mã bàn, sức chứa, tên khách nếu có, giờ đến, số người)

**Quy tắc nghiệp vụ:**
- Mỗi bàn có sức chứa tối đa (capacity) – không thể gán vượt quá
- Bàn "Occupied" không thể được gán cho đặt bàn khác
- Ưu tiên gán bàn theo khu vực phù hợp với loại khách/tiệc
- Tọa độ bàn (x, y) dùng để vẽ trên canvas, lưu theo cấu hình

---

### 2.4. Màn hình Chi tiết đặt bàn `/order/[id]` (Booking Detail)

**Mục đích nghiệp vụ:** Xem và thao tác toàn bộ thông tin của một đặt bàn cụ thể.

**Nghiệp vụ chi tiết:**

#### 2.4.1. Tab "TT-Đặt chỗ" (Thông tin đặt chỗ)
- Thông tin cơ bản: Mã đặt bàn, ngày giờ, số người, khu vực, bàn
- **Trạng thái hiện tại** và luồng thay đổi trạng thái
- **Ghi chú** của khách / ghi chú nội bộ
- Thông tin khách hàng: Tên, SĐT, email, số lần đến, tổng chi tiêu

#### 2.4.2. Tab "TT-Mở rộng" (Thông tin mở rộng)
- Thông tin thanh toán: Hình thức, trạng thái, số tiền
- **Tiền cọc** (nếu có): Số tiền, ngày cọc, phương thức, người thu
- Yêu cầu đặc biệt: Trang trí, bánh sinh nhật, ăn kiêng...
- Thông tin quản trị: Người tạo, ngày tạo, người cập nhật cuối

#### 2.4.3. Tab "Người tiếp nhận" (Receiver)
- **Timeline nhân viên:** Ai tiếp nhận, ai xác nhận, ai phục vụ
- Lưu vết ca làm việc (lễ tân sáng → quản lý chiều → phục vụ tối)

#### 2.4.4. Tab "Lịch sử thao tác" (Operations History)
- Timeline chi tiết các hành động trên bản ghi:
  - "Đặt bàn được tạo bởi Nguyễn Văn A"
  - "Bàn A03 được gán bởi Trần Thị B"
  - "Trạng thái chuyển từ 'Chờ' sang 'Đã đến'"
  - "Khách check-in lúc 11:32"

#### 2.4.5. Tab "Lịch sử tiêu dùng" (Consumption History)
- Bảng danh sách món đã gọi: Mã món, tên, số lượng, đơn giá, thành tiền
- Tổng cộng: Tạm tính → Thuế (VAT 10%) → Tổng thanh toán
- Trạng thái đơn hàng: Đang phục vụ / Đã thanh toán / Đã hủy
- **Nút "In hóa đơn"** và "Thanh toán"

**Quy tắc nghiệp vụ:**
- Không thể chỉnh sửa đặt bàn đã "Hoàn tất" hoặc "Đã hủy"
- **Nút "Đã đến"** chuyển trạng thái từ Pending → Arrived (hoặc tự động Dining nếu đã gán bàn)
- **Nút "Thanh toán"** kết thúc đơn hàng, chuyển trạng thái đặt bàn → Completed
- Chỉ có Quản lý ca mới được hủy đặt bàn đã check-in

---

### 2.5. Màn hình Chọn món (Tích hợp trong `/order/[id]`)

**Mục đích nghiệp vụ:** Ghi nhận món ăn/dịch vụ khách đặt, quản lý order theo bàn.

**Nghiệp vụ chi tiết:**
- Phân loại món theo danh mục: Buffet, Set Lunch, Thức ăn, Thức uống, Khác
- Thêm/sửa/xóa món trong order
- Số lượng và ghi chú cho từng món (VD: "Bò tái", "Không hành")
- Tự động tính tổng tiền và thuế

**Quy tắc nghiệp vụ:**
- Món đã ghi không thể xóa nếu đã chế biến (cần xác nhận bếp)
- Giá món có thể thay đổi theo khung giờ (giờ cao điểm/giờ thấp điểm)
- Hỗ trợ chia hóa đơn (split bill) cho bàn ghép

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
| **Branch** | `id`, `name`, `address`, `phone`, `isActive` | Cấu hình đa chi nhánh |
| **Zone** | `id`, `name`, `branchId`, `displayOrder` | VD: Tầng 1, VIP, Sân vườn |
| **Table** | `id`, `code`, `zoneId`, `capacity`, `status`, `x`, `y` | Tọa độ cho sơ đồ |
| **Customer** | `id`, `name`, `phone`, `email`, `visitCount`, `totalSpent` | CRM tích hợp |
| **Reservation** | `id`, `customerId`, `date`, `time`, `guests`, `status`, `tableCodes`, `notes` | Trung tâm hệ thống |
| **MenuItem** | `id`, `name`, `category`, `price`, `isAvailable` | Phân loại theo danh mục |
| **Order** | `id`, `reservationId`, `subTotal`, `vat`, `total`, `status` | Liên kết 1-1 với Reservation |
| **OrderItem** | `id`, `orderId`, `menuItemId`, `quantity`, `unitPrice`, `note` | Chi tiết từng món |
| **StaffLog** | `id`, `reservationId`, `action`, `staffName`, `timestamp` | Audit trail |

### 3.2. Enum/Trạng thái

**ReservationStatus:**
```
Pending → Arrived → Dining → Completed
                          ↘ Cancelled
```

**TableStatus:**
```
Available | Reserved | Occupied | Maintenance
```

**OrderStatus:**
```
Pending → Serving → Paid | Cancelled
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

1. **"Đã đến" (Arrived):** Chỉ được chuyển khi có ít nhất 1 bàn đã gán. Nếu chưa gán bàn, hệ thống gợi ý mở sơ đồ bàn.
2. **"Đang dùng" (Dining):** Tự động chuyển từ Arrived sau 15 phút (hoặc khi ghi món đầu tiên).
3. **"Hoàn tất" (Completed):** Chỉ chuyển sau khi thanh toán. Bàn được giải phóng.
4. **Quá giờ:** Nếu khách chưa đến sau 30 phút so với giờ hẹn, hệ thống cảnh báo và có thể tự động hủy (cấu hình).

### 4.3. Quy tắc về Phân quyền

| Tính năng | Lễ tân | Quản lý ca | Quản trị |
|-----------|--------|-------------|----------|
| Xem lịch đặt bàn | ✅ | ✅ | ✅ |
| Tạo đặt bàn mới | ✅ | ✅ | ✅ |
| Chỉnh sửa đặt bàn | ✅ (trừ Completed/Cancelled) | ✅ | ✅ |
| Hủy đặt bàn | ✅ (chỉ Pending) | ✅ | ✅ |
| Gán/Xóa bàn | ✅ | ✅ | ✅ |
| Check-in khách | ✅ | ✅ | ✅ |
| Ghi món | ✅ | ✅ | ✅ |
| Thanh toán | ❌ | ✅ | ✅ |
| Hủy đã check-in | ❌ | ✅ | ✅ |
| Cấu hình hệ thống | ❌ | ❌ | ✅ |
| Xem báo cáo | ❌ | ✅ | ✅ |

---

## 5. Luồng Xử lý Chi tiết

### 5.1. Luồng "Tiếp nhận đặt bàn qua điện thoại"

```
1. Lễ tân nghe điện thoại
2. Mở màn hình Lịch hoặc Danh sách
3. Nhấn "Thêm đặt bàn" (nút TODO)
4. Form đặt bàn hiện ra:
   - Nhập: Tên khách, SĐT, ngày giờ, số người, loại tiệc, nguồn khách, ghi chú
   - Gợi ý: Tìm kiếm khách hàng cũ theo SĐT
5. Chọn khu vực và gán bàn (hoặc để sau)
6. Lưu → Trạng thái: Pending
```

### 5.2. Luồng "Khách đến nhà hàng (Walk-in)"

```
1. Khách đến trực tiếp
2. Lễ tân kiểm tra sơ đồ bàn còn trống không
3. Tạo đặt bàn nhanh:
   - Nhập: Tên khách, SĐT, số người
   - Chọn bàn trống từ sơ đồ
4. Lưu → Trạng thái: Arrived (vì khách đã có mặt)
5. Chuyển sang màn hình Chọn món nếu khách gọi đồ ngay
```

### 5.3. Luồng "Phục vụ & Ghi món"

```
1. Phục vụ mở màn hình Chọn món cho bàn cần phục vụ
2. Chọn danh mục → Chọn món → Nhập số lượng → Ghi chú (nếu có)
3. Thêm món vào order
4. Gửi món đến bếp (in phiếu / WebSocket)
5. Theo dõi trạng thái: Đã gửi bếp → Đang chế biến → Đã lên món
6. Khi khách yêu cầu thêm/gọi lại, lặp lại bước 2-4
```

### 5.4. Luồng "Thanh toán & Kết thúc"

```
1. Khách yêu cầu thanh toán
2. Quản lý ca kiểm tra hóa đơn
3. Xác nhận tổng tiền với khách
4. Chọn hình thức thanh toán (Tiền mặt/Credit Card/Voucher)
5. In hóa đơn / Gửi email hóa đơn
6. Xác nhận thanh toán:
   - Order → Paid
   - Reservation → Completed
   - Table → Available
7. Dọn bàn
```

---

## 6. Ràng buộc Kỹ thuật & Gợi ý Triển khai

### 6.1. Hiện tại (Mock Data)
- Tất cả dữ liệu đang được mock cứng trong `src/lib/mock-data.ts`
- Chưa có kết nối API, chưa có server actions, chưa có database
- State management chỉ dùng `useState` local

### 6.2. Kiến trúc Đề xuất cho Production

```
Client (Next.js) 
    │
    ├── Zustand: UI state (sidebar, active tab, filters)
    ├── TanStack Query: Server state (reservations, tables)
    │     └── REST API / GraphQL → Backend (Node.js / .NET / PHP)
    ├── React Hook Form + Zod: Form validation
    └── WebSocket: Real-time updates (table status, new bookings)
```

### 6.3. Backlog Cải tiến

| Mức độ | Tính năng | Mô tả |
|--------|-----------|-------|
| 🔴 Cao | API Integration | Thay thế mock data bằng API calls |
| 🔴 Cao | Real-time | WebSocket cho cập nhật trạng thái bàn theo thời gian thực |
| 🔴 Cao | Form tạo đặt bàn | Modal/form để thêm/sửa đặt bàn |
| 🟡 Trung | Authentication | Đăng nhập, phân quyền |
| 🟡 Trung | Drag & Drop Floor | Kéo thả khách vào bàn trên sơ đồ |
| 🟡 Trung | Responsive Mobile | Giao diện tối ưu cho tablet |
| 🟢 Thấp | Báo cáo/Thống kê | Doanh thu, mật độ khách, món bán chạy |
| 🟢 Thấp | Dark Mode | Hỗ trợ giao diện tối |
| 🟢 Thấp | In ấn | In phiếu đặt bàn, hóa đơn |
| 🟢 Thấp | Đa ngôn ngữ | Hỗ trợ tiếng Việt/Tiếng Anh |

---

## 7. Sơ đồ Kiến trúc Component (Đã phân tích)

```
RootLayout (app/layout.tsx)
  └── DashboardLayout (app/(dashboard)/layout.tsx)
        ├── Sidebar
        │     ├── Brand Logo + Tên nhà hàng
        │     ├── Nav: Lịch, Danh sách, Sơ đồ bàn, Chọn món, Cấu hình
        │     └── User Profile
        ├── Header
        │     ├── Branch Selector (dropdown)
        │     ├── Search Bar
        │     ├── Notification Bell
        │     └── User Avatar
        └── Main Content
              ├── Page: Timeline (Lịch đặt bàn)     → /
              ├── Page: List (Danh sách)             → /list
              ├── Page: FloorPlan (Sơ đồ bàn)        → /floor-plan
              └── Page: OrderDetail (Chi tiết đặt)   → /order/[id]
                    ├── TabInfo
                    ├── TabExpanded
                    ├── TabReceiver
                    ├── TabOperations
                    └── TabConsumption
```

---

## 8. Các điểm cần làm rõ thêm

1. **Cơ chế "Khóa giờ"**: Có giới hạn giờ nhận đặt bàn không? Có auto-release bàn nếu khách không đến không?
2. **Xử lý hủy bàn**: Nếu khách hủy trong vòng 2h có tính phí không? Hệ thống có gửi thông báo không?
3. **Đặt bàn online**: Tích hợp với kênh nào (website, Facebook, GrabFood...)?
4. **Báo cáo**: Cần những chỉ số KPI nào? (Doanh thu/ngày, tỷ lệ hủy, bàn quay vòng...)
5. **Phần cứng**: Có kết nối máy in hóa đơn, máy POS, thiết bị bếp không?
6. **Phân quyền chi tiết**: Có cần vai trò "Thu ngân" riêng không? nhân viên bếp có quyền gì?
7. **Multiple branches**: Có cần chuyển đổi nhanh giữa các chi nhánh không? Dữ liệu có tách biệt không?

---

## 9. Kết luận

Dự án là một **hệ thống quản lý nhà hàng toàn diện** với 4 màn hình chính đã được xây dựng UI (Timeline, List, FloorPlan, Order Detail). Các màn hình này bao phủ được **luồng nghiệp vụ cốt lõi**: theo dõi đặt bàn, tra cứu, điều phối bàn, và chi tiết đặt bàn.

**Điểm mạnh:**
- Kiến trúc component sạch, tách biệt rõ ràng
- Màu sắc trạng thái trực quan
- Mock data đầy đủ cho 16+ kịch bản
- Giao diện chuyên nghiệp theo chuẩn SaaS

**Cần phát triển tiếp:**
- Form tạo/sửa đặt bàn
- Xác thực người dùng
- Real-time sync giữa các thiết bị
- API backend & database
- Module báo cáo

---

*Tài liệu này được tạo dựa trên phân tích mã nguồn dự án UI Clone (Next.js 14 + TailwindCSS + shadcn/ui).*
