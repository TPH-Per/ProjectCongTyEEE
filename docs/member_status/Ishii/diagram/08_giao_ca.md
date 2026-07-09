# MODULE 8: GIAO CA (SHIFT HANDOVER)

## 1. Tổng quan
- **Mục đích:** Đảm bảo bàn giao tiền mặt và các giao dịch thanh toán không tiền mặt (thẻ, chuyển khoản, voucher) chính xác giữa các ca làm việc, kiểm soát thất thoát và lưu trữ báo cáo giao ca đầy đủ.
- **Phạm vi:** Kiểm tra trạng thái hóa đơn, đối chiếu tiền mặt thực tế và in báo cáo đóng ca.
- **Người dùng mục tiêu:** Thu ngân, Quản lý.

## 2. Actors tham gia
- **Thu ngân:** Thực hiện kiểm đếm, kê khai số tiền thực tế thu được trong ca, lập báo cáo giải trình nếu có chênh lệch.
- **Quản lý:** Giám sát quá trình giao ca, duyệt các ca có chênh lệch tiền mặt lớn.
- **Hệ thống:** Kiểm tra điều kiện đóng ca, tự động đối chiếu số liệu hệ thống và số liệu thực tế kê khai, khóa dữ liệu ca làm việc.

## 3. Luồng nghiệp vụ chính & Swimlanes (Activity Diagram)

```mermaid
flowchart LR
    subgraph Lane_Cashier ["Thu ngân"]
        C1("1. Yêu cầu đóng ca & bắt đầu giao ca")
        C2("3. Nhập số tiền mặt thực tế kiểm đếm & kê khai")
        C3("6. Nhập giải trình (Nếu chênh lệch > 500k)")
        C4("8. Xác nhận đóng ca & in báo cáo giao ca (PDF)")
    end

    subgraph Lane_Manager ["Quản lý"]
        M1("7. Kiểm tra & duyệt biên bản giao ca")
    end

    subgraph Lane_System ["Hệ thống POS"]
        S1("2. Kiểm tra hóa đơn chưa thanh toán")
        S2("4. Đối chiếu số liệu hệ thống & tính chênh lệch")
        S3("5. Kiểm tra điều kiện chênh lệch (> 500k)")
        S4("9. Khóa dữ liệu ca làm việc")
    end

    C1 ==> S1
    S1 -.-> C2
    C2 ==> S2
    S2 ==> S3
    S3 -.-> C3
    C3 -.-> M1
    M1 -.-> C4
    C4 ==> S4

    style Lane_Cashier fill:transparent,stroke:#ccc,stroke-width:2px,stroke-dasharray: 5 5
    style Lane_Manager fill:transparent,stroke:#ccc,stroke-width:2px,stroke-dasharray: 5 5
    style Lane_System fill:transparent,stroke:#ccc,stroke-width:2px,stroke-dasharray: 5 5

    style C1 fill:#e6fffa,stroke:#319795,stroke-width:1px
    style C2 fill:#e6fffa,stroke:#319795,stroke-width:1px
    style C3 fill:#e6fffa,stroke:#319795,stroke-width:1px
    style C4 fill:#e6fffa,stroke:#319795,stroke-width:1px

    style M1 fill:#fffaf0,stroke:#dd6b20,stroke-width:1px

    style S1 fill:#ebf8ff,stroke:#3182ce,stroke-width:1px
    style S2 fill:#ebf8ff,stroke:#3182ce,stroke-width:1px
    style S3 fill:#ebf8ff,stroke:#3182ce,stroke-width:1px
    style S4 fill:#ebf8ff,stroke:#3182ce,stroke-width:1px
```

## 4. Use Cases
- **UC-015: Bàn giao ca làm việc**
  - **Actor:** Thu ngân
  - **Precondition:** Ca làm việc hiện tại đang mở.
  - **Main flow:**
    1. Thu ngân chọn "Đóng ca".
    2. Nhập số tiền mặt thực tế tại két.
    3. Nhập số lượng voucher nhận được.
    4. Hệ thống so sánh với số liệu ghi nhận trên POS.
    5. Đóng ca và in phiếu bàn giao ca (PDF).
  - **Postcondition:** Trạng thái ca chuyển sang Đã đóng, thu ngân đăng xuất.

## 5. Business Rules
- **Nghiêm cấm:** Không thể đóng ca nếu còn bất kỳ phiếu/order nào ở trạng thái "Đang order" hoặc "Chờ thanh toán" (phải thanh toán hoặc hủy trước khi đóng).
- Nếu phát hiện chênh lệch tiền mặt giữa thực tế kê khai và hệ thống **lớn hơn 500,000 VNĐ**, thu ngân bắt buộc phải nhập lý do giải trình và Quản lý phải ký duyệt.
- Báo cáo giao ca sau khi đã đóng và khóa **không được phép chỉnh sửa dưới bất kỳ hình thức nào** để đảm bảo tính minh bạch tài chính.

## 6. Dữ liệu
- **Đầu vào:** Số dư đầu ca, số tiền mặt đếm thực tế, số lượng voucher.
- **Đầu ra:** Biên bản giao ca PDF (bao gồm doanh thu theo giờ, VAT, giảm giá, chênh lệch), trạng thái ca đóng.
