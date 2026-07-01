-- Thêm cột JSONB vào menu_items để lưu thông tin nguyên liệu hiển thị cho khách hàng
-- Yêu cầu: Đơn giản, dùng cho UI đọc, không mapping relational với bảng ingredients trong kho.

ALTER TABLE public.menu_items
ADD COLUMN IF NOT EXISTS ingredients jsonb NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.menu_items.ingredients IS 'Mảng JSON chứa tên các nguyên liệu để hiển thị cho khách (VD: ["Thịt bò", "Hành tây"]). Không liên kết tự động với kho.';
