# Project Rules

## Architecture Rules

* **Strict RPC Architecture for Supabase Data Access**: 
  - Do NOT use the JS Supabase Client for direct table queries (e.g., `.from('table').select()`, `.insert()`).
  - ALL data fetching and data mutation MUST be performed by calling a PostgreSQL function (RPC) using `supabase.rpc('function_name')`.
  - All SQL functions must be defined using `SECURITY DEFINER` (if they require bypassing or complex transaction logic) OR strictly utilize Row Level Security (RLS).
  - This ensures complete data encapsulation and maximum security ("Database as an API" pattern).
