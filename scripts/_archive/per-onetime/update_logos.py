import os
import re

directory = r'C:\Users\Per\Downloads\noMoreF2TECH\src\layouts'

replacements = [
    (re.compile(r'<div class="w-10 h-10 rounded-2xl kawaii-gradient flex items-center justify-center text-white font-black text-base shadow-md">\s*🐂\s*</div>\s*<div>\s*<h1 class="text-[^"]*">NGƯU CÁT</h1>\s*<p class="[^"]*">[^<]*</p>\s*</div>', re.DOTALL),
     '<img src="/images/nguucat-logo.png" alt="Ngưu Cát Logo" class="h-10 w-auto object-contain" />'),
    (re.compile(r'<div class="w-10 h-10 rounded-2xl kawaii-gradient flex items-center justify-center text-white font-black text-base shadow-md">\s*🐂\s*</div>\s*<div>\s*<h1 class="text-[^"]*">NGƯU CÁT</h1>\s*</div>', re.DOTALL),
     '<img src="/images/nguucat-logo.png" alt="Ngưu Cát Logo" class="h-10 w-auto object-contain" />'),
    (re.compile(r'<h1 class="text-[^"]*">Ngưu Cát KDS</h1>'),
     '<img src="/images/nguucat-logo.png" alt="Ngưu Cát Logo" class="h-8 w-auto object-contain" />'),
    (re.compile(r'<h1 class="text-[^"]*">Ngưu Cát Portal</h1>'),
     '<img src="/images/nguucat-logo.png" alt="Ngưu Cát Logo" class="h-8 w-auto object-contain" />')
]

for filename in os.listdir(directory):
    if filename.endswith('.vue'):
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content
        for pattern, repl in replacements:
            new_content = pattern.sub(repl, new_content)
            
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Updated {filename}')
