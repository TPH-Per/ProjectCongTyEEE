// File: src/data/mockMenuData.ts
// ─────────────────────────────────────────────────────────────────────────────
// Normalized relational mock data for the Menu Management module.
//
// Hierarchy:  Category → SubCategory (nullable) → Item
//
// ⚠️ Key rules:
//  • sub_category_id is NULLABLE — an item may belong directly to a Category.
//  • is_active = false  →  permanently hidden from POS (Inactive / locked).
//  • is_sold_out = true →  temporarily out of stock, still visible but dimmed.
//  • Delete = soft-delete (flip is_active), never remove from the array.
// ─────────────────────────────────────────────────────────────────────────────

// ─── Interfaces ──────────────────────────────────────────────────────────────

export interface MenuCategory {
  id: string
  name: string
  name_en: string
  name_jp: string
  icon: string
  color: string
  sort_order: number
  is_active: boolean
  is_visible_on_pos: boolean
}

export interface MenuSubCategory {
  id: string
  category_id: string
  name: string
  sort_order: number
  is_active: boolean
}

export interface MenuItem {
  id: string
  name: string
  name_en: string
  name_jp: string
  sku: string
  barcode: string
  image_url: string
  description: string
  category_id: string
  /** Nullable — null means the item belongs directly to its Category. */
  sub_category_id: string | null
  base_price: number
  /** Tax percentage: 0, 8, or 10. */
  tax_rate: number
  is_active: boolean
  is_sold_out: boolean
  /** Kitchen printer target: 'bar' | 'kitchen-hot' | 'kitchen-cold' | null. */
  kitchen_printer_id: string | null
  sort_order: number
  button_size: 'sm' | 'md' | 'lg'
  button_color: string
}

export interface KitchenPrinter {
  id: string
  name: string
  name_en: string
}

// ─── Kitchen Printers ────────────────────────────────────────────────────────

export const kitchenPrinters: KitchenPrinter[] = [
  { id: 'bar', name: 'Quầy Bar', name_en: 'Bar' },
  { id: 'kitchen-hot', name: 'Bếp Nóng', name_en: 'Hot Kitchen' },
  { id: 'kitchen-cold', name: 'Bếp Nguội', name_en: 'Cold Kitchen' },
]

// ─── Tax Rate Options ─────────────────────────────────────────────────────────

export const taxRateOptions = [
  { value: 0, label: '0% — Miễn thuế' },
  { value: 8, label: '8% — Thuế suất giảm' },
  { value: 10, label: '10% — Thuế suất tiêu chuẩn' },
]

// ─── Button Size Options ──────────────────────────────────────────────────────

export const buttonSizeOptions: { value: MenuItem['button_size']; label: string }[] = [
  { value: 'sm', label: 'Nhỏ (1×1)' },
  { value: 'md', label: 'Vừa (2×1)' },
  { value: 'lg', label: 'Lớn (2×2)' },
]

// ─── Button Color Palette ─────────────────────────────────────────────────────

export const buttonColorOptions = [
  { value: '#F54C0D', label: 'Cam thương hiệu' },
  { value: '#EF4444', label: 'Đỏ' },
  { value: '#F59E0B', label: 'Vàng cam' },
  { value: '#10B981', label: 'Xanh lá' },
  { value: '#3B82F6', label: 'Xanh dương' },
  { value: '#8B5CF6', label: 'Tím' },
  { value: '#EC4899', label: 'Hồng' },
  { value: '#6B7280', label: 'Xám' },
]

// ─── Categories ───────────────────────────────────────────────────────────────

export const mockCategories: MenuCategory[] = [
  {
    id: 'cat-buffet',
    name: 'Gói Buffet',
    name_en: 'Buffet Packages',
    name_jp: 'ビュッフェ',
    icon: '🍱',
    color: '#F59E0B',
    sort_order: 1,
    is_active: true,
    is_visible_on_pos: true,
  },
  {
    id: 'cat-food',
    name: 'Thức Ăn',
    name_en: 'Food',
    name_jp: 'フード',
    icon: '🥩',
    color: '#EF4444',
    sort_order: 2,
    is_active: true,
    is_visible_on_pos: true,
  },
  {
    id: 'cat-drinks',
    name: 'Đồ Uống',
    name_en: 'Drinks',
    name_jp: 'ドリンク',
    icon: '🍺',
    color: '#3B82F6',
    sort_order: 3,
    is_active: true,
    is_visible_on_pos: true,
  },
  {
    id: 'cat-other',
    name: 'Khác',
    name_en: 'Other',
    name_jp: 'その他',
    icon: '🧾',
    color: '#6B7280',
    sort_order: 4,
    is_active: true,
    is_visible_on_pos: true,
  },
]

