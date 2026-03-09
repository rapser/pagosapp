-- =============================================================================
-- Tabla: payments (pagos)
-- Ejecutar en Supabase: SQL Editor → pegar y ejecutar.
-- La app trabaja offline (SwiftData) y sincroniza con esta tabla.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    currency TEXT NOT NULL DEFAULT 'PEN' CHECK (currency IN ('PEN', 'USD')),
    due_date TIMESTAMPTZ NOT NULL,
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    category TEXT NOT NULL,
    event_identifier TEXT,
    group_id UUID,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_user_id ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_due_date ON public.payments(due_date);
CREATE INDEX IF NOT EXISTS idx_payments_is_paid ON public.payments(is_paid);
CREATE INDEX IF NOT EXISTS idx_payments_currency ON public.payments(currency);

COMMENT ON TABLE public.payments IS 'Pagos del usuario; sincronizados desde la app (SwiftData + Supabase).';

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own payments"
    ON public.payments FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own payments"
    ON public.payments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own payments"
    ON public.payments FOR UPDATE
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own payments"
    ON public.payments FOR DELETE USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.set_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payments_updated_at ON public.payments;
CREATE TRIGGER payments_updated_at
    BEFORE UPDATE ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION public.set_payments_updated_at();
-- Si tu Postgres no acepta EXECUTE FUNCTION, usa: EXECUTE PROCEDURE public.set_payments_updated_at();
