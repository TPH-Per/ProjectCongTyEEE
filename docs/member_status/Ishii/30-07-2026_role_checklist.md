# ✅ CHECKLIST NGHIỆP VỤ THEO VAI TRÒ — POS NGƯU CÁT

**Ngày:** Thứ Năm, 30/07/2026  
**Cơ sở:** `30-07-2026_business_summary.md`  
**Mục đích:** Danh sách kiểm tra nghiệp vụ cho từng vai trò người dùng trong hệ thống

---

## 1. RECEPTION (LỄ TÂN / THU NGÂN)

> **Modules truy cập:** reception, hall  
> **Route chính:** `/reception/*`  
> **Layout:** ReceptionLayout  
> **Stores:** restaurantStore, receptionStore, shiftStore

### 1.1 Dashboard tổng quan

- [ ] Vào `/reception/dashboard`
- [ ] Kiểm tra thông tin ca làm việc hiện tại (mở/chưa mở)
- [ ] Xem danh sách bàn đang phục vụ
- [ ] Xem danh sách đặt bàn hôm nay
- [ ] Kiểm tra thông báo (notifications) từ hệ thống
- [ ] Xem tên chi nhánh đang hoạt động (fetchBranchInfo)
- [ ] Kiểm tra layout hiển thị đúng (`h-full`, không double padding)

### 1.2 Mở ca làm việc

- [ ] Vào `/reception/shift-summary?action=open` hoặc sidebar "Mở ca"
- [ ] Modal OpenShiftModal hiển thị
- [ ] Nhập tiền mặt đầu ca (`opening_cash`)
- [ ] Validation: số tiền hợp lệ
- [ ] Xác nhận mở ca → hệ thống tạo shift (localStorage)
- [ ] Hệ thống tự tạo mock payments (4 cash, 2 card, 1 transfer)
- [ ] Dashboard hiển thị "Ca đang mở" + shift summary
- [ ] F5 reload → shift vẫn giữ (localStorage persist)

### 1.3 Quản lý sơ đồ bàn (Floor Plan)

