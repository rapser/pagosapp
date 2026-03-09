-- =============================================================================
-- Tabla: user_profiles (perfil de usuario)
-- Ejecutar en Supabase: SQL Editor → pegar y ejecutar.
-- Perfil extendido del usuario (auth.users); la app lo lee/actualiza aquí.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.user_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    date_of_birth TIMESTAMPTZ,
    gender TEXT,
    country TEXT,
    city TEXT,
    preferred_currency TEXT NOT NULL DEFAULT 'PEN'
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);

COMMENT ON TABLE public.user_profiles IS 'Perfil del usuario (datos extendidos); vinculado a auth.users.';

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
    ON public.user_profiles FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
    ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own profile"
    ON public.user_profiles FOR DELETE USING (auth.uid() = user_id);
