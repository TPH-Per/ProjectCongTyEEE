flowchart LR

%%==========================
%% CUSTOMER
%%==========================

subgraph CUSTOMER["👤 Khách hàng"]
direction TB

START((●))

C1["Mở màn hình Theo dõi món ăn"]
C2["Xem tiến độ món ăn & timeline"]
C3["Lọc danh sách (Tất cả, Đang chế biến,...)"]
C4["Yêu cầu Làm mới thủ công"]

START --> C1
C1 --> C2
C2 --> C3
C2 --> C4

end

%%==========================
%% STAFF (KITCHEN / WAITER)
%%==========================

subgraph STAFF["🧑‍🍳 Nhân viên Bếp / Phục vụ"]
direction TB

ST1["Nhận Order & chế biến"]
ST2["Cập nhật trạng thái chế biến trên KDS"]
ST3["Hoàn thành & phục vụ món"]
ST4["Cập nhật đã phục vụ trên POS/KDS"]

ST1 --> ST2
ST2 --> ST3
ST3 --> ST4

end

%%==========================
%% POS SYSTEM / SUPABASE
%%==========================

subgraph SYSTEM["💻 Hệ thống POS / Supabase"]
direction TB

S1["Tải dữ liệu order & tính tiến độ %"]
S2["Khởi tạo Realtime lắng nghe cập nhật"]
S3["Đẩy sự kiện qua Realtime/WebSocket"]
S4["Cập nhật UI khách hàng & thông báo"]
S5["Lưu vết thời gian phục vụ (servedAt)"]

S1 --> S2
S3 --> S4
S5 --> S3

end

%%==========================
%% FLOW CONNECTIONS
%%==========================

C1 ==> S1
S1 -.-> C2
ST2 ==> S3
S4 -.-> C2
C4 ==> S1
ST4 ==> S5

%%==========================
%% STYLE DEFINITIONS
%%==========================

classDef start fill:#4CAF50,color:#fff,stroke:#2E7D32,stroke-width:2px;
classDef customer fill:#E3F2FD,stroke:#1976D2,stroke-width:2px;
classDef staff fill:#FFF3E0,stroke:#F57C00,stroke-width:2px;
classDef system fill:#E8F5E9,stroke:#388E3C,stroke-width:2px;

class START start;
class C1,C2,C3,C4 customer;
class ST1,ST2,ST3,ST4 staff;
class S1,S2,S3,S4,S5 system;
