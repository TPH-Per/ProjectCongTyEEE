const fs = require('fs')
const env = fs.readFileSync('.env.local', 'utf8')
const anonKeyMatch = env.match(/VITE_SUPABASE_ANON_KEY=(.*)/)
const urlMatch = env.match(/VITE_SUPABASE_URL=(.*)/)
const key = anonKeyMatch ? anonKeyMatch[1].trim() : ''
const url = urlMatch ? urlMatch[1].trim() : ''

fetch(url + '/rest/v1/', {
  headers: {
    'apikey': key,
    'Authorization': 'Bearer ' + key
  }
})
.then(r => r.json())
.then(data => {
  console.log(Object.keys(data))
  if (data.definitions) {
    console.log('Using definitions')
  } else if (data.components) {
    console.log('Using components.schemas')
    if (data.components.schemas.reservations) {
        console.log('reservations:', Object.keys(data.components.schemas.reservations.properties))
    }
  }
})
