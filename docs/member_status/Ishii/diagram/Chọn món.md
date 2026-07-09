@startuml
!theme plain

skinparam backgroundColor White
skinparam shadowing false
skinparam defaultFontSize 12
skinparam ArrowColor Black
skinparam ActivityBorderColor Black

title SƠ ĐỒ ACTIVITY - NGHIỆP VỤ CHỌN MÓN

|Khách hàng|

start

:Yêu cầu chọn bàn;
:Yêu cầu chọn món;

|Nhân viên (Phục vụ / Thu ngân)|

:Ghi nhận yêu cầu chọn bàn;
:Nhập thông tin vào hệ thống;
:Ghi nhận chọn bàn;

if (Bàn còn trống?) then (Có)

else (Không)

    :Đề xuất bàn khác;

    if (Khách đồng ý?) then (Có)
        :Chọn bàn mới;
    else (Không)
        :Hủy yêu cầu;
        stop
    endif

endif

if (Có thao tác đặc biệt?) then (Có)

    if (Chuyển bàn?) then (Có)
        :Chuyển bàn;

    else (Không)

        if (Ghép phiếu?) then (Có)
            :Ghép phiếu;

        else (Không)

            if (Tách phiếu?) then (Có)
                :Tách phiếu;

            else (Không)

                if (Tách món?) then (Có)
                    :Tách món;

                else (Không)

                    if (In lại bếp?) then (Có)
                        :In lại bếp;

                    else (Không)
                        :Hủy phiếu;
                        stop
                    endif

                endif

            endif

        endif

    endif

endif

:Chọn món;

:Nhập thông tin món;
note right

- Tên món
- Số lượng
- Ghi chú chế biến
  end note

:Gửi Order đến POS;

|Hệ thống POS|

:Phân loại món;

if (Salad?) then (Có)

    :Gửi Bếp Salad;

else (Không)

    if (Món thịt?) then (Có)

        :Gửi Bếp Thịt;

    else (Không)

        if (Món nóng?) then (Có)

            :Gửi Bếp Nóng;

        else (Khác)

            :Gửi Bếp Alacarte;

        endif

    endif

endif

:Tạo phiếu Order;

:In phiếu bếp;

note right
Tên món
Số lượng
Ghi chú
Bàn
Thời gian
end note

|Bếp|

:Bếp nhận Order;
:Máy in in phiếu;
:Xem phiếu;
:Chế biến món;
:Hoàn thành món;

|Khách hàng|

:Chuyển sang quy trình phục vụ;

stop

@enduml
