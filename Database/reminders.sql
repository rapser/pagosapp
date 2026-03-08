-- =============================================================================
-- Tabla: reminders (recordatorios)
-- Ejecutar en Supabase: SQL Editor → pegar y ejecutar.
-- La app trabaja offline (SwiftData) y sincroniza con esta tabla.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reminder_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    due_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON public.reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_due_date ON public.reminders(due_date);

COMMENT ON TABLE public.reminders IS 'Recordatorios del usuario; sincronizados desde la app (SwiftData + Supabase).';
COMMENT ON COLUMN public.reminders.reminder_type IS 'Tipo: cardRenewal, membership, subscription, pension, deposit, documents, taxes, other.';

ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own reminders"
    ON public.reminders FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own reminders"
    ON public.reminders FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reminders"
    ON public.reminders FOR UPDATE
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reminders"
    ON public.reminders FOR DELETE USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.set_reminders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS reminders_updated_at ON public.reminders;
CREATE TRIGGER reminders_updated_at
    BEFORE UPDATE ON public.reminders
    FOR EACH ROW
    EXECUTE FUNCTION public.set_reminders_updated_at();
-- Si tu Postgres no acepta EXECUTE FUNCTION, usa: EXECUTE PROCEDURE public.set_reminders_updated_at();

-- Si la tabla ya existía sin la columna description, ejecutar:
-- ALTER TABLE public.reminders ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
