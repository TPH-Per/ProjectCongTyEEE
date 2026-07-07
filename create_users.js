import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';

const envFile = fs.readFileSync('.env.local', 'utf-8');
const envVars = envFile.split('\n').reduce((acc, line) => {
  const [key, value] = line.split('=');
  if (key && value) acc[key.trim()] = value.trim();
  return acc;
}, {});

const supabase = createClient(envVars.VITE_SUPABASE_URL, envVars.VITE_SUPABASE_ANON_KEY);

async function createAccounts() {
  const accounts = [
    { email: 'staff@procurement.com', password: 'password123', role: 'procurement', branchId: '00000000-0000-0000-0000-000000000000' }, // Needs valid branch id
    { email: 'manager@procurement.com', password: 'password123', role: 'procurement_manager' }
  ];

  for (const account of accounts) {
    const { data, error } = await supabase.auth.signUp({
      email: account.email,
      password: account.password,
    });
    if (error) {
      console.error('Error signing up', account.email, error);
    } else {
      console.log('Signed up', account.email, data.user?.id);
    }
  }
}

createAccounts();
