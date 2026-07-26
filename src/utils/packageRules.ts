/**
 * Shared package + promo rule engine.
 *
 * Both the cashier (ReceptionOrderView.vue) and the customer menu
 * (CustomerMenu.vue) need to decide:
 *   1. Whether a given menu item is "included" in a buffet package
 *      (free when ordered inside the package), and
 *   2. Whether lunch-time / promo discounts apply.
 *
 * Before this module existed, each side carried its own copy of these
 * rules — and they diverged. The cashier used subcategory IDs
 * (`isEligibleMenu` via `parentCatId`), the customer matched on names
 * (`name.includes('1390')`). Same business intent, two implementations,
 * slow re-renders on both sides. This file is the single source of
 * truth.
 *
 * Spec source: docs/member_status/Ishii/02_07_2026.md (5 buffet SETs,
 * Kids Meal, Buffet Lẩu, Set 550JP, A la carte) + Ishii VAT 8% /
 * service 5% / lunch 50%.
 */

export interface PackageRuleItem {
  id: string
  name: string
  category_id: string
  /** Subcategory id from `menu_categories`. Pass `''` when unknown. */
  subCatId?: string
  /** Per-unit price; kept here so callers can zero it when in-pkg. */
  price: number
}

/**
 * Categories whose items are buffet-eligible in principle. Subcategory
 * ID filtering then decides which tier actually includes the item.
 */
const ELIGIBLE_PARENT_CATEGORIES = new Set([
  'thuc_an',         // Thức ăn
  'thuc_uong',       // Thức uống (no alcohol)
  'thuc_uong_co_con', // Thức uống có cồn
  'buffet',
])

/**
 * Subcategories that explicitly include WAGYU / premium beef. Used as
 * a normalised signal so callers can either pass `subCatId` (cashier
 * path) or fall back to id-includes checks (customer path).
 */
const WAGYU_HINTS = ['wagyu']
const PREMIUM_BEEF_HINTS = [
  'premium', 'sirloin', 'short_ribs', 'short-ribs',
  'tongue', 'beef_tongue', 'thăn ngoại', 'dẻ sườn', 'lưỡi',
]
const BEEF_HINTS = [
  'beef', 'wagyu', 'tongue', 'bò',
  'thăn', 'sirloin', 'sườn', 'lưỡi',
]
const ALCOHOL_HINTS = [
  'beer', 'whisky', 'shochu', 'nihonshuu', 'wine',
  'alcohol_set', 'rượu', 'soju', 'bia',
]
const DESSERT_HINTS = ['dessert']

/**
 * Subcategories allowed in the cheap buffet tiers (490 / 380). These
 * are the "safe" items that don't bleed into premium-beef territory
 * but still cover the full meal arc (rice, soup, noodles, drink…).
 */
const ALLOWED_LOW_TIER_SUBCATS = new Set([
  'pork', 'chicken',
  'soft_drink', 'tea', 'non_alcoholic',
  'appetizer', 'salad', 'rice', 'noodle', 'soup',
  'dessert', 'sauce',
  'sukiyaki', 'grill_alacarte', 'alacarte',
])

const KIDS_HINTS = ['kids', 'kid', 'egg', 'fries']
const LAU_HINTS = ['lẩu', 'lau', 'rau', 'nước', 'coca', 'bia', 'nấm']
const SET_550JP_HINTS = ['bento', 'sashimi', 'tempura', 'miso']
const DRINK_HINTS = ['uong', 'con']
const LUNCH_HINTS = ['lunch']

function lc(s: string): string {
  return (s ?? '').toLowerCase()
}

/**
 * Returns true iff this item is a surcharge that should NEVER be free
 * inside a package (per Ishii 02/07/2026: `khac-phi` items are always
 * charged). Apply for every package.
 */
export function isSurchargeItem(item: PackageRuleItem): boolean {
  if (item.category_id === 'khac' && (item.subCatId ?? '') === 'surcharge') {
    return true
  }
  // Defensive fallback: id / name containing "khac-phi" / "surcharge"
  // is rare but worth catching.
  const k = lc(item.id) + lc(item.name)
  return k.includes('khac-phi') || k.includes('surcharge')
}

function hasAny(haystack: string, needles: readonly string[]): boolean {
  return needles.some((n) => haystack.includes(n))
}

/**
 * Resolve the buffet tier that this item belongs to. `null` means the
 * item is not package-eligible at the current packageName.
 *
 *   - `1390`  — top tier, anything in ELIGIBLE_PARENT_CATEGORIES
 *   - `1150`  — everything in the 1390 tier EXCEPT wagyu
 *   - `680`   — 1150 tier EXCEPT wagyu + premium beef
 *   - `490` / `380` — only "safe" subcategories, no beef, no alcohol
 *   - `kids` — KIDS / egg / fries / dessert only
 *   - `lau`  — buffet lẩu (hotpot dishes + drinks + veggies)
 *   - `550jp`— Set 550JP (bento / sashimi / tempura / miso)
 *   - `drink`— SET DRINK-only packages
 *
 * The caller passes the currently-selected package name so we can
 * short-circuit when the package isn't recognised.
 */
