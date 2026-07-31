# KẾ HOẠCH KIỂM THỬ UI POS/F&B THEO MASTER CHECKLIST

**Phiên bản kế hoạch:** 1.0  
**Ngày lập:** 2026-07-31  
**Đối tượng kiểm thử:** giao diện base hiện tại của dự án `POS-prototype`  
**Workbook điều khiển:** `POS_FNB_Master_Checklist_TichHop_NghiepVu_VaiTro_2026-07-31.xlsx`  
**Đầu ra khi thực thi:** workbook được cập nhật tiến độ và một báo cáo Markdown duy nhất  
**Tên báo cáo dự kiến:** `BAO_CAO_KIEM_THU_UI_POS_FNB_2026-07-31.md`

---

## 1. Mục tiêu

Kế hoạch này hướng dẫn kiểm tra có hệ thống xem giao diện base hiện tại:

1. có cung cấp đủ màn hình, control và luồng thao tác cho các nghiệp vụ trong workbook hay không;
2. có xử lý đúng trạng thái, dữ liệu hiển thị, validation, nhánh lỗi và quyền theo vai trò hay không;
3. có thiếu UI, thiếu bước nghiệp vụ, chỉ có placeholder/mock hoặc có hành vi sai hay không;
4. có giữ trạng thái đúng sau refresh và đồng bộ đúng giữa các màn hình/tab hay không;
5. có đủ bằng chứng để kết luận từng dòng trong `02_Checklist_Master` hay chưa.

Đây là kế hoạch **UI-first**. Chỉ kiểm tra những gì có thể khởi phát, quan sát hoặc chứng minh từ giao diện hiện tại. Kết quả UI sẽ được dùng làm đầu vào để suy ra yêu cầu dữ liệu/database ở giai đoạn sau, nhưng kế hoạch này không nghiệm thu schema, migration, stored procedure hay dữ liệu trong database thật.

---

## 2. Phạm vi và ranh giới kết luận

### 2.1. Trong phạm vi

- Toàn bộ 1.231 dòng trong `02_Checklist_Master`.
- 34 flow trong `04_TongHop_Flow`.
- 13 vai trò, nhóm `BUSINESS RULES CHUNG` và 5 chiều quyền trong `05_MaTran_Quyen`.
- 48 route giao diện đang có trong source hiện tại.
- Các viewport desktop POS, tablet phục vụ và mobile khách hàng.
- Functional, Negative/Boundary, Security, Integration và Reliability theo cột `Test Type`.
- Loading, empty, error, disabled, validation, confirmation, refresh, multi-tab, double-click và direct URL.
- Dữ liệu nhìn thấy trên UI; trạng thái lưu ở trình duyệt; request/network nếu giao diện thật sự phát sinh request.
- Preview/in/outbox chỉ được ghi nhận đúng bản chất là preview/simulation.

### 2.2. Ngoài phạm vi của đợt UI-first

- Thiết kế hoặc nghiệm thu database.
- Khẳng định dữ liệu đã được lưu ở backend chỉ dựa trên toast hoặc state trong trình duyệt.
- Kiểm thử tải, bảo mật hạ tầng, penetration test hoặc tính sẵn sàng production.
- Xác nhận VietQR, Viettel S-Invoice, máy in/Print Bridge là tích hợp thật khi không có môi trường/thiết bị/credential thật.
- Tự sửa source, tự bổ sung nghiệp vụ hoặc tự thay đổi expected result trong lúc test.

### 2.3. Nguyên tắc không tự bịa

Mỗi bước test và mỗi kết luận phải truy vết được về ít nhất một nguồn:

1. workbook master, ưu tiên `02_Checklist_Master`, `04_TongHop_Flow`, `05_MaTran_Quyen`, `06_Issue_Log`, `07_TruyVet_Nguon`;
2. tài liệu local `flow_nghiepvu_can_check/CHECKLIST_FLOW_NGHIEP_VU_CHI_TIET.md`;
3. route/component/domain behavior thực tế trong `src/`;
4. kiểm tra trực tiếp bằng trình duyệt;
5. test có sẵn trong `e2e/` chỉ là bằng chứng hỗ trợ, không tự động thay cho UAT trực tiếp.

Nếu nguồn mâu thuẫn, dùng `Source Conflict`; không tự chọn nguồn “đúng”. Nếu nguồn được workbook tham chiếu nhưng không truy cập được, ghi `BLOCKED` kèm nguồn thiếu, không tự lấp nội dung.

---

## 3. Kết quả đọc workbook

### 3.1. Cấu trúc

| Sheet | Vai trò trong đợt test |
|---|---|
| `00_HuongDan` | Quy tắc PASS/FAIL/BLOCKED/N/A và gate nghiệm thu |
| `01_Dashboard` | Tổng hợp tiến độ và gate |
| `02_Checklist_Master` | Nguồn thực thi chính, 1.231 dòng |
| `03_TongHop_VaiTro` | Coverage và verdict theo vai trò |
| `04_TongHop_Flow` | Coverage và verdict theo 34 flow |
| `05_MaTran_Quyen` | Menu, direct URL, server/API, branch scope, audit |
| `06_Issue_Log` | 20 functional gap và 8 source conflict đã seed |
| `07_TruyVet_Nguon` | Nguồn, mapping và kiểm tra toàn vẹn |
| `99_DanhMuc` | Danh mục validation |

### 3.2. Quy mô

