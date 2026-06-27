# BẢN TÓM TẮT CHI TIẾT GIAO DIỆN NGƯỜI DÙNG (UI) VÀ LUỒNG XỬ LÝ PHÂN HỆ BẾP (KITCHEN MODULE) — NGƯU CÁT POS

Tài liệu này tóm tắt toàn bộ giao diện người dùng (UI), các thành phần điều khiển, và ý nghĩa của việc xử lý nghiệp vụ (Business & Technical Logic) trong phân hệ Bếp (**Kitchen Module**) của hệ thống Ngưu Cát POS. Phân hệ bếp được thiết kế tối ưu cho môi trường vận hành áp lực cao, nhiệt độ lớn, thiếu sáng hoặc ánh sáng phức tạp, hỗ trợ tương tác cảm ứng trực quan không cần chuột.

---

## 🗺️ TỔNG QUAN PHÂN HỆ BẾP (KITCHEN SYSTEM OVERVIEW)

Hệ thống bếp của Ngưu Cát POS gồm **3 phân hệ màn hình cốt lõi** hoạt động đồng bộ theo thời gian thực (Real-time Sync) thông qua Pinia Store (`kitchen.ts`) và cơ chế liên lạc nội bộ:

1. **Kitchen Display System (KDS)**: Màn hình hiển thị và chế biến tại các trạm bếp (Bếp Nướng, Bếp Lẩu, Bếp Lạnh, Bếp Chiên, Quầy Bar).
2. **Kitchen Expo Station (Pass/Expo)**: Màn hình điều phối ra món và kiểm soát chất lượng (Quality Control - QC) do Bếp trưởng (Chef) quản lý trước khi chuyển cho nhân viên sảnh phục vụ khách.
3. **Kitchen Requisition (Kho Bếp)**: Màn hình lập yêu cầu, phê duyệt xuất kho và kiểm kê kho nội bộ giữa trạm bếp và thủ kho chính.

---

## 📺 1. MÀN HÌNH KITCHEN DISPLAY SYSTEM (KDS)

Màn hình KDS là trung tâm chế biến món ăn tại từng trạm. Giao diện được thiết kế với **Dark Mode làm mặc định** giúp giảm mỏi mắt, tăng độ tương phản hiển thị thông tin rõ ràng từ khoảng cách 2 - 3 mét.

### 🎨 Đặc điểm UI & Bố cục chung
*   **Header (80px)**: Hiển thị Logo, Trạm hiện tại (ví dụ: `BẾP NƯỚNG`), Đồng hồ thời gian thực (Digital Clock), Badge cảnh báo khẩn cấp và các nút điều hướng nhanh.
*   **Filter Bar (60px)**: 
    *   *Bộ lọc Trạm (Station Filter)*: Cho phép xem đơn của từng trạm riêng biệt (Nướng, Lẩu, Lạnh, Chiên, Bar, hoặc Xem tất cả `ALL`).
    *   *Sắp xếp*: Sắp xếp theo FIFO (Cũ nhất trước), Mới nhất trước, hoặc theo Độ ưu tiên.
    *   *Tìm kiếm*: Tìm nhanh theo số bàn hoặc mã ID Ticket.
*   **Status Bar (50px)**: Thanh thống kê số lượng đơn hàng theo 4 trạng thái:
    *   *Chờ chế biến*: Hiển thị số đơn mới chưa xác nhận.
    *   *Đang làm*: Số lượng đơn đang trong quá trình nấu.
    *   *Hoàn thành*: Số lượng đơn đã xong trong ca.
    *   *Trễ (>15 phút)*: Cảnh báo số lượng đơn bị tồn đọng quá lâu.
*   **Kanban Board (Vùng làm việc chính)**: Chia làm 4 cột dọc tương ứng với tiến trình xử lý món ăn.

### 📋 Chi tiết các cột Kanban & Thao tác UI

