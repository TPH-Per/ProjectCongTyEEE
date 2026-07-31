CREATE OR REPLACE FUNCTION rpc_list_branches() 
RETURNS SETOF branches 
LANGUAGE sql 
SECURITY DEFINER 
AS $$ 
  SELECT * FROM public.branches ORDER BY branch_name; 
$$;
NOTIFY pgrst, 'reload schema';
