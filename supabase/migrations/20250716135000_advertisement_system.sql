-- Advertisement System Module Migration
-- Extends Lucky Rascals with advertisement campaigns and viewing analytics

-- 1. Create advertisement and campaign types
CREATE TYPE public.ad_status AS ENUM ('active', 'paused', 'completed', 'expired');
CREATE TYPE public.campaign_type AS ENUM ('video', 'banner', 'interactive');
CREATE TYPE public.viewing_status AS ENUM ('started', 'completed', 'abandoned', 'rewarded');

-- 2. Create advertisement campaigns table
CREATE TABLE public.ad_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
    reward_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    minimum_view_duration INTEGER NOT NULL DEFAULT 10, -- seconds
    max_views_per_user INTEGER DEFAULT 3,
    total_budget DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    spent_budget DECIMAL(10,2) DEFAULT 0.00,
    campaign_type public.campaign_type DEFAULT 'video'::public.campaign_type,
    status public.ad_status DEFAULT 'active'::public.ad_status,
    start_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create advertisement views tracking table
CREATE TABLE public.ad_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES public.ad_campaigns(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    view_duration INTEGER NOT NULL DEFAULT 0, -- seconds watched
    completion_percentage DECIMAL(5,2) DEFAULT 0.00,
    reward_earned DECIMAL(10,2) DEFAULT 0.00,
    viewing_status public.viewing_status DEFAULT 'started'::public.viewing_status,
    device_info JSONB,
    interaction_data JSONB,
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    rewarded_at TIMESTAMPTZ
);

