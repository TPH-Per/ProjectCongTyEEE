# 📚 NguuCat POS — Docs Index

> Đọc tài liệu theo thứ tự để hiểu toàn bộ hệ thống từ thiết kế → thực thi → kiểm thử → deploy.

---

## 🗺️ Thứ tự đọc cho AI Agent

```
1. DATABASE_DESIGN.md         ← Hiểu kiến trúc + nguyên tắc thiết kế
2. DATABASE_SCHEMA.sql        ← Schema đầy đủ (23 bảng, enum, index, trigger)
3. DATABASE_SCHEMA_REVIEW.md  ← Đánh giá gaps + khuyến nghị bổ sung
4. SUPABASE_SETUP.md          ← Thiết lập Supabase project + credentials
5. SUPABASE_AUTH.md            ← Auth flow, JWT claims, RLS policies, useAuth composable
6. SUPABASE_FUNCTIONS.md       ← 9 Edge Functions (code đầy đủ)
7. SUPABASE_REALTIME.md        ← Realtime subscriptions + useRealtime composable
8. API_IMPLEMENTATION_GUIDE.md ← ★ WHAT: Map mỗi view → queries, mutations, subscriptions
9. EXECUTION_PLAYBOOK.md       ← ★ HOW: Thứ tự thực hiện 7 phases, step by step
10. TESTING_VERIFICATION_GUIDE.md ← ★ TEST: Script kiểm thử từng API, composable, E2E
```

---

## 📄 Chi tiết từng file

### Thiết kế (Design)

| File | Nội dung | Dòng |
|------|----------|------|
| [DATABASE_DESIGN.md](DATABASE_DESIGN.md) | Kiến trúc DB, 2 tầng consistency (HIGH/LOW), multi-tenant, JSONB strategy | ~400 |
| [DATABASE_SCHEMA.sql](DATABASE_SCHEMA.sql) | PostgreSQL DDL đầy đủ: 23 bảng, 8 enum, indexes, triggers, seed | ~570 |
| [DATABASE_SCHEMA_REVIEW.md](DATABASE_SCHEMA_REVIEW.md) | So sánh schema vs 24 views UI, xác định gaps (P0-P3), SQL bổ sung | ~300 |
| [COST_ANALYSIS.md](COST_ANALYSIS.md) | Chi phí vận hành Supabase Pro, Vercel, 3rd party | ~350 |

### Backend (Supabase)

| File | Nội dung | Dòng |
|------|----------|------|
| [SUPABASE_SETUP.md](SUPABASE_SETUP.md) | Thiết lập project, credentials, extensions, storage, Vercel deploy | ~257 |
| [SUPABASE_AUTH.md](SUPABASE_AUTH.md) | Auth hooks, JWT claims injection, RLS policies (30+), router guard, useAuth code | ~580 |
| [SUPABASE_FUNCTIONS.md](SUPABASE_FUNCTIONS.md) | 9 Edge Functions: check-in, add-order-item, checkout, close-shift, export-csv, kds-push, tax-invoice, request-checkout, custom-access-token | ~900 |
| [SUPABASE_REALTIME.md](SUPABASE_REALTIME.md) | Realtime setup, useRealtime composable, 17 subscription mappings, performance tuning | ~350 |

### Thực thi (Execution)

| File | Nội dung | Dòng |
|------|----------|------|
| [API_IMPLEMENTATION_GUIDE.md](API_IMPLEMENTATION_GUIDE.md) | ★ Master guide: project setup, 18 composables, 27 views → API mapping, Edge Function table, Realtime map, RLS matrix, seed data, checklist | ~800 |
| [EXECUTION_PLAYBOOK.md](EXECUTION_PLAYBOOK.md) | ★ Step-by-step: 7 phases (infra → auth → composables → Edge Functions → wire views → realtime → deploy), rollback strategy | ~650 |
| [TESTING_VERIFICATION_GUIDE.md](TESTING_VERIFICATION_GUIDE.md) | ★ Test scripts: unit tests composables, PowerShell Edge Function tests, RLS tests, realtime tests, performance benchmarks | ~400 |

### Tham khảo (Reference)

| File | Nội dung |
|------|----------|
| [OrderFlowChart 2026 ver1.4.xlsx - sheet1.csv](OrderFlowChart%202026%20ver1.4.xlsx%20-%20sheet1.csv) | Sơ đồ luồng gọi món gốc từ F2Tech |
| [POS checklist Dec2025 ver1.3.xlsx](POS%20checklist%20Dec2025%20ver1.3.xlsx) | Checklist POS gốc |
| [WEEKLY_REPORT_2026-06-21.md](WEEKLY_REPORT_2026-06-21.md) | Báo cáo tiến độ tuần |

---

## ⚡ Quick Start cho Agent mới

```
1. Đọc API_IMPLEMENTATION_GUIDE.md (hiểu WHAT)
2. Đọc EXECUTION_PLAYBOOK.md Phase 0-1 (setup + auth)
3. Thực hiện Phase 0 → test → Phase 1 → test
4. Tiếp tục theo thứ tự Phase 2 → ... → Phase 7
5. Chạy tests từ TESTING_VERIFICATION_GUIDE.md sau mỗi phase
```

---

## 📊 Metrics tổng quan

| Metric | Value |
|--------|-------|
| Tổng số bảng DB | 23 (19 HIGH + 4 LOW) |
| Tổng số Edge Functions | 9 |
| Tổng số views frontend | 27 |
| Tổng số composables cần tạo | 18 |
| Tổng số Realtime subscriptions | 17 |
| Tổng số RLS policies | 30+ |
| Tổng số portals (roles) | 7 (Admin, Manager, Reception, Staff, Tablet, Kitchen, Superadmin) |
| Tổng dòng docs | ~5,000+ |
