-- Lucky Rascals Authentication Module Migration
-- Creates tables for user management, OTP verification, and basic app structure

-- 1. Create custom types
CREATE TYPE public.user_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE public.otp_type AS ENUM ('whatsapp', 'sms');
CREATE TYPE public.verification_status AS ENUM ('pending', 'verified', 'failed');

-- 2. Create user_profiles table (intermediary for auth.users)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL UNIQUE,
    upi_id TEXT,
    whatsapp_enabled BOOLEAN DEFAULT false,
    total_earnings DECIMAL(10,2) DEFAULT 0.00,
    status public.user_status DEFAULT 'active'::public.user_status,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create OTP verification table
CREATE TABLE public.otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    otp_type public.otp_type NOT NULL,
    status public.verification_status DEFAULT 'pending'::public.verification_status,
    expires_at TIMESTAMPTZ NOT NULL,
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create stores table
CREATE TABLE public.stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    qr_code TEXT NOT NULL UNIQUE,
    location TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create essential indexes
CREATE INDEX idx_user_profiles_phone ON public.user_profiles(phone_number);
CREATE INDEX idx_otp_verifications_phone ON public.otp_verifications(phone_number);
CREATE INDEX idx_otp_verifications_expires ON public.otp_verifications(expires_at);
CREATE INDEX idx_stores_qr_code ON public.stores(qr_code);

-- 6. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- 7. Helper functions for RLS
CREATE OR REPLACE FUNCTION public.owns_profile(profile_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = profile_id AND up.id = auth.uid()
)
$$;

CREATE OR REPLACE FUNCTION public.can_access_otp(phone_num TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.phone_number = phone_num AND up.id = auth.uid()
)
$$;

-- 8. Create profile creation function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (
        id, 
        phone_number, 
        upi_id, 
        whatsapp_enabled
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.phone, ''),
        COALESCE(NEW.raw_user_meta_data->>'upi_id', ''),
        COALESCE((NEW.raw_user_meta_data->>'whatsapp_enabled')::boolean, false)
    );
    RETURN NEW;
END;
$$;

-- 9. Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 10. RLS Policies
CREATE POLICY "users_own_profile" 
ON public.user_profiles 
FOR ALL
TO authenticated
USING (public.owns_profile(id)) 
WITH CHECK (public.owns_profile(id));

CREATE POLICY "users_can_access_own_otp" 
ON public.otp_verifications 
FOR ALL
TO authenticated
USING (public.can_access_otp(phone_number)) 
WITH CHECK (public.can_access_otp(phone_number));

CREATE POLICY "public_can_view_active_stores" 
ON public.stores 
FOR SELECT
TO public
USING (is_active = true);

-- 11. Mock data for testing
DO $$
DECLARE
    user1_id UUID := gen_random_uuid();
    user2_id UUID := gen_random_uuid();
    store1_id UUID := gen_random_uuid();
    store2_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (user1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'user@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"upi_id": "user@paytm", "whatsapp_enabled": true}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, '+919876543210', '', '', null),
        (user2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'demo@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"upi_id": "demo@gpay", "whatsapp_enabled": false}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, '+919876543211', '', '', null);

    -- Create stores
    INSERT INTO public.stores (id, name, qr_code, location) VALUES
        (store1_id, 'Cafe Mocha', 'QR_CAFE_MOCHA_001', 'MG Road, Bangalore'),
        (store2_id, 'Pizza Corner', 'QR_PIZZA_CORNER_002', 'Brigade Road, Bangalore');

    -- Create sample OTP verification
    INSERT INTO public.otp_verifications (phone_number, otp_code, otp_type, expires_at) VALUES
        ('+919876543210', '123456', 'whatsapp'::public.otp_type, now() + interval '10 minutes');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 12. Cleanup function
CREATE OR REPLACE FUNCTION public.cleanup_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    auth_user_ids_to_delete UUID[];
BEGIN
    -- Get auth user IDs to delete
    SELECT ARRAY_AGG(id) INTO auth_user_ids_to_delete
    FROM auth.users
    WHERE email LIKE '%@example.com';
    
    -- Delete in dependency order
    DELETE FROM public.otp_verifications WHERE phone_number IN (
        SELECT phone_number FROM public.user_profiles WHERE id = ANY(auth_user_ids_to_delete)
    );
    DELETE FROM public.user_profiles WHERE id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.stores WHERE name IN ('Cafe Mocha', 'Pizza Corner');
    DELETE FROM auth.users WHERE id = ANY(auth_user_ids_to_delete);
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;