#### Cột 1: CHỜ XÁC NHẬN (Pending Orders)
*   **UI Thiết kế**: Hiển thị các thẻ đơn hàng (Ticket Card) màu xanh dương đậm (`#1A237E`).
    *   Hiển thị số bàn cực lớn (VD: **Bàn A01**).
    *   Hệ thống Badge phân loại loại hình ăn: **BUFFET VÒNG 1**, **BUFFET GỌI THÊM**, **A LA CARTE**, **TRẢ MÓN (REMAKE)** giúp đầu bếp nhận biết ngay tính chất đơn.
    *   Badge nhấp nháy **FIFO** dành cho đơn hàng cũ nhất đang xếp hàng, nhắc nhở đầu bếp thực hiện đúng nguyên tắc chế biến trước.
    *   Bộ đếm thời gian (Timer) tự động tăng dần theo thời gian thực. Đổi màu theo mức độ chờ: Xanh dương (<10p) $\rightarrow$ Cam (10-15p) $\rightarrow$ Đỏ (>15p, Badge trễ nhấp nháy).
    *   Danh sách món ăn hiển thị số lượng lớn nổi bật (VD: `2x Sườn bò`). Mỗi món ăn kèm theo checkbox trạng thái.
    *   Ghi chú món ăn hiển thị màu cam nổi bật, kèm icon cảnh báo để tránh bỏ sót các yêu cầu đặc biệt của khách (không hành, ít cay, dị ứng).
*   **Thao tác xử lý**: Đầu bếp nhấn nút **XÁC NHẬN** (Acknowledge) ở chân thẻ. 
*   **Ý nghĩa xử lý**: Xác nhận trạm bếp đã tiếp nhận đơn và bắt đầu chuẩn bị nguyên liệu, chuyển trạng thái đơn sang cột tiếp theo.

#### Cột 2: ĐANG CHẾ BIẾN (Cooking Orders)
*   **UI Thiết kế**: Thẻ đơn chuyển sang màu vàng cam (`#E65100`).
    *   Hiển thị danh sách các món cần nấu. Đầu bếp có thể bấm trực tiếp vào từng món để đánh dấu checkbox đã xong từng phần (món nào nấu xong trước bấm trước để chuyển đổi trạng thái dẹt mờ `opacity-60` và gạch ngang chữ).
*   **Thao tác xử lý**: Khi nấu xong toàn bộ các món trong thẻ, đầu bếp nhấn nút **XONG TẤT CẢ** (Complete Ticket) ở cuối thẻ.
*   **Ý nghĩa xử lý**: Chuyển toàn bộ các món ăn trong ticket sang trạng thái sẵn sàng điều phối, tự động đẩy dữ liệu sang cột "Sẵn sàng ra món" và màn hình **Expo QC** của Bếp trưởng.

#### Cột 3: SẴN SÀNG RA MÓN (Ready for Pass)
*   **UI Thiết kế**: Thẻ đơn chuyển sang màu xanh lá cây (`#2E7D32`).
*   **Thao tác xử lý**: Nút nhấn **HOÀN TẤT TICKET** dành cho nhân viên tiếp thực (Runner) hoặc đầu bếp khi chuyển món lên khay giao đi.
*   **Ý nghĩa xử lý**: Xác nhận món ăn đã rời khu vực bếp nấu để chuyển sang khu bàn ăn của khách.

#### Cột 4: HOÀN TẤT (Completed Orders)
*   **UI Thiết kế**: Danh sách thẻ đơn hàng đã phục vụ thành công trong ca, chữ gạch ngang màu xám nhạt để lưu lịch sử đối chiếu khi cần thiết.

---

### ⚙️ Các chức năng phụ trợ nâng cao (Modals & Sidebar)

1.  **HACCP Checklist Modal (Vệ sinh an toàn thực phẩm)**:
    *   *UI*: Bảng biểu kiểm soát hiển thị các hạng mục: Nhiệt độ tủ đông, tủ mát, dụng cụ thớt, nhiệt độ dầu, vệ sinh bề mặt nướng, hạn sử dụng nguyên liệu.
    *   *Ý nghĩa xử lý*: Đầu ca/Cuối ca, bếp trưởng hoặc giám sát phải kiểm tra và tick chọn lưu thông tin. Đảm bảo toàn bộ quy trình chế biến tuân thủ nghiêm ngặt chuẩn an toàn thực phẩm, ghi nhận nhật ký vận hành pháp lý của nhà hàng.
2.  **Prep List & Tiến Độ Sơ Chế Modal**:
    *   *UI*: Hiển thị danh sách các công việc sơ chế chuẩn bị (Prep tasks) kèm thanh tiến độ (Progress bar).
    *   *Ý nghĩa xử lý*: Theo dõi việc rã đông, cắt thái thịt, pha chế nước lẩu, nhặt rau đầu ca. Đảm bảo các trạm bếp luôn chuẩn bị đủ định lượng nguyên liệu sơ chế trước khi đón khách giờ cao điểm.
