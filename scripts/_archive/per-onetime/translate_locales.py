import re
from deep_translator import GoogleTranslator
import time

def translate_file(target_lang, output_file):
    with open('src/locales/vi.ts', 'r', encoding='utf-8') as f:
        vi_content = f.read()

    translator = GoogleTranslator(source='vi', target=target_lang)
    
    # We will search for all string values in vi.ts
    # format: key: "value", or key: 'value',
    pattern = re.compile(r'([a-zA-Z0-9_]+)\s*:\s*([\"\'])(.*?)\2', re.DOTALL)
    
    # But wait, app: { name: '...', ... } is nested.
    # The regex works for nested too, as long as it finds key: 'value'.
    
    def replace_match(match):
        key = match.group(1)
        quote = match.group(2)
        text = match.group(3)
        
        # Don't translate English-only strings or placeholders if they shouldn't be translated
        # Also wait, translating 500 strings one by one will be slow, let's print progress
        if not re.search(r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]', text):
            # If no Vietnamese characters, just return as is (like 'vi', 'ja') unless we specifically want to translate it.
            pass
            
        print(f"Translating: {text[:30]}...")
        try:
            translated = translator.translate(text)
            time.sleep(0.1) # Be nice to the API
        except Exception as e:
            print(f"Failed to translate {text}, keeping original. Error: {e}")
            translated = text
            
        # Escape quotes inside translated text
        if quote == "'":
            translated = translated.replace("'", "\\'")
        else:
            translated = translated.replace('"', '\\"')
            
        return f"{key}: {quote}{translated}{quote}"

    new_content = pattern.sub(replace_match, vi_content)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
        
translate_file('en', 'src/locales/en.ts')
print("Finished English translation")
translate_file('ja', 'src/locales/ja.ts')
print("Finished Japanese translation")
