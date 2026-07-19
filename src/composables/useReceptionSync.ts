// File: src/composables/useReceptionSync.ts
//
// Thin wrapper around `useReceptionStore` (Pinia) that auto-loads
// reservations on mount and exposes a simplified API for components.
//
// Usage in any reception view:
//   const { reservations, waitingList, addReservation, assignTable } = useReceptionSync()
//
// Pinia reactivity handles cross-component sync automatically — no
// CustomEvent / window dispatch is needed. When component A calls
// `assignTable`, component B's `waitingReservations` computed updates
// in the same tick.

import { onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useReceptionStore } from '@/stores/receptionStore'

export function useReceptionSync(options?: { autoLoad?: boolean }) {
  const store = useReceptionStore()
  const autoLoad = options?.autoLoad ?? true

  // Destructure reactive state + getters with storeToRefs so they
  // stay reactive (plain destructuring would break reactivity).
  const {
    reservations,
    activeSessions,
    lastUpdated,
    isLoaded,
    todayReservations,
    waitingReservations,
    seatedReservations,
    pendingCount,
    confirmedCount,
    seatedCount,
    completedCount,
    cancelledCount,
  } = storeToRefs(store)

  // Auto-load on mount unless the caller opts out
  onMounted(() => {
    if (autoLoad) {
      store.loadReservations()
    }
  })

  return {
    // State (reactive refs)
    reservations,
    activeSessions,
    lastUpdated,
    isLoaded,

    // Getters (reactive refs)
    todayReservations,
    waitingReservations,
    seatedReservations,
    pendingCount,
    confirmedCount,
    seatedCount,
    completedCount,
    cancelledCount,

    // Actions (store methods, stable references)
    loadReservations: store.loadReservations,
    addReservation: store.addReservation,
    updateReservation: store.updateReservation,
    deleteReservation: store.deleteReservation,
    assignTable: store.assignTable,
    releaseTable: store.releaseTable,
    getSessionByTable: store.getSessionByTable,
    getReservationByTable: store.getReservationByTable,
    resetState: store.resetState,
    resetToMock: store.resetToMock,
    persistToStorage: store.persistToStorage,
    loadFromStorage: store.loadFromStorage,
  }
}

export default useReceptionSync
