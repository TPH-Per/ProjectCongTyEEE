// supabase/functions/issue-tax-invoice/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { requireAppUser, AuthError } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface TaxInvoicePayload {
  invoiceId: string
  taxCode: string          // MST người mua
  customerCompany: string
  customerAddress: string
  customerEmail?: string   // gửi HĐ điện tử
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    // Manager / admin only — this calls a paid 3rd-party API (VNPT/VT).
    const { profile, admin } = await requireAppUser(req, {
      roles: ['manager', 'admin'],
    })
    const body: TaxInvoicePayload = await req.json()

    // Validate payload
    if (!body.invoiceId) throw new AuthError('invoiceId là bắt buộc', 400)
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRe.test(body.invoiceId)) throw new AuthError('invoiceId không phải UUID', 400)

    // 1. Validate MST format (10 hoặc 13 số)
    if (!/^\d{10}(-\d{3})?$/.test(body.taxCode)) {
      throw new AuthError('MST không hợp lệ (phải 10 hoặc 13 số)', 400)
    }

    // 2. Lấy invoice + order items
    const { data: invoice } = await admin
      .from('invoices')
      .select(`
        id, invoice_number, subtotal, vat, discount, total, branch_id,
        reservations(
          orders(
            id, order_number, reservation_id,
            order_items(name_snapshot, quantity, unit_price, line_total)
          )
        )
      `)
      .eq('id', body.invoiceId)
      .maybeSingle()
    if (!invoice) throw new AuthError('Invoice không tồn tại', 404)

    // Branch ownership — fail BEFORE calling the external API so we never
    // bill an invoice we don't have permission to issue.
    if (profile.role !== 'admin' && profile.branch_id !== invoice.branch_id) {
      throw new AuthError('Invoice thuộc chi nhánh khác — bạn không có quyền xuất HĐ', 403)
    }

    // 3. Build XML theo chuẩn Nghị định 123/2020
    const xml = buildVNInvoiceXML({
      invoiceNumber: invoice.invoice_number,
      taxCode: body.taxCode,
      customerCompany: body.customerCompany,
      customerAddress: body.customerAddress,
      items: (invoice as any).reservations?.orders?.[0]?.order_items ?? [],
      subtotal: invoice.subtotal,
      vat: invoice.vat,
      total: invoice.total,
    })

    // 4. Gọi cổng thuế (VNPT/VT example). Fail fast if API key is missing
    //    rather than letting `fetch` get an opaque 500 downstream. We throw
    //    a plain Error (not AuthError) because this is a misconfiguration,
    //    not an auth failure — the caller should treat it as 500.
    const vtApiKey = Deno.env.get('VT_API_KEY')
    if (!vtApiKey) {
      throw new Error('Cấu hình VT_API_KEY chưa có — không thể xuất hóa đơn điện tử')
    }
    const vtApiUrl = Deno.env.get('VT_API_URL') ?? 'https://api.vntax.vn/v1/invoices'
    const resp = await fetch(vtApiUrl, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${vtApiKey}`, 'Content-Type': 'application/xml' },
      body: xml,
    })
    if (!resp.ok) {
      const err = await resp.text()
      throw new Error(`VT API error: ${err}`)
    }
    const result = await resp.json()

    // 5. Update invoice metadata
    await admin
      .from('invoices')
      .update({
        tax_info: { tax_code: body.taxCode, company_name: body.customerCompany, address: body.customerAddress },
        metadata: {
          ...(invoice as any).metadata,
          vt_invoice_id: result.id,
          vt_serial: result.serial,
          vt_number: result.number,
          vt_status: result.status,
          vt_xml_url: result.view_url,
          issued_at: new Date().toISOString(),
        },
      })
      .eq('id', invoice.id)

    // 6. Lưu PDF vào storage (nếu cần)
    if (result.pdf_url) {
      const { data: upload } = await admin.storage
        .from('invoices')
        .upload(`${invoice.branch_id}/${invoice.invoice_number}.pdf`, await fetch(result.pdf_url).then(r => r.blob()), {
          contentType: 'application/pdf',
        })
      if (upload) {
        await admin.from('invoices').update({
          metadata: { ...(invoice as any).metadata, pdf_path: upload.path },
        }).eq('id', invoice.id)
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        invoiceNumber: invoice.invoice_number,
        vtNumber: result.number,
        vtStatus: result.status,
        viewUrl: result.view_url,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e: any) {
    const status = e.name === 'AuthError' ? e.status : (e.status || 400)
    return new Response(
      JSON.stringify({ error: e.message, errorName: e.name }),
      { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})

function buildVNInvoiceXML(data: any): string {
  // Format XML theo Nghị định 123/2020
  return `<?xml version="1.0" encoding="UTF-8"?>
<Invoice>
  <InvoiceNumber>${data.invoiceNumber}</InvoiceNumber>
  <Buyer>
    <TaxCode>${data.taxCode}</TaxCode>
    <Name>${escapeXml(data.customerCompany)}</Name>
    <Address>${escapeXml(data.customerAddress)}</Address>
  </Buyer>
  <Items>
    ${data.items.map((it: any, i: number) => `
    <Item>
      <LineNumber>${i + 1}</LineNumber>
      <Name>${escapeXml(it.name_snapshot)}</Name>
      <Quantity>${it.quantity}</Quantity>
      <UnitPrice>${it.unit_price}</UnitPrice>
      <LineTotal>${it.line_total}</LineTotal>
    </Item>`).join('')}
  </Items>
  <SubTotal>${data.subtotal}</SubTotal>
  <VAT>${data.vat}</VAT>
  <Total>${data.total}</Total>
</Invoice>`
}

function escapeXml(s: string): string {
  return String(s).replace(/[<>&'"]/g, (c) => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&apos;', '"': '&quot;' }[c]!))
}