| Chỉ tiêu | Số lượng |
|---|---:|
| Tổng Master rows | 1.231 |
| Role-detail được bảo toàn | 777 |
| Core-flow steps được bảo toàn | 434 |
| Control checks | 35 |
| Mapping gộp độ tin cậy cao | 15 |
| P0 | 597 dòng / 1.486 phút |
| P1 | 565 dòng / 1.142 phút |
| P2 | 69 dòng / 138 phút |
| Tổng ước lượng gốc trong workbook | 2.766 phút, tương đương 46,1 giờ thao tác thuần |

Ước lượng 46,1 giờ chưa gồm dựng môi trường, chụp bằng chứng, ghi issue, điều tra source conflict, retest và viết báo cáo. Không dùng con số này làm cam kết lịch nếu chưa biết số tester và môi trường tích hợp.

### 3.3. Test type

| Test type | Số dòng |
|---|---:|
| Functional | 996 |
| Negative/Boundary | 130 |
| Integration | 46 |
| Security | 45 |
| Reliability | 14 |

---

## 4. Baseline giao diện hiện tại trước khi test

Đây là kết quả khảo sát source để lập kế hoạch, **không phải kết quả thực thi test case**.

### 4.1. Kiến trúc quan sát được

- Ứng dụng là Next.js, React, Zustand.
- Domain state được persist vào `localStorage`; vai trò/chi nhánh/ca của phiên demo nằm trong `sessionStorage`.
- Đồng bộ tab dùng BroadcastChannel/persisted state.
- Layout POS lọc menu theo 7 vai trò demo: `Quản lý`, `Lễ tân`, `Phục vụ`, `Thu ngân`, `Bếp`, `Kế toán`, `Kho`.
- Workbook yêu cầu 13 vai trò nghiệp vụ cộng `BUSINESS RULES CHUNG`.
- Source hiện có lọc menu theo role nhưng chưa thấy route guard trong layout. Phải kiểm chứng bằng direct URL và thao tác trực tiếp trước khi kết luận.
- Tích hợp QR/e-Invoice/print có rủi ro là placeholder, preview hoặc outbox mô phỏng; workbook đã seed `SRC-06`.

### 4.2. Chênh lệch route cần xử lý bằng mapping

Workbook role-detail dùng các namespace như `/reception/*`, `/staff/*`, `/customer/*`, `/manager/*`, `/purchasing/*`, `/superadmin/*`. UI hiện tại chủ yếu dùng route theo chức năng như `/hall`, `/cashier`, `/inventory`, `/procurement`, `/accounting`, `/m/:tableCode`.

Quy tắc:

1. không đánh PASS cho route không tồn tại chỉ vì có màn hình tương đương ở route khác;
2. không đánh FAIL toàn bộ nghiệp vụ chỉ vì route legacy khác tên;
3. với mỗi dòng, kiểm tra riêng:
   - yêu cầu route/layout có được đáp ứng không;
   - hành vi nghiệp vụ có màn hình thay thế hợp lệ không;
4. ghi route thật vào `Kết quả thực tế`;
5. liên kết `SRC-03` nếu khác kiến trúc route;
6. chỉ PO/BA mới được chấp nhận mapping route như một quyết định sản phẩm.

### 4.3. Route inventory hiện tại

**POS/Back office:** `/hall`, `/hall/list`, `/hall/:sessionId/order`, `/reservations`, `/reservations/calendar`, `/cashier/:sessionId`, `/cashier/bills`, `/cashier/shift/close`, `/kitchen`, `/kitchen/expo`, `/kitchen/availability`, `/inventory`, `/inventory/ingredients`, `/inventory/ingredients/:id`, `/inventory/receipts`, `/inventory/waste`, `/procurement/requisitions`, `/procurement/suppliers`, `/procurement/orders`, `/procurement/payables`, `/accounting`, `/accounting/reconciliation`, `/accounting/cashbook`, `/accounting/vouchers`, `/accounting/receivables`, `/accounting/pl`, `/admin/staff`, `/admin/roles`, `/admin/menu`, `/admin/menu/:id/recipe`, `/admin/menu/packages`, `/admin/floors`, `/admin/vouchers`, `/admin/audit`, `/manager`, `/manager/revenue`, `/manager/cogs`, `/manager/menu-performance`, `/manager/reservations`, `/crm/customers`, `/crm/feedback`, `/bod`.

**Tablet/mobile/demo:** `/tablet/tables`, `/tablet/order/:sessionId`, `/tablet/service-queue`, `/m/:tableCode`, `/m/:tableCode/menu`, `/m/:tableCode/orders`, `/m/:tableCode/bill`, `/m/:tableCode/feedback`, `/demo`, `/`.

---

## 5. Môi trường và dữ liệu kiểm thử

### 5.1. Môi trường tối thiểu

- Chromium desktop ở viewport tối thiểu 1366×768.
- Tablet landscape, ưu tiên 1024×768.
- Mobile, ưu tiên 390×844.
- Hai tab cùng browser context để kiểm tra realtime/BroadcastChannel.
- Một browser context riêng để kiểm tra isolation của session.
- DevTools Console và Network mở khi kiểm tra integration/error.
- Không dùng browser extension làm thay đổi request hoặc storage.

### 5.2. Dữ liệu chuẩn từ tài liệu local

- Nạp lại `/demo` trước mỗi flow độc lập.
- Kịch bản chính: `Nạp kịch bản đầu ca sáng`.
- Kịch bản booking/drag-drop: `Nạp kịch bản giờ cao điểm`.
- Chi nhánh có mã bàn `CN1-*`.
- Bàn gợi ý: `CN1-A02`, `CN1-A03`, `CN1-A04`; booking mẫu `CN1-B01`.
- Gói: `Standard 50 món`, `Selected Beef 88 món`.
- Khách thành viên: `Nguyễn Văn An`.
- Voucher: `NGUUCAT10`.
- Món trong gói: `Ba chỉ bò`/`BO01`.
- Món ngoài gói: `Bò Wagyu A5`/`BO05`.
- Quản lý duyệt: `Đỗ Quốc Hưng`.
- PIN đúng/sai: `1234` / `0000`.

