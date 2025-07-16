-- Business Campaign System Module Migration
-- Creates tables for business campaigns, advertisements, and rewards

-- 1. Create additional enum types for business system
CREATE TYPE public.campaign_status AS ENUM ('active', 'paused', 'completed', 'expired');
CREATE TYPE public.ad_type AS ENUM ('video', 'image', 'banner');
CREATE TYPE public.reward_status AS ENUM ('pending', 'completed', 'failed');

-- 2. Create business_campaigns table
CREATE TABLE public.business_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    reward_amount DECIMAL(10,2) NOT NULL,
    min_watch_duration INTEGER DEFAULT 10, -- seconds
    budget_total DECIMAL(10,2) NOT NULL,
    budget_remaining DECIMAL(10,2) NOT NULL,
    status public.campaign_status DEFAULT 'active'::public.campaign_status,
    start_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create advertisements table
CREATE TABLE public.advertisements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES public.business_campaigns(id) ON DELETE CASCADE,
    ad_type public.ad_type NOT NULL,
    content_url TEXT NOT NULL,
    duration INTEGER, -- seconds for video ads
    thumbnail_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create ad_views table to track user engagement
CREATE TABLE public.ad_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES public.business_campaigns(id) ON DELETE CASCADE,
    ad_id UUID REFERENCES public.advertisements(id) ON DELETE CASCADE,
    watch_duration INTEGER NOT NULL, -- seconds watched
    completed BOOLEAN DEFAULT false,
    reward_earned DECIMAL(10,2) DEFAULT 0.00,
    reward_status public.reward_status DEFAULT 'pending'::public.reward_status,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create business_analytics table for tracking
CREATE TABLE public.business_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES public.business_campaigns(id) ON DELETE CASCADE,
    total_views INTEGER DEFAULT 0,
    total_completed_views INTEGER DEFAULT 0,
    total_rewards_paid DECIMAL(10,2) DEFAULT 0.00,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Create essential indexes
CREATE INDEX idx_business_campaigns_business_id ON public.business_campaigns(business_id);
CREATE INDEX idx_business_campaigns_status ON public.business_campaigns(status);
CREATE INDEX idx_advertisements_campaign_id ON public.advertisements(campaign_id);
CREATE INDEX idx_ad_views_user_id ON public.ad_views(user_id);
CREATE INDEX idx_ad_views_campaign_id ON public.ad_views(campaign_id);
CREATE INDEX idx_business_analytics_business_id ON public.business_analytics(business_id);
CREATE INDEX idx_business_analytics_date ON public.business_analytics(date);

-- 7. Enable RLS on new tables
ALTER TABLE public.business_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advertisements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_analytics ENABLE ROW LEVEL SECURITY;

-- 8. Helper functions for RLS
CREATE OR REPLACE FUNCTION public.owns_campaign(campaign_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.business_campaigns bc
    JOIN public.stores s ON bc.business_id = s.id
    WHERE bc.id = campaign_uuid
)
$$;

CREATE OR REPLACE FUNCTION public.can_view_ad(ad_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.advertisements a
    JOIN public.business_campaigns bc ON a.campaign_id = bc.id
    WHERE a.id = ad_uuid AND bc.status = 'active'::public.campaign_status
)
$$;

CREATE OR REPLACE FUNCTION public.owns_ad_view(view_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.ad_views av
    WHERE av.id = view_uuid AND av.user_id = auth.uid()
)
$$;

-- 9. RLS Policies
CREATE POLICY "public_can_view_active_campaigns"
ON public.business_campaigns
FOR SELECT
TO public
USING (status = 'active'::public.campaign_status);

CREATE POLICY "public_can_view_active_ads"
ON public.advertisements
FOR SELECT
TO public
USING (public.can_view_ad(id));

CREATE POLICY "users_manage_own_ad_views"
ON public.ad_views
FOR ALL
TO authenticated
USING (public.owns_ad_view(id))
WITH CHECK (public.owns_ad_view(id));

CREATE POLICY "public_can_view_business_analytics"
ON public.business_analytics
FOR SELECT
TO public
USING (true);

