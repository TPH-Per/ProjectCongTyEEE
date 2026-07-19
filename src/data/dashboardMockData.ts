/**
 * Mock data for the Reception Dashboard.
 *
 * Used as fallback / demo data for the revenue chart, top-selling items,
 * and supplementary statistics that are not yet backed by a real API.
 *
 * When real endpoints become available, replace the imports in
 * ReceptionDashboardView.vue with actual RPC calls and delete this file.
 */

export interface DashboardRevenuePoint {
  date: string;
  revenue: number;
  orders: number;
}

export interface DashboardTopItem {
  id: number;
  name: string;
  sold: number;
  revenue: number;
}

export interface DashboardExtraStats {
  totalRevenue: number;
  averageOrderValue: number;
  totalCustomers: number;
  newCustomers: number;
}

export const dashboardRevenueData: DashboardRevenuePoint[] = [
  { date: '2026-07-13', revenue: 12_500_000, orders: 45 },
  { date: '2026-07-14', revenue: 15_800_000, orders: 52 },
  { date: '2026-07-15', revenue: 14_200_000, orders: 48 },
  { date: '2026-07-16', revenue: 18_900_000, orders: 61 },
  { date: '2026-07-17', revenue: 22_100_000, orders: 73 },
  { date: '2026-07-18', revenue: 19_500_000, orders: 65 },
  { date: '2026-07-19', revenue: 15_750_000, orders: 52 },
]

export const dashboardTopItems: DashboardTopItem[] = [
  { id: 1, name: 'Vé Người Lớn 1380', sold: 45, revenue: 62_100_000 },
  { id: 2, name: 'Set Lunch Bò Cao Cấp', sold: 28, revenue: 8_372_000 },
  { id: 3, name: 'Nước ngọt uống không giới hạn', sold: 67, revenue: 5_360_000 },
  { id: 4, name: 'Set Tiệc Chiều Đãi Deluxe', sold: 15, revenue: 8_985_000 },
  { id: 5, name: 'Salad Cá Ngừ', sold: 32, revenue: 4_000_000 },
]

export const dashboardExtraStats: DashboardExtraStats = {
  totalRevenue: 15_750_000,
  averageOrderValue: 1_250_000,
  totalCustomers: 87,
  newCustomers: 12,
}
