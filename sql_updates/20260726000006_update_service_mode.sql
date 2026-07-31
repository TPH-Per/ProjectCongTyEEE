ALTER TABLE public.dining_sessions DROP CONSTRAINT IF EXISTS dining_sessions_service_mode_check;
ALTER TABLE public.dining_sessions ADD CONSTRAINT dining_sessions_service_mode_check CHECK (service_mode = ANY (ARRAY['a_la_carte'::text, 'buffet'::text, 'set_menu'::text]));