-- 4. Create reward transactions table
CREATE TABLE public.reward_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    ad_view_id UUID REFERENCES public.ad_views(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    upi_transaction_id TEXT,
    transaction_status TEXT DEFAULT 'pending',
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create essential indexes for performance
CREATE INDEX idx_ad_campaigns_store_id ON public.ad_campaigns(store_id);
CREATE INDEX idx_ad_campaigns_status ON public.ad_campaigns(status);
CREATE INDEX idx_ad_campaigns_dates ON public.ad_campaigns(start_date, end_date);
CREATE INDEX idx_ad_views_campaign_id ON public.ad_views(campaign_id);
CREATE INDEX idx_ad_views_user_id ON public.ad_views(user_id);
CREATE INDEX idx_ad_views_status ON public.ad_views(viewing_status);
CREATE INDEX idx_reward_transactions_user_id ON public.reward_transactions(user_id);
CREATE INDEX idx_reward_transactions_status ON public.reward_transactions(transaction_status);

-- 6. Enable RLS on all tables
ALTER TABLE public.ad_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_transactions ENABLE ROW LEVEL SECURITY;

-- 7. Helper functions for RLS policies
CREATE OR REPLACE FUNCTION public.is_campaign_active(campaign_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.ad_campaigns ac
    WHERE ac.id = campaign_id 
    AND ac.status = 'active'::public.ad_status
    AND (ac.end_date IS NULL OR ac.end_date > CURRENT_TIMESTAMP)
)
$$;

CREATE OR REPLACE FUNCTION public.can_view_campaign(campaign_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.ad_campaigns ac
    WHERE ac.id = campaign_id 
    AND public.is_campaign_active(campaign_id)
    AND ac.spent_budget < ac.total_budget
)
$$;

CREATE OR REPLACE FUNCTION public.owns_ad_view(view_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.ad_views av
    WHERE av.id = view_id AND av.user_id = auth.uid()
)
$$;

CREATE OR REPLACE FUNCTION public.owns_reward_transaction(transaction_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.reward_transactions rt
    WHERE rt.id = transaction_id AND rt.user_id = auth.uid()
)
$$;

-- 8. RLS Policies
CREATE POLICY "users_can_view_active_campaigns" 
ON public.ad_campaigns 
FOR SELECT
TO authenticated
USING (public.is_campaign_active(id));

CREATE POLICY "users_manage_own_ad_views" 
ON public.ad_views 
FOR ALL
TO authenticated
USING (public.owns_ad_view(id)) 
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_view_own_rewards" 
ON public.reward_transactions 
FOR SELECT
TO authenticated
USING (public.owns_reward_transaction(id));

-- 9. Functions for campaign management
CREATE OR REPLACE FUNCTION public.get_user_campaign_views(user_uuid UUID, campaign_uuid UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT COUNT(*)::INTEGER
FROM public.ad_views av
WHERE av.user_id = user_uuid AND av.campaign_id = campaign_uuid
$$;

CREATE OR REPLACE FUNCTION public.record_ad_view_completion(
    campaign_uuid UUID,
    user_uuid UUID,
    duration_seconds INTEGER,
    completion_percent DECIMAL(5,2)
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    view_id UUID;
    campaign_record RECORD;
    reward_amount DECIMAL(10,2) := 0.00;
    new_status public.viewing_status := 'completed'::public.viewing_status;
BEGIN
    -- Get campaign details
    SELECT * INTO campaign_record
    FROM public.ad_campaigns ac
    WHERE ac.id = campaign_uuid AND public.is_campaign_active(campaign_uuid);
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Campaign not found or inactive';
    END IF;
    
    -- Check if user exceeded max views
    IF public.get_user_campaign_views(user_uuid, campaign_uuid) >= campaign_record.max_views_per_user THEN
        RAISE EXCEPTION 'User has exceeded maximum views for this campaign';
    END IF;
    
    -- Determine reward eligibility
    IF duration_seconds >= campaign_record.minimum_view_duration AND completion_percent >= 80.0 THEN
        reward_amount := campaign_record.reward_amount;
        new_status := 'rewarded'::public.viewing_status;
    END IF;
    
    -- Insert ad view record
    INSERT INTO public.ad_views (
        campaign_id, user_id, view_duration, completion_percentage, 
        reward_earned, viewing_status, completed_at, rewarded_at
    ) VALUES (
        campaign_uuid, user_uuid, duration_seconds, completion_percent,
        reward_amount, new_status, CURRENT_TIMESTAMP,
        CASE WHEN new_status = 'rewarded'::public.viewing_status THEN CURRENT_TIMESTAMP ELSE NULL END
    ) RETURNING id INTO view_id;
    
    -- Create reward transaction if eligible
    IF reward_amount > 0 THEN
        INSERT INTO public.reward_transactions (user_id, ad_view_id, amount)
        VALUES (user_uuid, view_id, reward_amount);
        
        -- Update user total earnings
        UPDATE public.user_profiles
        SET total_earnings = total_earnings + reward_amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = user_uuid;
        
        -- Update campaign spent budget
        UPDATE public.ad_campaigns
        SET spent_budget = spent_budget + reward_amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = campaign_uuid;
    END IF;
    
    RETURN view_id;
END;
$$;

-- 10. Mock data for testing
DO $$
DECLARE
    campaign1_id UUID := gen_random_uuid();
    campaign2_id UUID := gen_random_uuid();
    store1_id UUID;
    store2_id UUID;
    user_id UUID;
BEGIN
    -- Get existing store IDs
    SELECT id INTO store1_id FROM public.stores WHERE name = 'Cafe Mocha' LIMIT 1;
    SELECT id INTO store2_id FROM public.stores WHERE name = 'Pizza Corner' LIMIT 1;
    
    -- Get existing user ID
    SELECT id INTO user_id FROM public.user_profiles LIMIT 1;
    
    -- Create sample campaigns
    INSERT INTO public.ad_campaigns (
        id, title, description, video_url, thumbnail_url, store_id, 
        reward_amount, minimum_view_duration, total_budget, campaign_type
    ) VALUES
        (campaign1_id, 'Try Our New Coffee Blend', 'Experience the rich taste of our premium coffee blend with 20% off your first order.',
         'https://sample-videos.com/zip/10/mp4/mp4-15s.mp4', 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=400',
         store1_id, 2.50, 10, 500.00, 'video'::public.campaign_type),
        (campaign2_id, 'Pizza Party Special', 'Join us for the ultimate pizza experience with fresh ingredients and amazing flavors.',
         'https://sample-videos.com/zip/10/mp4/mp4-20s.mp4', 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
         store2_id, 3.00, 15, 750.00, 'video'::public.campaign_type);
    
    -- Create sample ad view (if user exists)
    IF user_id IS NOT NULL THEN
        INSERT INTO public.ad_views (
            campaign_id, user_id, view_duration, completion_percentage,
            reward_earned, viewing_status, completed_at, rewarded_at
        ) VALUES (
            campaign1_id, user_id, 12, 85.00, 2.50, 
            'rewarded'::public.viewing_status, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    END IF;
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 11. Update cleanup function
CREATE OR REPLACE FUNCTION public.cleanup_advertisement_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete in dependency order
    DELETE FROM public.reward_transactions WHERE ad_view_id IN (
        SELECT id FROM public.ad_views WHERE campaign_id IN (
            SELECT id FROM public.ad_campaigns WHERE title LIKE '%Coffee Blend%' OR title LIKE '%Pizza Party%'
        )
    );
    DELETE FROM public.ad_views WHERE campaign_id IN (
        SELECT id FROM public.ad_campaigns WHERE title LIKE '%Coffee Blend%' OR title LIKE '%Pizza Party%'
    );
    DELETE FROM public.ad_campaigns WHERE title LIKE '%Coffee Blend%' OR title LIKE '%Pizza Party%';
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;