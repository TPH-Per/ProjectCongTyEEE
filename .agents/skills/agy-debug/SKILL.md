---
name: agy-debug
description: "AI Assistant specialized in debugging and explaining errors for POS Ngưu Cát system (Vue 3, TypeScript, Supabase/Postgres, Pinia, Vue i18n). Use when resolving errors, console logs, or invalid database/input operations."
---

# 🤖 PROMPT CHO AI ASSISTANT (Agy) - DEBUG & EXPLAIN ERRORS

## 📋 **CONTEXT & YÊU CẦU**

Bạn là AI Assistant chuyên debug và giải thích lỗi cho hệ thống POS Ngưu Cát.

**Tech Stack:**
- Frontend: Vue 3 + TypeScript + Vite
- Backend: Node.js + Express + PostgreSQL
- Database: Supabase/PostgreSQL với UUID
- State Management: Pinia
- i18n: Vue I18n

**Nhiệm vụ của bạn:**
1. Phân tích lỗi từ screenshot/console logs
2. Giải thích nguyên nhân rõ ràng
3. Đề xuất giải pháp cụ thể với code
4. Cung cấp steps để fix
5. Prevent future errors

---

## 🎯 **TEMPLATE PROMPT**

### **Version 1: Khi có screenshot lỗi**

```markdown
# 🐛 DEBUG REQUEST

## 1. THÔNG TIN LỖI
- **URL:** http://localhost:5173/customer/cart
- **Error Message:** "invalid input syntax for type uuid: \"bf1390-1\""
- **Thời điểm:** Khi click nút "Đặt món"
- **Screenshot:** [Đính kèm ảnh]

## 2. CODE LIÊN QUAN
```typescript
// File: src/views/customer/CartView.vue
// Function gây lỗi (nếu biết):
async function checkout() {
  const response = await api.post('/orders', {
    items: cartItems.value,
    table_id: 'A05'
  })
}
```

## 3. DATABASE SCHEMA
```sql
-- Table: cart_items
CREATE TABLE cart_items (
  id UUID PRIMARY KEY,
  menu_item_id UUID REFERENCES menu_items(id),
  quantity INTEGER,
  notes TEXT
);

-- Table: menu_items
CREATE TABLE menu_items (
  id UUID PRIMARY KEY,
  code VARCHAR(50),
  name VARCHAR(255),
  price DECIMAL
);
```

## 4. YÊU CẦU PHÂN TÍCH
✅ Giải thích lỗi là gì?
✅ Tại sao lỗi xảy ra?
✅ Code/Database nào gây lỗi?
✅ Cách fix chi tiết?
✅ Prevent như thế nào?
✅ Cung cấp code fix cụ thể

## 5. MONG ĐỢI
- Trả lời bằng tiếng Việt
- Code examples rõ ràng
- Step-by-step debugging
- Best practices
```

---

### **Version 2: Khi có console logs**

```markdown
# 🔍 CONSOLE LOG ANALYSIS

## ERROR LOGS
```
[Error] POST http://localhost:3000/api/orders 500 (Internal Server Error)
[Error] invalid input syntax for type uuid: "bf1390-1"
[Warn] Cart item validation failed
[Log] Cart items: [{menu_item_id: "bf1390-1", quantity: 2}]
```

## NETWORK REQUEST
```json
// Request Payload
{
  "items": [
    {
      "menu_item_id": "bf1390-1",
      "quantity": 2,
      "notes": "Không hành"
    }
  ],
  "table_code": "A05"
}

// Response
{
  "error": "Database query failed",
  "message": "invalid input syntax for type uuid: \"bf1390-1\"",
  "code": "22P02"
}
```

## YÊU CẦU
1. ✅ Phân tích lỗi từ logs
2. ✅ Xác định root cause
3. ✅ Fix code ở đâu?
4. ✅ Migration script nếu cần
5. ✅ Test cases để verify
```

---

### **Version 3: Comprehensive Debug Prompt**

```markdown
# 🛠️ COMPREHENSIVE DEBUGGING SESSION

## PROJECT INFO
- **Project:** POS Ngưu Cát - Restaurant Management System
- **Environment:** Development (localhost)
- **Database:** PostgreSQL with UUID primary keys
- **Issue Type:** Data validation / Type mismatch

## CURRENT ISSUE
Khi khách hàng thêm món vào giỏ và thanh toán, gặp lỗi UUID invalid.

## DATA FLOW
1. User click "Thêm vào giỏ" → 
2. Frontend gọi API `/api/cart/add` →
3. Backend lưu vào DB →
4. User click "Đặt món" →
5. ❌ Lỗi xảy ra ở đây

## SUSPECTED CAUSES
- [ ] Menu item ID không phải UUID format
- [ ] Frontend gửi sai data type
- [ ] Backend không validate input
- [ ] Database migration issue
- [ ] Code generate ID sai format

## DEBUGGING STEPS NEEDED
1. ✅ Check console logs
2. ✅ Inspect network requests
3. ✅ Query database for invalid UUIDs
4. ✅ Review validation logic
5. ✅ Check data seeding scripts

## EXPECTED OUTPUT
### A. Root Cause Analysis
- Nguyên nhân chính:
- Nguyên nhân phụ:
- Impact:

### B. Solution
**Immediate Fix:**
```sql
-- SQL script
```

**Code Fix:**
```typescript
// TypeScript code
```

**Validation:**
```typescript
// Validation function
```

### C. Prevention
- [ ] Add database constraints
- [ ] Add frontend validation
- [ ] Add backend validation
- [ ] Add unit tests
- [ ] Add migration script

### D. Testing Steps
1. Clear cart
2. Add item again
3. Verify UUID format
4. Complete checkout
5. Verify success

## ADDITIONAL CONTEXT
- Affected users: All customers
- Frequency: Every time
- Workaround: None
- Priority: Critical (blocking checkout)
```
