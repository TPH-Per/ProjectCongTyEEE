import { computed, onBeforeUnmount, watch, type Ref } from 'vue'
import Swal from 'sweetalert2'
import { useI18n } from 'vue-i18n'

/**
 * Composable for modals / drawers that hold editable form state.
 *
 * Usage:
 *
 *   const { isDirty, confirmIfDirty } = useUnsavedGuard(form, baseline)
 *
 *   <button @click="close()">Cancel</button>
 *
 *   async function close() {
 *     if (await confirmIfDirty()) {
 *       isOpen.value = false
 *     }
 *   }
 *
 * `form` and `baseline` are arbitrary reactive objects. We do a shallow JSON
 * compare — fine for primitives, refs and arrays of primitives, which is what
 * most modal forms hold. If a view needs deep equality for nested objects,
 * pass a `baseline()` function that returns a deep-cloned snapshot.
 *
 * ## Browser back button / tab close
 *
 * The guard also installs (and tears down on scope unmount) two global
 * listeners so the user does not silently lose typed changes via:
 *
 *   1. `beforeunload` — tab close, refresh, hard navigate away. The browser
 *      shows its own native confirmation with copy "Changes you made may not
 *      be saved" (we don't get to choose the wording). When the form is
 *      clean, the listener is a no-op and the browser prompts normally.
 *   2. `popstate` — back/forward button navigation. We push a sentinel state
 *      into `history.state` whenever the form becomes dirty; navigating
 *      away pops it back and triggers our Swal confirm. On "Keep editing"
 *      we re-push the sentinel so the user can keep typing. On "Discard"
 *      we navigate on to the requested route.
 *
 * Both listeners are removed automatically when the calling component
 * unmounts (`onBeforeUnmount`), so they never leak across routes.
 */
export function useUnsavedGuard<T>(
  form: Ref<T>,
  baseline: Ref<T> | (() => T),
) {
  const { t } = useI18n()

  const baselineValue = computed<T>(() =>
    typeof baseline === 'function' ? (baseline as () => T)() : baseline.value,
  )

  const isDirty = computed(
    () => JSON.stringify(form.value) !== JSON.stringify(baselineValue.value),
  )

  async function confirmIfDirty(): Promise<boolean> {
    if (!isDirty.value) return true
    const r = await Swal.fire({
      icon: 'warning',
      title: t('common.unsaved_changes_title'),
      text: t('common.unsaved_changes_text'),
      showCancelButton: true,
      confirmButtonText: t('common.discard'),
      cancelButtonText: t('common.keep_editing'),
      reverseButtons: true,
    })
    return r.isConfirmed
  }

  // ---------------------------------------------------------------------------
  // Browser back / tab-close protection
  // ---------------------------------------------------------------------------

  // 1. beforeunload — tab close / refresh / external navigation.
  //    The browser shows its own native dialog; we just need to return a
  //    non-empty `event.returnValue` while the form is dirty.
  function onBeforeUnload(event: BeforeUnloadEvent) {
    if (isDirty.value) {
      event.preventDefault()
      // Legacy browsers (and current Firefox) require setting returnValue.
      event.returnValue = t('common.unsaved_changes_text')
      return event.returnValue
    }
    return undefined
  }

  // 2. popstate — back/forward button. We push a sentinel history entry
  //    whenever the form becomes dirty, so a back-button pop lands on our
  //    sentinel instead of leaving the page silently. The handler asks
  //    whether to discard, then either re-pushes (keep editing) or
  //    history.back() (discard and continue navigating).
  const SENTINEL_KEY = '__useUnsavedGuard_sentinel'
  let sentinelInstalled = false

  function pushSentinel() {
    if (typeof window === 'undefined') return
    if (sentinelInstalled) return
    window.history.pushState({ [SENTINEL_KEY]: true }, '', window.location.href)
    sentinelInstalled = true
  }

  function removeSentinel() {
    if (typeof window === 'undefined') return
    if (!sentinelInstalled) return
    // Step off our sentinel without firing another popstate.
    if (window.history.state && (window.history.state as any)[SENTINEL_KEY]) {
      window.history.go(-1)
    }
    sentinelInstalled = false
  }

  async function onPopState(_event: PopStateEvent) {
    if (!isDirty.value) {
      // Form became clean while on the sentinel — quietly consume it.
      sentinelInstalled = false
      return
    }
    // User is trying to leave. Stop and ask.
    const discard = await confirmIfDirty()
    if (discard) {
      // Allow navigation: drop the sentinel flag and re-fire the back.
      sentinelInstalled = false
      window.removeEventListener('popstate', onPopState)
      window.history.back()
      // Re-install listener after the navigation flush; the caller is gone
      // by then anyway (component unmount).
      return
    }
    // Keep editing — re-push the sentinel so subsequent back-presses still
    // land on us.
    pushSentinel()
  }

  // Install / tear down depending on dirty state.
  if (typeof window !== 'undefined') {
    watch(
      isDirty,
      (dirty) => {
        if (dirty) {
          pushSentinel()
          window.addEventListener('beforeunload', onBeforeUnload)
          window.addEventListener('popstate', onPopState)
        } else {
          // Became clean — quietly remove the sentinel so the back button
          // behaves normally again.
          removeSentinel()
          window.removeEventListener('beforeunload', onBeforeUnload)
          window.removeEventListener('popstate', onPopState)
        }
      },
      { immediate: true },
    )

    onBeforeUnmount(() => {
      window.removeEventListener('beforeunload', onBeforeUnload)
      window.removeEventListener('popstate', onPopState)
      removeSentinel()
    })
  }

  return { isDirty, confirmIfDirty }
}