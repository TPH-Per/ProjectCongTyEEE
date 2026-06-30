import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
import path from 'path'

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') })

const supabaseUrl = process.env.VITE_SUPABASE_URL
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing Supabase credentials in .env.local')
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseKey)

async function runTests() {
  console.log('--- STARTING SCENARIO TESTS ---')
  
  // Get active branch
  const { data: branches, error: errBranch } = await supabase.from('branches').select('id').limit(1)
  if (errBranch || !branches?.length) {
    console.error('Failed to get branch', errBranch)
    return
  }
  const branchId = branches[0].id
  console.log('Using Branch:', branchId)

  // Get a user (cashier)
  const { data: users, error: errUser } = await supabase.from('users').select('id').limit(1)
  if (errUser || !users?.length) {
    console.error('Failed to get user (cashier)', errUser)
    return
  }
  const cashierId = users[0].id
  console.log('Using Cashier:', cashierId)

  // Get a customer
  const { data: customers, error: errCust } = await supabase.from('customers').select('id').limit(1)
  const customerId = customers?.[0]?.id

  // --- T1: Full checkout with voucher ---
  console.log('\\n--- T1: Full checkout with voucher ---')
  
  // 1. Create Order
  const { data: order, error: errOrder } = await supabase.from('orders').insert({
    branch_id: branchId,
    order_type: 'DINE_IN',
    status: 'COMPLETED', // To pass checkout
    customer_id: customerId || null
  }).select().single()
  
  if (errOrder) {
    console.error('Error creating order:', errOrder)
  } else {
    console.log('Created Order:', order.id)
    
    // 2. Add Voucher
    const voucherCode = 'WELCOME10'
    const { error: errVoucher } = await supabase.from('campaign_vouchers').insert({
      campaign_id: (await supabase.from('campaigns').insert({
        name: 'Welcome', type: 'LOYALTY', start_date: new Date().toISOString(), end_date: new Date(Date.now() + 86400000).toISOString(), budget: 1000000, status: 'ACTIVE', config: {}
      }).select().single()).data.id,
      code: voucherCode,
      discount_type: 'PERCENT',
      discount_value: 10,
      max_uses: 10
    })

    // 3. Process Checkout
    const { data: checkoutRes, error: errCheckout } = await supabase.rpc('process_checkout', {
      p_order_id: order.id,
      p_branch_id: branchId,
      p_cashier_id: cashierId,
      p_payment_method: 'CASH',
      p_voucher_code: voucherCode,
      p_points_to_use: 0
    })
    
    if (errCheckout) {
      console.error('Checkout failed:', errCheckout)
    } else {
      console.log('Checkout success:', checkoutRes)
    }
  }

  console.log('\\n--- TESTS COMPLETED ---')
}

runTests()
