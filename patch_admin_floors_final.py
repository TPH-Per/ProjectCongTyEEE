import re

with open('src/views/admin/AdminFloorsView.vue', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports if missing
if "import { supabase }" not in content:
    content = content.replace(
        "import { ref, computed, onMounted, onUnmounted } from 'vue';",
        "import { ref, computed, onMounted, onUnmounted } from 'vue';\nimport { supabase } from '@/lib/supabase';\nimport { useAuth } from '@/composables/useAuth';"
    )

# 2. Clear mock data areas
areas_pattern = r'const areas = ref<AreaInfo\[\]>\(\[.*?\]\);'
content = re.sub(areas_pattern, 'const areas = ref<AreaInfo[]>([]);', content, flags=re.DOTALL)

# 3. Clear mock data bookings
bookings_pattern = r'const bookings = ref<Booking\[\]>\(\[.*?\]\);'
content = re.sub(bookings_pattern, 'const bookings = ref<Booking[]>([]);', content, flags=re.DOTALL)

# 4. Update onMounted
onmounted_pattern = r'onMounted\(\(\) => \{(.*?)\}\);'
def on_mounted_repl(match):
    inner = match.group(1)
    # We want to insert the supabase fetching logic
    fetch_logic = """
  const { session } = useAuth();
  if (session.value) {
    const branchId = session.value.user.user_metadata?.branch_id;
    if (branchId) {
      const { data: tablesData } = await supabase.from('tables').select('*').eq('branch_id', branchId);
      if (tablesData) {
        const zones = [...new Set(tablesData.map(t => t.zone))];
        areas.value = zones.map(z => ({
          name: z,
          description: z,
          tables: tablesData.filter(t => t.zone === z).map(t => ({
            code: t.code,
            status: t.status === 'AVAILABLE' ? 'Available' : t.status === 'OCCUPIED' ? 'Serving' : t.status === 'RESERVED' ? 'Reserved' : 'Available',
            capacity: t.capacity
          }))
        }));
      }

      const { data: resData } = await supabase.from('reservations').select('*, customers(name, phone)').eq('branch_id', branchId);
      if (resData) {
        bookings.value = resData.map(r => ({
          id: r.id,
          bookingNumber: r.booking_code,
          customerName: r.customers?.name || 'Khách',
          phone: r.customers?.phone || '',
          adults: r.guests || 0,
          children: r.children_count || 0,
          reservationTime: r.reservation_time,
          assignedTable: r.table_id || '',
          notes: (r.booking_info as any)?.notes || '',
          status: r.status === 'PENDING' ? 'Waiting' : r.status === 'CONFIRMED' ? 'Waiting' : r.status === 'CHECKED_IN' ? 'Arrived' : r.status === 'SEATED' ? 'Seated' : r.status === 'COMPLETED' ? 'Completed' : 'Cancelled',
          date: r.reservation_date
        }));
      }
    }
  }
"""
    return f"onMounted(async () => {{{inner}{fetch_logic}}});"

content = re.sub(onmounted_pattern, on_mounted_repl, content, flags=re.DOTALL)

# 5. Fix cancelBooking
cancel_booking_pattern = r"function cancelBooking\(id: string\) \{(.*?)\.then\(\(result\) => result\.isConfirmed\) \{(.*?)\}\n\}"
def cancel_booking_repl(match):
    swal = match.group(1).replace("?'),", "?',") # Fix the stray parenthesis if it exists
    body = match.group(2)
    return f"async function cancelBooking(id: string) {{\n  const result = await {swal};\n  if (result.isConfirmed) {{{body}}}\n}}"

content = re.sub(cancel_booking_pattern, cancel_booking_repl, content, flags=re.DOTALL)

with open('src/views/admin/AdminFloorsView.vue', 'w', encoding='utf-8') as f:
    f.write(content)
