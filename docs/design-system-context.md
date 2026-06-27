# KITCHEN MODULE - DESIGN SYSTEM CONTEXT

## 1. MỤC TIÊU THIẾT KẾ

Kitchen Display System (KDS) cần đảm bảo:
- **Dễ đọc từ xa**: Bếp trưởng đứng cách màn hình 2-3m vẫn đọc được.
- **Tương phản cao**: Môi trường bếp nhiều ánh sáng, dầu mỡ, hơi nước.
- **Thao tác nhanh**: Nút bấm lớn, dễ chạm khi đeo găng tay hoặc tay bị ướt.
- **Phân cấp thông tin rõ ràng**: Ưu tiên cao cho trạng thái, thời gian chờ và cảnh báo dị ứng.

## 2. BỐ CỤC KITCHEN SCREEN (LAYOUT)

### 2.1. Layout chính

```text
  KDS HEADER (80px)                                          
  [Logo] [Station: BẾP NƯỚNG] [Timer] [Alert Badge] [User] 

  FILTER BAR (60px)                                          
  [Station Filter] [Status Filter] [Sort Options] [Search...]

  STATUS BAR (50px)                                          
  [Chờ: 12] [Đang nấu: 8] [Sẵn sàng: 5] [Trễ: 3]

  TICKET GRID AREA (Flex: 1)                                
  - Kanban Board chia thành 3 cột tương ứng với các trạng thái:
    1. Chờ chế biến (Pending)
    2. Đang làm (Preparing)
    3. Hoàn thành (Done)
```

### 2.2. Ticket Card Design
- **Kích thước:** Width: 280px (fixed), Height: Auto (min 200px).
- **Cấu trúc:**
  - Header: Mã đơn hàng (ID) và thời gian đếm ngược (Timer).
  - Table Info: Tên bàn (ví dụ: Bàn A01) và số lượng khách.
  - Item List: Danh sách món ăn kèm số lượng phóng to (ví dụ: `2x Sườn Wagyu`).
  - Notes: Ghi chú đặc biệt hoặc cảnh báo dị ứng (highlight đỏ/vàng).
  - Actions: Nút thao tác nhanh ở chân card (BẮT ĐẦU / HOÀN TẤT).

## 3. HỆ THỐNG MÀU SẮC KDS (DARK MODE CHỦ ĐẠO)

### 3.1. Màu nền & Màu chữ
- **Nền chính (Bg Primary)**: `#1A1A1A`
- **Nền phụ (Bg Secondary)**: `#2D2D2D`
- **Nền thẻ (Bg Card)**: `#4A4A4A`
- **Text chính**: `#FFFFFF`
- **Text phụ**: `#E0E0E0`
- **Ghi chú/Giá trị**: `#FFA726` (Cam vàng)

### 3.2. Màu trạng thái Ticket (Border & Glow)
- **Mới (New)**: Border `#3949AB` (Indigo/Xanh đậm)
- **Đang nấu (Cooking)**: Border `#F57C00` (Cam)
- **Sẵn sàng (Ready)**: Border `#4CAF50` (Xanh lá)
- **Trễ (Delayed)**: Border `#F44336` (Đỏ) + Nhấp nháy nguy hiểm.

### 3.3. Cảnh báo thời gian
- **Timer Bình thường**: Màu xanh lá (`#4CAF50`) khi thời gian chờ < 10 phút.
- **Timer Cảnh báo**: Màu cam (`#FF9800`) khi thời gian chờ từ 10 - 15 phút.
- **Timer Nguy hiểm**: Màu đỏ (`#F44336`) khi thời gian chờ > 15 phút.

## 4. TYPOGRAPHY & TOUCH TARGETS

### 4.1. Kích thước Font chữ
- **Số bàn / Số thứ tự**: 24px - 32px (Bold) để dễ nhận diện từ xa.
- **Tên món & Số lượng**: 18px - 20px (Semibold) giúp kiểm tra nhanh.
- **Thời gian chờ (Timer)**: 28px (Font chữ Monospace như Courier New).

### 4.2. Touch Targets (Tương tác cảm ứng)
- Các nút hành động có kích thước tối thiểu `48x48px` (khuyên dùng `56x56px` cho môi trường bếp) để dễ bấm và có khoảng cách (gap) tối thiểu `8px` tránh ấn nhầm.

## 5. ANIMATIONS & HIỆU ỨNG TRỰC QUAN
- **Hiệu ứng Pulse (Nhịp thở)**: Áp dụng cho các card ưu tiên hoặc bị trễ.
- **Hiệu ứng Blink (Nhấp nháy)**: Áp dụng cho đồng hồ khi quá hạn nấu (> 15 phút).
- **Âm thanh (Audio Cue)**: Phát tiếng bíp ngắn khi có đơn hàng mới chuyển từ POS xuống.
