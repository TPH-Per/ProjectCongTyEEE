import os
import glob
import re

LAYOUTS_DIR = 'src/layouts'
layouts = glob.glob(os.path.join(LAYOUTS_DIR, '*.vue'))

header_logo_html = '''
        <!-- Logos in Header -->
        <div class="flex items-center gap-4 ml-auto mr-4">
          <img src="/images/nguucat-logo.png" alt="Ngưu Cát" class="h-8 object-contain" />
          <span class="text-gray-300 font-light">|</span>
          <img src="/images/qut-logo.jpg" alt="QUT" class="h-6 object-contain" />
        </div>
'''

sidebar_logo_html = '''
          <div class="flex items-center gap-3">
            <img src="/images/nguucat-logo.png" alt="Ngưu Cát" class="h-10 object-contain drop-shadow-sm" />
            <img src="/images/qut-logo.jpg" alt="QUT" class="h-6 object-contain opacity-90" />
          </div>
'''

for layout in layouts:
    with open(layout, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace sidebar logos
    content = re.sub(
        r'<div class="w-10 h-10 rounded-2xl bg-gray-900.*?</div>\s*<div>\s*<h1 class="text-sm font-black.*?</h1>\s*<p class="text-\[10px\].*?</p>\s*</div>',
        sidebar_logo_html.strip(),
        content,
        flags=re.DOTALL
    )
    
    # Inject into header
    if '<header' in content:
        # Some headers have justify-between. Let's inject right before the right-side controls.
        # <div class="flex items-center gap-3"> usually appears twice (left and right).
        # We can just put it inside the <header> at the end of the left flex container or as a new flex item.
        # Actually, let's just insert it right after the left title div.
        content = re.sub(
            r'(<header[^>]*>.*?<div class="flex items-center gap-3">.*?</h2>\s*</div>)',
            r'\1' + header_logo_html,
            content,
            flags=re.DOTALL
        )
    
    with open(layout, 'w', encoding='utf-8') as f:
        f.write(content)

print("Layouts patched.")
