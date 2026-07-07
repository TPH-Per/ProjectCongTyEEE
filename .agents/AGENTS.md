# Project Rules

## Architecture Rules

* **Strict RPC Architecture for Supabase Data Access**: 
  - Do NOT use the JS Supabase Client for direct table queries (e.g., `.from('table').select()`, `.insert()`).
  - ALL data fetching and data mutation MUST be performed by calling a PostgreSQL function (RPC) using `supabase.rpc('function_name')`.
  - All SQL functions must be defined using `SECURITY DEFINER` (if they require bypassing or complex transaction logic) OR strictly utilize Row Level Security (RLS).
  - This ensures complete data encapsulation and maximum security ("Database as an API" pattern).

## Documentation & Diagram Rules

* **Mermaid Activity Diagrams with Swimlanes**: 
  - ALWAYS use `flowchart LR`.
  - Use `subgraph` to define horizontal swimlanes.
  - Nodes must represent Use Cases and be explicitly sequenced (e.g., numbered 1, 2, 3...).
  - Arrows must point directly from Node to Node (e.g. `C1 ==> R1`), NEVER to a subgraph boundary.
  - Subgraph styles must be transparent with dashed borders to reduce visual noise (e.g., `style Lane1 fill:transparent,stroke:#ccc,stroke-width:2px,stroke-dasharray: 5 5`).
  - Differentiate physical actions (`==>`) from system syncs (`-.->`).
  - Apply soft colors to nodes based on their roles for easy reading.
