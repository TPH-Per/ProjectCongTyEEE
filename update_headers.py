import os
import re

LAYOUTS_DIR = 'src/layouts'

AVATAR_HTML = '''
        <LanguageSwitcher />
        <!-- Header User Avatar -->
        <div class="flex items-center gap-2 ml-4">
          <img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-[hsl(var(--border))] object-contain bg-[hsl(var(--muted))]" />
        </div>
      </header>
'''

for file in os.listdir(LAYOUTS_DIR):
    if not file.endswith('.vue'):
        continue
        
    path = os.path.join(LAYOUTS_DIR, file)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    if 'Header User Avatar' in content:
        continue
        
    if '<LanguageSwitcher />' in content and '</header>' in content:
        new_content = re.sub(r'<LanguageSwitcher\s*/>\s*</header>', AVATAR_HTML.strip(), content)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Patched {file}")
