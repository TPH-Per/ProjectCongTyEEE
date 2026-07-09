@startuml
title Payment Workflow

skinparam shadowing false
skinparam activity {
BackgroundColor White
BorderColor Black
ArrowColor Black
DiamondBackgroundColor #FFD700
DiamondBorderColor #B8860B
}

|👤 Khách hàng|
start
:Yêu cầu thanh toán;

|🧑‍💼 Phục vụ / Thu ngân|
:Đến bàn và kiểm tra\nOrder/Bill;
:Thông báo tổng tiền\n(VAT + Service Charge);

if (Có Voucher/Coupon?) then (Có)
:Áp dụng Voucher/\nCoupon;
:Tính lại tổng tiền;
else (Không)
endif

if (Phương thức thanh toán?) then (Tiền mặt)
:Nhận tiền mặt;
elseif (QR)
:Khách quét QR\nvà thanh toán;
else (Thẻ)
:Thanh toán bằng\nthẻ ngân hàng;
endif

:Xác nhận giao dịch\nthành công;

|💻 Hệ thống POS|
:Lưu giao dịch thanh toán;
:Cập nhật Bill = Paid;
:Cập nhật trạng thái\nBàn = Available;
:Cập nhật tồn kho;
:Cập nhật doanh thu;

|🧑‍💼 Phục vụ / Thu ngân|
:In hóa đơn;
:Giao hóa đơn\ncho khách;
:Dọn bàn;

|👤 Khách hàng|
:Hoàn tất thanh toán;
stop

@enduml
