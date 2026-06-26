const { createClient } = require('@supabase/supabase-js')
const fs = require('fs')
const env = fs.readFileSync('.env.local', 'utf8')
const anonKeyMatch = env.match(/VITE_SUPABASE_ANON_KEY=(.*)/)
const urlMatch = env.match(/VITE_SUPABASE_URL=(.*)/)
const key = anonKeyMatch ? anonKeyMatch[1].trim() : ''
const url = urlMatch ? urlMatch[1].trim() : ''

const supabase = createClient(url, key)

async function test() {
  const { data, error } = await supabase.from('orders').select('*').limit(1)
  console.log('Error:', error)
  console.log('Columns:', data && data.length > 0 ? Object.keys(data[0]) : 'No data')
}
test()
