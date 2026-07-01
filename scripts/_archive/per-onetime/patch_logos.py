import os
import glob
import re

LAYOUTS_DIR = 'src/layouts'
LOGIN_VIEW = 'src/views/LoginView.vue'

layouts = glob.glob(os.path.join(LAYOUTS_DIR, '*.vue'))

# We have 30 stickers. We can assign one to each layout.
stickers = [f'sticker{i}.png' for i in range(1, 10)]

logo_html = '''
          <div class="flex items-center gap-3">
            <img src="/images/nguucat-logo.png" alt="Ngưu Cát" class="h-10 object-contain drop-shadow-sm" />
            <span class="text-gray-300">|</span>
            <img src="/images/qut-logo.jpg" alt="QUT" class="h-6 object-contain opacity-90" />
          </div>
'''

sidebar_text_re = re.compile(r'<div class="flex items-center gap-2\.5">.*?</div>.*?</div>', re.DOTALL)

for i, layout in enumerate(layouts):
    with open(layout, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Replace the NC text block with the dual logos
    new_content = re.sub(
        r'<div class="w-10 h-10 rounded-2xl bg-gray-900.*?</div>\s*<div>\s*<h1 class="text-sm font-black.*?</h1>\s*<p class="text-\[10px\].*?</p>\s*</div>',
        logo_html.strip(),
        content,
        flags=re.DOTALL
    )

    # 2. Add the sticker. A good place is at the bottom of the sidebar, right before </aside>
    sticker_html = f'''
      <!-- Decorative Sticker -->
      <div class="px-6 py-4 flex justify-center opacity-80 mt-auto">
        <img src="/images/sticker{i+1}.png" alt="Sticker" class="w-24 h-24 object-contain drop-shadow-md hover:scale-110 transition-transform" />
      </div>
'''
    
    # Let's insert the sticker right before <div class="p-3 border-t (which is the user profile section at bottom of sidebar)
    new_content = new_content.replace(
        '<div class="p-3 border-t border-[hsl(var(--border))] relative">',
        sticker_html + '\n      <div class="p-3 border-t border-[hsl(var(--border))] relative">'
    )

    with open(layout, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Patched {layout} with sticker{i+1}")

# For LoginView.vue
with open(LOGIN_VIEW, 'r', encoding='utf-8') as f:
    content = f.read()

login_logos = f'''
      <div class="flex justify-center items-center gap-4 mb-6">
        <img src="/images/nguucat-logo.png" alt="Ngưu Cát" class="h-14 object-contain" />
        <span class="text-gray-300 text-xl">|</span>
        <img src="/images/qut-logo.jpg" alt="QUT" class="h-8 object-contain" />
      </div>
'''

new_content = re.sub(
    r'<h1 class="login-title">.*?</h1>\s*<p class="login-subtitle">.*?</p>',
    login_logos,
    content,
    flags=re.DOTALL
)

# Add sticker
new_content = new_content.replace(
    '<div class="login-card">',
    f'<div class="login-card relative">\n        <img src="/images/sticker10.png" class="absolute -top-12 -right-12 w-28 h-28 drop-shadow-xl rotate-12" />'
)

# Fix login colors to orange theme
new_content = new_content.replace('#ff7b89', '#FF672E').replace('var(--kawaii-cream, #fff5f7)', '#FFF8F5')

with open(LOGIN_VIEW, 'w', encoding='utf-8') as f:
    f.write(new_content)
print(f"Patched {LOGIN_VIEW} with sticker10")

