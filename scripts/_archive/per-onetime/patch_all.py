import os
import glob
import re

LAYOUTS_DIR = 'src/layouts'
VIEWS_DIR = 'src/views'

# 1. Fix Layouts
layouts = glob.glob(os.path.join(LAYOUTS_DIR, '*.vue'))

header_logo_html = '''
        <!-- Logos in Header -->
        <div class="flex items-center gap-4 ml-4">
          <img src="/images/nguucat-logo.png" alt="Ngưu Cát" class="h-8 object-contain" />
          <span class="text-gray-300 font-light">|</span>
          <img src="/images/qut-logo.jpg" alt="QUT" class="h-6 object-contain" />
        </div>
'''

for layout in layouts:
    with open(layout, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Let's remove the decorative sticker we added to the sidebar previously
    content = re.sub(r'<!-- Decorative Sticker -->.*?</div>\s*</div>', '</div>', content, flags=re.DOTALL)
    
    # We want to put the logos in the header.
    # Look for <header ...> <div class="flex items-center gap-3">
    # We will inject the logos into that flex container.
    if '<header' in content:
        # Just inject it inside the header, right after the left div
        content = re.sub(
            r'(<header[^>]*>.*?<div class="flex items-center gap-3">.*?</h2>\s*</div>)',
            r'\1' + header_logo_html,
            content,
            flags=re.DOTALL
        )
    
    with open(layout, 'w', encoding='utf-8') as f:
        f.write(content)

# 2. Add stickers to all Views
views = []
for root, dirs, files in os.walk(VIEWS_DIR):
    for file in files:
        if file.endswith('.vue') and file != 'LoginView.vue':
            views.append(os.path.join(root, file))

sticker_idx = 1
for view in views:
    with open(view, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'sticker' in content.lower():
        continue # Already has a sticker
    
    sticker_file = f"sticker{sticker_idx}.png"
    # Find the first child of <template> that is a tag
    # Example: <template>\n  <div class="...">
    
    sticker_html = f'''
    <!-- Unique Page Sticker -->
    <div class="absolute top-4 right-4 z-10 pointer-events-none opacity-90">
      <img src="/images/{sticker_file}" alt="Page Sticker" class="w-20 h-20 object-contain drop-shadow-md" />
    </div>
'''

    # Insert after the first <div> inside <template>
    match = re.search(r'<template>\s*<([a-zA-Z0-9-]+)[^>]*>', content)
    if match:
        tag_end = match.end()
        new_content = content[:tag_end] + sticker_html + content[tag_end:]
        with open(view, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
    sticker_idx += 1
    if sticker_idx > 27:
        sticker_idx = 1
        
print("Layouts and Views patched.")
