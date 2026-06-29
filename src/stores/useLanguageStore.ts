import { defineStore } from 'pinia';
import { setI18nLocale, i18n } from '@/locales';

export type Lang = 'vi' | 'en' | 'ja';

const dict: Record<Lang, Record<string, string>> = {
  vi: {
    // Inventory
    'inventory.title':                'Quản Lý Kho',
    'inventory.lowStock':             'Tồn kho thấp',
    'inventory.expiryWarning':        'Sắp hết hạn',
    'inventory.addStock':             'Nhập kho',
    'inventory.adjust':               'Điều chỉnh',
    'inventory.unit':                 'ĐVT',
    'inventory.quantity':             'Số lượng',
    'inventory.threshold':            'Ngưỡng cảnh báo',
    'inventory.search':               'Tìm nguyên liệu...',
    // Requisition
    'req.title':                      'Phiếu Yêu Cầu',
    'req.create':                     'Tạo phiếu',
    'req.status.pending':             'Chờ duyệt',
    'req.status.approved':            'Đã duyệt',
    'req.status.rejected':            'Từ chối',
    'req.status.processing':          'Đang xử lý',
    'req.status.completed':           'Hoàn thành',
    'req.status.cancelled':           'Đã hủy',
    'req.type.outbound':              'Xuất kho',
    'req.type.inbound':               'Nhập kho',
    'req.type.return':                'Trả hàng',
    'req.approve':                    'Duyệt',
    'req.reject':                     'Từ chối',
    'req.confirm_delivery':           'Xác nhận nhận hàng',
    'req.rejection_reason':           'Lý do từ chối',
    'req.needed_by':                  'Cần trước ngày',
    // Shift
    'shift.start':                    'Bắt đầu ca',
    'shift.close':                    'Đóng ca',
    'shift.handover':                 'Bàn giao ca',
    'shift.type.morning':             'Ca Sáng',
    'shift.type.afternoon':           'Ca Chiều',
    'shift.type.evening':             'Ca Tối',
    'shift.count_ingredients':        'Kiểm kê nguyên liệu',
    'shift.discrepancy':              'Chênh lệch',
    // Tablet
    'tablet.touch_to_start':          'Chạm để bắt đầu',
    'tablet.select_language':         'Chọn ngôn ngữ',
    // Branch
    'branch.title':                   'Chi Nhánh',
    'branch.add':                     'Thêm chi nhánh',
    'branch.edit':                    'Chỉnh sửa',
    'branch.deactivate':              'Vô hiệu hóa',
    'branch.capacity':                'Sức chứa',
    'branch.manager':                 'Quản lý',
    // Integrations
    'integration.title':              'Tích hợp',
    'integration.payment':            'Thanh toán',
    'integration.delivery':           'Giao hàng',
    'integration.test_connection':    'Kiểm tra kết nối',
    'integration.api_key':            'API Key',
    'integration.webhook':            'Webhook URL',
    // Common
    'common.save':                    'Lưu',
    'common.cancel':                  'Hủy',
    'common.confirm':                 'Xác nhận',
    'common.loading':                 'Đang tải...',
    'common.error':                   'Lỗi',
    'common.success':                 'Thành công',
    'common.search':                  'Tìm kiếm',
    'common.no_data':                 'Không có dữ liệu',
  },
  en: {
    'inventory.title':                'Inventory Management',
    'inventory.lowStock':             'Low Stock',
    'inventory.expiryWarning':        'Expiring Soon',
    'inventory.addStock':             'Add Stock',
    'inventory.adjust':               'Adjust Count',
    'inventory.unit':                 'Unit',
    'inventory.quantity':             'Quantity',
    'inventory.threshold':            'Alert Threshold',
    'inventory.search':               'Search ingredients...',
    'req.title':                      'Requisitions',
    'req.create':                     'New Requisition',
    'req.status.pending':             'Pending Approval',
    'req.status.approved':            'Approved',
    'req.status.rejected':            'Rejected',
    'req.status.processing':          'Processing',
    'req.status.completed':           'Completed',
    'req.status.cancelled':           'Cancelled',
    'req.type.outbound':              'Outbound',
    'req.type.inbound':               'Inbound',
    'req.type.return':                'Return',
    'req.approve':                    'Approve',
    'req.reject':                     'Reject',
    'req.confirm_delivery':           'Confirm Delivery',
    'req.rejection_reason':           'Reason for rejection',
    'req.needed_by':                  'Needed by',
    'shift.start':                    'Start Shift',
    'shift.close':                    'Close Shift',
    'shift.handover':                 'Shift Handover',
    'shift.type.morning':             'Morning Shift',
    'shift.type.afternoon':           'Afternoon Shift',
    'shift.type.evening':             'Evening Shift',
    'shift.count_ingredients':        'Count Ingredients',
    'shift.discrepancy':              'Discrepancy',
    'tablet.touch_to_start':          'Touch to Begin',
    'tablet.select_language':         'Select Language',
    'branch.title':                   'Branches',
    'branch.add':                     'Add Branch',
    'branch.edit':                    'Edit',
    'branch.deactivate':              'Deactivate',
    'branch.capacity':                'Capacity',
    'branch.manager':                 'Manager',
    'integration.title':              'Integrations',
    'integration.payment':            'Payment',
    'integration.delivery':           'Delivery',
    'integration.test_connection':    'Test Connection',
    'integration.api_key':            'API Key',
    'integration.webhook':            'Webhook URL',
    'common.save':                    'Save',
    'common.cancel':                  'Cancel',
    'common.confirm':                 'Confirm',
    'common.loading':                 'Loading...',
    'common.error':                   'Error',
    'common.success':                 'Success',
    'common.search':                  'Search',
    'common.no_data':                 'No data',
  },
  ja: {
    'inventory.title':                '在庫管理',
    'inventory.lowStock':             '在庫不足',
    'inventory.expiryWarning':        '期限切れ間近',
    'inventory.addStock':             '在庫追加',
    'inventory.adjust':               '在庫調整',
    'inventory.unit':                 '単位',
    'inventory.quantity':             '数量',
    'inventory.threshold':            '警告閾値',
    'inventory.search':               '食材を検索...',
    'req.title':                      '請求書',
    'req.create':                     '請求書作成',
    'req.status.pending':             '承認待ち',
    'req.status.approved':            '承認済み',
    'req.status.rejected':            '却下',
    'req.status.processing':          '処理中',
    'req.status.completed':           '完了',
    'req.status.cancelled':           'キャンセル',
    'req.type.outbound':              '出庫',
    'req.type.inbound':               '入庫',
    'req.type.return':                '返品',
    'req.approve':                    '承認',
    'req.reject':                     '却下',
    'req.confirm_delivery':           '納品確認',
    'req.rejection_reason':           '却下理由',
    'req.needed_by':                  '必要な日付',
    'shift.start':                    'シフト開始',
    'shift.close':                    'シフト終了',
    'shift.handover':                 '引き継ぎ',
    'shift.type.morning':             '朝番',
    'shift.type.afternoon':           '昼番',
    'shift.type.evening':             '夜番',
    'shift.count_ingredients':        '在庫確認',
    'shift.discrepancy':              '差異',
    'tablet.touch_to_start':          'タッチしてください',
    'tablet.select_language':         '言語を選択',
    'branch.title':                   '店舗管理',
    'branch.add':                     '店舗を追加',
    'branch.edit':                    '編集',
    'branch.deactivate':              '無効化',
    'branch.capacity':                '収容人数',
    'branch.manager':                 '店長',
    'integration.title':              '外部連携',
    'integration.payment':            '決済',
    'integration.delivery':           '配達',
    'integration.test_connection':    '接続テスト',
    'integration.api_key':            'APIキー',
    'integration.webhook':            'Webhook URL',
    'common.save':                    '保存',
    'common.cancel':                  'キャンセル',
    'common.confirm':                 '確認',
    'common.loading':                 '読み込み中...',
    'common.error':                   'エラー',
    'common.success':                 '成功',
    'common.search':                  '検索',
    'common.no_data':                 'データなし',
  }
};