Tester phải xác nhận dữ liệu trên UI sau khi reset. Nếu snapshot đã thay đổi và dữ liệu không còn đúng, ghi dữ liệu thật đã dùng; không ép expected result theo tên mẫu cũ.

### 5.3. Isolation

- Một flow thay đổi dữ liệu phải có snapshot riêng.
- Không chạy song song hai flow write trên cùng browser profile.
- Chụp trạng thái trước và sau.
- Sau flow, refresh và mở lại màn hình liên quan.
- Khi kiểm tra double-click, chỉ thực hiện trên dữ liệu có thể reset.

---

## 6. Thứ tự thực thi

### Giai đoạn 0 — Chuẩn bị và đóng băng baseline

1. Sao lưu workbook trước khi ghi kết quả.
2. Ghi commit/build identifier nếu dự án có; nếu không có Git metadata thì ghi timestamp và hash các file source chính.
3. Chạy `npm run typecheck`, `npm run lint`, `npm test`, `npm run build`.
4. Khởi động ứng dụng và xác nhận `/demo`, `/hall`, `/tablet/tables`, `/m/CN1-A01`.
5. Lập thư mục evidence theo quy tắc ở mục 10.
6. Không chuyển bất kỳ dòng nào khỏi `NOT RUN` trong bước chuẩn bị.

### Giai đoạn 1 — Route/screen smoke

1. Mở đủ 48 route hiện có với dữ liệu hợp lệ cho dynamic route.
2. Ghi HTTP/navigation result, heading, loading/empty/error state, console error.
3. Đổi 7 vai trò demo và kiểm tra menu.
4. Thử direct URL cho màn hình bị ẩn.
5. Tạo bảng mapping “route yêu cầu → route thật → mức tương đương → quyết định BA/PO”.
6. Cập nhật `SRC-01`, `SRC-02`, `SRC-03`, `SRC-08` bằng bằng chứng; chưa đóng conflict nếu chưa có quyết định.

### Giai đoạn 2 — P0 theo chuỗi giao dịch end-to-end

Thứ tự để giảm reset và vẫn giữ khả năng truy vết:

1. `SHIFT-01` mở ca.
2. `RSV-02`, `RSV-03` booking/cọc/xếp bàn.
3. `HALL-01`, `HALL-03` mở/ghép bàn.
4. `ORD-01` gọi món.
5. `KIT-01` bếp/expo/in.
6. `VOID-01` hủy món.
7. `PAY-01`, `PAY-02`, `PAY-03` tính tiền/thanh toán.
8. `BILL-01`, `INV-01`, `DEBT-01`.
9. `WH-02`, `WH-03` tác động kho/công nợ.
10. `ACC-01`, `SHIFT-02`.
11. `ADM-04` BOM.
12. Security P0 và `BUSINESS RULES CHUNG` P0.

### Giai đoạn 3 — P1

Chạy các flow `SYS-01`, `ADM-01`, `ADM-02`, `ADM-03`, `ADM-05`, `ADM-06`, `RSV-01`, `HALL-02`, `HALL-04`, `GST-01`, `WH-01`, `PR-01`, `PO-01`, `RPT-01`, `SYNC-01`; sau đó hoàn tất các role-detail P1.

### Giai đoạn 4 — P2, usability và báo cáo phụ

Chạy 69 dòng P2 sau khi P0/P1 đã có verdict. P2 không được dùng để trì hoãn issue P0/P1.

### Giai đoạn 5 — Permission matrix

Với từng role, chạy đủ 5 chiều: menu, direct URL, server/API action qua UI, branch scope, audit. Chỉ ẩn menu không đủ PASS.

### Giai đoạn 6 — Retest và gate

1. Chỉ retest issue có trạng thái `READY FOR RETEST` hoặc `FIXED`.
2. Reset đúng scenario và chạy lại cùng Master ID.
3. Cập nhật `Retest Status` và evidence mới.
4. Không đóng issue chỉ dựa trên thông báo “đã sửa”.
5. Đánh gate ở `01_Dashboard` sau khi công thức đã recalculation.

---

## 7. Playbook chi tiết cho 34 flow

Mỗi flow phải lọc `02_Checklist_Master` theo `TC ID`, chạy đúng thứ tự `Step`, và cập nhật từng dòng; không chỉ cập nhật verdict ở `04_TongHop_Flow`.

### 7.1. Hệ thống và quản trị

