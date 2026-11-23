-- ==============================================================================
-- WarrantyVault: Supabase Database Setup Script
-- ==============================================================================
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New query).
-- This sets up the schema, indexes, Row-Level Security (RLS), and automatic
-- timestamp triggers for personal vehicle battery warranty tracking.
-- ==============================================================================

-- 1. Create companies table
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_user_company_name UNIQUE (user_id, name)
);

-- Note: To ensure case-insensitive uniqueness per user:
CREATE UNIQUE INDEX IF NOT EXISTS idx_companies_user_lower_name
ON public.companies (user_id, lower(trim(name)));

-- 2. Create batteries table
CREATE TABLE IF NOT EXISTS public.batteries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    vehicle_number TEXT NOT NULL,
    owner_name TEXT NOT NULL,
    company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
    company_name TEXT NOT NULL,
    warranty_months INT NOT NULL CHECK (warranty_months BETWEEN 1 AND 120),
    purchase_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    owner_phone TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Indexes for fast search, filter, and sorting
CREATE INDEX IF NOT EXISTS idx_batteries_user_id ON public.batteries (user_id);
CREATE INDEX IF NOT EXISTS idx_batteries_vehicle_number ON public.batteries (vehicle_number);
CREATE INDEX IF NOT EXISTS idx_batteries_expiry_date ON public.batteries (expiry_date);
CREATE INDEX IF NOT EXISTS idx_batteries_created_at ON public.batteries (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_companies_user_id ON public.companies (user_id);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batteries ENABLE ROW LEVEL SECURITY;

-- Grant API access to authenticated and anon roles so PostgREST and Flutter can query tables
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.companies TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.batteries TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- 5. RLS Policies for companies table
DROP POLICY IF EXISTS "Users can view own companies" ON public.companies;
CREATE POLICY "Users can view own companies"
    ON public.companies FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own companies" ON public.companies;
CREATE POLICY "Users can insert own companies"
    ON public.companies FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own companies" ON public.companies;
CREATE POLICY "Users can update own companies"
    ON public.companies FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own companies" ON public.companies;
CREATE POLICY "Users can delete own companies"
    ON public.companies FOR DELETE
    USING (auth.uid() = user_id);

-- 6. RLS Policies for batteries table
DROP POLICY IF EXISTS "Users can view own batteries" ON public.batteries;
CREATE POLICY "Users can view own batteries"
    ON public.batteries FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own batteries" ON public.batteries;
CREATE POLICY "Users can insert own batteries"
    ON public.batteries FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own batteries" ON public.batteries;
CREATE POLICY "Users can update own batteries"
    ON public.batteries FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own batteries" ON public.batteries;
CREATE POLICY "Users can delete own batteries"
    ON public.batteries FOR DELETE
    USING (auth.uid() = user_id);

-- 7. Trigger to keep updated_at current on batteries table
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_batteries_updated_at ON public.batteries;
CREATE TRIGGER trigger_batteries_updated_at
    BEFORE UPDATE ON public.batteries
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 8. Seed default companies helper function
-- This seeds the 7 default companies for the calling user if they don't have companies yet.
CREATE OR REPLACE FUNCTION public.seed_default_companies_for_user()
RETURNS void AS $$
DECLARE
    default_companies TEXT[] := ARRAY['Exide', 'Surya', 'Amaron', 'Star', 'Power', 'AVM', 'ABM'];
    c_name TEXT;
    uid UUID := auth.uid();
BEGIN
    IF uid IS NOT NULL THEN
        FOREACH c_name IN ARRAY default_companies
        LOOP
            INSERT INTO public.companies (user_id, name)
            VALUES (uid, c_name)
            ON CONFLICT (user_id, lower(trim(name))) DO NOTHING;
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
