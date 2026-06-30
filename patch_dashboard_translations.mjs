import fs from 'fs';

const dictDashboard = {
  'reception.dashboard.loading_data': { vi: 'Đang tải dữ liệu', en: 'Loading data', ja: 'データを読み込み中' },
  'reception.dashboard.shift_overview': { vi: 'Tổng quan ca làm việc', en: 'Shift Overview', ja: 'シフト概要' },
  'reception.dashboard.today': { vi: 'Hôm nay', en: 'Today', ja: '今日' },
  'reception.dashboard.tables_in_use': { vi: 'Bàn đang sử dụng', en: 'Tables In Use', ja: '利用中のテーブル' },
  'reception.dashboard.pending_checkout': { vi: 'Chờ thanh toán', en: 'Pending Checkout', ja: 'チェックアウト待ち' },
  'reception.dashboard.today_reservations': { vi: 'Đặt bàn hôm nay', en: 'Today Reservations', ja: '今日の予約' },
  'reception.dashboard.active_shift': { vi: 'Ca hiện tại', en: 'Active Shift', ja: '現在のアクティブなシフト' },
  'reception.dashboard.opened_at': { vi: 'Mở lúc', en: 'Opened at', ja: '開始時間' },
  'reception.dashboard.opening_cash': { vi: 'Tiền mặt đầu ca', en: 'Opening cash', ja: '釣銭準備金' },
  'reception.dashboard.needs_action_now': { vi: 'Cần xử lý ngay', en: 'Needs Action Now', ja: '要対応' },
  'reception.dashboard.checkout_request': { vi: 'Yêu cầu thanh toán', en: 'Checkout Request', ja: 'チェックアウト要求' },
  'reception.dashboard.guests': { vi: 'Khách', en: 'Guests', ja: 'ゲスト' },
  'reception.dashboard.proceed_to_checkout': { vi: 'Tiến hành thanh toán', en: 'Proceed to checkout', ja: '会計に進む' },
  'reception.dashboard.no_checkout_requests': { vi: 'Không có yêu cầu thanh toán', en: 'No checkout requests', ja: 'チェックアウト要求なし' },
  'reception.dashboard.tables_serving_list': { vi: 'Danh sách bàn đang phục vụ', en: 'Tables Serving List', ja: '提供中のテーブル' },
  'reception.dashboard.table_code': { vi: 'Mã bàn', en: 'Table', ja: 'テーブル' },
  'reception.dashboard.guest_col': { vi: 'Khách', en: 'Guests', ja: 'ゲスト' },
  'reception.dashboard.time_col': { vi: 'Thời gian', en: 'Time', ja: '時間' },
  'reception.dashboard.status_col': { vi: 'Trạng thái', en: 'Status', ja: 'ステータス' },
  'reception.dashboard.invoice_col': { vi: 'Hóa đơn', en: 'Invoice', ja: '請求書' },
  'reception.dashboard.dining': { vi: 'Đang dùng bữa', en: 'Dining', ja: '食事中' },
  'reception.dashboard.checkout_action': { vi: 'Thanh toán', en: 'Checkout', ja: '会計' },
  'reception.dashboard.no_tables_serving': { vi: 'Không có bàn nào đang phục vụ', en: 'No tables serving', ja: '提供中のテーブルはありません' },
  'reception.dashboard.booking_code': { vi: 'Mã đặt', en: 'Booking', ja: '予約コード' },
  'reception.dashboard.hour': { vi: 'Giờ', en: 'Hour', ja: '時間' },
  'reception.dashboard.num_guests': { vi: 'Số khách', en: 'Guests', ja: 'ゲスト数' },
  'reception.dashboard.no_bookings_today': { vi: 'Không có đặt bàn hôm nay', en: 'No bookings today', ja: '今日の予約はありません' },
  'reception.dashboard.no_branch_error': { vi: 'Lỗi: Không tìm thấy chi nhánh', en: 'Error: No branch found', ja: 'エラー：店舗が見つかりません' }
};

const updateLocale = (lang) => {
  let content = fs.readFileSync(`src/locales/${lang}.ts`, 'utf-8');
  for (const [key, tr] of Object.entries(dictDashboard)) {
    const val = tr[lang];
    const regex = new RegExp(`'${key}':\\s*'(.*?)'`, 'g');
    if (content.match(regex)) {
      content = content.replace(regex, `'${key}': '${val}'`);
    } else {
      // If not exists, insert it
      content = content.replace(/}\s*$/, `  '${key}': '${val}',\n}\n`);
    }
  }
  fs.writeFileSync(`src/locales/${lang}.ts`, content);
}

updateLocale('vi');
updateLocale('en');
updateLocale('ja');

console.log('Fixed reception.dashboard translation strings perfectly');