export const useLanguageStore = defineStore('language', {
  state: () => ({
    lang: (localStorage.getItem('app_lang') ?? 'vi') as Lang,
  }),
  getters: {
    t: (state) => (key: string, defaultOrParams?: string | Record<string, string>, params?: Record<string, string>): string => {
      // Import the global i18n instance
      // Note: We use dynamic import or get it from global if possible to avoid circular dependency
      // but here we can just use it if we import it at the top.
      const hasI18nKey = i18n.global.te(key, state.lang);
      if (hasI18nKey) {
         if (typeof defaultOrParams === 'object') {
             return i18n.global.t(key, defaultOrParams) as string;
         } else if (params) {
             return i18n.global.t(key, params) as string;
         } else {
             return i18n.global.t(key) as string;
         }
      }

      // Fallback 1: Use internal dict
      let val = dict[state.lang]?.[key] ?? dict['vi']?.[key];
      
      // Fallback 2: Use provided default string if available
      if (!val && typeof defaultOrParams === 'string') {
          val = defaultOrParams;
      }
      
      // Fallback 3: Return key
      if (!val) {
          val = key;
      }

      const actualParams = typeof defaultOrParams === 'object' ? defaultOrParams : params;
      if (actualParams) {
        for (const [k, v] of Object.entries(actualParams)) {
          val = val.replace(`{${k}}`, v as string);
        }
      }
      return val;
    },
    langOptions: () => [
      { code: 'vi', label: 'Tiếng Việt', flag: '🇻🇳' },
      { code: 'en', label: 'English',    flag: '🇬🇧' },
      { code: 'ja', label: '日本語',      flag: '🇯🇵' },
    ] as const,
  },
  actions: {
    setLanguage(lang: Lang) {
      this.lang = lang;
      localStorage.setItem('app_lang', lang);
      setI18nLocale(lang);
    }
  }
});
