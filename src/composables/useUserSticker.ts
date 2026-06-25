import { computed } from 'vue'
import { useAuth } from './useAuth'

export function useUserSticker() {
  const { profile } = useAuth()
  
  const stickerUrl = computed(() => {
    if (!profile.value?.id) return '/images/sticker1.png'
    let hash = 0
    for (let i = 0; i < profile.value.id.length; i++) {
      hash = profile.value.id.charCodeAt(i) + ((hash << 5) - hash)
    }
    const stickerNum = (Math.abs(hash) % 23) + 1
    return `/images/sticker${stickerNum}.png`
  })

  return {
    stickerUrl
  }
}