- [ ] Vào tab Sơ đồ bàn (`table_map`) tại `/reception/floors`
- [ ] Kiểm tra timeline slider 11:00–22:00
- [ ] Xem 10 khu vực: A (chính), B (VIP), C (ban công), R (phòng riêng), T (sân thượng), Capichi, Shopee, BE, Grab, Catalog
- [ ] Tổng 57 bàn hiển thị đúng
- [ ] Xem trạng thái từng bàn: Available (xanh #27ae60) / Serving (đỏ #c0392b) / Reserved (vàng #f1c40f)
- [ ] Kéo thả bàn để sắp xếp (drag & drop, vue-draggable-plus)
- [ ] Phát hiện conflict (bàn bị trùng lịch)
- [ ] Double-click bàn → context menu hiện tại vị trí chuột

### 1.4 Gọi món (POS Order)

- [ ] Double-click bàn → chọn "Chọn món"
- [ ] Vào tab Thực đơn (`menu`)
- [ ] Dùng bộ lọc nhanh: ⭐ Nổi bật / 🔥 Phổ biến / 🕒 Mới
- [ ] Dùng bộ lọc nâng cao (theo category/subcategory)
- [ ] Click món → modal chi tiết (MenuItemDetailModal)
- [ ] Chọn số lượng trong modal
- [ ] Thêm ghi chú đặc biệt cho món (nếu có)
- [ ] Thêm vào giỏ hàng (CartItem)
- [ ] Chọn gói buffet (package) cho bàn
- [ ] Kiểm tra giỏ hàng: món trong gói = 0đ ("Trong gói")
- [ ] Kiểm tra: surcharge items (khac-phi) luôn tính phí
- [ ] Kiểm tra: món "lunch" được giảm 50%
- [ ] Mã đơn hàng tự sinh: SF_0000XXXX
- [ ] Gửi bếp → đơn hàng chuyển `confirmed → cooking`
- [ ] Tạm lưu đơn nếu cần
- [ ] In bill tạm tính (kitchen ticket)
- [ ] Quản lý course/packages (nhiều vòng gọi món)

### 1.5 Thao tác bàn (Context Menu — 6 thao tác)

- [ ] **Chọn món:** Luôn hiển thị — mở POS order
- [ ] **Chuyển bàn:** Double-click bàn nguồn → "Chuyển bàn" → bàn nguồn viền đỏ pulsing → click bàn đích (viền xanh bouncing) → Swal xác nhận → thực thi
- [ ] **Ghép phiếu:** Double-click bàn nguồn → "Ghép phiếu" → click bàn đích → xác nhận → gộp đơn
- [ ] **Tách phiếu:** Double-click bàn nguồn → "Tách phiếu" → click bàn đích → xác nhận → tách đơn
- [ ] **Tách món:** Double-click bàn nguồn → "Tách món" → chọn món cụ thể → click bàn đích → xác nhận
- [ ] **Hủy phiếu:** Double-click bàn → "Hủy phiếu" → nhập PIN Manager `1234` → gõ "HỦY" → xác nhận
- [ ] Bàn không hợp lệ trong selection mode: mờ 30% opacity
- [ ] Cancel selection mode → reset state

### 1.6 Thanh toán (Checkout)

- [ ] Vào `/reception/checkout/:id`
- [ ] Tìm kiếm khách hàng (nếu có) — theo phone/name
- [ ] Chọn loại doanh thu: food / beverage / service / other
- [ ] Áp dụng voucher (nếu có) — percent / fixed / buy_x_get_y
- [ ] Kiểm tra Subtotal
- [ ] Kiểm tra Service charge 5% = Subtotal × 0.05
- [ ] Kiểm tra VAT 8% = (Subtotal + Service charge) × 0.08
- [ ] Kiểm tra Total = (Subtotal + Service charge) × 1.08
- [ ] Chọn phương thức: cash / card / transfer / other
- [ ] Kết hợp nhiều phương thức thanh toán
- [ ] Bàn phím số hiển thị đúng (3 cột: danh sách món + chi tiết + keypad)
- [ ] Xác nhận thanh toán → in hóa đơn
- [ ] Cập nhật trạng thái bàn → available

### 1.7 Quản lý đặt bàn (Reservation)

- [ ] Vào `/reception/reservation-detail`
- [ ] Tạo đặt bàn mới: customer, table, time, meal type
- [ ] Phân khu giờ tự động: morning (<11h) / lunch (11–14h) / afternoon (14–17h) / evening (>17h)
- [ ] Chọn meal type: LUNCH / DINNER
- [ ] Trạng thái đặt bàn: PENDING → CONFIRMED → SEATED → COMPLETED
- [ ] Có thể CANCELLED
- [ ] Gán bàn: assignTable
- [ ] Giải phóng bàn: releaseTable
- [ ] Check-in khách: CONFIRMED → SEATED
- [ ] Hoàn tất: SEATED → COMPLETED
- [ ] Chuẩn hóa trạng thái từ nhiều nguồn (DB, view cũ) về 5 trạng thái canonical

### 1.8 Xử lý đơn chờ (Pending)

- [ ] Vào tab Chưa xử lý (`pending`)
- [ ] Xem danh sách đơn chờ
- [ ] Duyệt / từ chối / xử lý từng đơn
- [ ] Kiểm tra đơn từ Customer tablet (nếu có realtime)

### 1.9 Quản lý thực đơn (tại Reception)

- [ ] Vào `/reception/menu-management`
- [ ] Thêm/sửa/xóa category
- [ ] Thêm/sửa/xóa subcategory
- [ ] Thêm/sửa/xóa menu item
- [ ] Soft-delete món (is_active = false) — không xóa cứng
- [ ] Copy món (tự thêm "(Bản sao)" + "-COPY")
- [ ] Không xóa category/subcategory còn item con
- [ ] Bulk lock/unlock (sold-out toggle) — QuickLockBar + QuickLockToggle
- [ ] Kéo thả sắp xếp thứ tự category/subcategory
- [ ] Broadcast event `menu:item-status-changed` cho POS realtime

### 1.10 Tồn kho tức thời

- [ ] Vào `/reception/inventory`
- [ ] Xem tồn kho tức thời tại chi nhánh
- [ ] Kiểm tra ngưỡng cảnh báo tồn kho

### 1.11 Chi khác (Other Expense)

- [ ] Vào `/reception/other-expense`
- [ ] Ghi nhận chi phí khác (không thuộc doanh thu)
- [ ] Modal nhập chi phí: showOtherIncomeModal

### 1.12 Báo cáo & Doanh thu

- [ ] Vào `/reception/reports` — xem báo cáo tổng hợp
- [ ] Vào `/reception/revenue-overview` — tổng quan doanh thu
- [ ] Phân tích doanh thu theo phương thức (cash/card/transfer/other)
- [ ] Phân tích theo loại doanh thu (food/beverage/service/other)

### 1.13 Xử lý món (Process Items)

- [ ] Vào `/reception/process-items`
- [ ] Xem danh sách món cần xử lý
- [ ] Cập nhật trạng thái món: Pending → Preparing → Served
- [ ] Hủy món nếu cần (Cancelled)

### 1.14 Đóng ca & Đối soát

- [ ] Vào sidebar "Tổng kết ca" → `/reception/shift-summary`
- [ ] Kiểm tra 4 overview cards: cash, card, transfer, total
- [ ] Xem bảng doanh thu theo phương thức + tỷ lệ %
- [ ] Vào "Ra ca" → `/reception/close-shift`
- [ ] Nhập closing_cash thực tế
- [ ] Hệ thống tính expected_cash = opening_cash + cash_revenue
- [ ] Kiểm tra cash_difference (variance)
- [ ] Nếu |variance| > 100.000đ → nhập PIN Manager (CloseShiftModal)
- [ ] PIN keypad 4 số hiển thị
- [ ] Ghi chú bắt buộc khi có chênh lệch
- [ ] Đổi màu variance: xanh (không lệch) / vàng (lệch nhỏ) / đỏ (lệch lớn)
- [ ] Xuất CSV báo cáo ca
- [ ] Xác nhận đóng ca → shift status chuyển sang closed

### 1.15 Bàn giao ca (Shift Handover)

- [ ] Vào `/reception/shift-handover`
- [ ] Kiểm tra thông tin bàn giao
- [ ] Xác nhận dữ liệu ca kết thúc

---

## 2. STAFF (NHÂN VIÊN PHỤC VỤ)

> **Modules truy cập:** staff, hall  
> **Route chính:** `/staff/*`  
> **Layout:** StaffLayout

### 2.1 Sơ đồ bàn

- [ ] Vào `/staff/floor-plan`
- [ ] Xem trạng thái bàn: trống / đang phục vụ / đã đặt
- [ ] Xem màu bàn: xanh (trống), đỏ (có khách), vàng (đặt trước)
- [ ] Chọn bàn để phục vụ

### 2.2 Mở bàn mới (Walk-in)

- [ ] Vào `/staff/open-table`
- [ ] Chọn bàn trống
- [ ] Mở phiên phục vụ (walk-in)
- [ ] Chọn gói buffet cho khách (1390/1150/680/490/380/kids/lau/550jp/drink)
- [ ] Bàn chuyển trạng thái: available → serving

### 2.3 Quản lý bàn đang phục vụ

- [ ] Vào `/staff/active-tables`
- [ ] Xem danh sách bàn đang phục vụ
- [ ] Cập nhật trạng thái món: Pending → Preparing → Served
- [ ] Đánh dấu món đã phục vụ khách
- [ ] Gọi nhân viên hỗ trợ nếu cần

### 2.4 CRM tại bàn (In-Dining CRM)

- [ ] Vào `/staff/in-dining-crm`
- [ ] Chọn bàn cần khảo sát
- [ ] Đánh dấu trạng thái: not_started → assigned
- [ ] Bắt đầu survey: assigned → in_progress
- [ ] Thu thập thông tin khách:
  - [ ] Họ tên khách
  - [ ] Số điện thoại
  - [ ] Zalo
  - [ ] Tags (VIP, repeater, new, etc.)
  - [ ] Lý do đến (visit reason)
  - [ ] Feedback / góp ý
  - [ ] Marketing consent (đồng ý nhận MKT)
- [ ] Hoàn tất: → completed
- [ ] Hoặc bỏ qua: → skipped
- [ ] Hoặc khách từ chối: → customer_refused
- [ ] Hoặc quá hạn: → expired
- [ ] Hoặc nộp muộn: → late_submitted

### 2.5 Hỗ trợ khách (qua Hall)

- [ ] Phản hồi yêu cầu dịch vụ từ khách
- [ ] Xử lý: call_staff (gọi nhân viên)
- [ ] Xử lý: add_charcoal (thêm than)
- [ ] Xử lý: water (nước)
- [ ] Xử lý: tissue (khăn)
- [ ] Xử lý: bowl (chén bát)
- [ ] Xử lý: sauce (gia vị)
- [ ] Xử lý: ice (đá)
- [ ] Xử lý: grill_change (thay vỉ nướng)
- [ ] Xử lý: charcoal_change (thay than)
- [ ] Xử lý: checkout / request_bill (tính tiền)
- [ ] Xử lý: call_waiter (gọi phục vụ)
- [ ] Đánh dấu yêu cầu đã xử lý xong

---

## 3. KITCHEN (BẾP)

> **Modules truy cập:** kitchen  
> **Route chính:** `/kitchen/*`  
> **Layout:** KitchenLayout  
> **Store:** kitchen.ts

### 3.1 Kitchen Display System (KDS)

- [ ] Vào `/kitchen/kds`
- [ ] Xem danh sách đơn hàng từ bếp (theo thứ tự thời gian)
- [ ] Theo dõi trạng thái món: Pending → Preparing → Served
- [ ] Đánh dấu món đang chuẩn bị (Pending → Preparing)
- [ ] Đánh dấu món đã xong → chuyển sang Expo
- [ ] Nhận yêu cầu thay vỉ nướng (GrillRequest)
- [ ] Xem danh sách PrepTask (nhiệm vụ chuẩn bị bếp)
- [ ] Cập nhật trạng thái PrepTask

### 3.2 Expo (Xuất món / QC)

- [ ] Vào `/kitchen/expo`
- [ ] Xem danh sách món đã xong từ KDS
- [ ] Kiểm tra món trước khi xuất
- [ ] QC chất lượng món
- [ ] Đánh dấu món đã xuất → phục vụ bàn
- [ ] Từ chối món không đạt (nếu cần)

### 3.3 Tồn kho bếp

- [ ] Vào `/kitchen/inventory`
- [ ] Xem KitchenStock (tồn bếp) vs MainStock (tồn kho tổng)
- [ ] Kiểm tra minKitchenStock — cảnh báo ngưỡng thấp
- [ ] Kiểm kê nguyên liệu thực tế
- [ ] Xem danh sách InventoryItem
- [ ] So sánh tồn thực tế vs tồn hệ thống

### 3.4 Yêu cầu xuất kho (Requisition)

- [ ] Vào `/kitchen/requisition`
- [ ] Tạo phiếu yêu cầu xuất kho (RequisitionForm)
- [ ] Chọn nguyên liệu cần xuất (RequisitionItem)
- [ ] Nhập số lượng yêu cầu
- [ ] Ghi chú cho từng item
- [ ] Trạng thái: pending
- [ ] Chờ duyệt / nhận đề xuất thay thế (substitute_proposed)
- [ ] Xem timeline yêu cầu (RequisitionTimeline)
- [ ] Nhận hàng sau khi duyệt (approved → delivered)
- [ ] Bếp trưởng ký nhận
- [ ] Hệ thống tự cập nhật COGS
- [ ] Xem danh sách yêu cầu (RequisitionList)
- [ ] Xem chi tiết yêu cầu (RequisitionDetail)
- [ ] Trạng thái badge hiển thị đúng (RequisitionStatusBadge)
- [ ] Dùng toolbar lọc/tìm kiếm (RequisitionToolbar)

### 3.5 Bàn giao ca bếp (Handover)

- [ ] Vào `/kitchen/handover`
- [ ] **Bước 1 — Bếp ra (outgoing):**
  - [ ] Kiểm kê nguyên liệu còn lại
  - [ ] Ghi số lượng từng nguyên liệu (HandoverLogItem)
  - [ ] Ghi nhiệt độ tủ lạnh
  - [ ] Ghi nhiệt độ tủ đông
- [ ] **Bước 2 — Bếp vào (incoming):**
  - [ ] Ký nhận bàn giao
  - [ ] Xác nhận số lượng nguyên liệu
  - [ ] Báo cáo sai lệch (nếu có)
- [ ] **Bước 3 — Hoàn tất:**
  - [ ] Audit log tự động tạo
  - [ ] HandoverLog lưu vào hệ thống

### 3.6 Audit & COGS

- [ ] Mọi thay đổi trạng thái tạo audit log
- [ ] COGS tự cập nhật khi xuất kho
- [ ] Kiểm tra audit log để đối soát

---

## 4. CUSTOMER (KHÁCH HÀNG — TABLET)

> **Modules truy cập:** customer  
> **Route chính:** `/customer/*`  
> **Layout:** CustomerLayout (Dark Wood theme, landscape tablet)  
> **Store:** customerStore.ts  
> **API:** customerApi.ts

### 4.1 Mở khóa tablet

- [ ] Màn hình chờ (TabletIdleView) — touch to start
- [ ] Chọn ngôn ngữ (TabletLanguageView): VI / EN / JA
- [ ] Nhập passcode nhân viên (6 ký tự) — PasscodeInput
- [ ] Hệ thống xác thực authenticateStaff(passcode)
- [ ] Mock passcode: 123456 / 654321

### 4.2 Chọn chi nhánh & khu vực

- [ ] Chọn chi nhánh (BranchGrid component)
- [ ] Chọn khu vực (AreaGrid component — grid 2 cột)
- [ ] 10 khu vực: A, B, C, R, T, Capichi, Shopee, BE, Grab, Catalog

### 4.3 Chọn bàn

- [ ] Chọn bàn từ TableGrid (grid 4-5 cột)
- [ ] Timeout 60s chọn bàn (BR-08)
- [ ] Nếu timeout → giải phóng bàn → quay về chọn khu
- [ ] Hệ thống tạo session (createSession)
- [ ] Flip bàn sang occupied
- [ ] Yêu cầu session active để truy cập menu/cart/orders (BR-09)

### 4.4 Chọn gói buffet (PackageSelector)

- [ ] Xem danh sách gói buffet
- [ ] Chọn gói phù hợp:
  - [ ] 1390 — tất cả categories eligible
  - [ ] 1150 — loại trừ wagyu
  - [ ] 680 — loại trừ wagyu + premium beef
  - [ ] 490 — chỉ safe items (pork, chicken, soft_drink, tea, appetizer, salad, rice, noodle, soup, dessert)
  - [ ] 380 — tương tự 490 (safe items)
  - [ ] kids — chỉ KIDS / egg / fries / dessert
  - [ ] lau — buffet lẩu (hotpot + drinks + veggies)
  - [ ] 550jp — set bento / sashimi / tempura / miso
  - [ ] drink — SET DRINK-only

### 4.5 Xem menu & gọi món

- [ ] Duyệt menu theo danh mục (MenuCategoryBar + MenuSubcategoryBar)
- [ ] Duyệt theo category tabs (CategoryTabs)
- [ ] Xem grid món ăn (MenuItemCard)
- [ ] Click món → modal chi tiết (MenuItemDetailModal)
- [ ] Chọn số lượng
- [ ] Thêm ghi chú đặc biệt
- [ ] Thêm vào giỏ (CartItem)
- [ ] Món trong gói buffet → giá = 0đ ("Trong gói")
- [ ] Surcharge items (khac-phi) → luôn tính phí
- [ ] Món "lunch" → giảm 50% — hiển thị "{half}đ (Lunch 50%)"
- [ ] Group món theo trạm bếp: hot, meat, salad (BR-23)
- [ ] Format kitchen ticket text (BR-27)
- [ ] Tăng printedCount kitchen ticket (BR-28)
- [ ] FAB gọi phục vụ (floating action button)

### 4.6 Giỏ hàng & đặt món

- [ ] Vào giỏ hàng `/customer/cart`
- [ ] Xem BottomCartBar (floating cart summary)
- [ ] Xem CartBar (top cart summary)
- [ ] Kiểm tra danh sách món
- [ ] Kiểm tra billing summary:
  - [ ] Subtotal
  - [ ] Service charge 5%
  - [ ] VAT 8%
  - [ ] Total
- [ ] Sửa số lượng món trong giỏ
- [ ] Xóa món khỏi giỏ
- [ ] Xác nhận đặt món → createOrder() (RPC)
- [ ] Hệ thống: validate UUID cho cart items
- [ ] Hệ thống: activate session
- [ ] Hệ thống: insert order + items
- [ ] Hệ thống: tính subtotal/VAT
- [ ] Hệ thống: emit notification
- [ ] Hệ thống: auto-create CRM survey
- [ ] Menu template deep-clone & remap ID từ DB (UUID thật)

### 4.7 Lịch sử đơn hàng

- [ ] Vào `/customer/orders`
- [ ] Xem danh sách đơn đã đặt (getOrderHistory)
- [ ] Xem bill settlement tổng hợp
- [ ] Theo dõi trạng thái từng món (OrderTrackingModal)
- [ ] Trạng thái: pending → preparing → served
- [ ] Cập nhật đơn (updateOrder) nếu cần
- [ ] Kiểm tra trạng thái đơn (getOrderStatus)

### 4.8 Yêu cầu dịch vụ (ServiceRequestGrid)

- [ ] Vào `/customer/service`
- [ ] Chọn 1 trong các loại yêu cầu:
  - [ ] Gọi nhân viên (call_staff)
  - [ ] Thêm than (add_charcoal)
  - [ ] Nước (water)
  - [ ] Khăn (tissue)
  - [ ] Chén bát (bowl)
  - [ ] Gia vị (sauce)
  - [ ] Đá (ice)
  - [ ] Thay vỉ nướng (grill_change)
  - [ ] Thay than (charcoal_change)
  - [ ] Tính tiền (checkout)
  - [ ] Yêu cầu bill (request_bill)
  - [ ] Gọi phục vụ (call_waiter)
- [ ] Xem log yêu cầu dịch vụ
- [ ] Cập nhật trạng thái yêu cầu (updateServiceRequest)

### 4.9 Yêu cầu thanh toán

- [ ] Yêu cầu thanh toán (requestPayment)
- [ ] Yêu cầu hóa đơn đỏ (requestInvoice)
- [ ] Nhập mã số thuế công ty (InvoiceRequestModal)
- [ ] Nhập tên công ty
- [ ] Xác nhận yêu cầu

### 4.10 CRM info tại bàn

- [ ] Xem CrmInfoModal
- [ ] Nhập/thông tin khách (updateCrmInfo)
- [ ] Xem CustomerDetailDrawer
- [ ] Xem TierBadge (hạng khách hàng)

### 4.11 Đánh giá & Phản hồi

- [ ] Vào `/customer/feedback`
- [ ] Chọn số sao 1-5 (StarRating) (BR-35)
- [ ] Chọn ít nhất 1 tiêu chí đánh giá (FeedbackCriteria) (BR-36)
- [ ] Nhập góp ý (tùy chọn)
- [ ] Gửi đánh giá (submitFeedback)

### 4.12 Kết thúc phiên

- [ ] Màn hình Thank you + QR code
- [ ] Countdown 30s
- [ ] Tự động quay về màn hình Passcode (phiên mới)
- [ ] Hệ thống clear session (localStorage)
- [ ] clearSession(): xóa localStorage + reset store
- [ ] Persist orders vào localStorage để khôi phục (restoreSessionFromLocalStorage)

### 4.13 Realtime subscriptions

- [ ] subscribeToTableUpdates — cập nhật trạng thái bàn
- [ ] subscribeToServiceRequests — cập nhật yêu cầu dịch vụ
- [ ] subscribeToOrderUpdates — cập nhật trạng thái đơn

---

## 5. HALL (QUẢN LÝ SẢNH)

> **Modules truy cập:** hall  
> **Route chính:** `/hall/*`  
> **Layout:** HallDashboard  
> **Store:** hallStore.ts

### 5.1 Dashboard sảnh

- [ ] Vào HallDashboard
- [ ] Xem tổng quan sảnh: bàn hoạt động, đặt bàn, hàng đợi dịch vụ
- [ ] 4 views: Calendar, Detail, Floor Plan, Order Menu

### 5.2 Sơ đồ bàn

- [ ] Vào FloorPlanView
- [ ] Xem sơ đồ bàn trực quan
- [ ] Lọc bàn khả dụng theo time slot
- [ ] Phân tích time slot từ giờ (morning/lunch/afternoon/evening)

### 5.3 Bàn đang phục vụ

- [ ] Vào ActiveTablesView
- [ ] Xem danh sách bàn đang phục vụ
- [ ] Theo dõi trạng thái đơn hàng

### 5.4 Gọi món

- [ ] Vào OrderMenuView
- [ ] Gọi món cho bàn (tương tự POS)
- [ ] Tích hợp useMenu composable

### 5.5 Thanh toán

- [ ] Vào CheckoutView
- [ ] Thanh toán cho bàn
- [ ] Áp dụng voucher
- [ ] Tính service charge 5% + VAT 8%

### 5.6 Hàng đợi dịch vụ

- [ ] Vào ServiceQueueView
- [ ] Xem yêu cầu dịch vụ từ khách
- [ ] Phân phối yêu cầu cho nhân viên
- [ ] Đánh dấu đã xử lý

### 5.7 Lịch đặt bàn

- [ ] Vào ReservationCalendar
- [ ] Xem lịch đặt bàn theo ngày/tuần
- [ ] Lọc theo time slot: morning / lunch / afternoon / evening
- [ ] Tích hợp useReservation composable

### 5.8 Quản lý đặt bàn

- [ ] Vào ReservationManagerView
- [ ] Tạo/sửa/hủy đặt bàn
- [ ] Gán bàn cho đặt bàn
- [ ] Xem chi tiết đặt bàn (ReservationDetail)
- [ ] Lọc bàn khả dụng (useTable composable)

---

## 6. MANAGER (QUẢN LÝ CHI NHÁNH)

> **Modules truy cập:** manager, reception, staff, hall  
> **Route chính:** `/manager/*`  
> **Layout:** ManagerLayout

### 6.1 Dashboard quản lý

- [ ] Vào `/manager/dashboard`
- [ ] Xem tổng quan chi nhánh: doanh thu, số bàn, khách
- [ ] Kiểm tra KPI/KGI tiến độ

### 6.2 Doanh thu

- [ ] Vào `/manager/revenue`
- [ ] Xem báo cáo doanh thu theo ngày/tuần/tháng
- [ ] Phân tích theo phương thức: cash / card / transfer / other
- [ ] Phân tích theo loại doanh thu: food / beverage / service / other
- [ ] So sánh doanh thu theo thời gian

### 6.3 Giá vốn hàng bán (COGS)

- [ ] Vào `/manager/cogs`
- [ ] Xem COGS theo món / danh mục
- [ ] Phân tích biên lợi nhuận
- [ ] So sánh COGS vs doanh thu

### 6.4 Marketing

- [ ] Vào `/manager/marketing`
- [ ] Xem hiệu quả chiến dịch marketing tại chi nhánh
- [ ] Phân tích ROI chiến dịch

### 6.5 CRM

- [ ] Vào `/manager/crm`
- [ ] Xem dữ liệu khách hàng tại chi nhánh
- [ ] Phân tích khách quen (repeater), khách mới (new), VIP
- [ ] Xem avg_spent_per_customer
- [ ] Xem tổng số khách (total_customers)
- [ ] Xem khách mới tháng này (new_customers_this_month)

### 6.6 Tồn kho

- [ ] Vào `/manager/inventory`
- [ ] Xem tồn kho chi nhánh
- [ ] Kiểm tra ngưỡng cảnh báo (minKitchenStock)
- [ ] Phân tích ABC
- [ ] Kiểm tra expiry tracking

### 6.7 Hội viên

- [ ] Vào `/manager/membership`
- [ ] Quản lý thẻ hội viên
- [ ] Xem hạng khách hàng (tier badge)
- [ ] Xem TierBadge component

### 6.8 Voucher

- [ ] Vào `/manager/voucher`
- [ ] Tạo/sửa/xóa voucher
- [ ] Phân loại: percent / fixed / buy_x_get_y
- [ ] Thiết lập hạn sử dụng (valid_until)
- [ ] Theo dõi lượt sử dụng

### 6.9 Quản lý ca (kế thừa Reception)

- [ ] Nhập PIN Manager khi đóng ca lệch > 100.000đ
- [ ] Nhập PIN Manager khi hủy order (1234)
- [ ] Nhập PIN Manager khi giảm giá (cần lý do)
- [ ] ManagerAuthModal hiển thị đúng
- [ ] VARIANCE_PIN_THRESHOLD = 100.000 VND

---

## 7. ADMIN (QUẢN TRỊ HỆ THỐNG)

> **Modules truy cập:** admin, manager, reception, staff, hall, kitchen, purchasing, accounting, crm, marketing, bod, tablet  
> **Route chính:** `/admin/*`  
> **Layout:** AdminLayout  
> **Store:** menuManagementStore.ts

### 7.1 Dashboard quản trị

- [ ] Vào `/admin/dashboard`
- [ ] Xem tổng quan hệ thống
- [ ] Kiểm tra trạng thái các chi nhánh

### 7.2 Chọn chi nhánh

- [ ] Vào `/select-branch`
- [ ] Chọn chi nhánh làm việc
- [ ] Hệ thống lưu branch_id vào session

### 7.3 Quản lý tài khoản

- [ ] Vào `/admin/accounts`
- [ ] Tạo tài khoản người dùng (email, role, branch_id)
- [ ] Sửa thông tin tài khoản
- [ ] Vô hiệu hóa tài khoản
- [ ] Phân quyền theo role (16+ roles)
- [ ] Gán chi nhánh cho user
- [ ] Xem danh sách tất cả user

### 7.4 Quản lý thực đơn (menuManagementStore)

- [ ] Vào `/admin/menus`
- [ ] **Categories:**
  - [ ] Thêm category mới
  - [ ] Sửa category (name i18n: vi/en/ja)
  - [ ] Soft-delete category (is_active = false)
  - [ ] Không xóa category còn subcategory con
  - [ ] Kéo thả sắp xếp (reorder)
- [ ] **Subcategories:**
  - [ ] Thêm subcategory mới
  - [ ] Sửa subcategory (name i18n)
  - [ ] Soft-delete subcategory
  - [ ] Không xóa subcategory còn item con
  - [ ] Kéo thả sắp xếp
- [ ] **Menu items:**
  - [ ] Thêm món mới (name i18n, price, category, subcategory)
  - [ ] Sửa món
  - [ ] Soft-delete món (is_active = false)
  - [ ] Copy món (tự thêm "(Bản sao)" + "-COPY")
  - [ ] Bulk lock/unlock (sold-out toggle)
  - [ ] QuickLockBar + QuickLockToggle
- [ ] **Realtime:**
  - [ ] Broadcast event `menu:item-status-changed`
  - [ ] POS nhận realtime update

### 7.5 Quản lý sơ đồ bàn

- [ ] Vào `/admin/floors`
- [ ] Thêm/sửa/xóa bàn (table_code, area, capacity)
- [ ] Cấu hình khu vực (10 khu: A, B, C, R, T, Capichi, Shopee, BE, Grab, Catalog)
- [ ] Thiết lập sức chứa (capacity)
- [ ] Xem sơ đồ trực quan

### 7.6 Quản lý KPI / KGI

- [ ] Vào `/admin/kpi`
- [ ] Thiết lập chỉ tiêu KPI cho chi nhánh
- [ ] Thiết lập KGI (Key Goal Indicator)
- [ ] Theo dõi tiến độ
- [ ] Phân tích hiệu suất

### 7.7 Nhật ký kiểm toán (Audit)

- [ ] Vào `/admin/audit`
- [ ] Xem audit log: user_id, action, entity, timestamp
- [ ] Lọc theo user
- [ ] Lọc theo action
- [ ] Lọc theo entity
- [ ] Lọc theo ngày
- [ ] Xuất báo cáo audit

### 7.8 Quản lý voucher

- [ ] Vào `/admin/voucher`
- [ ] Tạo voucher: percent / fixed / buy_x_get_y
- [ ] Thiết lập giá trị voucher
- [ ] Thiết lập hạn sử dụng (valid_until)
- [ ] Theo dõi lượt sử dụng
- [ ] Vô hiệu hóa voucher

---

## 8. PURCHASING (THU MUA)

> **Modules truy cập:** purchasing  
> **Route chính:** `/purchasing/*`  
> **Layout:** PurchasingLayout  
> **API:** procurement.api.ts

### 8.1 Dashboard thu mua

- [ ] Vào PurchasingDashboardView
- [ ] Xem tổng quan: yêu cầu chờ, đơn hàng, tồn kho
- [ ] Kiểm tra cảnh báo tồn kho thấp

### 8.2 Quản lý nhà cung cấp

- [ ] Vào SupplierManagerView
- [ ] Thêm nhà cung cấp (name, contact, products)
- [ ] Sửa thông tin NCC
- [ ] Xóa NCC
- [ ] Xem danh sách NCC (getSuppliers)
- [ ] Xem sản phẩm từng NCC cung cấp

### 8.3 Quản lý nguyên liệu

- [ ] Vào IngredientsManagerView
- [ ] Thêm nguyên liệu (name, unit, unit_cost, supplier)
- [ ] Sửa nguyên liệu (saveIngredient)
- [ ] Xóa nguyên liệu
- [ ] Xem thống kê nguyên liệu (getIngredientStats)
- [ ] Kiểm tra đơn vị tính (unit)

### 8.4 Tạo yêu cầu mua hàng (Requisition)

- [ ] Vào RequisitionsView / RequisitionListView
- [ ] Tạo yêu cầu mới (createRequisition)
- [ ] Chọn nguyên liệu cần mua
- [ ] Nhập số lượng yêu cầu
- [ ] Đính kèm báo giá từ nhiều NCC
- [ ] Ghi chú cho yêu cầu
- [ ] Trạng thái: pending

### 8.5 Duyệt yêu cầu

- [ ] Duyệt yêu cầu (approveRequisition)
- [ ] Hoặc đề xuất thay thế (substitute_proposed)
- [ ] Hoặc từ chối (rejected)
- [ ] Kiểm tra báo giá từ nhiều NCC trước khi duyệt

### 8.6 Tạo đơn đặt hàng (PO)

- [ ] Vào POCreateView
- [ ] Chọn NCC
- [ ] Chọn nguyên liệu + số lượng + giá
- [ ] Tạo đơn đặt hàng
- [ ] Kiểm tra tổng giá trị đơn

### 8.7 Quản lý đơn đặt hàng

- [ ] Vào POListView / PurchaseOrdersView
- [ ] Xem danh sách PO
- [ ] Theo dõi trạng thái đơn
- [ ] Lọc theo NCC / ngày / trạng thái
- [ ] Xem chi tiết PO

### 8.8 Nhập kho (Goods Receipt)

- [ ] Vào GoodsReceiptView / DailyReceiptView
- [ ] Nhập kho khi nhận hàng
- [ ] Kiểm tra số lượng thực nhận vs đặt hàng
- [ ] Ghi nhận giao dịch: type = IN (recordInventoryTx)
- [ ] Ghi unit_cost, supplier, notes
- [ ] Tự động cập nhật getCurrentStock()

### 8.9 Quản lý phiếu nhập

- [ ] Vào ReceiptsManagerView
- [ ] Xem danh sách phiếu nhập (getGoodsReceipts)
- [ ] Kiểm tra chi tiết phiếu
- [ ] Lọc theo NCC / ngày

### 8.10 Kiểm kê kho

- [ ] Vào InventoryAuditView
- [ ] Thực hiện kiểm kê (stocktake)
- [ ] So sánh tồn thực tế vs hệ thống
- [ ] Điều chỉnh tồn kho (adjustStockLogic)
- [ ] Ghi giao dịch: type = ADJUST
- [ ] Ghi chú lý do điều chỉnh

### 8.11 Giao dịch kho

- [ ] Xem getInventoryTransactions()
- [ ] Lọc theo type: IN / OUT / ADJUST / PURCHASE
- [ ] Kiểm tra ABC analysis
- [ ] Kiểm tra expiry tracking
- [ ] Mua hàng trực tiếp (purchaseItem)
- [ ] Hủy bỏ hàng (discardItem)

---

## 9. ACCOUNTING (KẾ TOÁN)

> **Modules truy cập:** accounting  
> **Route chính:** `/accounting/*`  
> **Layout:** AccountingLayout  
> **Composables:** useAccounting, useAccountingModule, useTaxInvoice, useReport

### 9.1 Dashboard kế toán

- [ ] Vào AccountingDashboardView
- [ ] Xem tổng quan tài chính
- [ ] Kiểm tra công nợ quá hạn
- [ ] Xem alert cảnh báo

### 9.2 Tài chính tổng quan

- [ ] Vào FinancialDashboardView
- [ ] Xem tổng quan tài chính toàn hệ thống
- [ ] Xem Chart.js / D3.js biểu đồ

### 9.3 Dòng tiền (Cash Flow)

- [ ] Vào CashFlowView
- [ ] Theo dõi dòng tiền vào/ra
- [ ] Phân tích theo ngày/tuần/tháng
- [ ] Xem Chart.js biểu đồ dòng tiền

### 9.4 Phải trả nhà cung cấp (AP)

- [ ] Vào APPayablesView
- [ ] Xem công nợ nhà cung cấp
- [ ] Theo dõi hạn thanh toán
- [ ] Tạo lệnh thanh toán
- [ ] Đánh dấu đã thanh toán

### 9.5 Báo cáo Lợi nhuận & Lỗ (P&L)

- [ ] Vào PLReportView
- [ ] Xem báo cáo P&L
- [ ] Phân tích: doanh thu - chi phí - lợi nhuận
- [ ] Phân tích theo danh mục
- [ ] Xuất báo cáo

### 9.6 Quản lý hóa đơn

- [ ] Vào InvoiceManagerView
- [ ] Tạo hóa đơn đỏ (tax_code, company, amount)
- [ ] Sửa hóa đơn
- [ ] Trạng thái: draft → issued → paid | cancelled
- [ ] Tìm kiếm hóa đơn theo mã số thuế
- [ ] Xuất hóa đơn

### 9.7 Thuế

- [ ] Vào TaxExportView — xuất báo cáo thuế
- [ ] Vào TaxRecordsView — xem hồ sơ thuế
- [ ] Kiểm tra VAT 8% đã thu
- [ ] Tính toán thuế phải nộp
- [ ] Xuất file thuế (CSV/PDF)

### 9.8 Định giá tồn kho

- [ ] Vào InventoryValuationView
- [ ] Định giá tồn kho (FIFO / weighted average)
- [ ] Kiểm tra COGS
- [ ] Phân tích giá trị tồn kho theo danh mục

---

## 10. CRM (CHĂM SÓC KHÁCH HÀNG)

> **Modules truy cập:** crm  
> **Route chính:** `/crm/*`  
> **Layout:** CRMLayout  
> **Store:** crmStore.ts

### 10.1 Dashboard CRM

- [ ] Vào CRMDashboardView
- [ ] Xem thống kê tổng quan:
  - [ ] Tổng số khách hàng (total_customers)
  - [ ] Khách mới tháng này (new_customers_this_month)
  - [ ] Khách quen (repeater_customers)
  - [ ] Khách VIP (vip_customers)
  - [ ] Chi tiêu trung bình (avg_spent_per_customer)
- [ ] Xem biểu đồ Chart.js

### 10.2 Bàn đang phục vụ (cần khảo sát)

- [ ] Vào CRMServingTablesView
- [ ] Xem danh sách bàn đang phục vụ (CrmServingTable)
- [ ] Kiểm tra trạng thái survey từng bàn
- [ ] Phân công staff khảo sát (not_started → assigned)
- [ ] Theo dõi tiến độ khảo sát
- [ ] Xem CrmSurveyInput: name, phone, zalo, marketing consent, tags, visit reason, feedback

### 10.3 Danh sách khách hàng

- [ ] Vào CustomerListView
- [ ] Tìm kiếm khách (name, phone, zalo)
- [ ] Lọc theo tag (VIP, repeater, new)
- [ ] Xem chi tiết khách hàng (CustomerDetailView)
- [ ] Xem lịch sử đặt bàn
- [ ] Xem lịch sử đơn hàng
- [ ] Xem feedback khách hàng

### 10.4 Phản hồi khách hàng

- [ ] Vào CustomerFeedbackView
- [ ] Xem feedback từ khách (rating + tiêu chí + góp ý)
- [ ] Phân tích xu hướng đánh giá
- [ ] Lọc theo số sao (1-5)
- [ ] Lọc theo tiêu chí

### 10.5 Quản lý phản hồi

- [ ] Vào FeedbackManagerView
- [ ] Phân loại feedback (positive / negative / neutral)
- [ ] Phản hồi khách (nếu cần)
- [ ] Đánh dấu đã xử lý
- [ ] Thống kê tỷ lệ hài lòng

### 10.6 Quản lý voucher

- [ ] Vào VoucherManagerView
- [ ] Tạo/sửa/xóa voucher
- [ ] Phân loại: percent / fixed / buy_x_get_y
- [ ] Theo dõi lượt sử dụng + hạn sử dụng
- [ ] Phân tích hiệu quả voucher

### 10.7 Trạng thái CRM Survey

- [ ] not_started → assigned → in_progress → completed
- [ ] Hoặc: skipped / customer_refused / expired / late_submitted
- [ ] Theo dõi tỷ lệ hoàn thành survey

---

## 11. MARKETING (MARKETING)

> **Modules truy cập:** marketing  
> **Route chính:** `/marketing/*`  
> **Layout:** MarketingLayout  
> **Composables:** useMarketing, useCampaign

### 11.1 Dashboard marketing

- [ ] Vào MarketingDashboardView
- [ ] Xem tổng quan chiến dịch
- [ ] Kiểm tra ngân sách marketing
- [ ] Xem ROI tổng

### 11.2 Danh sách chiến dịch

- [ ] Vào CampaignListView
- [ ] Xem danh sách chiến dịch
- [ ] Lọc theo trạng thái: active / ended / scheduled
- [ ] Lọc theo ngày
- [ ] Xem chi tiết chiến dịch

### 11.3 Tạo / quản lý chiến dịch

- [ ] Vào CampaignsView
- [ ] Tạo chiến dịch mới
- [ ] Cấu hình thời gian (start/end)
- [ ] Cấu hình đối tượng mục tiêu
- [ ] Cấu hình ngân sách
- [ ] Kích hoạt chiến dịch
- [ ] Tạm dừng chiến dịch
- [ ] Kết thúc chiến dịch

### 11.4 Phân tích chiến dịch

- [ ] Vào CampaignAnalyticsView
- [ ] Xem hiệu quả chiến dịch (ROI, conversion, reach)
- [ ] So sánh nhiều chiến dịch
- [ ] Xem biểu đồ Chart.js
- [ ] Phân tích theo chi nhánh

---

## 12. BOD (BAN GIÁM ĐỐC)

> **Modules truy cập:** bod  
> **Route chính:** `/bod/*`  
> **Layout:** BODLayout  
> **Composable:** useBOD

### 12.1 Dashboard BOD

- [ ] Vào BODDashboardView
- [ ] Xem tổng quan toàn hệ thống
- [ ] Kiểm tra số lượng chi nhánh hoạt động

### 12.2 Dashboard tổng công ty (HQ)

- [ ] Vào HQDashboardView
- [ ] Xem dữ liệu tổng hợp tất cả chi nhánh
- [ ] So sánh hiệu suất giữa các chi nhánh
- [ ] Xem biểu đồ Chart.js / D3.js

### 12.3 Hiệu suất chi nhánh

- [ ] Vào BranchPerformanceView
- [ ] Xem ranking chi nhánh theo doanh thu
- [ ] Phân tích KPI/KGI từng chi nhánh
- [ ] So sánh theo thời gian (tháng/quý/năm)
- [ ] Xem chi tiết từng chi nhánh

### 12.4 Phê duyệt

- [ ] Vào BODApprovalsView
- [ ] Xem danh sách yêu cầu phê duyệt (bod_approvals)
- [ ] Duyệt yêu cầu
- [ ] Từ chối yêu cầu (kèm lý do)
- [ ] Kiểm tra: người yêu cầu, loại yêu cầu, trạng thái
- [ ] Theo dõi lịch sử phê duyệt

### 12.5 Nhật ký kiểm toán

- [ ] Vào AuditLogsView
- [ ] Xem audit log toàn hệ thống
- [ ] Lọc theo user / action / entity / ngày
- [ ] Xuất báo cáo audit
- [ ] Kiểm tra audit_events: user_id, action, entity, timestamp

### 12.6 Cấu hình hệ thống

- [ ] Vào SystemConfigView
- [ ] Xem/sửa cấu hình hệ thống
- [ ] Cấu hình branch_settings (JSONB: key, value)
- [ ] Cấu hình system_events
- [ ] Kiểm tra notifications settings

---

## 13. SUPERADMIN (SIÊU QUẢN TRỊ)

> **Modules truy cập:** Tất cả modules  
> **Route chính:** `/superadmin/*`  
> **Layout:** SuperadminLayout

### 13.1 Dashboard siêu quản trị

- [ ] Vào SuperadminDashboardView
- [ ] Xem tổng quan toàn hệ thống (đa tenant)
- [ ] Kiểm tra số lượng thương hiệu (brands)
- [ ] Kiểm tra số lượng chi nhánh
- [ ] Xem tổng quan tài chính toàn hệ thống

### 13.2 Quản lý thương hiệu

- [ ] Vào SuperadminBrandsView
- [ ] Thêm thương hiệu mới (brand)
- [ ] Sửa thông tin thương hiệu
- [ ] Xóa thương hiệu
- [ ] Quản lý chi nhánh theo thương hiệu
- [ ] Gán chi nhánh vào thương hiệu

### 13.3 Tích hợp bên thứ 3

- [ ] Vào SuperadminIntegrationsView
- [ ] Cấu hình tích hợp thanh toán (payment gateway)
- [ ] Cấu hình tích hợp giao hàng (delivery)
- [ ] Kiểm tra trạng thái kết nối
- [ ] Cấu hình delivery partners: Shopee, BE, Grab
- [ ] Kiểm tra API keys / webhook URLs
- [ ] Test kết nối tích hợp

---

## 14. BUSINESS RULES CHUNG (ÁP DỤNG ĐA VAI TRÒ)

### 14.1 Tính tiền (Reception + Customer)

- [ ] Subtotal = tổng giá món
- [ ] Service charge = Subtotal × 5%
- [ ] VAT = (Subtotal + Service charge) × 8%
- [ ] Total = (Subtotal + Service charge) × 1.08
- [ ] Engine: computeTotals() trong packageRules.ts
- [ ] Đồng nhất customer & cashier (shared pricing engine)

### 14.2 Package eligibility (Reception + Customer)

- [ ] Món trong gói buffet → giá = 0đ
- [ ] Surcharge items (khac-phi) → luôn tính phí
- [ ] Lunch items → giảm 50%
- [ ] Kiểm tra eligibility theo tier:
  - [ ] 1390 — tất cả categories
  - [ ] 1150 — loại trừ wagyu
  - [ ] 680 — loại trừ wagyu + premium beef
  - [ ] 490/380 — chỉ safe subcategories
  - [ ] kids — chỉ KIDS / egg / fries / dessert
  - [ ] lau — hotpot + drinks + veggies
  - [ ] 550jp — bento / sashimi / tempura / miso
  - [ ] drink — drink-only

### 14.3 PIN Manager (Reception + Manager)

- [ ] Hủy order → PIN 1234 + gõ "HỦY"
- [ ] Giảm giá → lý do + PIN Manager
- [ ] Đóng ca lệch > 100.000đ → PIN Manager
- [ ] VARIANCE_PIN_THRESHOLD = 100.000 VND
- [ ] ManagerAuthModal hiển thị đúng
- [ ] CloseShiftModal PIN keypad 4 số

### 14.4 Trạng thái đơn hàng (Customer + Reception + Kitchen)

- [ ] draft → confirmed → cooking → served → completed
- [ ] Có thể cancelled
- [ ] Trạng thái món: Pending → Preparing → Served
- [ ] Trạng thái món: Cancelled

### 14.5 Trạng thái đặt bàn (Reception + Hall)

- [ ] PENDING → CONFIRMED → SEATED → COMPLETED
- [ ] Có thể CANCELLED
- [ ] Time slots: morning (<11h) / lunch (11-14h) / afternoon (14-17h) / evening (>17h)
- [ ] Meal types: LUNCH / DINNER

### 14.6 Trạng thái bàn (Reception + Hall + Staff)

- [ ] available (trống) — màu xanh #27ae60
- [ ] reserved (đã đặt) — màu vàng #f1c40f
- [ ] arrived (đã đến)
- [ ] serving (đang phục vụ) — màu đỏ #c0392b
- [ ] occupied
- [ ] 10 khu vực: A, B, C, R, T, Capichi, Shopee, BE, Grab, Catalog
- [ ] Tổng 57 bàn

### 14.7 CRM Survey (Staff + CRM)

- [ ] not_started → assigned → in_progress → completed
- [ ] skipped — bỏ qua khảo sát
- [ ] customer_refused — khách từ chối
- [ ] expired — quá hạn
- [ ] late_submitted — nộp muộn
- [ ] Thu thập: name, phone, zalo, tags, visit reason, feedback, marketing consent

### 14.8 Requisition (Kitchen + Purchasing)

- [ ] pending → substitute_proposed → approved → delivered
- [ ] Hoặc: rejected
- [ ] COGS tự cập nhật khi delivered
- [ ] Audit log cho mọi thay đổi trạng thái

### 14.9 Ca làm việc (Reception + Manager)

- [ ] open → closed
- [ ] expected_cash = opening_cash + cash_revenue
- [ ] variance = closing_cash - expected_cash
- [ ] |variance| > 100K → cần PIN Manager
- [ ] Revenue breakdown: cash, card, transfer, other
- [ ] Ghi chú bắt buộc khi lệch
- [ ] Xuất CSV báo cáo ca
- [ ] localStorage persist shift state

### 14.10 Giao dịch kho (Purchasing + Kitchen)

- [ ] IN — nhập kho
- [ ] OUT — xuất kho
- [ ] ADJUST — điều chỉnh
- [ ] PURCHASE — mua hàng
- [ ] Mỗi giao dịch ghi: unit_cost, supplier, notes
- [ ] ABC analysis
- [ ] Expiry tracking
- [ ] Stocktake (kiểm kê)

### 14.11 Menu management (Admin + Reception)

- [ ] Soft-delete (is_active = false) — không xóa cứng
- [ ] Copy item → tự thêm "(Bản sao)" + "-COPY"
- [ ] Không xóa category/subcategory còn item con
- [ ] Bulk lock/unlock (sold-out toggle)
- [ ] Broadcast menu:item-status-changed cho POS realtime
- [ ] Kéo thả sắp xếp categories/subcategories
- [ ] Name i18n: vi/en/ja cho mọi category/subcategory/item

### 14.12 Tablet (Customer)

- [ ] Timeout 60s chọn bàn (BR-08) → giải phóng → quay về chọn khu
- [ ] Yêu cầu session active để truy cập menu/cart/orders (BR-09)
- [ ] Group món theo trạm bếp: hot, meat, salad (BR-23)
- [ ] Format kitchen ticket text (BR-27)
- [ ] Tăng printedCount kitchen ticket (BR-28)
- [ ] Rating 1-5 sao (BR-35)
- [ ] Chọn ít nhất 1 tiêu chí đánh giá (BR-36)
- [ ] Logic xử lý feedback trong store (BR-37/38)
- [ ] Passcode staff 6 ký tự (mock: 123456/654321)
- [ ] Persist orders vào localStorage
- [ ] restoreSessionFromLocalStorage() trong CustomerLayout onMounted
- [ ] clearSession() — xóa localStorage + reset store
- [ ] Menu template deep-clone & remap ID (UUID thật)
- [ ] Validation UUID cho cart items

### 14.13 Đa ngôn ngữ (Tất cả roles)

- [ ] VI / EN / JA
- [ ] setApplicationLanguage() đồng bộ Pinia + vue-i18n + html lang
- [ ] localStorage persistence
- [ ] 3 lớp phân giải: flat key → nested key → fallback dict
- [ ] ~600+ translation keys
- [ ] Modules i18n: Hall, Checkout, Service, Reservation, Purchasing, Accounting, Campaigns, BOD, Feedback, Inventory, Requisition, Shift, Tablet, Branch, Integration, CRM, Reception, Dashboard, Common, Admin, Kitchen, Customer

### 14.14 Dual-mode (Technical)

- [ ] Supabase configured → supabase.rpc() + Realtime
- [ ] Supabase not configured → Mock data + localStorage
- [ ] Fallback tự động, không crash
- [ ] RPC-Only: truy cập DB qua supabase.rpc()
- [ ] MockModeNotice banner hiển thị khi mock mode

### 14.15 Realtime subscriptions (Customer + Reception)

- [ ] subscribeToTableUpdates — cập nhật trạng thái bàn
- [ ] subscribeToServiceRequests — cập nhật yêu cầu dịch vụ
- [ ] subscribeToOrderUpdates — cập nhật trạng thái đơn
- [ ] Order từ Customer tablet → flow vào Reception (cần bổ sung)
- [ ] Supabase Realtime channel subscription

### 14.16 Kiến trúc & Composables (Technical)

- [ ] 11 Pinia stores: restaurantStore, receptionStore, customerStore, hallStore, kitchen, crmStore, menuManagementStore, shiftStore, i18n, useLanguageStore
- [ ] 47 composables: useAuth, useOrder, useTable, useTableOperations, useMenu, useShift, useCheckout, useReceptionSync, useCheckIn, useCRM, useCustomer, useCustomerSession, useMembership, useVoucher, useFeedback, useServiceRequest, useKDS, useKitchenShift, useInventory, useRequisition, usePurchaseOrder, usePurchasing, useAccounting, useAccountingModule, useReport, useTaxInvoice, useBranch, useBusinessRules, useKPI, useBOD, useCampaign, useMarketing, useRealtime, useNotification, useTablet, useUnsavedGuard, useUserSticker, useAudit, useOCR, useIntegrations
- [ ] 14 layouts theo role
- [ ] Route guard dựa trên ROUTE_ROLES map
- [ ] getHomeRouteForRole() / getFallbackRouteForRole()
- [ ] Per-Server Printing Architecture (Supabase Realtime Pub/Sub + Local Print Queue)

### 14.17 Domain Model (Technical)

- [ ] Branch → Users, Tables, MenuItems, Reservations, Orders, etc.
- [ ] Customer → Reservations, Surveys
- [ ] Order → OrderItems → MenuItem
- [ ] Order → Bills → Payments
- [ ] Invoice → AppliedVoucher
- [ ] Shift → Payments
- [ ] Package → PackageItem → MenuItem
- [ ] MenuCategory → MenuSubCategory → MenuItem
- [ ] 22+ bảng database chính
- [ ] 12+ enums (UserRole, TableStatus, ReservationStatus, OrderStatus, etc.)
- [ ] 7 JSONB interfaces (I18nString, CustomerPreferences, PackageItemConfig, etc.)

### 14.18 Design System (Technical)

- [ ] Reception theme: Dark POS (#1e1e1e, #ff8f00, #27ae60, #c0392b, #f1c40f)
- [ ] Customer theme: Dark Wood (#3D2817, #1a110a, #E8772E, #C62828, #4CAF50)
- [ ] Global theme: #0d0d0f background, Amber-500 primary, Nunito font
- [ ] Kawaii UI: #FF7B89 primary, #FF5A6E dark, #2C3E50 navy, #FFF5F7 cream
- [ ] 7 button variants: primary, secondary, warning, success, danger, neutral, urgent
- [ ] Design tokens: colors.ts, requisitionTokens.ts
- [ ] POS-specific CSS: orderingScreen.css (.sidebar-pos, .header-pos, .main-content-pos)
- [ ] Font: Nunito (primary), Cormorant Garamond (brand/serif)
- [ ] Tailwind: orange palette 50-900, cream, navy, dark mode class-based

### 14.19 Khoảng cách cần khắc phục

- [ ] Realtime sync: Order từ Customer tablet chưa tự xuất hiện ở Reception
- [ ] DB integration: Hầu hết in-memory (mock), chỉ hall_cancel_order_or_item có RPC
- [ ] Transfer/merge: Chỉ sửa restaurantStore trong RAM, không ghi DB
- [ ] Cần bổ sung Supabase Realtime subscription hoặc polling mechanism
