import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'

dotenv.config({ path: '.env.local' })
dotenv.config({ path: '.env' })

const supabase = createClient(process.env.VITE_SUPABASE_URL, process.env.VITE_SUPABASE_ANON_KEY)

async function run() {
  const { data, error } = await supabase
    .from('audit_events')
    .select('*, users(full_name), branches(name)')
    .order('created_at', { ascending: false })
    .limit(5);
  console.log(JSON.stringify(data, null, 2))
}
run()
