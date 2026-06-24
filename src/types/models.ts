/**
 * Shortcut/alias types used across composables and views.
 * The full row shapes live in `@/types/database`.
 */
import type {
  AppUser,
  Branch,
  Zone,
  TableT as Table,
  Customer,
  MenuCategory,
  MenuItem,
  Package,
  Reservation,
  Order,
  OrderItem,
  Invoice,
  Payment,
  Shift,
  KPITarget,
  MarketingCost,
  Notification,
} from '@/types/database'

export type {
  AppUser,
  Branch,
  Zone,
  Table,
  Customer,
  MenuCategory,
  MenuItem,
  Package,
  Reservation,
  Order,
  OrderItem,
  Invoice,
  Payment,
  Shift,
  KPITarget,
  MarketingCost,
  Notification,
}

/** UI-side enums (kept in sync with the DB enum types in @/types/database). */
export type OrderItemStatus = 'Pending' | 'Preparing' | 'Served' | 'Cancelled'