3.  **Báo Hết Món (86'd List) Modal**:
    *   *UI*: Danh sách các món ăn kèm nút bật/tắt (Toggle) trạng thái hoạt động/hết hàng.
    *   *Ý nghĩa xử lý*: Khi nguyên liệu của một món ăn bị cạn kiệt, bếp trưởng kích hoạt trạng thái "86'd" (Hết hàng). Hệ thống KDS lập tức đánh dấu đỏ cảnh báo "HẾT MÓN" trên thẻ đang chờ, đồng thời đồng bộ ngược lên hệ thống POS sảnh để nhân viên không cho phép khách gọi thêm món đó nữa.
4.  **Yêu cầu Vỉ & Than (Grill & Coal Requests) Sidebar Panel**:
    *   *UI*: Bảng điều khiển rộng 320px bên phải màn hình KDS, hiển thị danh sách yêu cầu thay vỉ hoặc châm than của từng bàn. Thẻ yêu cầu khẩn cấp (Urgent) hiển thị viền đỏ đậm nhấp nháy.
    *   *Ý nghĩa xử lý*: Bếp nướng cần duy trì nhiệt độ than ổn định và vỉ sạch. Khi vỉ bẩn hoặc than yếu, đầu bếp gửi yêu cầu. Nhân viên tiếp than sẽ nhìn bảng này để xử lý kịp thời (thời gian xử lý tiêu chuẩn: 2-3 phút), tránh làm gián đoạn trải nghiệm ăn uống của khách hàng.
5.  **Cảnh báo Trễ (Delayed Orders Modal)**:
    *   *UI*: Cửa sổ danh sách các đơn hàng chờ quá 15 phút mà chưa hoàn thành.
    *   *Ý nghĩa xử lý*: Giúp Bếp trưởng giám sát trực quan các điểm nghẽn cổ chai trong bếp, chủ động điều phối nhân sự sang hỗ trợ trạm đang bị quá tải để giải quyết nhanh các đơn bị trễ.

---

## 🍳 2. MÀN HÌNH KITCHEN EXPO STATION (PASS/EXPO)

Màn hình Expo đặt tại khu vực ra món (Pass), nơi Bếp trưởng tiến hành kiểm tra chất lượng sản phẩm cuối cùng (Quality Control) trước khi đưa ra sảnh phục vụ.

### 🎨 Bố cục giao diện
Thiết kế chia làm **2 cột lớn** trực quan:
*   **Cột Trái (60%) - QC Active Queue (Hàng chờ kiểm tra)**: Hiển thị các thẻ món ăn đã nấu xong từ KDS chuyển lên.
*   **Cột Phải (40%) - Remake Queue & Delivery Logs**: Hiển thị danh sách các món ăn bị lỗi cần làm lại khẩn cấp và lịch sử giao món thành công.

### 📋 Luồng xử lý và Các thành phần UI đặc thù

#### 1. Bộ lọc nhanh hàng chờ QC (QC Queue Bar)
*   Thanh ngang trên cùng chia làm 4 bộ lọc dựa trên trạng thái món ăn:
    *   *Chờ QC (Waiting)*: Danh sách món mới nấu xong cần kiểm tra.
    *   *Đạt (Passed)*: Danh sách các đơn đã duyệt thành công.
    *   *Remake (Làm lại)*: Thống kê số lượng món bị đánh rớt QC đang nấu lại.
    *   *Dị ứng (Allergy)*: Cảnh báo đỏ nổi bật đối với các đơn hàng chứa lưu ý dị ứng của thực khách.

#### 2. Thao tác Kiểm soát chất lượng (QC Card)
*   **UI Cảnh báo dị ứng**: Nếu thẻ đơn hàng có thông tin dị ứng, một khối cảnh báo màu đỏ rộng (`#FF5722`) có tiêu đề: `🛑 CẢNH BÁO DỊ ỨNG NGHIÊM TRỌNG: [Chi tiết dị ứng]` sẽ hiển thị trên cùng để cảnh cáo bếp trưởng kiểm tra kỹ vật chứa và quy trình không nhiễm chéo.
*   **Bảng Checklist Tiêu Chuẩn Món Ăn (Expo QC Checklist)**:
    *   Hiển thị danh sách các tiêu chí bắt buộc bếp trưởng phải kiểm tra bằng mắt/dụng cụ đo:
        1.  🌡️ *Nhiệt độ đạt chuẩn (≥ 60°C đối với món nóng)*
        2.  ⚖️ *Định lượng chuẩn xác (Đúng định mức đĩa)*
        3.  🎨 *Trình bày thẩm mỹ (Sạch sẽ, đẹp mắt, đúng khay dĩa)*
        4.  🥬 *Đầy đủ đồ kèm (Nước chấm, rau ăn kèm, đồ gia vị phụ)*
    *   Bếp trưởng tick chọn các tiêu chí này. Hệ thống hỗ trợ tương tác nhanh, trực quan.

#### 3. Hai nhánh xử lý chính (QC Actions):

##### Nhánh A: ĐẠT TIÊU CHUẨN $\rightarrow$ RA MÓN (QC Pass)
*   **Thao tác**: Nhấn nút **ĐẠT - RA MÓN** (QC Pass).
*   **UI xuất hiện**: Một Modal xác nhận ra món hiện ra, hiển thị chi tiết tên món ăn, số bàn, số lượng và thông tin người tiếp nhận món ăn (Runner).
*   **Ý nghĩa xử lý**: Xác nhận món ăn hoàn hảo, hệ thống lưu lịch sử phục vụ, cập nhật trạng thái món ăn trên POS sảnh thành "Đã phục vụ" để khách hàng an tâm thưởng thức.

##### Nhánh B: KHÔNG ĐẠT TIÊU CHUẨN $\rightarrow$ LÀM LẠI (QC Fail / Remake)
*   **Thao tác**: Nhấn nút **KHÔNG ĐẠT QC** (QC Fail).
*   **UI xuất hiện**: Modal báo lỗi (Remake Modal) yêu cầu bếp trưởng chọn lý do chế biến lỗi:
    *   *Món ăn bị nguội (Cold food)*
    *   *Sai định lượng/Không đúng dĩa (Wrong portion)*
    *   *Trình bày xấu/Bẩn khay dĩa (Bad presentation)*
    *   *Sai vị/Cháy/Sống (Incorrect seasoning/Overcooked)*
    *   *Nhập lý do khác thủ công...*
    *   *Chọn mức độ nghiêm trọng (Thường / Gấp / Khẩn cấp)*.
*   **Ý nghĩa xử lý**: 
    *   Hệ thống sẽ chuyển món ăn này sang **Remake Queue** hiển thị ở cột bên phải màn hình Expo với thứ tự ưu tiên cao nhất (**P1 - HIGH**).
    *   Đồng thời, hệ thống tự động phát tín hiệu còi/chuông và đẩy thẻ đơn hàng này ngược lại cột đầu tiên của màn hình **KDS** với Badge **TRẢ MÓN (REMAKE)** nhấp nháy màu đỏ tím để bắt đầu quá trình nấu lại ngay lập tức.
    *   Giúp kiểm soát chất lượng đầu ra chặt chẽ, không để món lỗi lọt tới bàn của thực khách, đồng thời ghi nhận lỗi chế biến vào nhật ký hiệu suất của bếp viên để cải tiến tay nghề.

---

## 🏢 3. MÀN HÌNH KITCHEN REQUISITION (YÊU CẦU XUẤT KHO BẾP)

Màn hình này giải quyết bài toán quản lý nguyên vật liệu tiêu hao, luân chuyển hàng hóa từ Kho tổng (Main Warehouse) vào các Trạm bếp hoạt động trực tiếp trong ca.

### 🎨 Bố cục giao diện
*   **Sidebar trái**:
    *   *Tồn Kho Bếp Hiện Tại*: Hiển thị trực quan danh sách các nguyên liệu chính (Thịt bò Wagyu, Nước lẩu, Rau, Sườn heo, Cá hồi, Tôm...) kèm biểu tượng cảm xúc sinh động. Hiển thị số lượng tồn kho bếp thực tế trên định mức tối thiểu cần có (`Số tồn / Định mức min`). Chữ tự động chuyển màu đỏ cảnh báo nếu tồn kho thực tế dưới mức an toàn (VD: 0/3kg).
    *   *Prep List*: Theo dõi song song tiến độ sơ chế của ca.
*   **Workspace chính**: Gồm 3 Tab chức năng đại diện cho các vai trò và giai đoạn xử lý.

### 📋 Quy trình xử lý qua các Tab giao diện

```
[Bếp trưởng: Tạo phiếu] ──(Pending)──> [Thủ kho: Phê duyệt/Điều chỉnh] ──(Approved)──> [Bếp trưởng: Nhận hàng & Ký] ──(Delivered)──> [Hệ thống tự động trừ/cộng kho]
```

#### Tab 1: 📝 YÊU CẦU CỦA BẾP (Bếp trưởng / Head Chef)
*   **UI Thiết kế**: Danh sách các phiếu yêu cầu xuất kho (`REQ-001`, `REQ-002`...) do bếp trưởng trạm tạo ra. Hiển thị rõ Trạm yêu cầu, Người lập, Ngày giờ, Ghi chú lý do, Độ ưu tiên (Low, Medium, High) và Trạng thái phiếu (Pending, Approved, Delivered, Rejected).
*   **Thao tác**:
    *   Nhấn **TẠO PHIẾU MỚI** $\rightarrow$ Hiện Modal chọn nguyên liệu từ danh sách kho tổng, nhập số lượng cần xuất, nhập ghi chú lý do rồi nhấn Gửi.
    *   Khi thủ kho giao hàng thực tế tới bếp, bếp trưởng bấm vào phiếu đang ở trạng thái `Approved` để kiểm tra kiện hàng. 
    *   Nếu đạt chuẩn, bấm nút **XÁC NHẬN NHẬN HÀNG** (Confirm Delivery).
    *   Nếu phát hiện hàng hỏng/thiếu hụt nặng, bấm nút **TỪ CHỐI NHẬN** (Reject) và nhập lý do từ chối bàn giao.
*   **Ý nghĩa xử lý**: Giúp bếp trưởng luôn chủ động bổ sung nguyên liệu thiếu hụt kịp thời trước giờ cao điểm, kiểm tra giám sát chất lượng nguyên liệu đầu vào từ kho tổng.

#### Tab 2: 🏢 XỬ LÝ KHO (Thủ kho / Storekeeper)
*   **UI Thiết kế**: Giao diện chuyên biệt dành cho Thủ kho để quản lý tập trung toàn bộ yêu cầu từ các trạm bếp đổ về.
*   **Thao tác xử lý**:
    *   Thủ kho click chọn một phiếu `Pending` để mở chi tiết hàng cần xuất.
    *   Đối chiếu số tồn kho tổng thực tế:
        *   *Nếu đủ hàng*: Thủ kho có thể sửa lại số lượng xuất thực tế nếu cần, rồi nhấn nút **PHÊ DUYỆT & XUẤT KHO** (Approve Requisition). Trạng thái phiếu chuyển thành `Approved`.
        *   *Nếu thiếu hụt*: Thủ kho có thể nhập đề xuất sản phẩm thay thế (VD: *Thay bò Wagyu bằng bò Mỹ thượng hạng*) hoặc nhấn nút **TỪ CHỐI YÊU CẦU** (Reject Requisition) và nhập lý do (VD: *Hết hàng tại kho tổng*). Trạng thái phiếu chuyển thành `Rejected`.
*   **Ý nghĩa xử lý**: Đảm bảo kho chính luôn kiểm soát chặt chẽ việc xuất kho, ngăn chặn thất thoát nguyên liệu, điều phối linh hoạt tài nguyên thực phẩm trong toàn nhà hàng.

#### Tab 3: 📈 THỐNG KÊ & NHẬT KÝ (Audit Logs / Lịch sử)
*   **UI Thiết kế**: Hiển thị dòng thời gian (Timeline) chi tiết lịch trình của từng phiếu xuất kho.
*   **Ý nghĩa xử lý (Audit Trail)**: Ghi nhận chính xác giây, phút: Ai là người tạo phiếu? Ai phê duyệt? Ai ký nhận bàn giao? Hoạt động trừ kho diễn ra khi nào? Đây là bằng chứng pháp lý kỹ thuật số chống gian lận, phục vụ kiểm toán tài chính và phân tích hao hụt nguyên vật liệu cuối tháng.

---

## 💾 4. CƠ CHẾ DỮ LIỆU VÀ QUẢN LÝ TRẠNG THÁI TRUNG TÂM (`kitchen.ts`)

Toàn bộ hoạt động của các màn hình trên được neo giữ bởi cơ chế quản lý trạng thái của **Pinia Store** trong file `kitchen.ts`:

### 🗄️ Các thực thể dữ liệu chính (Interfaces)
*   `RequisitionItem`: Định nghĩa cấu trúc món hàng trong phiếu xuất kho gồm số lượng yêu cầu (`requestedQty`), số lượng thực giao (`deliveredQty`), trạng thái hàng, lý do từ chối hoặc hàng thay thế.
*   `Requisition`: Định nghĩa một phiếu xuất kho hoàn chỉnh gồm ID, Trạm bếp gửi, Người gửi, Mức độ ưu tiên, Trạng thái tổng (`pending` | `approved` | `delivered` | `rejected`), danh sách các món hàng và mảng nhật ký kiểm toán (`auditLogs`).
*   `AuditLog`: Ghi nhận nhật ký tương tác: ID log, nội dung hành động, tên người thực hiện, nhãn thời gian.
*   `InventoryItem`: Quản lý tồn kho thực tế của từng loại nguyên liệu tại cả Kho tổng và Kho bếp riêng biệt.

### ⚙️ Các hàm xử lý trạng thái lõi (State & Actions)
*   `addRequisition(req)`: Khởi tạo phiếu yêu cầu xuất kho mới với mã số tăng dần tự động dạng `REQ-00X`, ghi nhận log hành động khởi tạo và đưa lên đầu danh sách hàng đợi xử lý.
*   `updateRequisitionStatus(id, status, actor, reason)`: Cập nhật trạng thái tổng thể của phiếu xuất kho. Đặc biệt, **khi trạng thái chuyển thành `delivered` (đã ký nhận)**, hệ thống kích hoạt logic tự động:
    $$\text{Tồn kho tổng} \leftarrow \max(0, \text{Tồn kho tổng} - \text{Số lượng thực giao})$$
    $$\text{Tồn kho bếp} \leftarrow \text{Tồn kho bếp} + \text{Số lượng thực giao}$$
    Đồng thời ghi nhận chi tiết hành động ký xác nhận của bếp trưởng vào nhật ký `auditLogs`.
*   `updateRequisitionItemDelivery(...)`: Cho phép thủ kho điều chỉnh chính xác số lượng thực xuất của từng dòng nguyên liệu trong phiếu khi xử lý xuất kho thực tế.

---

## 🏆 5. Ý NGHĨA VẬN HÀNH VÀ LỢI ÍCH KINH DOANH (OPERATIONAL BENEFITS)

Việc chuẩn hóa thiết kế UI và luồng xử lý chặt chẽ của Phân hệ Bếp mang lại những giá trị thực tế to lớn cho nhà hàng Ngưu Cát:

1.  **Vận hành chuẩn FIFO (First-In, First-Out)**: Loại bỏ hoàn toàn tình trạng trôi đơn, sót đơn của khách hàng. Đầu bếp luôn nhận biết rõ đơn nào vào trước để chế biến trước thông qua các Badge cảnh báo nhấp nháy.
2.  **Đồng bộ thời gian thực thông minh (Real-time Efficiency)**: Giảm thiểu sai sót thông tin giữa nhân viên phục vụ sảnh và đầu bếp bếp nóng/lạnh. Việc đổi trạng thái món ăn cập nhật lập tức giúp giảm thời gian chờ của thực khách.
3.  **Tăng tốc độ xử lý trả món (Remake optimization)**: Luồng QC Fail tạo ra quy trình làm lại khép kín với độ ưu tiên cao nhất, lấy lại thiện cảm của thực khách khi món ăn gặp sự cố lỗi chế biến nhanh chóng.
4.  **Kiểm soát thất thoát nguyên vật liệu hiệu quả**: Quy trình Kitchen Requisition chuẩn hóa 4 bước ký duyệt rõ ràng và tự động cập nhật số liệu kho triệt tiêu các hành vi gian lận nguyên liệu, giúp quản lý nắm bắt chính xác hao hụt hàng ca/ngày.
5.  **Đáp ứng chuẩn vệ sinh và an toàn thực phẩm (HACCP)**: Việc số hóa bảng kiểm tra HACCP giúp duy trì tính kỷ luật của đội ngũ bếp, bảo vệ uy tín thương hiệu nhà hàng trước các nguy cơ ngộ độc thực phẩm.
