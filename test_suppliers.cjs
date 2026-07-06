const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const url = 'https://zjtnmrcczkbcoxjlndva.supabase.co';
const key = 'sb_publishable_sT0PaVmZo2jFGBX_9TOT4w_zrjmIWQ5';

const supabase = createClient(url, key);

async function run() {
  const { data: auth, error: authErr } = await supabase.auth.signInWithPassword({
    email: 'admin@nomoref2.com',
    password: 'testpassword'
  });
  if (authErr) {
    console.error('Auth error:', authErr);
  }
  
  const { data, error } = await supabase.from('users').select('*');
  console.log('users:', data?.find(u => u.email === 'manager@procurement.com'));
}

run();
