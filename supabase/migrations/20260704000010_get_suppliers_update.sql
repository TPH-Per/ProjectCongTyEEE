-- Re-create get_suppliers to include category
DROP FUNCTION IF EXISTS public.get_suppliers();

CREATE OR REPLACE FUNCTION public.get_suppliers()
RETURNS TABLE (
  id UUID,
  name TEXT,
  contact_info TEXT,
  tax_code TEXT,
  category TEXT,
  payment_terms TEXT,
  contract_type TEXT,
  payment_due_day INTEGER,
  is_active BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.name,
    COALESCE(s.contact_name, '') || ' / ' ||
      COALESCE(s.contact_phone, '') || ' / ' ||
      COALESCE(s.contact_email, '') AS contact_info,
    s.tax_code,
    s.category,
    s.payment_terms,
    s.contract_type,
    s.payment_due_day,
    s.is_active
  FROM public.suppliers s
  ORDER BY s.name ASC;
END;
$$;
