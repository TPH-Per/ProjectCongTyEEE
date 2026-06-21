import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import { i18n } from './locales'
import { useI18nStore } from './stores/i18n'
import '@/styles/globals.css'
import '@/styles/styles.css'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)
app.use(i18n)

// Khởi tạo store i18n — store này tự đồng bộ locale với vue-i18n
// và <html lang> ngay khi khởi tạo, nên chỉ cần gọi để kích hoạt.
useI18nStore()

app.mount('#app')