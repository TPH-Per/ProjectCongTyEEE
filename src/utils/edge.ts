import { supabase } from '@/lib/supabase'

/**
 * Helper to call a Supabase Edge Function with the current session.
 * Throws an Error with a friendly message when the function returns
 * non-2xx so callers can surface it in the UI.
 */
export async function callEdgeFunction<TReq, TRes>(
  name: string,
  body: TReq,
): Promise<TRes> {
  const { data, error } = await supabase.functions.invoke<TRes>(name, {
    body: body as Record<string, unknown>,
  })
  if (error) {
    throw new Error(`Edge Function ${name} failed: ${error.message}`)
  }
  return data as TRes
}
