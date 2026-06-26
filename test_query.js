import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://zjtnmrcczkbcoxjlndva.supabase.co'
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'dummy'

// Need to extract the real key from .env
const fs = require('fs')
const env = fs.readFileSync('.env.local', 'utf8')
const anonKeyMatch = env.match(/VITE_SUPABASE_ANON_KEY=(.*)/)
const key = anonKeyMatch ? anonKeyMatch[1].trim() : supabaseKey

const supabase = createClient(supabaseUrl, key)

async function test() {
  const { data, error } = await supabase.from('orders').select('*, reservations(guests,table_id,tables(code))').limit(1)
  console.log('Error:', error)
}
test()
