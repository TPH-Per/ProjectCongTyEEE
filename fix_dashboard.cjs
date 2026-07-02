const fs = require('fs');
let f2 = fs.readFileSync('src/layouts/DashboardLayout.vue', 'utf8');

f2 = f2.replace(
  /<button class="p-1 rounded-lg hover:bg-white text-\[hsl\(var\(--muted-foreground\)\)\]">[\s\S]*?<\/button>/m,
  \<button class="flex items-center gap-2 p-1 px-2 rounded-lg hover:bg-white hover:text-red-600 text-[hsl(var(--muted-foreground))] transition-colors" @click="handleSignOut">
            <LogOut :size="13" />
            <span class="text-xs font-semibold">{{ t('layout.logout') }}</span>
          </button>\
);

if (!f2.includes('function handleSignOut()')) {
  f2 = f2.replace(
    /const { t } = useI18n\(\)/,
    \const { t } = useI18n()
const { signOut } = useAuth()
const router = useRouter()

async function handleSignOut() {
  await signOut()
  await router.push({ name: 'login' })
}\
  );
  if (!f2.includes('useRouter')) {
    f2 = f2.replace(/from 'vue-router'/, ", useRouter } from 'vue-router'");
  }
  if (!f2.includes('useAuth')) {
    f2 = f2.replace(/import { useUserSticker } from '@\/composables\/useUserSticker'/, "import { useUserSticker } from '@/composables/useUserSticker'\nimport { useAuth } from '@/composables/useAuth'");
  }
}

fs.writeFileSync('src/layouts/DashboardLayout.vue', f2);
