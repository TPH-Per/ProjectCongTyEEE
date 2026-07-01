import os
import re

def extract_files(md_path):
    with open(md_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Matches markdown code blocks that start with `// supabase/functions/...`
    # Format: 
    # ```ts
    # // supabase/functions/...
    # ...code...
    # ```
    
    pattern = re.compile(r'```(?:ts|typescript)\n\s*//\s*(supabase/functions/[^\n]+)\n(.*?)\n```', re.DOTALL)
    
    matches = pattern.findall(content)
    base_dir = r"C:\Users\Per\Downloads\noMoreF2TECH"
    
    print(f"Found {len(matches)} files to write.")
    for file_path, code in matches:
        full_path = os.path.join(base_dir, file_path.strip().replace('/', os.sep))
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, 'w', encoding='utf-8') as out:
            # We add back the comment line so the file has its name, or just write the code.
            # Usually we write the comment too.
            out.write(f"// {file_path.strip()}\n")
            out.write(code)
        print(f"Wrote {full_path}")

extract_files(r"C:\Users\Per\Downloads\noMoreF2TECH\docs\SUPABASE_FUNCTIONS.md")
