<!--
  AdminMenusView.vue
  ------------------
  Back-office page for managing two distinct concepts:

   1. Packages  — first-class entities (set menu, buffet, drink, voucher)
      that bundle a configurable number of menu_items and have their own
      price / duration / item_limit.

   2. Menu items — atomic dishes / drinks. Organised under
      category → optional subcategory → item, with `unit` and
      `price_display` per Ishii 2026-06-24 §VI.1.

  Both lists are sourced from Supabase. Schema lives in
  supabase/migrations/20260625130000_menu_schema_align_ishii.sql and
  20260623000000_setup.sql (packages / package_items).

  No hardcoded fallback data — empty state is empty. If Supabase errors,
  we surface a Swal toast and keep the existing list intact.

  Layout (desktop):
   ┌─────────────────────────────────────────────────────────────────┐
   │ Page header · stats · search · add buttons                       │
   ├──────────────────────┬──────────────────────────────────────────┤
   │ Packages (cards)     │ Menu items tree                          │
   │  · type / limit      │  · category chips                        │
   │  · duration          │  · subcategory sections                  │
   │  · item count        │  · table rows (toggle, edit)             │
   │  · active toggle     │                                          │
   └──────────────────────┴──────────────────────────────────────────┘
-->
<template>
  <div class="space-y-6 max-w-[1600px] mx-auto pb-24 select-none">

    <!-- ─── Page header ────────────────────────────────────────────── -->
    <header class="flex flex-col gap-3 border-b border-gray-200/80 pb-4">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div>
          <h1 class="text-2xl font-black text-gray-900 tracking-tight flex items-center gap-2">
            <span class="text-2xl">🍱</span>
            {{ i18n.t('admin_menus.title') }}
          </h1>
          <p class="text-xs text-gray-500 font-medium mt-1">{{ i18n.t('admin_menus.subtitle') }}</p>
        </div>

        <!-- Stats strip -->
        <div class="flex items-center gap-2 text-[10px] font-black uppercase tracking-wider">
          <div class="flex items-center gap-1.5 bg-emerald-50 text-emerald-700 px-2.5 py-1.5 rounded-xl border border-emerald-100/60">
            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
            {{ activeItemCount }} / {{ menuItems.length }} {{ i18n.t('admin_menus.items_selling') }}
          </div>
          <div class="flex items-center gap-1.5 bg-amber-50 text-amber-700 px-2.5 py-1.5 rounded-xl border border-amber-100/60">
            <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
            {{ activePackageCount }} / {{ packages.length }} {{ i18n.t('admin_menus.packages_selling') }}
          </div>
          <div class="flex items-center gap-1.5 bg-sky-50 text-sky-700 px-2.5 py-1.5 rounded-xl border border-sky-100/60">
            <span class="w-1.5 h-1.5 rounded-full bg-sky-500"></span>
            {{ categories.length }} {{ i18n.t('admin_menus.categories') }}
          </div>
        </div>
      </div>

      <!-- Toolbar: search + add buttons -->
      <div class="flex flex-col sm:flex-row gap-2 sm:items-center sm:justify-between">
        <div class="relative flex-1 max-w-md">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input
            v-model="searchQuery"
            type="text"
            :placeholder="i18n.t('admin_menus.search_placeholder')"
            class="w-full pl-9 pr-3 py-2 text-sm rounded-xl border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400 placeholder:text-gray-400"
          />
        </div>
        <div class="flex gap-2">
          <button
            @click="editMenuItem()"
            class="inline-flex items-center gap-1.5 px-4 py-2 bg-white border border-gray-200 hover:bg-gray-50 text-gray-800 rounded-xl text-sm font-bold shadow-sm transition-colors"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>{{ i18n.t('admin_menus.add_item') }}</button>
          <button
            @click="editPackage()"
            class="inline-flex items-center gap-1.5 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-xl text-sm font-bold shadow-md transition-colors"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 12V8H6a2 2 0 0 1-2-2c0-1.1.9-2 2-2h12v4"/><path d="M4 6v12c0 1.1.9 2 2 2h14v-4"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>{{ i18n.t('admin_menus.add_package') }}</button>
        </div>
      </div>
    </header>

    <!-- ─── Loading skeleton ───────────────────────────────────────── -->
    <div v-if="loading" class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <div class="lg:col-span-1 bg-white border border-gray-200 rounded-2xl p-4 shadow-sm animate-pulse">
        <div class="h-4 bg-gray-100 rounded w-1/3 mb-3"></div>
        <div class="space-y-2">
          <div v-for="n in 4" :key="n" class="h-16 bg-gray-50 rounded-xl"></div>
        </div>
      </div>
      <div class="lg:col-span-2 bg-white border border-gray-200 rounded-2xl p-4 shadow-sm animate-pulse">
        <div class="h-4 bg-gray-100 rounded w-1/4 mb-3"></div>
        <div class="space-y-2">
          <div v-for="n in 8" :key="n" class="h-8 bg-gray-50 rounded"></div>
        </div>
      </div>
    </div>

    <!-- ─── Main grid ──────────────────────────────────────────────── -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-4 items-start">

      <!-- LEFT: Packages -->
      <section class="lg:col-span-1 space-y-4 lg:sticky lg:top-4">
        <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
          <header class="px-4 py-3 border-b border-gray-100 bg-gray-50/60 flex items-center justify-between">
            <h3 class="text-xs font-black text-gray-800 uppercase tracking-wider flex items-center gap-1.5">
              <span class="w-1.5 h-3 bg-rose-500 rounded-full"></span>{{ i18n.t('admin_menus.package_menu') }}</h3>
            <span class="text-[10px] text-gray-400 font-bold">
              {{ packages.length }} {{ i18n.t('admin_menus.packages_count') }}
            </span>
          </header>

          <div v-if="filteredPackages.length === 0" class="px-4 py-10 text-center text-xs text-gray-400 font-medium">
            <div class="text-3xl mb-2 opacity-40">📦</div>
            <p>{{ i18n.t('admin_menus.no_packages') }}</p>
            <button
              @click="editPackage()"
              class="mt-3 text-rose-600 hover:text-rose-700 text-xs font-bold underline"
            >{{ i18n.t('admin_menus.create_first_package') }}</button>
          </div>

          <div v-else class="p-3 space-y-2 max-h-[calc(100vh-280px)] overflow-y-auto">
            <article
              v-for="pkg in filteredPackages"
              :key="pkg.id"
              :class="[
                'border rounded-xl p-3 transition-all hover:shadow-sm',
                pkg.is_active
                  ? 'border-gray-200 bg-white'
                  : 'border-gray-200 bg-gray-50/60 opacity-70'
              ]"
            >
              <div class="flex justify-between items-start gap-2">
                <div class="min-w-0 flex-1">
                  <h4 class="font-bold text-sm text-gray-900 truncate" :title="pkg.name">
                    {{ pkg.name }}
                  </h4>
                  <div class="text-sm font-extrabold text-rose-600 mt-0.5">
                    {{ formatVnd(pkg.price) }}
                  </div>
                  <div class="mt-1.5 flex items-center gap-1.5 flex-wrap">
                    <span :class="['text-[9px] font-black uppercase tracking-wider px-1.5 py-0.5 rounded', typeBadgeClass(pkg.type)]">
                      {{ typeLabel(pkg.type) }}
                    </span>
                    <span v-if="pkg.item_limit != null" class="text-[9px] font-semibold text-gray-500 bg-gray-100 px-1.5 py-0.5 rounded">
                      ≤ {{ pkg.item_limit }} {{ i18n.t('admin_menus.items') }}
                    </span>
                    <span v-if="pkg.duration_minutes != null" class="text-[9px] font-semibold text-gray-500 bg-gray-100 px-1.5 py-0.5 rounded">
                      {{ pkg.duration_minutes }}{{ i18n.t('admin_menus.minutes') }}
                    </span>
                    <span class="text-[9px] font-semibold text-blue-700 bg-blue-50 px-1.5 py-0.5 rounded border border-blue-100/60">
                      {{ itemCountByPackage.get(pkg.id) ?? 0 }} {{ i18n.t('admin_menus.items_in_package') }}
                    </span>
                  </div>
                </div>

                <div class="flex flex-col items-end gap-1.5 shrink-0">
                  <ToggleSwitch
                    :model-value="pkg.is_active"
                    @update:model-value="(v: boolean) => togglePackageActive(pkg, v)"
                  />
                  <button
                    @click="editPackage(pkg)"
                    class="text-[10px] font-bold text-blue-600 hover:text-blue-800 px-2 py-1 rounded hover:bg-blue-50"
                    :title="i18n.t('admin_menus.edit_package')"
                  >{{ i18n.t('admin_menus.edit') }}</button>
                </div>
              </div>
            </article>
          </div>
        </div>

        <!-- Category legend -->
        <div class="bg-white border border-gray-200 rounded-2xl shadow-sm p-4">
          <h4 class="text-[10px] font-black text-gray-800 uppercase tracking-wider mb-2">{{ i18n.t('admin_menus.category_legend') }}</h4>
          <div class="grid grid-cols-2 gap-1.5">
            <div
              v-for="cat in categories"
              :key="cat.id"
              class="flex items-center gap-2 px-2 py-1.5 rounded-lg border border-gray-100"
            >
              <span
                class="w-2 h-2 rounded-full shrink-0"
                :class="cat.color === 'yellow' ? 'bg-amber-400' : cat.color === 'pink' ? 'bg-rose-400' : 'bg-gray-400'"
              ></span>
              <span class="text-[11px] font-bold text-gray-700 truncate">{{ cat.name }}</span>
              <span class="text-[9px] font-bold text-gray-400 ml-auto">
                {{ itemsByCategoryId.get(cat.id)?.length ?? 0 }}
              </span>
            </div>
          </div>
        </div>
      </section>

      <!-- RIGHT: Menu items -->
      <section class="lg:col-span-2 space-y-4">
        <!-- Filter chips -->
        <div class="bg-white border border-gray-200 rounded-2xl shadow-sm p-3">
          <div class="flex items-center justify-between mb-2">
            <h3 class="text-xs font-black text-gray-800 uppercase tracking-wider flex items-center gap-1.5">
              <span class="w-1.5 h-3 bg-emerald-500 rounded-full"></span>{{ i18n.t('admin_menus.items_title') }}</h3>
            <span class="text-[10px] text-gray-400 font-bold">
              {{ filteredMenuItems.length }} / {{ menuItems.length }} {{ i18n.t('admin_menus.items_count') }}
            </span>
          </div>

          <div class="flex flex-wrap gap-1.5">
            <button
              @click="selectedCategoryId = null"
              :class="[
                'inline-flex items-center gap-1 text-[10px] font-black uppercase tracking-wider px-2.5 py-1 rounded-full border transition-colors',
                selectedCategoryId === null
                  ? 'bg-gray-900 text-white border-gray-900'
                  : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'
              ]"
            >{{ i18n.t('admin_menus.all') }}</button>
            <button
              v-for="cat in categories"
              :key="cat.id"
              @click="selectedCategoryId = cat.id"
              :class="[
                'inline-flex items-center gap-1 text-[10px] font-black uppercase tracking-wider px-2.5 py-1 rounded-full border transition-colors',
                selectedCategoryId === cat.id
                  ? 'bg-gray-900 text-white border-gray-900'
                  : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'
              ]"
            >
              <span
                class="w-1.5 h-1.5 rounded-full"
                :class="cat.color === 'yellow' ? 'bg-amber-400' : cat.color === 'pink' ? 'bg-rose-400' : 'bg-gray-400'"
              ></span>
              {{ cat.name }}
              <span class="ml-1 opacity-70">
                ({{ itemsByCategoryId.get(cat.id)?.length ?? 0 }})
              </span>
            </button>
          </div>

          <!-- Subcategory chips -->
          <div
            v-if="subcategoriesForSelectedCategory.length > 0"
            class="mt-2 pt-2 border-t border-gray-100"
          >
            <div class="flex flex-wrap gap-1">
              <button
                @click="selectedSubcategoryId = null"
                :class="[
                  'text-[10px] font-semibold px-2 py-0.5 rounded-full transition-colors',
                  selectedSubcategoryId === null
                    ? 'bg-rose-100 text-rose-700'
                    : 'bg-gray-50 text-gray-600 hover:bg-gray-100'
                ]"
              >{{ i18n.t('admin_menus.every_subcategory') }}</button>
              <button
                v-for="sub in subcategoriesForSelectedCategory"
                :key="sub.id"
                @click="selectedSubcategoryId = (selectedSubcategoryId === sub.id ? null : sub.id)"
                :class="[
                  'text-[10px] font-semibold px-2 py-0.5 rounded-full transition-colors',
                  selectedSubcategoryId === sub.id
                    ? 'bg-rose-100 text-rose-700'
                    : 'bg-gray-50 text-gray-600 hover:bg-gray-100'
                ]"
              >
                {{ sub.name }}
              </button>
            </div>
          </div>
        </div>

        <!-- Items grouped by category/subcategory -->
        <div
          v-for="cat in visibleCategories"
          :key="cat.id"
          class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden"
        >
          <header
            class="px-4 py-2.5 border-b border-gray-100 flex items-center justify-between"
            :class="cat.color === 'yellow' ? 'bg-amber-50/40' : cat.color === 'pink' ? 'bg-rose-50/40' : 'bg-gray-50/60'"
          >
            <div class="flex items-center gap-2">
              <span
                class="w-2 h-2 rounded-full"
                :class="cat.color === 'yellow' ? 'bg-amber-400' : cat.color === 'pink' ? 'bg-rose-400' : 'bg-gray-400'"
              ></span>
              <h3 class="text-xs font-black text-gray-800 uppercase tracking-wider">
                {{ cat.name }}
              </h3>
              <span class="text-[10px] font-bold text-gray-500">
                ({{ itemsByCategoryId.get(cat.id)?.length ?? 0 }})
              </span>
            </div>
            <button
              @click="editMenuItem(undefined, cat.id)"
              class="text-[10px] font-bold text-blue-600 hover:text-blue-800 hover:bg-blue-50 px-2 py-1 rounded transition-colors"
            >{{ i18n.t('admin_menus.add_item') }}</button>
          </header>

          <!-- Items directly under category (no subcategory) -->
          <div
            v-if="(directItemsByCategoryId.get(cat.id) ?? []).length > 0"
            class="overflow-x-auto"
          >
            <table class="w-full text-left text-sm">
              <thead class="bg-gray-50/40 text-[10px] font-black uppercase tracking-wider text-gray-500 border-b border-gray-100">
                <tr>
                  <th class="px-4 py-2 w-16">{{ i18n.t('admin_menus.turn_on') }}</th>
                  <th class="px-4 py-2">{{ i18n.t('admin_menus.item_name') }}</th>
                  <th class="px-4 py-2 w-24">{{ i18n.t('admin_menus.unit') }}</th>
                  <th class="px-4 py-2 text-right w-28">{{ i18n.t('admin_menus.price') }}</th>
                  <th class="px-4 py-2 text-right w-16">{{ i18n.t('admin_menus.edit') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr
                  v-for="item in directItemsByCategoryId.get(cat.id)"
                  :key="item.id"
                  :class="[
                    'hover:bg-gray-50/60 transition-colors',
                    !item.is_available ? 'opacity-60 bg-gray-50/40' : 'bg-white'
                  ]"
                >
                  <td class="px-4 py-2">
                    <ToggleSwitch
                      size="sm"
                      :model-value="item.is_available"
                      @update:model-value="(v: boolean) => toggleMenuItemAvailable(item, v)"
                    />
                  </td>
                  <td class="px-4 py-2">
                    <div class="font-bold text-gray-900 text-sm leading-tight">{{ item.name }}</div>
                    <div v-if="item.description" class="text-[11px] text-gray-400 truncate max-w-md">
                      {{ item.description }}
                    </div>
                  </td>
                  <td class="px-4 py-2 text-xs text-gray-500">{{ item.unit }}</td>
                  <td class="px-4 py-2 text-right">
                    <div class="text-sm font-extrabold text-gray-900">
                      {{ formatVnd(item.price) }}
                    </div>
                    <div v-if="item.price_display" class="text-[10px] font-bold text-gray-400">
                      {{ item.price_display }}
                    </div>
                  </td>
                  <td class="px-4 py-2 text-right">
                    <button
                      @click="editMenuItem(item)"
                      class="text-blue-600 hover:text-blue-800 p-1"
                      :title="i18n.t('admin_menus.edit_item')"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Items grouped by subcategory -->
          <div v-for="sub in subcategoriesByCategoryId.get(cat.id) ?? []" :key="sub.id" class="border-t border-gray-100">
            <header class="px-4 py-2 bg-gray-50/30 flex items-center justify-between">
              <h4 class="text-[11px] font-black text-gray-600 uppercase tracking-wider flex items-center gap-1">
                <span class="text-rose-400">└─</span>
                {{ sub.name }}
                <span class="text-gray-400 font-semibold">
                  ({{ itemsBySubcategoryId.get(sub.id)?.length ?? 0 }})
                </span>
              </h4>
              <button
                @click="editMenuItem(undefined, cat.id, sub.id)"
                class="text-[10px] font-bold text-blue-600 hover:text-blue-800 hover:bg-blue-50 px-2 py-0.5 rounded transition-colors"
              >{{ i18n.t('admin_menus.add') }}</button>
            </header>

            <div v-if="(itemsBySubcategoryId.get(sub.id) ?? []).length > 0" class="overflow-x-auto">
              <table class="w-full text-left text-sm">
                <tbody class="divide-y divide-gray-100">
                  <tr
                    v-for="item in itemsBySubcategoryId.get(sub.id)"
                    :key="item.id"
                    :class="[
                      'hover:bg-gray-50/60 transition-colors',
                      !item.is_available ? 'opacity-60 bg-gray-50/40' : 'bg-white'
                    ]"
                  >
                    <td class="pl-8 pr-4 py-2 w-16">
                      <ToggleSwitch
                        size="sm"
                        :model-value="item.is_available"
                        @update:model-value="(v: boolean) => toggleMenuItemAvailable(item, v)"
                      />
                    </td>
                    <td class="px-4 py-2">
                      <div class="font-bold text-gray-900 text-sm leading-tight">{{ item.name }}</div>
                    </td>
                    <td class="px-4 py-2 text-xs text-gray-500 w-24">{{ item.unit }}</td>
                    <td class="px-4 py-2 text-right w-28">
                      <div class="text-sm font-extrabold text-gray-900">
                        {{ formatVnd(item.price) }}
                      </div>
                      <div v-if="item.price_display" class="text-[10px] font-bold text-gray-400">
                        {{ item.price_display }}
                      </div>
                    </td>
                    <td class="px-4 py-2 text-right w-16">
                      <button
                        @click="editMenuItem(item)"
                        class="text-blue-600 hover:text-blue-800 p-1"
                        :title="i18n.t('admin_menus.edit_item')"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div v-else class="px-8 py-3 text-[11px] text-gray-400 italic">{{ i18n.t('admin_menus.no_items_in_subcategory') }}</div>
          </div>

          <!-- Category empty -->
          <div
            v-if="(itemsByCategoryId.get(cat.id) ?? []).length === 0"
            class="px-4 py-6 text-center text-xs text-gray-400 font-medium"
          >{{ i18n.t('admin_menus.no_items_in_category') }}</div>
        </div>

        <!-- Empty state -->
        <div
          v-if="visibleCategories.length === 0"
          class="bg-white border border-dashed border-gray-200 rounded-2xl p-10 text-center text-sm text-gray-400 font-medium"
        >
          <div class="text-4xl mb-2 opacity-40">🍽️</div>
          <p v-if="searchQuery">{{ i18n.t('admin_menus.no_items_match') }} "{{ searchQuery }}".</p>
          <p v-else>{{ i18n.t('admin_menus.no_categories') }}</p>
        </div>
      </section>
    </div>

    <!-- ─── Package Modal ──────────────────────────────────────────── -->
    <div
      v-if="showPackageModal"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
    >
      <div class="bg-white rounded-2xl w-full max-w-lg overflow-hidden shadow-xl">
        <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50">
          <h3 class="font-bold text-lg text-gray-900">
            {{ editingPackage.id ? i18n.t('admin_menus.edit_package_modal') : i18n.t('admin_menus.add_package_modal') }}
          </h3>
          <button @click="showPackageModal = false" class="text-gray-400 hover:text-gray-600 text-2xl leading-none">&times;</button>
        </div>
        <form @submit.prevent="savePackage" class="p-6 space-y-4">
          <div>
            <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.package_name') }}</label>
            <input v-model="editingPackage.name" required type="text" placeholder="VD: Set Biz 1200K"
              class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400" />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.package_type') }}</label>
              <select v-model="editingPackage.type" required
                class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400">
                <option value="buffet">Buffet</option>
                <option value="set">Set Menu</option>
                <option value="drink">Drink</option>
                <option value="other">{{ i18n.t('admin_menus.other') }}</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.price_vnd') }}</label>
              <input v-model.number="editingPackage.price" required type="number" min="0"
                class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400" />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.item_limit') }}</label>
              <input v-model.number="editingPackage.item_limit" type="number" min="1" placeholder="VD: 20"
                class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400" />
              <p class="text-[10px] text-gray-400 mt-1">{{ i18n.t('admin_menus.leave_empty_if_no_limit') }}</p>
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.duration_minutes') }}</label>
              <input v-model.number="editingPackage.duration_minutes" type="number" min="1" placeholder="VD: 120"
                class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400" />
              <p class="text-[10px] text-gray-400 mt-1">{{ i18n.t('admin_menus.apply_for_buffet') }}</p>
            </div>
          </div>

          <div class="flex items-center gap-2 pt-2 border-t border-gray-100">
            <ToggleSwitch
              :model-value="!!editingPackage.is_active"
              @update:model-value="(v: boolean) => editingPackage.is_active = v"
            />
            <span class="text-sm font-medium text-gray-700">{{ i18n.t('admin_menus.is_active') }}</span>
          </div>

          <div class="pt-4 flex justify-end gap-2 border-t border-gray-100">
            <button type="button" @click="showPackageModal = false"
              class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">{{ i18n.t('admin_menus.cancel') }}</button>
            <button type="submit"
              :disabled="saving"
              class="px-4 py-2 text-sm font-bold text-white bg-gray-900 rounded-lg hover:bg-black disabled:opacity-50">
              {{ saving ? i18n.t('admin_menus.saving') : i18n.t('admin_menus.save') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ─── Menu Item Modal ────────────────────────────────────────── -->
    <div
      v-if="showMenuItemModal"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
    >
      <div class="bg-white rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto shadow-xl">
        <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50 sticky top-0 z-10">
          <h3 class="font-bold text-lg text-gray-900">
            {{ editingMenuItem.id ? i18n.t('admin_menus.edit_item_modal') : i18n.t('admin_menus.add_item_modal') }}
          </h3>
          <button @click="showMenuItemModal = false" class="text-gray-400 hover:text-gray-600 text-2xl leading-none">&times;</button>
        </div>
        <form @submit.prevent="saveMenuItem" class="p-6 space-y-4">
          <div>
            <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.item_name') }}</label>
            <input v-model="editingMenuItem.name" required type="text" placeholder="VD: Wagyu A5"
              class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400" />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.category') }}</label>
              <select v-model="editingMenuItem.category_id" required
                class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400">
                <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.subcategory') }}</label>
              <select v-model="editingMenuItem.subcategory_id"
                class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400">
                <option :value="null">{{ i18n.t('admin_menus.none') }}</option>
                <option v-for="sub in subcategoriesForCategory(editingMenuItem.category_id)" :key="sub.id" :value="sub.id">
                  {{ sub.name }}
                </option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-3 gap-3">
            <div class="col-span-2">
              <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.price_vnd') }}</label>
              <input v-model.number="editingMenuItem.price" required type="number" min="0"
                class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400" />
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.unit') }}</label>
              <input v-model="editingMenuItem.unit" required type="text" list="unit-suggestions"
                class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400" />
              <datalist id="unit-suggestions">
                <option v-for="u in unitSuggestions" :key="u" :value="u" />
              </datalist>
            </div>
          </div>

          <div>
            <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.price_display') }}</label>
            <input v-model="editingMenuItem.price_display" type="text" placeholder="VD: 1.380K"
              class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400" />
            <p class="text-[10px] text-gray-400 mt-1">{{ i18n.t('admin_menus.optional_price_display') }}</p>
          </div>

          <div>
            <label class="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">{{ i18n.t('admin_menus.description') }}</label>
            <textarea v-model="editingMenuItem.description" rows="2" :placeholder="i18n.t('admin_menus.short_description')"
              class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-rose-200 focus:border-rose-400"></textarea>
          </div>

          <div class="flex items-center gap-2 pt-2 border-t border-gray-100">
            <ToggleSwitch
              :model-value="!!editingMenuItem.is_available"
              @update:model-value="(v: boolean) => editingMenuItem.is_available = v"
            />
            <span class="text-sm font-medium text-gray-700">{{ i18n.t('admin_menus.is_selling') }}</span>
          </div>

          <div class="pt-4 flex justify-end gap-2 border-t border-gray-100">
            <button type="button" @click="showMenuItemModal = false"
              class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">{{ i18n.t('admin_menus.cancel') }}</button>
            <button type="submit"
              :disabled="saving"
              class="px-4 py-2 text-sm font-bold text-white bg-gray-900 rounded-lg hover:bg-black disabled:opacity-50">
              {{ saving ? i18n.t('admin_menus.saving') : i18n.t('admin_menus.save') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18nStore } from '@/stores/i18n'

const i18n = useI18nStore()
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import type {
  Package, MenuItem, PackageType, MenuCategory, MenuSub,
} from '@/types/database'
import ToggleSwitch from '@/components/ToggleSwitch.vue'
import Swal from 'sweetalert2'

const { branchId } = useAuth()

// ── State ─────────────────────────────────────────────────────────────────
const packages = ref<Package[]>([])
const menuItems = ref<MenuItem[]>([])
const categories = ref<MenuCategory[]>([])
const subcategories = ref<MenuSub[]>([])
const itemCountByPackage = ref<Map<string, number>>(new Map())

const loading = ref(false)
const saving = ref(false)
const searchQuery = ref('')
const selectedCategoryId = ref<string | null>(null)
const selectedSubcategoryId = ref<string | null>(null)

const showPackageModal = ref(false)
const showMenuItemModal = ref(false)
const editingPackage = ref<Partial<Package>>({})
const editingMenuItem = ref<Partial<MenuItem>>({})

// ── Helpers ───────────────────────────────────────────────────────────────
function formatVnd(n: number | null | undefined): string {
  if (n == null) return '—'
  return `${n.toLocaleString('vi-VN')}đ`
}

function typeLabel(type: PackageType | string): string {
  switch (type) {
    case 'buffet': return 'Buffet'
    case 'set': return 'Set'
    case 'drink': return 'Drink'
    case 'other': return 'Khác'
    default: return String(type)
  }
}
function typeBadgeClass(type: PackageType | string): string {
  switch (type) {
    case 'buffet': return 'bg-rose-100 text-rose-700'
    case 'set': return 'bg-blue-100 text-blue-700'
    case 'drink': return 'bg-emerald-100 text-emerald-700'
    default: return 'bg-gray-100 text-gray-600'
  }
}

const unitSuggestions = ['Phần', 'Vé', 'Ly', 'Lon', 'Chai', 'BỊCH', 'cái', 'hộp', 'đôi', 'Đĩa', 'Lọ', 'gram']

// ── Lookup maps ───────────────────────────────────────────────────────────
const itemsByCategoryId = computed(() => {
  const m = new Map<string, MenuItem[]>()
  for (const item of menuItems.value) {
    if (!m.has(item.category_id)) m.set(item.category_id, [])
    m.get(item.category_id)!.push(item)
  }
  return m
})

const directItemsByCategoryId = computed(() => {
  const m = new Map<string, MenuItem[]>()
  for (const item of menuItems.value) {
    if (item.subcategory_id) continue
    if (!m.has(item.category_id)) m.set(item.category_id, [])
    m.get(item.category_id)!.push(item)
  }
  return m
})

const subcategoriesByCategoryId = computed(() => {
  const m = new Map<string, MenuSub[]>()
  for (const sub of subcategories.value) {
    if (!m.has(sub.category_id)) m.set(sub.category_id, [])
    m.get(sub.category_id)!.push(sub)
  }
  return m
})

const itemsBySubcategoryId = computed(() => {
  const m = new Map<string, MenuItem[]>()
  for (const item of menuItems.value) {
    if (!item.subcategory_id) continue
    if (!m.has(item.subcategory_id)) m.set(item.subcategory_id, [])
    m.get(item.subcategory_id)!.push(item)
  }
  return m
})

const subcategoriesForSelectedCategory = computed(() => {
  if (!selectedCategoryId.value) return [] as MenuSub[]
  return subcategoriesByCategoryId.value.get(selectedCategoryId.value) ?? []
})

function subcategoriesForCategory(categoryId: string | null | undefined): MenuSub[] {
  if (!categoryId) return []
  return subcategoriesByCategoryId.value.get(categoryId) ?? []
}

const visibleCategories = computed(() => {
  let cats = categories.value
  if (selectedCategoryId.value) {
    cats = cats.filter(c => c.id === selectedCategoryId.value)
  }
  return cats.filter(cat => {
    const items = itemsByCategoryId.value.get(cat.id) ?? []
    if (!searchQuery.value) return true
    const q = searchQuery.value.toLowerCase()
    return (
      cat.name.toLowerCase().includes(q) ||
      items.some(i => i.name.toLowerCase().includes(q))
    )
  })
})

const filteredMenuItems = computed(() => {
  let items = menuItems.value
  if (selectedCategoryId.value) {
    items = items.filter(i => i.category_id === selectedCategoryId.value)
  }
  if (selectedSubcategoryId.value) {
    items = items.filter(i => i.subcategory_id === selectedSubcategoryId.value)
  }
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    items = items.filter(i =>
      i.name.toLowerCase().includes(q) ||
      (i.description ?? '').toLowerCase().includes(q)
    )
  }
  return items
})

const filteredPackages = computed(() => {
  if (!searchQuery.value) return packages.value
  const q = searchQuery.value.toLowerCase()
  return packages.value.filter(p => p.name.toLowerCase().includes(q))
})

const activeItemCount = computed(() => menuItems.value.filter(i => i.is_available).length)
const activePackageCount = computed(() => packages.value.filter(p => p.is_active).length)

// ── Data fetching ────────────────────────────────────────────────────────
async function fetchMenus() {
  if (!branchId.value) return
  const bid = branchId.value
  loading.value = true
  try {
    const [pkgRes, itemRes, catRes, subRes, pkgItemRes] = await Promise.all([
      supabase
        .from('packages')
        .select('*')
        .eq('branch_id', bid)
        .order('name'),
      supabase
        .from('menu_items')
        .select('*, menu_categories(name)')
        .eq('branch_id', bid)
        // `sort_order` is provided by migration
        // 20260625230000_menu_items_sort_order.sql — that migration is
        // applied to the remote DB, so items are now sorted by the
        // admin's manual ordering within each category.
        .order('category_id')
        .order('sort_order', { ascending: true, nullsFirst: false }),
      supabase
        .from('menu_categories')
        .select('*')
        .eq('branch_id', bid)
        .order('sort_order'),
      supabase
        .from('menu_subcategories')
        .select('*')
        .eq('branch_id', bid)
        .order('sort_order'),
      // Count package_items per package, restricted to the current branch
      // via the inner join on menu_items. We deliberately do NOT filter
      // by `package_items.is_active` here because some hot-path PostgREST
      // schema-cache reloads have been observed to intermittently miss
      // that column (the migration re-asserts it, see
      // 20260625220000_menu_subcategories_rls_grants_and_reload.sql).
      // Active rows in package_items are reliably served via the
      // branch_id inner join alone.
      supabase
        .from('package_items')
        .select('package_id, menu_item_id, menu_items!inner(branch_id)')
        .eq('menu_items.branch_id', bid),
    ])

    if (pkgRes.error) throw pkgRes.error
    if (itemRes.error) throw itemRes.error
    if (catRes.error) throw catRes.error
    if (subRes.error) throw subRes.error
    if (pkgItemRes.error) throw pkgItemRes.error

    packages.value = (pkgRes.data ?? []) as Package[]
    menuItems.value = (itemRes.data ?? []) as MenuItem[]
    categories.value = (catRes.data ?? []) as MenuCategory[]
    subcategories.value = (subRes.data ?? []) as MenuSub[]

    const counts = new Map<string, number>()
    for (const row of pkgItemRes.data ?? []) {
      counts.set(row.package_id, (counts.get(row.package_id) ?? 0) + 1)
    }
    itemCountByPackage.value = counts
  } catch (err: any) {
    console.error('[AdminMenusView] fetch failed:', err)
    Swal.fire({
      title: i18n.t('admin_menus.cannot_load_data'),
      text: err?.message ?? String(err),
      icon: 'error',
      confirmButtonColor: '#FF672E',
    })
  } finally {
    loading.value = false
  }
}

onMounted(fetchMenus)

// ── Package CRUD ──────────────────────────────────────────────────────────
function editPackage(pkg?: Package) {
  if (pkg) {
    editingPackage.value = { ...pkg }
  } else {
    editingPackage.value = {
      name: '',
      type: 'buffet' as PackageType,
      price: 0,
      item_limit: null,
      duration_minutes: null,
      is_active: true,
      branch_id: branchId.value,
      metadata: {},
    }
  }
  showPackageModal.value = true
}

async function savePackage() {
  saving.value = true
  try {
    if (editingPackage.value.id) {
      const { error } = await supabase.from('packages').update({
        name: editingPackage.value.name,
        type: editingPackage.value.type,
        price: editingPackage.value.price,
        item_limit: editingPackage.value.item_limit ?? null,
        duration_minutes: editingPackage.value.duration_minutes ?? null,
        is_active: editingPackage.value.is_active,
      }).eq('id', editingPackage.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('packages').insert([{
        name: editingPackage.value.name,
        type: editingPackage.value.type,
        price: editingPackage.value.price,
        item_limit: editingPackage.value.item_limit ?? null,
        duration_minutes: editingPackage.value.duration_minutes ?? null,
        is_active: editingPackage.value.is_active ?? true,
        branch_id: branchId.value,
        metadata: {},
      }])
      if (error) throw error
    }
    showPackageModal.value = false
    await fetchMenus()
  } catch (e: any) {
    console.error('[AdminMenusView] savePackage failed:', e)
    Swal.fire(i18n.t('admin_menus.error'), i18n.t('admin_menus.cannot_save_package') + (e?.message ?? String(e)), 'error')
  } finally {
    saving.value = false
  }
}

// ── Menu item CRUD ────────────────────────────────────────────────────────
function editMenuItem(item?: MenuItem, defaultCategoryId?: string, defaultSubcategoryId?: string | null) {
  if (item) {
    editingMenuItem.value = { ...item }
  } else {
    editingMenuItem.value = {
      name: '',
      category_id: defaultCategoryId ?? (categories.value[0]?.id ?? ''),
      subcategory_id: defaultSubcategoryId ?? null,
      price: 0,
      unit: 'Phần',
      price_display: '',
      description: '',
      is_available: true,
      is_active: true,
      branch_id: branchId.value,
      modifiers: [],
      tags: [],
      nutrition: {},
      metadata: {},
    }
  }
  showMenuItemModal.value = true
}

async function saveMenuItem() {
  saving.value = true
  try {
    const payload = {
      name: editingMenuItem.value.name,
      category_id: editingMenuItem.value.category_id,
      subcategory_id: editingMenuItem.value.subcategory_id ?? null,
      price: editingMenuItem.value.price,
      unit: editingMenuItem.value.unit,
      price_display: editingMenuItem.value.price_display ?? null,
      description: editingMenuItem.value.description ?? null,
      is_available: editingMenuItem.value.is_available,
      is_active: editingMenuItem.value.is_active ?? true,
    }
    if (editingMenuItem.value.id) {
      const { error } = await supabase.from('menu_items').update(payload).eq('id', editingMenuItem.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('menu_items').insert([{
        ...payload,
        branch_id: branchId.value,
        modifiers: [],
        tags: [],
        nutrition: {},
        metadata: {},
      }])
      if (error) throw error
    }
    showMenuItemModal.value = false
    await fetchMenus()
  } catch (e: any) {
    console.error('[AdminMenusView] saveMenuItem failed:', e)
    Swal.fire(i18n.t('admin_menus.error'), i18n.t('admin_menus.cannot_save_item') + (e?.message ?? String(e)), 'error')
  } finally {
    saving.value = false
  }
}

async function togglePackageActive(pkg: Package, newVal: boolean) {
  pkg.is_active = newVal
  try {
    const { error } = await supabase.from('packages').update({ is_active: newVal }).eq('id', pkg.id)
    if (error) throw error
  } catch (e) {
    console.error('[AdminMenusView] togglePackageActive failed:', e)
    pkg.is_active = !newVal
    Swal.fire(i18n.t('admin_menus.error'), i18n.t('admin_menus.cannot_update_package_status'), 'error')
  }
}

async function toggleMenuItemAvailable(item: MenuItem, newVal: boolean) {
  item.is_available = newVal
  try {
    const { error } = await supabase.from('menu_items').update({ is_available: newVal }).eq('id', item.id)
    if (error) throw error
  } catch (e) {
    console.error('[AdminMenusView] toggleMenuItemAvailable failed:', e)
    item.is_available = !newVal
    Swal.fire(i18n.t('admin_menus.error'), i18n.t('admin_menus.cannot_update_item_status'), 'error')
  }
}
</script>