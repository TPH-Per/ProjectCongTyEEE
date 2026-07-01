const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  try {
    const list = fs.readdirSync(dir);
    list.forEach(file => {
      file = path.join(dir, file);
      const stat = fs.statSync(file);
      if (stat && stat.isDirectory()) {
        results = results.concat(walk(file));
      } else if (file.endsWith('.vue')) {
        results.push(file);
      }
    });
  } catch (err) {
    // ignore
  }
  return results;
}

const views = walk('src/views');
const components = walk('src/components');

console.log("=== VIEWS ===");
views.forEach(file => {
  const content = fs.readFileSync(file, 'utf8');
  const usesSupabase = content.includes('supabase');
  const importsComposables = (content.match(/use[A-Z]\w+/g) || []).filter(c => c !== 'useRouter' && c !== 'useRoute' && c !== 'useI18n');
  const isLikelyStatic = content.includes('mock') || content.includes('dummy') || /const \w+ = ref\(\[\s*\{/.test(content);
  console.log('FILE:', file);
  console.log('  Supabase Direct:', usesSupabase);
  console.log('  Composables:', [...new Set(importsComposables)].join(', '));
  console.log('  Static Data Indication:', isLikelyStatic);
});

console.log("\n=== COMPONENTS ===");
components.forEach(file => {
  const content = fs.readFileSync(file, 'utf8');
  const usesSupabase = content.includes('supabase');
  const importsComposables = (content.match(/use[A-Z]\w+/g) || []).filter(c => c !== 'useRouter' && c !== 'useRoute' && c !== 'useI18n');
  const isLikelyStatic = content.includes('mock') || content.includes('dummy') || /const \w+ = ref\(\[\s*\{/.test(content);
  console.log('FILE:', file);
  console.log('  Supabase Direct:', usesSupabase);
  console.log('  Composables:', [...new Set(importsComposables)].join(', '));
  console.log('  Static Data Indication:', isLikelyStatic);
});
