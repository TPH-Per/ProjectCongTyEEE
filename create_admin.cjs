const { Client } = require('pg');

const connectionString = 'postgresql://postgres:123sinhtobo@db.zjtnmrcczkbcoxjlndva.supabase.co:5432/postgres';

async function createAdmin() {
  const client = new Client({ connectionString });
  
  try {
    await client.connect();
    
    // Check if the user already exists
    const existing = await client.query('SELECT id FROM auth.users WHERE email = $1', ['admin@nguucat.vn']);
    let userId;
    
    if (existing.rows.length > 0) {
      userId = existing.rows[0].id;
      console.log(`Admin user already exists with ID: ${userId}`);
    } else {
      console.log('User not found. Something is wrong.');
      return;
    }

    // Try to insert identity if missing
    try {
      await client.query(`
        INSERT INTO auth.identities (
          id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
        ) VALUES (
          gen_random_uuid(), $1, json_build_object('sub', $1::text, 'email', 'admin@nguucat.vn'), 'email', now(), now(), now()
        ) ON CONFLICT DO NOTHING
      `, [userId]);
    } catch (e) {}

    // Now insert/update public.users
    const pubUser = await client.query('SELECT id FROM public.users WHERE id = $1', [userId]);
    
    if (pubUser.rows.length === 0) {
      await client.query(`
        INSERT INTO public.users (
          id, branch_id, full_name, email, role, is_active
        ) VALUES (
          $1, 'b1000000-0000-0000-0000-000000000001', 'System Admin', 'admin@nguucat.vn', 'admin', true
        )
      `, [userId]);
      console.log('Created admin in public.users');
    } else {
      await client.query(`
        UPDATE public.users 
        SET role = 'admin', branch_id = 'b1000000-0000-0000-0000-000000000001' 
        WHERE id = $1
      `, [userId]);
      console.log('Updated existing admin in public.users');
    }
    
    console.log('\\n\\n=== SUCCESS ===');
    console.log('Email: admin@nguucat.vn');
    console.log('Password: admin123');
    console.log('Role: admin');
    
  } catch (err) {
    console.error('Error creating admin:', err);
  } finally {
    await client.end();
  }
}

createAdmin();
