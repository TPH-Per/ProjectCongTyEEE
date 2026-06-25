// combine.js
const fs = require('fs');
const schema = fs.readFileSync('docs/DATABASE_SCHEMA.sql', 'utf8');
const seed = fs.readFileSync('supabase/migrations/seed.sql', 'utf8');
fs.writeFileSync('supabase/migrations/20260623000000_setup.sql', schema + '\n' + seed);
console.log('Combined successfully');