-- 10. Function to update campaign budget after ad view
CREATE OR REPLACE FUNCTION public.update_campaign_budget()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.completed = true AND NEW.reward_status = 'completed'::public.reward_status THEN
        UPDATE public.business_campaigns
        SET budget_remaining = budget_remaining - NEW.reward_earned,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.campaign_id;
        
        -- Update user earnings
        UPDATE public.user_profiles
        SET total_earnings = total_earnings + NEW.reward_earned,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.user_id;
        
        -- Update analytics
        INSERT INTO public.business_analytics (
            business_id, campaign_id, total_views, total_completed_views, total_rewards_paid
        )
        SELECT 
            bc.business_id,
            NEW.campaign_id,
            1,
            1,
            NEW.reward_earned
        FROM public.business_campaigns bc
        WHERE bc.id = NEW.campaign_id
        ON CONFLICT (business_id, campaign_id, date)
        DO UPDATE SET
            total_views = business_analytics.total_views + 1,
            total_completed_views = business_analytics.total_completed_views + 1,
            total_rewards_paid = business_analytics.total_rewards_paid + NEW.reward_earned;
    END IF;
    
    RETURN NEW;
END;
$$;

-- 11. Create trigger for budget updates
CREATE TRIGGER update_campaign_budget_trigger
    AFTER UPDATE ON public.ad_views
    FOR EACH ROW
    EXECUTE FUNCTION public.update_campaign_budget();

-- 12. Mock data for testing
DO $$
DECLARE
    campaign1_id UUID := gen_random_uuid();
    campaign2_id UUID := gen_random_uuid();
    ad1_id UUID := gen_random_uuid();
    ad2_id UUID := gen_random_uuid();
    store1_id UUID;
    store2_id UUID;
    user1_id UUID;
BEGIN
    -- Get existing store and user IDs
    SELECT id INTO store1_id FROM public.stores WHERE name = 'Cafe Mocha' LIMIT 1;
    SELECT id INTO store2_id FROM public.stores WHERE name = 'Pizza Corner' LIMIT 1;
    SELECT id INTO user1_id FROM public.user_profiles LIMIT 1;
    
    -- Create business campaigns
    INSERT INTO public.business_campaigns (
        id, business_id, name, description, reward_amount, 
        budget_total, budget_remaining, status
    ) VALUES
        (campaign1_id, store1_id, 'Coffee Lovers Special', 'Watch our coffee brewing process and earn rewards!', 5.00, 1000.00, 1000.00, 'active'::public.campaign_status),
        (campaign2_id, store2_id, 'Pizza Mania', 'Discover our authentic pizza recipes!', 10.00, 2000.00, 2000.00, 'active'::public.campaign_status);
    
    -- Create advertisements
    INSERT INTO public.advertisements (
        id, campaign_id, ad_type, content_url, duration, thumbnail_url
    ) VALUES
        (ad1_id, campaign1_id, 'video'::public.ad_type, 'https://example.com/coffee-ad.mp4', 30, 'https://example.com/coffee-thumb.jpg'),
        (ad2_id, campaign2_id, 'video'::public.ad_type, 'https://example.com/pizza-ad.mp4', 25, 'https://example.com/pizza-thumb.jpg');
    
    -- Create sample ad view
    IF user1_id IS NOT NULL THEN
        INSERT INTO public.ad_views (
            user_id, campaign_id, ad_id, watch_duration, completed, reward_earned, reward_status
        ) VALUES
            (user1_id, campaign1_id, ad1_id, 30, true, 5.00, 'completed'::public.reward_status);
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 13. Function to get active campaigns by QR code
CREATE OR REPLACE FUNCTION public.get_campaigns_by_qr_code(qr_code_value TEXT)
RETURNS TABLE(
    campaign_id UUID,
    business_name TEXT,
    campaign_name TEXT,
    description TEXT,
    reward_amount DECIMAL(10,2),
    min_watch_duration INTEGER,
    location TEXT,
    ad_content_url TEXT,
    ad_duration INTEGER,
    ad_thumbnail_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bc.id as campaign_id,
        s.name as business_name,
        bc.name as campaign_name,
        bc.description,
        bc.reward_amount,
        bc.min_watch_duration,
        s.location,
        a.content_url as ad_content_url,
        a.duration as ad_duration,
        a.thumbnail_url as ad_thumbnail_url
    FROM public.business_campaigns bc
    JOIN public.stores s ON bc.business_id = s.id
    LEFT JOIN public.advertisements a ON bc.id = a.campaign_id
    WHERE s.qr_code = qr_code_value
      AND bc.status = 'active'::public.campaign_status
      AND bc.budget_remaining > 0
      AND s.is_active = true
      AND (a.is_active = true OR a.is_active IS NULL);
END;
$$;