| TC | P | Dòng / phút | Route chính hiện tại | Trình tự kiểm tra bắt buộc |
|---|---:|---:|---|---|
| `SYS-01` | P1 | 15 / 31 | `/hall`, layout POS, `/demo` | Reset; chọn từng chi nhánh; đối chiếu bàn/dữ liệu; đổi đủ 7 role; ghi menu hiện/ẩn; mở URL ẩn trực tiếp; thử thao tác write; đổi chi nhánh và kiểm tra scope; refresh; kiểm tra audit. Liên kết `SRC-01/02/03/08`. |
| `ADM-01` | P1 | 16 / 36 | `/admin/staff`, `/admin/roles`, `/admin/audit` | Tạo nhân viên với họ tên/SĐT/role; kiểm tra rỗng và SĐT trùng; đặt PIN đúng/sai; khóa/mở khóa; refresh; dùng role khác mở URL; thử hành vi cần PIN; kiểm tra audit. Không suy ra account login thật nếu chỉ có record nhân viên. |
| `ADM-02` | P1 | 17 / 34 | `/admin/menu`, `/kitchen/availability`, order screens | Tạo món đủ mã/tên/danh mục/loại/giá/station; thử rỗng, giá âm, mã trùng; khóa bán tại một chi nhánh; xác nhận món biến mất/disabled ở POS, tablet, mobile; mở bán lại; refresh và đổi branch. |
| `ADM-03` | P1 | 8 / 16 | `/admin/menu/packages`, open-table/order | Chọn gói; thay đổi danh sách món; lưu; refresh; mở bàn đúng gói; xác nhận món trong gói/ngoài gói và giá; thử gói không có món, món bị khóa và lựa chọn không hợp lệ. |
| `ADM-04` | P0 | 13 / 39 | `/admin/menu/:id/recipe`, inventory/order/checkout | Chọn món; thêm dòng NVL và định lượng dương; thử 0/âm/trùng NVL; lưu; refresh; gọi món và thanh toán; so sánh tồn trước/sau trên UI; kiểm tra thiếu tồn và branch isolation. Không nghiệm thu DB, chỉ ghi trạng thái quan sát từ UI. |
| `ADM-05` | P1 | 9 / 18 | `/admin/floors`, `/hall`, `/tablet/tables` | Thêm/chỉnh bàn, khu vực, sức chứa và vị trí; kiểm tra mã trùng/sức chứa 0 hoặc âm; refresh; xác nhận bàn xuất hiện nhất quán; kiểm tra bàn đang phục vụ/đã đặt không bị sửa trái rule; kiểm tra thiếu delete/maintenance nếu checklist yêu cầu. |
| `ADM-06` | P1 | 12 / 24 | `/admin/vouchers`, `/cashier/:sessionId` | Tạo voucher theo loại/giá trị/min bill/limit/expiry; thử code trùng, hết hạn, chưa hiệu lực, dưới min bill, vượt limit; áp voucher hợp lệ; xác nhận công thức và không áp lặp; refresh; kiểm tra scope chi nhánh nếu có. |

### 7.2. Ca, đặt bàn và vận hành sảnh

| TC | P | Dòng / phút | Route chính hiện tại | Trình tự kiểm tra bắt buộc |
|---|---:|---:|---|---|
| `SHIFT-01` | P0 | 6 / 18 | header POS, dialog mở ca | Ở trạng thái chưa mở ca, thử mở bàn để xác nhận bị chặn; mở ca với `2.000.000`; thử âm/rỗng; thử mở ca lần hai; refresh; đổi tab và xác nhận trạng thái ca. |
| `RSV-01` | P1 | 16 / 32 | `/reservations`, `/reservations/calendar` | Tạo booking với tên, SĐT, số khách, giờ, kênh, ghi chú; kiểm tra rỗng, SĐT sai, số khách 0/âm, giờ quá khứ, trùng giờ; refresh; kiểm tra list/calendar; tìm/sort/filter nếu checklist yêu cầu. |
| `RSV-02` | P0 | 8 / 24 | `/hall` drag/drop | Nạp giờ cao điểm; kéo booking vào bàn đang có khách, bàn thiếu sức chứa, bàn đủ chỗ; xác nhận waitlist/status; thử xung đột thời gian; thử yêu cầu nhiều bàn; refresh. Liên kết `GAP-12` nếu UI chỉ chọn một bàn. |
| `RSV-03` | P0 | 19 / 57 | `/reservations` và hall/check-in | Ghi cọc; kiểm tra phương thức, amount 0/âm/vượt rule; hủy/no-show/check-in; xác nhận cọc được hoàn/forfeit/khấu trừ đúng trên UI; refresh. Liên kết `GAP-10/11` nếu thiếu khấu trừ/hoàn hoặc phương thức bị cố định. |
| `HALL-01` | P0 | 15 / 45 | `/hall`, `/tablet/tables` | Chọn bàn trống; thử mở khi chưa có ca; mở à-la-carte, buffet và mixed; nhập người lớn/trẻ em; kiểm tra gói bắt buộc; thử sức chứa; xác nhận session, status bàn và điều hướng order; refresh. |
| `HALL-02` | P1 | 7 / 14 | floor/table action UI | Mở bàn nguồn và chuẩn bị bàn đích; chuyển toàn bàn; kiểm tra bàn đích bận/khác branch; kiểm tra session, món và số tiền sau chuyển; tìm UI chuyển một phần item/qty. Liên kết `GAP-02` nếu domain có nhưng UI không có. |
| `HALL-03` | P0 | 7 / 21 | merge-table dialog trên hall | Mở hai bàn; chọn bàn đích; xem preview; ghép; kiểm tra tableCodes/session/order/bill; thử ghép chính nó, bàn khác branch, bàn trạng thái không hợp lệ; refresh. Liên kết `GAP-01` nếu yêu cầu tách phiên không có UI. |
| `HALL-04` | P1 | 10 / 21 | order/cashier/hall | Đổi service mode qua các tổ hợp hợp lệ; kiểm tra gói buffet bắt buộc; đóng bàn trước/sau thanh toán; trạng thái chuyển sang dọn; hoàn tất dọn và mở lại; kiểm tra không mất session/order trái rule. |

### 7.3. Gọi món, khách hàng và bếp

