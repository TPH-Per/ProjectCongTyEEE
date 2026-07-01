import { computed } from 'vue'
import { useAuth } from './useAuth'

export function useUserSticker() {
  const { profile } = useAuth()
  
  const stickerUrl = computed(() => {
    const seed = profile.value?.id || 'default-user'
    return `https://api.dicebear.com/7.x/notionists/svg?seed=${seed}&backgroundColor=f87171,fb923c,fbbf24,34d399,38bdf8,818cf8,c084fc`
  })

  return {
    stickerUrl
  }
}
