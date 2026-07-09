flowchart LR

%%==========================
%% CUSTOMER
%%==========================

subgraph CUSTOMER["👤 Khách hàng"]
direction TB

START((●))

A1["Liên hệ đặt bàn"]

D1{"Chọn kênh đặt bàn?"}

A2["Website"]
A3["Capichi"]
A4["Facebook"]
A5["Zalo"]
A6["Vãng lai"]

START --> A1
A1 --> D1

D1 --> A2
D1 --> A3
D1 --> A4
D1 --> A5
D1 --> A6

end

%%==========================
%% RECEPTION
%%==========================

subgraph RECEPTION["💰 Thu ngân / Lễ tân"]
direction TB

R1["Tiếp nhận yêu cầu đặt bàn"]

R2["Nhập thông tin khách hàng<br/>• Tên khách<br/>• SĐT<br/>• Email<br/>• Nguồn nhận"]

R3["Nhập thông tin đặt bàn<br/>• Ngày<br/>• Giờ<br/>• SL người<br/>• SL trẻ em<br/>• SL bàn<br/>• Tên tiệc<br/>• Loại tiệc"]

R4["Nhập ghi chú<br/>• Người tiếp nhận<br/>• Nguồn khách<br/>• Yêu cầu đặc biệt"]

R5["Lưu Booking<br/>Trạng thái = Mới đặt"]

R6["Gửi thông báo đến Phục vụ"]

end

%%==========================
%% WAITER
%%==========================

subgraph WAITER["🍽️ Phục vụ"]
direction TB

W1["Nhận thông báo Booking"]

W2["Xem thông tin Booking<br/>• Bàn<br/>• Thời gian<br/>• Nhân viên tiếp nhận<br/>• Ghi chú<br/>• Nguồn khách"]

W3["Chuẩn bị bàn"]

W4["Bố trí bàn"]

W5["Cập nhật trạng thái<br/>Đã xác nhận / Đã cọc"]

W6["Chờ khách đến"]

END((◎))

end

%%==========================
%% MERGE
%%==========================

M1((Merge))

A2 --> M1
A3 --> M1
A4 --> M1
A5 --> M1
A6 --> M1

M1 --> R1

%%==========================
%% FLOW
%%==========================

R1 --> R2
R2 --> R3
R3 --> R4
R4 --> R5
R5 --> R6

R6 --> W1
W1 --> W2
W2 --> W3
W3 --> W4
W4 --> W5
W5 --> W6
W6 --> END

%%==========================
%% STYLE
%%==========================

classDef start fill:#4CAF50,color:#fff,stroke:#2E7D32,stroke-width:2px;
classDef finish fill:#F44336,color:#fff,stroke:#B71C1C,stroke-width:2px;
classDef customer fill:#E3F2FD,stroke:#1976D2,stroke-width:2px;
classDef reception fill:#FFF3E0,stroke:#F57C00,stroke-width:2px;
classDef waiter fill:#E8F5E9,stroke:#388E3C,stroke-width:2px;
classDef decision fill:#FFF8E1,stroke:#FBC02D,stroke-width:2px;
classDef merge fill:#ECEFF1,stroke:#607D8B,stroke-width:2px;

class START start;
class END finish;

class A1,A2,A3,A4,A5,A6 customer;
class R1,R2,R3,R4,R5,R6 reception;
class W1,W2,W3,W4,W5,W6 waiter;
class D1 decision;
class M1 merge;
