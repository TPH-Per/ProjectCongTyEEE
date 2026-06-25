const fs = require('fs');
const path = require('path');

function walk(dir, callback) {
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const p = path.join(dir, item);
    if (fs.statSync(p).isDirectory()) {
      walk(p, callback);
    } else {
      if (p.endsWith('.ts') || p.endsWith('.vue')) {
        callback(p);
      }
    }
  }
}

walk('src', (filepath) => {
  let content = fs.readFileSync(filepath, 'utf8');
  let original = content;

  // 1. Remove bad imports from types/database
  content = content.replace(/MenuCategory\s*,?\s*/g, '');
  content = content.replace(/Zone\s*,?\s*/g, '');
  content = content.replace(/KPITarget\s*,?\s*/g, '');
  content = content.replace(/MarketingCost\s*,?\s*/g, '');
  content = content.replace(/import\s+type\s*{\s*}\s+from\s+['"]@\/types\/database['"]/g, '');

  // 2. Fix useTable.ts
  if (filepath.endsWith('useTable.ts')) {
    content = content.replace(/async function listZones\(\): Promise<any\[\]> \{[\s\S]*?return \(data \?\? \[\]\) as any\[\]\s*\}/g, 
`async function listZones(): Promise<string[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('tables')
      .select('zone')
      .eq('branch_id', activeBranchId.value!)
      .eq('is_active', true)
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    const zones = [...new Set(data.map(t => t.zone))]
    return zones
  }`);
    // If the regex above failed because 'Zone' was stripped out
    content = content.replace(/async function listZones\(\): Promise<\[\]> \{[\s\S]*?return \(data \?\? \[\]\) as \[\]\s*\}/g, 
`async function listZones(): Promise<string[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('tables')
      .select('zone')
      .eq('branch_id', activeBranchId.value!)
      .eq('is_active', true)
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    const zones = [...new Set(data.map(t => t.zone))]
    return zones
  }`);
  }

  // 3. Fix useMenu.ts
  if (filepath.endsWith('useMenu.ts')) {
    content = content.replace(/async function getCategories\(\): Promise<\[\]> \{[\s\S]*?return \(data \?\? \[\]\) as \[\]\s*\}/g,
`async function getCategories(): Promise<string[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('menu_items')
      .select('category')
      .eq('branch_id', activeBranchId.value!)
      .eq('is_available', true)
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return [...new Set(data.map(t => t.category))]
  }`);
    content = content.replace(/\.eq\('category_id', categoryId\)/g, ".eq('category', categoryId)");
  }

  // 4. Fix useKPI and useMarketing
  if (filepath.endsWith('useKPI.ts')) {
    content = content.replace(/Promise<\[\]>/g, "Promise<any[]>");
    content = content.replace(/as \[\]/g, "as any[]");
  }
  if (filepath.endsWith('useMarketing.ts')) {
    content = content.replace(/Promise<\[\]>/g, "Promise<any[]>");
    content = content.replace(/as \[\]/g, "as any[]");
  }

  // 5. Fix UI Views that expected MenuCategory or Zone objects
  if (filepath.endsWith('.vue') || filepath.endsWith('mock-data.ts') || filepath.endsWith('.ts')) {
    content = content.replace(/cat\.id/g, "cat");
    content = content.replace(/cat\.name/g, "cat");
    
    // Replace z.id and z.name but ONLY if it's z.id or zone.id (common variable names)
    content = content.replace(/z\.id/g, "z");
    content = content.replace(/z\.name/g, "z");
    content = content.replace(/zone\.id/g, "zone");
    content = content.replace(/zone\.name/g, "zone");
    content = content.replace(/zone\.value/g, "zone");
  }
  
  if (content !== original) {
    fs.writeFileSync(filepath, content, 'utf8');
  }
});
console.log('Refactor script complete');
