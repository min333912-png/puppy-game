-- ============================================================================
-- 🐶 해피 멍멍이 타운 (Happy Doggy Town) - Supabase PostgreSQL Schema
-- Supabase SQL Editor에 전체 복사하여 실행(Run)하면 모든 테이블, 뷰, 함수가 생성됩니다.
-- ============================================================================

-- 1. 플레이어 프로필 & 클라우드 세이브 테이블 (player_profiles)
CREATE TABLE IF NOT EXISTS public.player_profiles (
    user_id BIGINT PRIMARY KEY,                     -- 로블록스 Player.UserId
    username TEXT NOT NULL,                         -- 플레이어 계정 이름
    display_name TEXT,                              -- 플레이어 표시 이름
    coins BIGINT NOT NULL DEFAULT 50,               -- 보유 코인
    love BIGINT NOT NULL DEFAULT 0,                 -- 보유 사랑도
    dog_level INT NOT NULL DEFAULT 1,               -- 강아지 레벨
    rebirths INT NOT NULL DEFAULT 0,                -- 환생 횟수 (트로피)
    volunteer_count INT NOT NULL DEFAULT 0,         -- 유기견 봉사 누적 횟수
    yard_tier INT NOT NULL DEFAULT 0,               -- 마당 업그레이드 단계 (0~3)
    active_breed TEXT NOT NULL DEFAULT 'GoldenRetriever', -- 대표 강아지 품종
    active_accessory TEXT NOT NULL DEFAULT '',      -- 장착 악세사리
    owned_dogs JSONB NOT NULL DEFAULT '["GoldenRetriever"]'::jsonb, -- 보유 강아지 배열
    owned_accessories JSONB NOT NULL DEFAULT '[]'::jsonb,           -- 보유 악세사리 배열
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_player_profiles_coins ON public.player_profiles (coins DESC);
CREATE INDEX IF NOT EXISTS idx_player_profiles_volunteer ON public.player_profiles (volunteer_count DESC);
CREATE INDEX IF NOT EXISTS idx_player_profiles_rebirths ON public.player_profiles (rebirths DESC, dog_level DESC);

-- 2. 유기견 보호소 전 세계 누적 통계 테이블 (global_shelter_stats)
CREATE TABLE IF NOT EXISTS public.global_shelter_stats (
    id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),    -- 단일 글로벌 통계 행
    total_rescues BIGINT NOT NULL DEFAULT 0,        -- 전 세계 누적 유기견 봉사/구조 횟수
    total_donated_coins BIGINT NOT NULL DEFAULT 0,  -- 전 세계 누적 지급된 봉사 지원금
    goal_tier INT NOT NULL DEFAULT 1,               -- 글로벌 캠페인 달성 단계
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.global_shelter_stats (id, total_rescues, total_donated_coins, goal_tier)
VALUES (1, 0, 0, 1)
ON CONFLICT (id) DO NOTHING;

-- 3. 유기견 보호소 실시간 구조/봉사 로그 테이블 (shelter_rescue_logs)
CREATE TABLE IF NOT EXISTS public.shelter_rescue_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    username TEXT NOT NULL,
    activity_type TEXT NOT NULL,                    -- 'STRAY_RESCUE', 'FEED', 'WASH', 'VET'
    reward_coins INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shelter_logs_created ON public.shelter_rescue_logs (created_at DESC);

-- 4. 강아지 스피드 레이싱 월드 레코드 테이블 (race_records)
CREATE TABLE IF NOT EXISTS public.race_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    username TEXT NOT NULL,
    dog_breed TEXT NOT NULL,
    lap_time_ms INT NOT NULL,                       -- 주행 기록 (밀리초 단위, 낮을수록 빠름)
    is_riding BOOLEAN NOT NULL DEFAULT false,       -- 강아지 탑승 여부
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_race_records_lap_time ON public.race_records (lap_time_ms ASC);

-- 5. 라이브 이벤트 프로모션 쿠폰 코드 테이블 (promo_codes & code_redemptions)
CREATE TABLE IF NOT EXISTS public.promo_codes (
    code TEXT PRIMARY KEY,                          -- 쿠폰 코드 (대문자)
    reward_coins INT NOT NULL DEFAULT 0,            -- 보상 코인
    reward_love INT NOT NULL DEFAULT 0,             -- 보상 사랑도
    reward_dog TEXT DEFAULT NULL,                   -- 보상 특별 강아지 품종 (선택)
    description TEXT NOT NULL DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.code_redemptions (
    id BIGSERIAL PRIMARY KEY,
    code TEXT NOT NULL REFERENCES public.promo_codes(code) ON DELETE CASCADE,
    user_id BIGINT NOT NULL,
    redeemed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (code, user_id)                          -- 플레이어당 1회만 사용 가능
);

-- 기본 프로모션 쿠폰 3종 시드 데이터
INSERT INTO public.promo_codes (code, reward_coins, reward_love, reward_dog, description, is_active)
VALUES
    ('HAPPYDOG2026', 500, 100, NULL, '해피 멍멍이 타운 오픈 기념 500 코인 & 100 사랑도!', true),
    ('SHELTERHERO', 800, 200, NULL, '유기견 구조 영웅 응원 지원금 800 코인 & 200 사랑도!', true),
    ('SUPABASE', 1500, 300, 'NeonHusky', 'Supabase DB 연동 기념 1,500 코인 & 네온 허스키 지급!', true)
ON CONFLICT (code) DO NOTHING;

-- 6. 유기견 봉사 완료 시 로그 기록 + 전 세계 통계 원자적 증가 RPC 함수
CREATE OR REPLACE FUNCTION public.record_shelter_activity(
    p_user_id BIGINT,
    p_username TEXT,
    p_activity_type TEXT,
    p_reward_coins INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_rescues BIGINT;
    v_total_coins BIGINT;
    v_goal_tier INT;
BEGIN
    INSERT INTO public.shelter_rescue_logs (user_id, username, activity_type, reward_coins)
    VALUES (p_user_id, p_username, p_activity_type, p_reward_coins);

    UPDATE public.global_shelter_stats
    SET total_rescues = total_rescues + 1,
        total_donated_coins = total_donated_coins + p_reward_coins,
        goal_tier = GREATEST(1, FLOOR((total_rescues + 1) / 20.0)::INT + 1),
        updated_at = now()
    WHERE id = 1
    RETURNING total_rescues, total_donated_coins, goal_tier
    INTO v_total_rescues, v_total_coins, v_goal_tier;

    RETURN jsonb_build_object(
        'total_rescues', v_total_rescues,
        'total_donated_coins', v_total_coins,
        'goal_tier', v_goal_tier
    );
END;
$$;

-- 7. RLS (Row Level Security) 설정 - 게임 서버에서 Anon/Service Key로 접근 허용
ALTER TABLE public.player_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.global_shelter_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shelter_rescue_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.race_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.code_redemptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow game server full access player_profiles" ON public.player_profiles;
CREATE POLICY "Allow game server full access player_profiles" ON public.player_profiles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow game server full access global_shelter_stats" ON public.global_shelter_stats;
CREATE POLICY "Allow game server full access global_shelter_stats" ON public.global_shelter_stats FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow game server full access shelter_rescue_logs" ON public.shelter_rescue_logs;
CREATE POLICY "Allow game server full access shelter_rescue_logs" ON public.shelter_rescue_logs FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow game server full access race_records" ON public.race_records;
CREATE POLICY "Allow game server full access race_records" ON public.race_records FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow game server read promo_codes" ON public.promo_codes;
CREATE POLICY "Allow game server read promo_codes" ON public.promo_codes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow game server full access code_redemptions" ON public.code_redemptions;
CREATE POLICY "Allow game server full access code_redemptions" ON public.code_redemptions FOR ALL USING (true) WITH CHECK (true);