| TC | P | Dòng / phút | Route chính hiện tại | Trình tự kiểm tra bắt buộc |
|---|---:|---:|---|---|
| `ORD-01` | P0 | 18 / 56 | `/hall/:sessionId/order`, `/tablet/order/:sessionId` | Chọn category; thêm món trong/ngoài gói; đổi số lượng; ghi chú nếu có; kiểm tra sold-out; gửi bếp; chống double-click; xác nhận station/ticket/status; refresh và kiểm tra KDS. |
| `GST-01` | P1 | 19 / 42 | `/m/:tableCode/*`, `/tablet/service-queue` | Với bàn có session, xem gói/menu; gọi món; xác nhận trạng thái chờ nhân viên; xem lịch sử; thử hủy món chờ và món đang chế biến; gửi từng loại yêu cầu phục vụ; xử lý queue; gửi feedback; thử tableCode sai/không có session. |
| `KIT-01` | P0 | 10 / 32 | `/kitchen`, `/kitchen/expo`, `/kitchen/availability` | Gửi món theo station; xác nhận card/timing; chuyển trạng thái theo thứ tự; khóa món; kiểm tra POS/mobile; chạy Expo; kiểm tra reprint/print label theo checklist. Chỉ PASS tích hợp in khi có print job/thiết bị thật; preview/outbox ghi simulated và liên kết `SRC-06`. |
| `VOID-01` | P0 | 16 / 55 | void-item dialog, audit | Chuẩn bị item ở từng trạng thái; hủy item được phép; bắt buộc lý do/manager/PIN; thử PIN sai; thử hủy món đang chế biến/đã phục vụ; xác nhận totals, stock effect, void ticket và audit; tìm UI hủy toàn order. Liên kết `GAP-03` nếu thiếu. |

### 7.4. Tính tiền, bill, công nợ và hóa đơn

| TC | P | Dòng / phút | Route chính hiện tại | Trình tự kiểm tra bắt buộc |
|---|---:|---:|---|---|
| `PAY-01` | P0 | 24 / 72 | `/cashier/:sessionId` | Tạo bill buffet + món lẻ; kiểm tra adult/child pricing, subtotal, service charge, VAT, voucher, loyalty, rounding và grand total; thử áp khuyến mãi lặp; refresh; đối chiếu display ở bill/receipt. Liên kết `SRC-07` nếu tỷ lệ 5%/8% chưa có nguồn cấu hình rõ. |
| `PAY-02` | P0 | 8 / 24 | payment dialog | Chọn tiền mặt; nhập received nhỏ hơn/bằng/lớn hơn total; kiểm tra chặn thiếu tiền và tiền thừa; double-click xác nhận; refresh; kiểm tra bill/payment/shift UI. Liên kết `GAP-07` nếu received không được dùng. |
| `PAY-03` | P0 | 13 / 55 | payment dialog VietQR/thẻ | Chọn thẻ/VietQR; kiểm tra amount/reference/QR/expiry/cancel/retry/success/failure/callback; thử refresh trong lúc pending; kiểm tra split payment nhiều dòng và tổng còn lại. Liên kết `GAP-06/08`, `SRC-05/06`; placeholder không được PASS integration thật. |
| `DEBT-01` | P0 | 12 / 36 | checkout, `/accounting/receivables` | Chọn khách; ghi nợ; kiểm tra bắt buộc customer/limit nếu có; xác nhận debt list; thu một phần/toàn phần/vượt nợ; refresh; kiểm tra lịch sử và audit. Không coi “Trả hết” là đủ nếu checklist yêu cầu partial. |
| `BILL-01` | P0 | 17 / 55 | `/cashier/bills`, receipt preview | Xem/in receipt; gọi lại bill với lý do; sửa và thanh toán lại; thử gọi bill không hợp lệ; tìm UI hủy bill với lý do/PIN/preview; xác nhận reversal và audit. Liên kết `GAP-04/05` nếu thiếu. |
| `INV-01` | P0 | 18 / 59 | issue-invoice dialog | Nhập MST/tên/địa chỉ; thử rỗng/sai; phát hành; kiểm tra trạng thái async, số hóa đơn, PDF/XML, retry/cancel/lookup; kiểm tra accounting view. Nếu chỉ tạo record/outbox/toast thì ghi simulated, liên kết `GAP-09` và `SRC-06`. |

### 7.5. Kho, mua hàng và kế toán

| TC | P | Dòng / phút | Route chính hiện tại | Trình tự kiểm tra bắt buộc |
|---|---:|---:|---|---|
| `WH-01` | P1 | 9 / 18 | `/inventory/ingredients`, ledger | Tạo NVL; kiểm tra mã/tên/unit/min stock/trùng; xem tồn và thẻ kho; filter/search; refresh; đổi branch; xác nhận tổng phát sinh khớp tồn hiện tại trên UI. |
| `WH-02` | P0 | 11 / 33 | `/inventory/receipts`, `/procurement/payables` | Chọn NCC/NVL/qty/price; thử 0/âm/rỗng; nhận hàng; kiểm tra tồn, weighted average cost và công nợ; thử nhận theo PO và nhận một phần. Liên kết `GAP-14` nếu chỉ nhập nhanh không theo PO/partial. |
| `WH-03` | P0 | 9 / 27 | `/inventory/waste`, inventory overview | Xuất hủy với qty/lý do; thử thiếu lý do, qty 0/âm/vượt tồn; kiểm tra balance, ledger, low-stock alert, COGS/audit nếu yêu cầu; refresh và branch isolation. |
| `PR-01` | P1 | 8 / 16 | `/procurement/requisitions` | Tạo PR; kiểm tra qty/ghi chú; duyệt/từ chối bằng role phù hợp; bắt buộc lý do từ chối; kiểm tra status và audit; thử duyệt hai lần. Liên kết `GAP-13` nếu thiếu dialog lý do. |
| `PO-01` | P1 | 17 / 34 | suppliers/orders/payables | Tạo NCC; tạo PO từ PR hoặc độc lập; kiểm tra qty/price/total; nhận hàng; kiểm tra payable; trả một phần/toàn phần/vượt nợ và chứng từ; refresh. Liên kết `GAP-15` nếu UI chỉ trả hết. |
| `ACC-01` | P0 | 11 / 33 | `/accounting/vouchers`, cashbook/audit | Lập phiếu chi; kiểm tra threshold duyệt; thử thiếu approver; hủy kèm lý do; kiểm tra cashbook/P&L/audit; tìm UI phiếu thu khác và khóa kỳ/back-date. Liên kết `GAP-16/19` khi thiếu. |