export function getPackageTier(
  item: PackageRuleItem,
  packageName: string,
): string | null {
  if (!packageName) return null
  const name = lc(packageName)
  const sub = lc(item.subCatId ?? '')
  const id = lc(item.id)
  const itemName = lc(item.name)
  const parent = lc(item.category_id)

  // Surcharges are never included in any buffet.
  if (isSurchargeItem(item)) return null

  // A la carte menu is its own thing — never bundled.
  if (name.includes('a la carte')) return null

  // Kids meal package
  if (name.includes('kids')) {
    if (hasAny(id + itemName + sub, KIDS_HINTS)) return 'kids'
    if (hasAny(sub + parent, DESSERT_HINTS)) return 'kids'
    return null
  }

  // SET DRINK — only drinks + soup + veg sides that pair with a drink
  if (name.includes('drink')) {
    return parent.includes('uong') || sub.includes('uong') ||
           sub.includes('con') || parent.includes('con') ? 'drink' : null
  }

  // Buffet Lẩu (hotpot) — the soup base + raw ingredients + drinks
  if (name.includes('lẩu')) {
    return hasAny(itemName + sub + id, LAU_HINTS) ? 'lau' : null
  }

  // Set 550JP — Japanese set
  if (name.includes('550jp')) {
    return hasAny(itemName + sub, SET_550JP_HINTS) ? '550jp' : null
  }

  // 5 buffet tiers — number-based
  const isEligible = ELIGIBLE_PARENT_CATEGORIES.has(parent)
  if (!isEligible) return null

  const isWagyu = hasAny(id + sub, WAGYU_HINTS)
  const isPremiumBeef = hasAny(id + sub, PREMIUM_BEEF_HINTS)
  const isBeef = hasAny(id + sub, BEEF_HINTS)
  const isAlcohol = parent === 'thuc_uong_co_con' ||
    hasAny(id + sub, ALCOHOL_HINTS)

  if (name.includes('1390')) return '1390'
  if (name.includes('1150')) return isWagyu ? null : '1150'
  if (name.includes('680'))  return (isWagyu || isPremiumBeef) ? null : '680'
  if (name.includes('490') || name.includes('380')) {
    if (isWagyu || isBeef || isAlcohol) return null
    return ALLOWED_LOW_TIER_SUBCATS.has(sub) ? '490' : null
  }

  return null
}

/**
 * True iff the item should be FREE when ordered inside the active
 * package. Surcharges and outside-tier items return false.
 */
export function isItemInPackage(
  item: PackageRuleItem,
  packageName: string,
): boolean {
  return getPackageTier(item, packageName) !== null
}

/**
 * Returns a copy of `item` with `price = 0` and `price_display` set
 * when the item is in the package. Otherwise returns the item as-is.
 * Mirrors the customer-side `getModifiedItem()` helper.
 */
export function applyPackage<T extends PackageRuleItem & { price_display?: string }>(
  item: T,
  packageName: string,
): T {
  if (isItemInPackage(item, packageName)) {
    return {
      ...item,
      price: 0,
      price_display: '0K (Trong gói)',
    }
  }
  return item
}

/**
 * Lunch 50% discount: items whose id / name contains "lunch" are
 * half-off.  Applies to BOTH cashier (already done at
 * ReceptionOrderView.vue:1354-1358) and customer (previously MISSING
 * — added when this module was extracted).
 */
export function isLunchItem(item: PackageRuleItem): boolean {
  return hasAny(lc(item.name) + lc(item.id), LUNCH_HINTS)
}

/**
 * Surcharge items ALWAYS show their price even inside a package —
 * this helper centralises that rule so neither side can forget it.
 */
export function isChargeableEvenInPackage(item: PackageRuleItem): boolean {
  return isSurchargeItem(item)
}

/**
 * Net price for ONE line item at the cashier preview level.
 *   1. Free if `isItemInPackage(item, packageName)`
 *      (surcharges always pay full price).
 *   2. Otherwise: half-off if `isLunchItem(item)`.
 *   3. Otherwise: full `item.price`.
 * Multiplied by `quantity` at the end. Math is intentionally cheap
 * (no VAT here — VAT is added by the order-level calculator).
 */
export function calculateItemUnitPrice(
  item: PackageRuleItem,
  packageName: string,
): number {
  const basePrice = Number(item.price ?? 0)
  if (isSurchargeItem(item)) return basePrice
  if (isItemInPackage(item, packageName)) return 0
  if (isLunchItem(item)) return Math.round(basePrice * 0.5)
  return basePrice
}

/**
 * Add VAT + service-charge to a `subtotal` (in VND). Used by both
 * the customer cart preview and the cashier-side order summary so
 * the two screens never disagree on the math.
 *
 * Spec (Ishii 02/07/2026):
 *   service_charge = round(subtotal * 0.05)
 *   vat            = round((subtotal + service_charge) * 0.08)
 *   total          = subtotal + service_charge + vat
 */
export function computeTotals(subtotal: number): {
  subtotal: number
  serviceCharge: number
  vat: number
  total: number
} {
  const sub = Math.max(0, Math.round(Number(subtotal) || 0))
  const serviceCharge = Math.round(sub * 0.05)
  const vat = Math.round((sub + serviceCharge) * 0.08)
  return {
    subtotal: sub,
    serviceCharge,
    vat,
    total: sub + serviceCharge + vat,
  }
}

/**
 * Bulk pricing helper: given a cart `[{id, name, category_id, subCatId?,
 * price, quantity}]` and the active package name, return the subtotal
 * in VND. Lunch discount is applied per-item BEFORE service/VAT.
 */
export function calcCartSubtotal(
  lines: Array<PackageRuleItem & { quantity: number }>,
  packageName: string,
): number {
  return lines.reduce(
    (s, it) => s + calculateItemUnitPrice(it, packageName) * Number(it.quantity ?? 1),
    0,
  )
}
