const fs = require('fs');
const path = require('path');

const layoutsDir = path.join(__dirname, 'src', 'layouts');
const files = fs.readdirSync(layoutsDir).filter(f => f.endsWith('.vue'));

files.forEach(file => {
    const filePath = path.join(layoutsDir, file);
    let content = fs.readFileSync(filePath, 'utf8');

    // Remove standalone <LanguageSwitcher />
    content = content.replace(/\s*<LanguageSwitcher \/>\s*/g, '\n');

    // Insert <LanguageSwitcher /> inside the last right-side div of the header before any avatars or logout buttons
    // The pattern is: we find the <button ... handleSignOut ...> and put LanguageSwitcher before it.
    // Or we find <img :src="stickerUrl" ...> and put it before it.
    
    // First, let's just insert it right before the signout button if exists
    if (content.includes('handleSignOut')) {
        content = content.replace(/(<button[^>]*@click="handleSignOut"[^>]*>)/, '  <LanguageSwitcher />\n          $1');
    } else {
        // Find avatar img if exists
        content = content.replace(/(<img[^>]*stickerUrl[^>]*>)/, '<LanguageSwitcher />\n          $1');
    }

    // Now make sure the LanguageSwitcher isn't completely missing if there's no signout/avatar
    if (!content.includes('<LanguageSwitcher')) {
        content = content.replace(/<\/header>/, '  <LanguageSwitcher />\n      </header>');
    }

    fs.writeFileSync(filePath, content, 'utf8');
});

console.log('Layouts fixed');
