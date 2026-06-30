import fs from 'fs';
const storeContent = fs.readFileSync('src/stores/useLanguageStore.ts', 'utf-8');
const match = storeContent.match(/ja:\s*{([\s\S]*?)}\s*};/);
if (match) {
  console.log("Match found! Ends with: " + storeContent.substring(match.index + match[0].length, match.index + match[0].length + 50));
} else {
  console.log("Match NOT found");
}