### 7.6. Đóng ca, báo cáo và đồng bộ

| TC | P | Dòng / phút | Route chính hiện tại | Trình tự kiểm tra bắt buộc |
|---|---:|---:|---|---|
| `SHIFT-02` | P0 | 18 / 57 | `/cashier/shift/close`, reconciliation | Chuẩn bị doanh thu/chi; nhập counted cash khớp/lệch; kiểm tra threshold, approver, PIN và lý do; đóng ca; xem Z-report; in/preview; refresh; kiểm tra accounting reconciliation; thử đóng lại. |
| `RPT-01` | P1 | 11 / 22 | `/manager/*`, `/accounting/*`, `/bod` | Tạo giao dịch có số kiểm soát; mở từng report; đối chiếu period/branch/filter/empty state; kiểm tra revenue/COGS/P&L/reservation/menu performance/branch comparison; không PASS nếu số liệu chỉ tĩnh không phản ánh giao dịch vừa tạo. |
| `SYNC-01` | P1 | 7 / 16 | `/demo`, hai tab nghiệp vụ | Mở hai tab; thay đổi ở A và quan sát B; refresh; reset scenario; xác nhận tab cũ không ghi đè; double-click/retry; đóng/mở tab; kiểm tra storage corruption nếu có thể. Liên kết `GAP-20` nếu tạo bản ghi trùng. |

---

## 8. Kế hoạch theo vai trò

Số dòng dưới đây là toàn bộ Master rows gắn Primary Role, gồm role-detail và core/control bổ sung.

| Nhóm | Tổng | P0 | Mapping UI hiện tại cần dùng | Trọng tâm |
|---|---:|---:|---|---|
| `RECEPTION` | 261 | 200 | role `Lễ tân`/`Thu ngân`; hall, reservations, cashier, shift | ca, booking, bàn, order, void, payment, bill |
| `STAFF` | 75 | 34 | role `Phục vụ`; hall, tablet order/queue | mở bàn, gọi món, hỗ trợ khách, CRM tại bàn |
| `KITCHEN` | 60 | 48 | role `Bếp`; kitchen/expo/availability | KDS, station, sold-out, handover, requisition |
| `CUSTOMER` | 121 | 43 | mobile `/m/:tableCode/*` và tablet | QR/table session, menu, order, service request, feedback |
| `HALL` | 48 | 26 | hall dưới role quản lý/lễ tân/phục vụ | sơ đồ, booking assignment, queue, table lifecycle |
| `MANAGER` | 50 | 18 | role `Quản lý`; `/manager/*` và các màn kế thừa | dashboard, revenue, COGS, reservation, oversight |
| `ADMIN` | 156 | 36 | role `Quản lý`; `/admin/*` | staff, role, menu, BOM, floors, voucher, audit |
| `PURCHASING` | 109 | 50 | role `Kho`/`Quản lý`; inventory/procurement | supplier, ingredient, PR, PO, receipt, AP |
| `ACCOUNTING` | 77 | 62 | role `Kế toán`; `/accounting/*` và invoice | cashbook, debt, AP, P&L, tax, e-Invoice |
| `CRM` | 39 | 6 | `/crm/customers`, `/crm/feedback`; chưa có role CRM riêng | customer list, feedback, survey status, voucher |
| `MARKETING` | 22 | 0 | chưa có namespace marketing trong route inventory | campaign list/create/analytics/dashboard; kiểm tra Missing UI theo từng item |
| `BOD` | 28 | 4 | `/bod` | branch performance, approval, system/audit visibility |
| `SUPERADMIN` | 18 | 1 | chưa có role/namespace superadmin trong UI inventory | brand, third-party integration, cross-module access |
| `BUSINESS RULES CHUNG` | 167 | 69 | nhiều route/viewport | pricing, statuses, PIN, branch, realtime, i18n, controls |

### Cách chạy một role batch

1. Lọc `Primary Role = <ROLE>`.
2. Chạy P0 rồi P1 rồi P2.
3. Với mỗi nhóm nghiệp vụ, chạy route/screen row trước, sau đó positive, negative/boundary, integration/reliability.
4. Với route legacy, ghi cả route yêu cầu và route thật.
5. Kết thúc role bằng 5 test permission.
6. Kiểm tra `03_TongHop_VaiTro`; không sửa công thức summary bằng tay.
7. Nếu role không tồn tại trong selector, không đánh FAIL hàng loạt chỉ từ quan sát này: kiểm tra từng UI capability, ghi source conflict và tổng hợp thành một gap có danh sách Master ID liên quan.

---

## 9. Business Rules và UI controls

### 9.1. Rule nghiệp vụ

