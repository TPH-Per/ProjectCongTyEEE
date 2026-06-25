const { Client } = require('pg');
const connectionString = 'postgresql://postgres:123sinhtobo@db.zjtnmrcczkbcoxjlndva.supabase.co:5432/postgres';

async function checkCols() {
  const client = new Client({ connectionString });
  await client.connect();
  const res = await client.query(`
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'menu_items';
  `);
  console.log(res.rows);
  await client.end();
}
checkCols();
