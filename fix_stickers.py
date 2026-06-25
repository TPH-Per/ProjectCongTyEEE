import os
import re

LAYOUTS_DIR = 'src/layouts'

for file in os.listdir(LAYOUTS_DIR):
    if not file.endswith('.vue'):
        continue
        
    path = os.path.join(LAYOUTS_DIR, file)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Check if useUserSticker is imported
    needs_update = False
    
    if 'useUserSticker' not in content:
        # Add import
        content = re.sub(r'<script setup lang="ts">\n', r'<script setup lang="ts">\nimport { useUserSticker } from \'@/composables/useUserSticker\'\n', content)
        needs_update = True
        
    if 'const { stickerUrl } = useUserSticker()' not in content:
        # Add const extraction after imports
        content = re.sub(r'(import .*?\n)(?!import)', r'\1\nconst { stickerUrl } = useUserSticker()\n', content, count=1)
        needs_update = True
        
    if needs_update:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {file}")