- Giá buffet theo adult/child và điều kiện miễn phí.
- Package eligibility và món trong/ngoài gói.
- Service charge, VAT, discount, voucher, loyalty, rounding.
- Trạng thái bàn, booking, order, item, bill, shift, PR/PO/receipt.
- Manager PIN, approver, reason bắt buộc.
- Không cho số âm/0/vượt tồn/vượt nợ/vượt sức chứa.
- Branch isolation.
- Refresh persistence và multi-tab consistency.
- Không tạo trùng do double-click/retry.
- Audit cho thao tác nhạy cảm.

### 9.2. Control UI

Với mọi loại control trong 35 dòng `CONTROL`:

- Text input: trim, rỗng, Unicode tiếng Việt, max length, ký tự đặc biệt.
- Numeric/money/quantity: rỗng, 0, âm, thập phân, cực lớn, paste text.
- Combobox: placeholder, search, keyboard, option disabled, clear.
- Checkbox/radio: default, mutually exclusive, persisted state.
- Dialog/sheet/button: focus, Escape, cancel, confirm, double-click, disabled/loading.
- Table/list: loading, empty, error, long text, sort/filter, overflow.
- Responsive: không double padding, không che nút, không tràn viewport.
- Accessibility cơ bản: label, keyboard focus, tên accessible của button.

---

## 10. Bằng chứng

### 10.1. Cấu trúc thư mục

```text
evidence/
  2026-07-31/
    <TC-ID>/
      <MASTER-ID>_<STATUS>_<step>_<slug>.png
      <MASTER-ID>_console.txt
      <MASTER-ID>_network.txt
      <MASTER-ID>_video.webm
```

### 10.2. Bằng chứng tối thiểu

- P0/P1 PASS: ảnh trước/sau hoặc video, URL, dữ liệu dùng và thời điểm.
- FAIL: ảnh lỗi, bước tái hiện, expected/actual, console/network nếu liên quan.
- BLOCKED: ảnh hoặc log chứng minh điều kiện chặn.
- Integration: request/response/callback/job/thiết bị thật. Toast/preview không đủ.
- Permission: ảnh menu và kết quả direct URL/action.
- Refresh/sync: ảnh/video trước và sau refresh hoặc ở hai tab.

Không đưa token, credential, thông tin cá nhân thật hoặc dữ liệu nhạy cảm vào evidence.

---

## 11. Quy tắc verdict

| Status | Dùng khi |
|---|---|
| `NOT RUN` | Chưa thao tác trực tiếp |
| `PASS` | Tất cả expected result đúng, state đúng sau refresh/retry, có evidence theo yêu cầu |
| `FAIL` | Có UI nhưng sai, thiếu một phần nghiệp vụ xác nhận, tính sai, sai trạng thái, sai quyền hoặc mất/trùng dữ liệu |
| `BLOCKED` | Không thể test do môi trường, quyền, dữ liệu, dependency hoặc source conflict chưa quyết định |
| `N/A` | Chỉ dùng khi PO/BA xác nhận ngoài phạm vi và có lý do/evidence |

Phân loại issue:

- `Functional Gap`: thiếu UI/rule/tích hợp hoặc chỉ có placeholder/mock.
- `Bug`: chức năng có nhưng chạy sai.
- `Data Issue`: dữ liệu seed/hiển thị làm sai hoặc cản test.
- `Security`: vượt quyền/direct URL/action không được chặn.
- `Source Conflict`: tài liệu/route/framework/expected mâu thuẫn.
- `Risk`: chưa thành defect xác nhận nhưng có rủi ro nghiệm thu.

Mọi `FAIL`/`BLOCKED` phải có `Issue ID`.

---

## 12. Cập nhật workbook trong khi test

### 12.1. Cột được phép cập nhật trong `02_Checklist_Master`

| Cột | Nội dung |
|---|---|
| W — `Kết quả thực tế` | Quan sát khách quan, route thật, dữ liệu và thông báo |
| X — `Status` | NOT RUN/PASS/FAIL/BLOCKED/N/A |
| Y — `Evidence` | Đường dẫn tương đối tới evidence |
| Z — `Issue ID` | Bắt buộc với FAIL/BLOCKED |
| AA — `Owner` | Người test hoặc owner xử lý nếu đã được phân công |
| AB — `Ngày test` | Ngày thực thi |
| AC — `Ghi chú tester` | Mapping route, giới hạn UI-only, retest note |

Không sửa A–V và AD–AF trong khi thực thi, trừ khi có change request được phê duyệt.

### 12.2. Permission matrix

Sau khi hoàn tất role, cập nhật `05_MaTran_Quyen`:

- T: Menu Visibility
- U: Direct URL
- V: API/Server Auth
- W: Branch Scope
- X: Audit Log

Cột Y là công thức Overall, không nhập tay.

Trong phạm vi UI-first, cột `API/Server Auth` chỉ PASS khi thao tác UI tạo request/server action thật và server từ chối đúng. Nếu app hoàn toàn local và không có server auth để quan sát, ghi `FAIL` hoặc `BLOCKED` theo expected/source; không giả định backend tương lai.

### 12.3. Issue log

`06_Issue_Log` hiện đã dùng hết hàng 5–32 cho 28 issue seed. Khi thêm issue:

1. thêm từ hàng 33;
2. mở rộng `IssueLogTable`;
3. copy style và data validation xuống hàng mới;
4. mở rộng các công thức ở Dashboard/Role/Flow đang tham chiếu `$5:$32`;
5. không ghi đè GAP/SRC seed;
6. một issue có thể liên kết nhiều Master ID, nhưng mỗi Master row FAIL/BLOCKED phải có Issue ID.

### 12.4. An toàn file

