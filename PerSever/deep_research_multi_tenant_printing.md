# BÁO CÁO NGHIÊN CỨU CHUYÊN SÂU (DEEP RESEARCH REPORT)
**Chủ đề:** Tối ưu hóa Kiến trúc Multi-tenant (Đa chi nhánh) cho Hệ thống In ấn qua Supabase
**Đánh giá phương pháp:** Sử dụng `pg_notify` với `printer_channel_{branch_id}` có thực sự tối ưu cho tương lai?

---

## 1. Đánh giá phương pháp hiện tại (`pg_notify` + `branch_id`)
Việc gắn thêm `branch_id` vào tên kênh (Ví dụ: `pg_notify('printer_channel_chi_nhanh_A')`) **giải quyết triệt để 100% lỗi in nhầm chéo chi nhánh**. Về mặt logic, đây là cách xử lý đúng và nhanh nhất.

**Tuy nhiên, xét về mặt Kiến trúc hệ thống (System Architecture) khi mở rộng (Scale-up) lên 10, 50 hoặc 100 chi nhánh, phương pháp này BẮT ĐẦU BỘC LỘ NHƯỢC ĐIỂM CHÍ MẠNG:**

### Nhược điểm 1: Cạn kiệt Kết nối Database (Connection Exhaustion)
Lệnh `LISTEN` của PostgreSQL yêu cầu Mini Server (`PerSever`) phải duy trì **1 kết nối sống (persistent connection) 24/24** tới thẳng Database.
- Nếu F2TECH có 50 chi nhánh ➡️ Database phải chịu 50 kết nối "treo" liên tục chỉ để chờ lệnh in.
- PostgreSQL cực kỳ ghét việc giữ quá nhiều kết nối treo (max_connections thường chỉ từ 100-300). Nó sẽ làm Database chậm chạp và kiệt sức. Dù anh dùng Session Pooler (port 5432) của Supabase, nó vẫn chiếm dụng tài nguyên.

### Nhược điểm 2: Giới hạn 8KB Payload (Bom nổ chậm)
Hàm `pg_notify` của PostgreSQL có một giới hạn vật lý cứng: **Payload (chuỗi JSON) truyền đi không được vượt quá 8,000 bytes (8KB).**
- Nếu 1 hóa đơn bình thường: ~2KB (Hoạt động hoàn hảo).
- Nếu 1 bàn tiệc sinh nhật order 50 món kèm nhiều ghi chú dài: Chuỗi JSON > 8KB.
- **Hậu quả:** Database báo lỗi `payload string too long`, Trigger bị sập, khách thanh toán web bị báo lỗi 500, và bill KHÔNG bao giờ được in!

### Nhược điểm 3: Fire-and-Forget (Bắn xong là quên)
`pg_notify` là cơ chế "bắn và quên". Nếu tại đúng phần ngàn giây mà Database bắn `notify`, mạng wifi của quán bị rớt (Lagging) ➡️ Tín hiệu đó bay vào khoảng không và mất vĩnh viễn. (Mặc dù `startup_recovery()` của ta sẽ quét lại khi có mạng, nhưng nó không còn tính Real-time nữa).

---

## 2. PHƯƠNG ÁN TỐI ƯU NHẤT TRONG HỆ SINH THÁI SUPABASE (The "Supabase Way")

Thay vì dùng `asyncpg` chọc thẳng vào tầng thấp (Raw Postgres) để nghe `LISTEN/NOTIFY`, giải pháp tiêu chuẩn công nghiệp (Industry Standard) cho các ứng dụng SaaS Đa chi nhánh trên Supabase là: **Sử dụng SUPABASE REALTIME (WebSockets).**

### Supabase Realtime hoạt động như thế nào?
Supabase có xây dựng riêng một cụm máy chủ khổng lồ tên là Realtime Cluster (Viết bằng ngôn ngữ Elixir chuyên trị Realtime). 
- Thay vì `PerSever` cắm kết nối vào Database, `PerSever` sẽ cắm kết nối WebSocket vào **Realtime Cluster**.
- Realtime Cluster đọc luồng thay đổi của DB (Logical Replication) và đẩy JSON xuống cho `PerSever`.

### Tại sao nó tối ưu tuyệt đối?
1. **Scale không giới hạn:** Realtime Cluster sinh ra để gánh hàng triệu kết nối WebSocket. 1000 chi nhánh kết nối cùng lúc cũng không tốn 1% sức mạnh nào của Database chính.
2. **Không giới hạn 8KB:** Vì dùng Logical Replication (Đọc lịch sử WAL), nó không bị kẹt giới hạn 8KB của `pg_notify`. Bill 100 món vẫn mượt.
3. **Bảo mật Multi-tenant bằng RLS (Row Level Security):** Anh chỉ cần bật RLS: `branch_id = auth.uid()`. Supabase Realtime sẽ TỰ ĐỘNG CHẶN không cho chi nhánh A nghe lén hóa đơn của chi nhánh B. Không cần phải tự code phân luồng kênh.

---

## 3. KẾT LUẬN & ĐỀ XUẤT CHO F2TECH

**Giai đoạn hiện tại (1 - 3 Chi nhánh):** 
- Việc dùng `pg_notify('printer_channel_' || branch_id)` là **đủ xài, nhanh gọn, và giải quyết triệt để lỗi in chéo**. Chấp nhận được trong MVP (Sản phẩm khả dụng tối thiểu).

**Giai đoạn Tương lai (Từ chi nhánh thứ 4 trở lên / Đóng gói bán SaaS):**
- **BẮT BUỘC** phải đập bỏ `pg_notify` và `asyncpg` trong `PerSever`. 
- Chuyển sang dùng thư viện `supabase-py` (hoặc `websockets`), đăng ký kênh `supabase.channel('public:print_jobs').on('INSERT', handle_print)`. Kèm theo kích hoạt RLS (Row Level Security) theo `branch_id`.

**Quyết định cuối cùng:** Phương pháp hiện tại (thêm `branch_id` vào notify) **CHƯA PHẢI LÀ TỐI ƯU NHẤT** về mặt Scale, nhưng **PHÙ HỢP NHẤT** về chi phí thời gian code cho hiện tại. Anh nên cho phép áp dụng cách 1 (pg_notify + branch_id) để kịp Go-live, và đưa cách 2 (Supabase Realtime) vào Tech Debt Backlog cho Phase 5.
