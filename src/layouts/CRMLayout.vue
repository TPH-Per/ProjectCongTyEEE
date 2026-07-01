<template>
  <div class="flex h-screen overflow-hidden bg-[hsl(var(--background))]">
    <!-- Sidebar -->
    <aside class="border-r border-[hsl(var(--border))] bg-white flex flex-col shrink-0 w-64 fixed inset-y-0 left-0 z-50 lg:relative lg:translate-x-0">
      <div class="p-5 border-b border-[hsl(var(--border))]">
        <div class="flex items-center gap-2.5">
          <TextLogo size="md" />
        </div>
      </div>
      <nav class="flex-1 px-3 space-y-1 py-4 overflow-y-auto">
        <RouterLink to="/crm/dashboard" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]" active-class="bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30">
          <span>{{ $t('crm.dashboard') }}</span>
        </RouterLink>
        <RouterLink to="/crm/feedback" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold text-[hsl(var(--foreground))] hover:bg-[hsl(var(--muted))]" active-class="bg-[hsl(var(--primary))]/12 text-[hsl(var(--primary))] font-extrabold border-[hsl(var(--primary))]/30">
          <span>{{ $t('crm.feedback') }}</span>
        </RouterLink>
      </nav>
    </aside>

    <main class="flex-1 flex flex-col overflow-hidden">
      <header class="h-16 border-b border-[hsl(var(--border))] bg-white flex items-center justify-between px-6 shrink-0">
        <div class="font-bold">CRM Module</div>
      </header>
      <section class="flex-1 overflow-auto p-6">
        <RouterView />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import TextLogo from '@/components/TextLogo.vue'
import { RouterView, RouterLink } from 'vue-router'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>