1. Trước phiên test tạo backup có timestamp.
2. Chỉ một người/process ghi workbook tại một thời điểm.
3. Lưu theo batch nhỏ, tối đa sau 20–30 Master rows hoặc sau mỗi flow.
4. Recalculate bằng LibreOffice sau khi cập nhật.
5. Quét `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?`.
6. Xác nhận table, validation, conditional formatting và công thức vẫn còn.
7. Không đổi tên sheet, Master ID, TC ID hoặc Source Ref.

---

## 13. Tự động hóa hỗ trợ

### 13.1. Test sẵn có

- `e2e/acceptance-full-scenario.spec.ts`
- `e2e/accounting-flow.spec.ts`
- `e2e/core-operations.spec.ts`
- `e2e/guest-flow.spec.ts`
- `e2e/hall-drag-drop.spec.ts`
- `e2e/inventory-bom.spec.ts`
- `e2e/landing-smoke.spec.ts`
- `e2e/multi-tab-sync.spec.ts`

### 13.2. Cách dùng

1. Chạy suite làm smoke/regression trước UAT.
2. Map mỗi automated test tới TC ID/Master ID trong báo cáo.
3. Lưu trace/video/screenshot khi fail.
4. Không chuyển Master row sang PASS chỉ vì automated suite xanh.
5. Ưu tiên bổ sung automation cho P0 lặp lại: permission direct URL, payment boundary, double-click/idempotency, role/branch matrix.

---

## 14. Tiêu chí hoàn thành và gate

Đợt test chỉ được coi là hoàn tất khi:

- 1.231 Master rows không còn `NOT RUN`, trừ phạm vi được phê duyệt rõ ràng;
- 34 flow có verdict và không còn P0 `NOT RUN`;
- mọi role đã kiểm đủ 5 chiều quyền;
- mọi P0/P1 FAIL/BLOCKED có issue và evidence;
- source conflict đã được resolve/accept bằng bằng chứng;
- integration thật chỉ PASS khi có bằng chứng thật;
- workbook không có formula error;
- báo cáo Markdown đã được phát hành.

Không nghiệm thu nếu còn một trong các điều kiện:

- P0 FAIL/BLOCKED chưa được chấp nhận;
- P0/P1 issue còn mở;
- core flow chưa hoàn tất;
- quyền chỉ kiểm menu mà chưa kiểm direct URL/action/branch/audit;
- VietQR/e-Invoice/Print/Realtime được PASS chỉ từ placeholder, preview hoặc toast;
- source conflict chưa có quyết định.

---

## 15. Cấu trúc báo cáo Markdown cuối cùng

File `BAO_CAO_KIEM_THU_UI_POS_FNB_2026-07-31.md` phải gồm:

1. Executive Summary.
2. Build/môi trường/phạm vi.
3. Nguồn và giới hạn UI-first.
4. Coverage tổng: status, priority, test type.
5. Coverage và verdict 34 flow.
6. Coverage và verdict 14 nhóm vai trò.
7. Permission matrix.
8. Functional gaps xác nhận.
9. Bugs/Data/Security issues.
10. Source conflicts và quyết định.
11. Integration thật so với simulated.
12. Danh sách chức năng UI còn thiếu, sắp theo P0/P1/P2.
13. Đề xuất backlog UI; yêu cầu dữ liệu/database suy ra để dành cho giai đoạn sau và phải được ghi là “đề xuất”, không phải hiện trạng.
14. Risks/limitations.
15. Retest summary.
16. Acceptance gate: ĐẠT/KHÔNG ĐẠT/BLOCKED/CHƯA KẾT LUẬN.
17. Phụ lục evidence và mapping automated test.

Mỗi gap/recommendation phải có: Master ID/TC ID, role, route, expected, actual, evidence, mức ưu tiên, ảnh hưởng và tiêu chí đóng.

---

## 16. Checklist bàn giao của người thực thi

- [ ] Có backup workbook trước khi ghi.
- [ ] Có build/environment identifier.
- [ ] Đã chạy preflight và 48-route smoke.
- [ ] Đã xử lý route mapping và source conflicts.
- [ ] Đã chạy đủ 597 P0.
- [ ] Đã chạy đủ 565 P1.
- [ ] Đã chạy đủ 69 P2 hoặc có phê duyệt N/A.
- [ ] Đã chạy 34 core flow.
- [ ] Đã chạy 14 role/business-rule groups.
- [ ] Đã cập nhật permission matrix.
- [ ] Mọi FAIL/BLOCKED có issue.
- [ ] Evidence không chứa thông tin nhạy cảm.
- [ ] Workbook recalculated, không có formula error.
- [ ] Dashboard và summary khớp Master.
- [ ] Báo cáo `.md` hoàn chỉnh.
- [ ] Gate nghiệm thu được kết luận có căn cứ.

---

## 17. Thứ tự ưu tiên cho phiên thực thi đầu tiên

Phiên đầu tiên nên giới hạn ở baseline và một vertical slice P0 để xác nhận quy trình ghi bằng chứng:

1. Backup workbook và reset `dau-ca-sang`.
2. Smoke `/demo`, `/hall`, `/cashier`, `/kitchen`, `/accounting`.
3. Chạy `SHIFT-01`.
4. Chạy `HALL-01`.
5. Chạy `ORD-01`.
6. Chạy `KIT-01`.
7. Chạy `PAY-01` và `PAY-02`.
8. Chạy `SHIFT-02`.
9. Điền từng Master row tương ứng.
10. Thêm issue mới nếu có, mở rộng table/formula đúng quy tắc.
11. Recalculate workbook.
12. Viết phần đầu của báo cáo `.md`.

Sau khi xác nhận quy trình này không làm hỏng workbook và evidence có thể truy vết, tiếp tục toàn bộ P0 theo mục 6.
