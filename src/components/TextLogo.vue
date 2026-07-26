<!--
  TextLogo.vue
  ------------
  Brand wordmark "Ngưu Cát" rendered as text in a premium serif
  (Cormorant Garamond, falling back to Playfair Display / Georgia).
  Replaces the legacy /images/nguucat-logo.png which on white backgrounds
  read as a low-resolution black/orange blob and didn't carry the brand
  name. Crisp at every DPI, identical in every browser, no asset loading
  flicker.

  Usage:
    <TextLogo size="md" />           // sidebar (default)
    <TextLogo size="lg" tagline />   // login / hero
    <TextLogo size="sm" />           // mobile header

  Props:
    size       'sm' = 18px (mobile) | 'md' = 22px (sidebar) |
                'lg' = 32px (login)  | 'xl' = 44px (hero / receipt)
    tagline    Show the Vietnamese subtitle under the wordmark
    gradient   When true, render the orange brand gradient; otherwise
               use a flat brand-orange (or navy when `mono` is set)
    mono       When true, use the navy/solid color regardless of gradient
    align      'left' (default) | 'center' | 'right'
-->
<script setup lang="ts">
withDefaults(
  defineProps<{
    /** Size variant of the wordmark. */
    size?: 'sm' | 'md' | 'lg' | 'xl'
    /** Show the Vietnamese subtitle under the wordmark. */
    tagline?: boolean
    /** Use the orange brand gradient as text fill. */
    gradient?: boolean
    /** Force solid navy color (overrides `gradient`). */
    mono?: boolean
    /** Force gold/luxurious color */
    gold?: boolean
    /** Text alignment. */
    align?: 'left' | 'center' | 'right'
  }>(),
  { size: 'md', tagline: false, gradient: false, mono: false, gold: false, align: 'left' },
)
</script>

<template>
  <span
    class="text-logo"
    :class="[`text-logo--${size}`, `text-logo--align-${align}`]"
  >
    <span
      class="text-logo__word"
      :class="[
        mono ? 'text-logo__word--mono'
             : gold ? 'text-logo__word--gold'
             : gradient ? 'text-logo__word--gradient' : 'text-logo__word--solid',
      ]"
    >
      Ngưu Cát
    </span>
    <span v-if="tagline" class="text-logo__tag">Hệ thống quản lý nhà hàng</span>
  </span>
</template>

<style scoped>
/* ----------------------------------------------------------------------- *
 * Container — vertical stack of wordmark + optional tagline.
 * align-* controls horizontal alignment within the flex column.
 * ----------------------------------------------------------------------- */
.text-logo {
  display: inline-flex;
  flex-direction: column;
  font-family: 'Cormorant Garamond', 'Playfair Display', Georgia, serif;
  font-weight: 700;
  line-height: 1;
  letter-spacing: 0.04em;
  user-select: none;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
}

.text-logo--align-left   { align-items: flex-start; }
.text-logo--align-center { align-items: center; text-align: center; }
.text-logo--align-right  { align-items: flex-end;   text-align: right; }

/* ----------------------------------------------------------------------- *
 * Wordmark — sizes. Letter-spacing tightens on bigger sizes (logotype
 * convention: large display wordmarks need LESS spacing so the letters
 * don't look "stamped" apart).
 * ----------------------------------------------------------------------- */
.text-logo--sm .text-logo__word {
  font-size: 18px;
  letter-spacing: 0.04em;
  font-weight: 600;
}
.text-logo--md .text-logo__word {
  font-size: 22px;
  letter-spacing: 0.05em;
  font-weight: 600;
}
.text-logo--lg .text-logo__word {
  font-size: 32px;
  letter-spacing: 0.06em;
  font-weight: 700;
}
.text-logo--xl .text-logo__word {
  font-size: 44px;
  letter-spacing: 0.06em;
  font-weight: 700;
}

/* ----------------------------------------------------------------------- *
 * Color variants.
 *   solid    → flat brand orange (#FF672E) — reads at any size, no
 *              clip-text shenanigans on small viewports.
 *   gradient → orange→deep-orange diagonal (login / hero only).
 *   mono     → navy (#2C3E50) for high-contrast sidebar headers.
 * ----------------------------------------------------------------------- */
.text-logo__word--solid {
  color: #FF672E;
}
.text-logo__word--gradient {
  background: linear-gradient(135deg, #FFA362 0%, #FF672E 60%, #E84A0E 100%);
  -webkit-background-clip: text;
          background-clip: text;
  -webkit-text-fill-color: transparent;
          color: transparent;
}
.text-logo__word--mono {
  color: #2C3E50;
}
.text-logo__word--gold {
  background: linear-gradient(135deg, #FCD973 0%, #D4AF37 50%, #AA7C11 100%);
  -webkit-background-clip: text;
          background-clip: text;
  -webkit-text-fill-color: transparent;
          color: transparent;
  text-shadow: 0 2px 10px rgba(212, 175, 55, 0.3);
}

/* ----------------------------------------------------------------------- *
 * Tagline — uppercase Vietnamese subtitle. Uses a sans (Nunito) for
 * contrast against the serif wordmark and proper small-caps spacing.
 * ----------------------------------------------------------------------- */
.text-logo__tag {
  margin-top: 4px;
  font-family: 'Nunito', 'Inter', system-ui, sans-serif;
  font-weight: 700;
  font-size: 10px;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: #94A3B8;
}
.text-logo--sm .text-logo__tag { font-size: 9px;  letter-spacing: 0.20em; }
.text-logo--md .text-logo__tag { font-size: 10px; letter-spacing: 0.22em; }
.text-logo--lg .text-logo__tag { font-size: 11px; letter-spacing: 0.26em; }
.text-logo--xl .text-logo__tag { font-size: 13px; letter-spacing: 0.30em; margin-top: 8px; }
</style>