// ─── SubCategories ────────────────────────────────────────────────────────────

export const mockSubCategories: MenuSubCategory[] = [
  // ── Thức Ăn ──
  { id: 'sub-wagyu', category_id: 'cat-food', name: 'Wagyu', sort_order: 1, is_active: true },
  { id: 'sub-beef', category_id: 'cat-food', name: 'Bò', sort_order: 2, is_active: true },
  { id: 'sub-pork', category_id: 'cat-food', name: 'Heo', sort_order: 3, is_active: true },
  { id: 'sub-chicken', category_id: 'cat-food', name: 'Gà', sort_order: 4, is_active: true },
  { id: 'sub-grill', category_id: 'cat-food', name: 'Đồ Nướng', sort_order: 5, is_active: true },
  { id: 'sub-appetizer', category_id: 'cat-food', name: 'Khai Vị', sort_order: 6, is_active: true },
  { id: 'sub-salad', category_id: 'cat-food', name: 'Xà Lách', sort_order: 7, is_active: true },
  { id: 'sub-rice', category_id: 'cat-food', name: 'Cơm', sort_order: 8, is_active: true },
  { id: 'sub-soup', category_id: 'cat-food', name: 'Súp', sort_order: 9, is_active: true },
  { id: 'sub-dessert', category_id: 'cat-food', name: 'Tráng Miệng', sort_order: 10, is_active: true },
  // ── Đồ Uống ──
  { id: 'sub-beer', category_id: 'cat-drinks', name: 'Bia', sort_order: 1, is_active: true },
  { id: 'sub-sake', category_id: 'cat-drinks', name: 'Rượu Sake & Wine', sort_order: 2, is_active: true },
  { id: 'sub-soft-drink', category_id: 'cat-drinks', name: 'Nước Ngọt', sort_order: 3, is_active: true },
  { id: 'sub-tea', category_id: 'cat-drinks', name: 'Trà', sort_order: 4, is_active: true },
]

// ─── Items ───────────────────────────────────────────────────────────────────
// Mix of items WITH sub_category_id and items WITHOUT (null = direct category).

