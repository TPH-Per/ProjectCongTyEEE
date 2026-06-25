const fs = require('fs');

let content = fs.readFileSync('src/views/admin/AdminFloorsView.vue', 'utf8');

// Imports
content = content.replace(
  "import { ref, computed, onMounted, onUnmounted } from 'vue';",
  "import { ref, computed, onMounted, onUnmounted } from 'vue';\nimport { supabase } from '@/lib/supabase';\nimport { useAuth } from '@/composables/useAuth';"
);

// Clear mock data
const areasRegex = /const areas = ref<AreaInfo\[\]>\(\[[\s\S]*?\]\);/;
content = content.replace(areasRegex, "const areas = ref<AreaInfo[]>([]);");

const bookingsRegex = /const bookings = ref<Booking\[\]>\(\[[\s\S]*?\]\);/;
content = content.replace(bookingsRegex, "const bookings = ref<Booking[]>([]);");

// Update onMounted
const onMountedRegex = /onMounted\(\(\) => \{[\s\S]*?\}\);/;
const fetchLogic = `onMounted(async () => {
  timer.value = window.setInterval(updateCurrentTime, 60000);
  window.addEventListener('resize', checkMobile);

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
});`;
content = content.replace(onMountedRegex, fetchLogic);

fs.writeFileSync('src/views/admin/AdminFloorsView.vue', content);
