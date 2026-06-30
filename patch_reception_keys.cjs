const fs = require('fs');

const file = 'C:\\Users\\Per\\Downloads\\noMoreF2TECH\\src\\stores\\useLanguageStore.ts';
let content = fs.readFileSync(file, 'utf8');

const keys = {
  'reception.dashboard.loading_data': { vi: 'Đang tải dữ liệu...', en: 'Loading data...', ja: 'データを読み込んでいます...' },
  'reception.dashboard.shift_overview': { vi: 'Tổng quan ca', en: 'Shift Overview', ja: 'シフト概要' },
  'reception.dashboard.today': { vi: 'Hôm nay', en: 'Today', ja: '今日' },
  'reception.dashboard.tables_in_use': { vi: 'Bàn đang phục vụ', en: 'Tables in Use', ja: '利用中のテーブル' },
  'reception.dashboard.pending_checkout': { vi: 'Chờ thanh toán', en: 'Pending Checkout', ja: '会計待ち' },
  'reception.dashboard.today_reservations': { vi: 'Đặt bàn hôm nay', en: 'Today Reservations', ja: '本日の予約' },
  'reception.dashboard.active_shift': { vi: 'Ca đang mở', en: 'Active Shift', ja: 'アクティブシフト' },
  'reception.dashboard.opened_at': { vi: 'Mở lúc', en: 'Opened at', ja: 'オープン時間' },
  'reception.dashboard.opening_cash': { vi: 'Tiền mặt đầu ca', en: 'Opening Cash', ja: '釣銭準備金' },
  'reception.dashboard.needs_action_now': { vi: 'Cần xử lý ngay', en: 'Needs Action Now', ja: 'すぐに対応が必要' },
  'reception.dashboard.checkout_request': { vi: 'Yêu cầu thanh toán', en: 'Checkout Request', ja: '会計リクエスト' },
  'reception.dashboard.guests': { vi: 'khách', en: 'guests', ja: '名' },
  'reception.dashboard.proceed_to_checkout': { vi: 'Tiến hành thanh toán', en: 'Proceed to Checkout', ja: '会計に進む' },
  'reception.dashboard.no_checkout_requests': { vi: 'Chưa có yêu cầu thanh toán nào.', en: 'No checkout requests.', ja: '会計リクエストはありません。' },
  'reception.dashboard.tables_serving_list': { vi: 'Danh sách bàn đang phục vụ', en: 'Tables Serving List', ja: '利用中テーブルリスト' },
  'reception.dashboard.table_code': { vi: 'Mã bàn', en: 'Table Code', ja: 'テーブルコード' },
  'reception.dashboard.guest_col': { vi: 'Khách', en: 'Guests', ja: '人数' },
  'reception.dashboard.time_col': { vi: 'Thời gian', en: 'Time', ja: '時間' },
  'reception.dashboard.status_col': { vi: 'Trạng thái', en: 'Status', ja: 'ステータス' },
  'reception.dashboard.invoice_col': { vi: 'Hóa đơn', en: 'Invoice', ja: '請求書' },
  'reception.dashboard.dining': { vi: 'Đang dùng bữa', en: 'Dining', ja: 'お食事中' },
  'reception.dashboard.checkout_action': { vi: 'Thanh toán', en: 'Checkout', ja: '会計' },
  'reception.dashboard.no_tables_serving': { vi: 'Không có bàn nào đang phục vụ', en: 'No tables serving', ja: '利用中のテーブルはありません' },
  'reception.dashboard.booking_code': { vi: 'Mã đặt bàn', en: 'Booking Code', ja: '予約コード' },
  'reception.dashboard.hour': { vi: 'Giờ', en: 'Hour', ja: '時間' },
  'reception.dashboard.num_guests': { vi: 'Số khách', en: 'No. Guests', ja: '人数' },
  'reception.dashboard.no_bookings_today': { vi: 'Không có đặt bàn nào trong ngày hôm nay', en: 'No bookings for today', ja: '本日の予約はありません' },
  'reception.dashboard.no_branch_error': { vi: 'Lỗi: Không tìm thấy thông tin chi nhánh.', en: 'Error: Branch not found.', ja: 'エラー：店舗が見つかりません。' }
};

for (const lang of ['vi', 'en', 'ja']) {
  const match = content.match(new RegExp(`(\\b${lang}:\\s*\\{[\\s\\S]*?)(\\n\\s*\\},)`));
  if (match) {
    let toAdd = '\n    // Reception Dashboard\n';
    for (const k in keys) {
      toAdd += `    '${k}': '${keys[k][lang].replace(/'/g, "\\'")}',\n`;
    }
    const replaced = match[1] + toAdd + match[2];
    content = content.replace(match[0], replaced);
  }
}

fs.writeFileSync(file, content);
console.log('Patched useLanguageStore.ts');