export const mockItems: MenuItem[] = [
  // ═══ BUFFET (directly under category — sub_category_id = null) ═══
  {
    id: 'item-001',
    name: 'Vé Buffet Người Lớn 1390',
    name_en: 'Adult Buffet Ticket 1390',
    name_jp: '大人ビュッフェチケット 1390',
    sku: 'BF-1390-ADT',
    barcode: '8935000000011',
    image_url: '',
    description: 'Gói buffet tiêu chuẩn cho người lớn — 90 phút.',
    category_id: 'cat-buffet',
    sub_category_id: null,
    base_price: 1390000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: null,
    sort_order: 1,
    button_size: 'lg',
    button_color: '#F59E0B',
  },
  {
    id: 'item-002',
    name: 'Vé Buffet Trẻ Em 680',
    name_en: 'Child Buffet Ticket 680',
    name_jp: '子供ビュッフェチケット 680',
    sku: 'BF-680-CHD',
    barcode: '8935000000028',
    image_url: '',
    description: 'Gói buffet cho trẻ em (dưới 12 tuổi) — 90 phút.',
    category_id: 'cat-buffet',
    sub_category_id: null,
    base_price: 680000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: null,
    sort_order: 2,
    button_size: 'lg',
    button_color: '#F59E0B',
  },
  {
    id: 'item-003',
    name: 'Vé Buffet Người Lớn 980',
    name_en: 'Adult Buffet Ticket 980',
    name_jp: '大人ビュッフェチケット 980',
    sku: 'BF-980-ADT',
    barcode: '8935000000035',
    image_url: '',
    description: 'Gói buffet tiết kiệm cho người lớn — 90 phút.',
    category_id: 'cat-buffet',
    sub_category_id: null,
    base_price: 980000,
    tax_rate: 10,
    is_active: false,
    is_sold_out: false,
    kitchen_printer_id: null,
    sort_order: 3,
    button_size: 'lg',
    button_color: '#6B7280',
  },

  // ═══ THỨC ĂN — Wagyu ═══
  {
    id: 'item-004',
    name: 'Wagyu A5 Sirloin 150g',
    name_en: 'Wagyu A5 Sirloin 150g',
    name_jp: '和牛A5サーロイン 150g',
    sku: 'WGY-SL-150',
    barcode: '8935000000042',
    image_url: '',
    description: 'Wagyu A5 Nhật Bản chuẩn, cắt sirloin 150g, nướng than hoa.',
    category_id: 'cat-food',
    sub_category_id: 'sub-wagyu',
    base_price: 850000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'kitchen-hot',
    sort_order: 1,
    button_size: 'md',
    button_color: '#EF4444',
  },
  {
    id: 'item-005',
    name: 'Wagyu A5 Ribeye 200g',
    name_en: 'Wagyu A5 Ribeye 200g',
    name_jp: '和牛A5リブアイ 200g',
    sku: 'WGY-RB-200',
    barcode: '8935000000059',
    image_url: '',
    description: 'Wagyu A5 Ribeye 200g, vân mỡ đan xen hoàn hảo.',
    category_id: 'cat-food',
    sub_category_id: 'sub-wagyu',
    base_price: 1200000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: true,
    kitchen_printer_id: 'kitchen-hot',
    sort_order: 2,
    button_size: 'md',
    button_color: '#EF4444',
  },
  {
    id: 'item-006',
    name: 'Wagyu A5 Tenderloin 120g',
    name_en: 'Wagyu A5 Tenderloin 120g',
    name_jp: '和牛A5テンダーロイン 120g',
    sku: 'WGY-TL-120',
    barcode: '8935000000066',
    image_url: '',
    description: 'Wagyu A5 Tenderloin — phần mềm nhất, 120g.',
    category_id: 'cat-food',
    sub_category_id: 'sub-wagyu',
    base_price: 980000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'kitchen-hot',
    sort_order: 3,
    button_size: 'md',
    button_color: '#EF4444',
  },

  // ═══ THỨC ĂN — Bò ═══
  {
    id: 'item-007',
    name: 'Bò Mỹ Sirloin 200g',
    name_en: 'US Beef Sirloin 200g',
    name_jp: '米牛サーロイン 200g',
    sku: 'BF-US-SL-200',
    barcode: '8935000000073',
    image_url: '',
    description: 'Bò Mỹ nhập khẩu, sirloin 200g, ướp muối tiêu.',
    category_id: 'cat-food',
    sub_category_id: 'sub-beef',
    base_price: 320000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'kitchen-hot',
    sort_order: 1,
    button_size: 'md',
    button_color: '#F54C0D',
  },
  {
    id: 'item-008',
    name: 'Bò Úc Short Rib 250g',
    name_en: 'AU Beef Short Rib 250g',
    name_jp: '豪牛カルビ 250g',
    sku: 'BF-AU-SR-250',
    barcode: '8935000000080',
    image_url: '',
    description: 'Sườn bò Úc Short Rib, ướp sốt BBQ đặc biệt.',
    category_id: 'cat-food',
    sub_category_id: 'sub-beef',
    base_price: 380000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'kitchen-hot',
    sort_order: 2,
    button_size: 'md',
    button_color: '#F54C0D',
  },

  // ═══ THỨC ĂN — Heo ═══
  {
    id: 'item-009',
    name: 'Ba Chỉ Heo 200g',
    name_en: 'Pork Belly 200g',
    name_jp: '豚バラ 200g',
    sku: 'PK-BL-200',
    barcode: '8935000000097',
    image_url: '',
    description: 'Ba chỉ heo cắt lát mỏng, nướng than hoa.',
    category_id: 'cat-food',
    sub_category_id: 'sub-pork',
    base_price: 160000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'kitchen-hot',
    sort_order: 1,
    button_size: 'md',
    button_color: '#F59E0B',
  },
  {
    id: 'item-010',
    name: 'Sườn Heo Nướng Muối 300g',
    name_en: 'Grilled Pork Ribs 300g',
    name_jp: '豚カルビ焼き 300g',
    sku: 'PK-RB-300',
    barcode: '8935000000103',
    image_url: '',
    description: 'Sườn heo non ướp muối tiêu, nướng than.',
    category_id: 'cat-food',
    sub_category_id: 'sub-pork',
    base_price: 220000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: true,
    kitchen_printer_id: 'kitchen-hot',
    sort_order: 2,
    button_size: 'md',
    button_color: '#F59E0B',
  },

  // ═══ THỨC ĂN — Gà ═══
  {
    id: 'item-011',
    name: 'Đùi Gà Nướng Muối 250g',
    name_en: 'Grilled Chicken Thigh 250g',
    name_jp: '鶏もも焼き 250g',
    sku: 'CK-TH-250',
    barcode: '8935000000110',
    image_url: '',
    description: 'Đùi gà debone ướp muối tiêu, nướng than hoa.',
    category_id: 'cat-food',
    sub_category_id: 'sub-chicken',
    base_price: 140000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'kitchen-hot',
    sort_order: 1,
    button_size: 'md',
    button_color: '#F59E0B',
  },

  // ═══ THỨC ĂN — Khai Vị ═══
  {
    id: 'item-012',
    name: 'Salad Cá Hồi Fresh',
    name_en: 'Fresh Salmon Salad',
    name_jp: '鮭サラダ',
    sku: 'AP-SAL-SF',
    barcode: '8935000000127',
    image_url: '',
    description: 'Salad cá hồi tươi, sốt mè rang.',
    category_id: 'cat-food',
    sub_category_id: 'sub-appetizer',
    base_price: 180000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'kitchen-cold',
    sort_order: 1,
    button_size: 'sm',
    button_color: '#10B981',
  },
  {
    id: 'item-013',
    name: 'Súp Miso Rong Biển',
    name_en: 'Miso Seaweed Soup',
    name_jp: '味噌汁',
    sku: 'AP-SUP-MS',
    barcode: '8935000000134',
    image_url: '',
    description: 'Súp miso truyền thống Nhật Bản với rong biển và đậu hũ.',
    category_id: 'cat-food',
    sub_category_id: 'sub-soup',
    base_price: 60000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'kitchen-hot',
    sort_order: 1,
    button_size: 'sm',
    button_color: '#10B981',
  },

  // ═══ THỨC ĂN — Tráng Miệng ═══
  {
    id: 'item-014',
    name: 'Kem Trà Xanh Matcha',
    name_en: 'Matcha Green Tea Ice Cream',
    name_jp: '抹茶アイス',
    sku: 'DS-IC-MT',
    barcode: '8935000000141',
    image_url: '',
    description: 'Kem matcha Nhật Bản, 2 viên.',
    category_id: 'cat-food',
    sub_category_id: 'sub-dessert',
    base_price: 75000,
    tax_rate: 8,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'kitchen-cold',
    sort_order: 1,
    button_size: 'sm',
    button_color: '#10B981',
  },

  // ═══ ĐỒ UỐNG — Bia ═══
  {
    id: 'item-015',
    name: 'Bia Sapporo Draft 330ml',
    name_en: 'Sapporo Draft Beer 330ml',
    name_jp: 'サッポロ生ビール 330ml',
    sku: 'BR-SP-330',
    barcode: '8935000000158',
    image_url: '',
    description: 'Bia Sapporo Draft lon 330ml.',
    category_id: 'cat-drinks',
    sub_category_id: 'sub-beer',
    base_price: 75000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'bar',
    sort_order: 1,
    button_size: 'sm',
    button_color: '#3B82F6',
  },
  {
    id: 'item-016',
    name: 'Bbia Tiger Lon 500ml',
    name_en: 'Tiger Beer Can 500ml',
    name_jp: 'タイガービール 500ml',
    sku: 'BR-TG-500',
    barcode: '8935000000165',
    image_url: '',
    description: 'Bia Tiger lon 500ml.',
    category_id: 'cat-drinks',
    sub_category_id: 'sub-beer',
    base_price: 55000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'bar',
    sort_order: 2,
    button_size: 'sm',
    button_color: '#3B82F6',
  },

  // ═══ ĐỒ UỐNG — Sake & Wine ═══
  {
    id: 'item-017',
    name: 'Sake Junmai 180ml',
    name_en: 'Junmai Sake 180ml',
    name_jp: '純米酒 180ml',
    sku: 'SK-JM-180',
    barcode: '8935000000172',
    image_url: '',
    description: 'Sake Junmai Nhật Bản, chai 180ml.',
    category_id: 'cat-drinks',
    sub_category_id: 'sub-sake',
    base_price: 220000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'bar',
    sort_order: 1,
    button_size: 'sm',
    button_color: '#8B5CF6',
  },
  {
    id: 'item-018',
    name: 'Rượu Vang Đỏ Chile 750ml',
    name_en: 'Chilean Red Wine 750ml',
    name_jp: 'チリ産赤ワイン 750ml',
    sku: 'WN-RD-750',
    barcode: '8935000000189',
    image_url: '',
    description: 'Vang đỏ Chile Merlot, chai 750ml.',
    category_id: 'cat-drinks',
    sub_category_id: 'sub-sake',
    base_price: 450000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: true,
    kitchen_printer_id: 'bar',
    sort_order: 2,
    button_size: 'md',
    button_color: '#8B5CF6',
  },

  // ═══ ĐỒ UỐNG — Nước Ngọt ═══
  {
    id: 'item-019',
    name: 'Nước Suối Lavie 500ml',
    name_en: 'Lavie Water 500ml',
    name_jp: 'ラビエ水 500ml',
    sku: 'SD-LV-500',
    barcode: '8935000000196',
    image_url: '',
    description: 'Nước khoáng Lavie 500ml.',
    category_id: 'cat-drinks',
    sub_category_id: 'sub-soft-drink',
    base_price: 20000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'bar',
    sort_order: 1,
    button_size: 'sm',
    button_color: '#3B82F6',
  },
  {
    id: 'item-020',
    name: 'Coca Cola Lon 330ml',
    name_en: 'Coca Cola Can 330ml',
    name_jp: 'コカ・コーラ 330ml',
    sku: 'SD-CC-330',
    barcode: '8935000000202',
    image_url: '',
    description: 'Coca Cola lon 330ml.',
    category_id: 'cat-drinks',
    sub_category_id: 'sub-soft-drink',
    base_price: 25000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'bar',
    sort_order: 2,
    button_size: 'sm',
    button_color: '#3B82F6',
  },

  // ═══ ĐỒ UỐNG — Trà ═══
  {
    id: 'item-021',
    name: 'Trà Xanh Đá Xay',
    name_en: 'Iced Green Tea',
    name_jp: 'アイス緑茶',
    sku: 'TE-GT-ICE',
    barcode: '8935000000219',
    image_url: '',
    description: 'Trà xanh đá xay, ly 400ml.',
    category_id: 'cat-drinks',
    sub_category_id: 'sub-tea',
    base_price: 45000,
    tax_rate: 8,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: 'bar',
    sort_order: 1,
    button_size: 'sm',
    button_color: '#10B981',
  },

  // ═══ KHÁC — trực thuộc Category (sub_category_id = null) ═══
  {
    id: 'item-022',
    name: 'Phí Dịch Vụ Buffet',
    name_en: 'Buffet Service Charge',
    name_jp: 'ビュッフェサービス料',
    sku: 'OTH-SVC',
    barcode: '8935000000226',
    image_url: '',
    description: 'Phí dịch vụ 5% áp dụng cho gói buffet.',
    category_id: 'cat-other',
    sub_category_id: null,
    base_price: 50000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: null,
    sort_order: 1,
    button_size: 'sm',
    button_color: '#6B7280',
  },
  {
    id: 'item-023',
    name: 'Khăn Lạnh ướp lạnh',
    name_en: 'Cold Towel',
    name_jp: 'おしぼり',
    sku: 'OTH-TWL',
    barcode: '8935000000233',
    image_url: '',
    description: 'Khăn lạnh ướp tinh dầu.',
    category_id: 'cat-other',
    sub_category_id: null,
    base_price: 15000,
    tax_rate: 10,
    is_active: true,
    is_sold_out: false,
    kitchen_printer_id: null,
    sort_order: 2,
    button_size: 'sm',
    button_color: '#6B7280',
  },
  {
    id: 'item-024',
    name: 'Hộp Đựng Mang Về',
    name_en: 'Takeout Box',
    name_jp: 'テイクアウト箱',
    sku: 'OTH-BOX',
    barcode: '8935000000240',
    image_url: '',
    description: 'Hộp đựng thức ăn mang về.',
    category_id: 'cat-other',
    sub_category_id: null,
    base_price: 10000,
    tax_rate: 10,
    is_active: false,
    is_sold_out: false,
    kitchen_printer_id: null,
    sort_order: 3,
    button_size: 'sm',
    button_color: '#6B7280',
  },
]
