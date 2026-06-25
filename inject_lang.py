import os
import re

directory = r'C:\Users\Per\Downloads\noMoreF2TECH\src\layouts'

import_statement = "import LanguageSwitcher from '@/components/LanguageSwitcher.vue'\n"
component_tag = "<LanguageSwitcher />\n        "

for filename in os.listdir(directory):
    if filename.endswith('.vue'):
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Inject the LanguageSwitcher inside the header (right side)
        # Look for the last items-center gap-3 before the </header>
        header_end = content.find('</header>')
        if header_end != -1:
            # Add component
            content = content[:header_end] + component_tag + content[header_end:]
            
            # Add import
            script_start = content.find('<script setup lang="ts">')
            if script_start != -1:
                insert_pos = script_start + len('<script setup lang="ts">\n')
                content = content[:insert_pos] + import_statement + content[insert_pos:]
                
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'Injected LanguageSwitcher into {filename}')
