/**
 * Shortcut/alias types used across composables and views.
 * The full row shapes live in `@/types/database`.
 */
import type {
  AppUser,
  Branch,
  TableT as Table,
  Customer,
  MenuItem,
  Package,
  Reservation,
  Order,
  OrderItem,
  Invoice,
  Payment,
  Shift,
  Notification,
  BranchSetting,
} from '@/types/database'

export type {
  AppUser,
  Branch,
  Table,
  Customer,
  MenuItem,
  Package,
  Reservation,
  Order,
  OrderItem,
  Invoice,
  Payment,
  Shift,
  Notification,
  BranchSetting,
}

/** UI-side enums (kept in sync with the DB enum types in @/types/database). */
export type OrderItemStatus = 'Pending' | 'Preparing' | 'Served' | 'Cancelled'
