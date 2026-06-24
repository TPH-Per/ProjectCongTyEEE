const fs = require('fs');
const path = require('path');

function replaceInFile(filePath, searchRegex, replacement) {
  if (!fs.existsSync(filePath)) return;
  let content = fs.readFileSync(filePath, 'utf8');
  content = content.replace(searchRegex, replacement);
  fs.writeFileSync(filePath, content);
}

const functionsDir = path.join(__dirname, 'supabase', 'functions');

// 1. add-order-item
let f = path.join(functionsDir, 'add-order-item', 'index.ts');
replaceInFile(f, 
  /\.select\('id, branch_id, table_id, status'\)/g, 
  `.select('id, status, branch_id, reservation_id, reservation:reservations(table_id)')`
);
replaceInFile(f, 
  /const tableId = order\.table_id/g, 
  `const tableId = order.reservation?.table_id`
);
replaceInFile(f, 
  /const { data: assignments(.|\n)*?if \(!assignment\)(.|\n)*?}/g, 
  `const { data: table } = await admin.from('tables').select('metadata').eq('id', tableId).single();\n    const assignment = { metadata: table?.metadata };`
);
replaceInFile(f, 
  /order_id: order\.id,/g, 
  `order_id: order.id,\n        status: 'Pending',\n        metadata: {},`
);

// 2. check-in
f = path.join(functionsDir, 'check-in', 'index.ts');
replaceInFile(f,
  /const assignments = body\.tableIds\.map\(\(t\) => \(\{(.|\n)*?\}\)\)(.|\n)*?await admin\.from\('table_assignments'\)\.insert\(assignments\)/g,
  `let finalResvId = body.reservationId;
    if (!finalResvId) {
      const { data: resv } = await admin.from('reservations').insert({
        branch_id: user.user_metadata.branch_id || body.tableIds[0],
        status: 'Dining',
        source: 'walk_in',
        table_id: body.tableIds[0],
        booking_code: 'WI-' + Date.now(),
        reservation_date: new Date().toISOString().split('T')[0],
        reservation_time: new Date().toISOString().split('T')[1].substring(0,8),
        guests: body.partySize,
        created_by: user.id
      }).select().single();
      finalResvId = resv?.id;
    }
    const tableMetadata = { ...packageMeta, flow_mode: body.flowMode, party_size: body.partySize, demographics_capture: body.partySize, reservation_id: finalResvId, assigned_by: user.id, assigned_at: new Date().toISOString() };
    await admin.from('tables').update({ status: 'occupied', metadata: tableMetadata }).in('id', body.tableIds);`
);
replaceInFile(f, /\{ assignments \}/g, `{ reservationId: finalResvId }`);

// 3. checkout
f = path.join(functionsDir, 'checkout', 'index.ts');
replaceInFile(f,
  /\.select\('id, branch_id, table_id, reservation_id, status, subtotal, vat, total, discount'\)/g,
  `.select('id, branch_id, reservation_id, status, subtotal, vat, total, discount')`
);
replaceInFile(f,
  /order_id: order\.id,\n        invoice_number: invoiceNumber,\n        status: 'paid',\n        subtotal: order\.subtotal,\n        vat: order\.vat,\n        discount: Number\(order\.discount\) \+ voucherDiscount,\n        total: finalTotal,\n        tax_code: body\.taxCode \?\? customer\?\.tax_code,\n        customer_company: body\.customerCompany,\n        customer_address: body\.customerAddress,\n        customer_snapshot: customer \?\? \{ name: 'Walk-in' \},\n        issued_at: new Date\(\)\.toISOString\(\),\n        issued_by: user\.id,\n        metadata: \{ notes: body\.notes \},/g,
  `reservation_id: order.reservation_id,
        invoice_number: invoiceNumber,
        status: 'paid',
        subtotal: order.subtotal,
        vat: order.vat,
        discount: Number(order.discount) + voucherDiscount,
        total: finalTotal,
        tax_info: { tax_code: body.taxCode ?? customer?.tax_code, company_name: body.customerCompany, address: body.customerAddress },
        applied_vouchers: voucher ? [{ voucher_id: voucher.id, code: voucher.code, discount_amount: voucherDiscount }] : [],
        customer_snapshot: customer ?? { name: 'Walk-in' },
        notes: body.notes ? { text: body.notes } : {},
        metadata: {},
        issued_at: new Date().toISOString(),
        issued_by: user.id,`
);
replaceInFile(f, /\/\/ 6\. Ghi voucher_redemption(.|\n)*?eq\('id', voucher\.id\)\n    }/g, 
  `// 6. Update voucher count
    if (voucher) {
      await admin.from('vouchers').update({ used_count: voucher.used_count + 1 }).eq('id', voucher.id);
    }`
);
replaceInFile(f, /\/\/ 8\. Release table_assignments(.|\n)*?\} \/\/ 9\. Update reservation/g, 
  `// 8. Release table_assignments
    const { data: tbs } = await admin.from('tables').select('id, metadata').eq('status', 'occupied');
    const myTbs = (tbs || []).filter((t: any) => t.metadata?.reservation_id === order.reservation_id);
    if (myTbs.length > 0) {
      await admin.from('tables').update({ status: 'available', metadata: {} }).in('id', myTbs.map((t: any) => t.id));
    }
    // 9. Update reservation`
);

// 4. export-shift-csv
f = path.join(functionsDir, 'export-shift-csv', 'index.ts');
replaceInFile(f,
  /\.select\(`\n        id, method, amount, received_amount, change_amount, paid_at, revenue_type,\n        invoices\(invoice_number, customer_snapshot, tax_code, total, orders\(order_number, table_id\)\)\n      `\)/g,
  `.select(\`id, method, amount, received_amount, change_amount, paid_at, revenue_type, invoices(invoice_number, customer_snapshot, tax_info, total, reservations(orders(order_number), table_id))\`)`
);
replaceInFile(f, 
  /const tableId = inv\?\.orders\?\.table_id/g, 
  `const tableId = inv?.reservations?.table_id`
);
replaceInFile(f, 
  /const orderNo = inv\?\.orders\?\.order_number/g, 
  `const orderNo = inv?.reservations?.orders?.[0]?.order_number`
);
replaceInFile(f, 
  /const tax = inv\?\.tax_code \?\? ''/g, 
  `const tax = inv?.tax_info?.tax_code ?? ''`
);

// 5. issue-tax-invoice
f = path.join(functionsDir, 'issue-tax-invoice', 'index.ts');
replaceInFile(f, 
  /\.select\('id, invoice_number, total, tax_code, customer_company, customer_address, orders\(order_number, branch_id\)'\)/g, 
  `.select('id, invoice_number, total, tax_info, reservations(orders(order_number, branch_id))')`
);
replaceInFile(f, 
  /tax_code: body\.taxCode,\n          customer_company: body\.customerCompany,\n          customer_address: body\.customerAddress/g, 
  `tax_info: { tax_code: body.taxCode, company_name: body.customerCompany, address: body.customerAddress }`
);

// 6. kds-push
f = path.join(functionsDir, 'kds-push', 'index.ts');
replaceInFile(f, 
  /order:orders\(order_number, table_id\)/g, 
  `order:orders(order_number, reservation:reservations(table_id))`
);
replaceInFile(f, 
  /table_id: \(item as any\)\.order\?\.table_id,/g, 
  `table_id: (item as any).order?.reservation?.table_id,`
);

console.log("Backend fixes applied.");
