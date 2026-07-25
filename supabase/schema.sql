-- ============================================
-- 报备助手 - Supabase 数据库 Schema
-- ============================================

-- 1. 用户档案表
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    pairing_code TEXT UNIQUE,       -- 配对码
    paired_with UUID REFERENCES profiles(id), -- 配对的用户ID
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 位置记录表
CREATE TABLE locations (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    altitude DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    battery_level INTEGER,         -- 电量百分比 0-100
    is_charging BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 状态表
CREATE TABLE statuses (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL,           -- 出门了/到公司了/回家路上/到家了/睡了/忙/自定义
    message TEXT,                   -- 自定义消息
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 聊天消息表
CREATE TABLE messages (
    id BIGSERIAL PRIMARY KEY,
    from_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    to_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. 紧急通知表
CREATE TABLE alerts (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== 索引 ==========
CREATE INDEX idx_locations_user_time ON locations(user_id, created_at DESC);
CREATE INDEX idx_locations_created_at ON locations(created_at DESC);
CREATE INDEX idx_statuses_user_time ON statuses(user_id, created_at DESC);
CREATE INDEX idx_messages_participants ON messages(from_user_id, to_user_id, created_at DESC);
CREATE INDEX idx_messages_unread ON messages(to_user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_alerts_user_time ON alerts(user_id, created_at DESC);

-- ========== 实时订阅 ==========
-- 位置变化实时推送
ALTER PUBLICATION supabase_realtime ADD TABLE locations;
-- 状态变化实时推送
ALTER PUBLICATION supabase_realtime ADD TABLE statuses;
-- 消息实时推送
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
-- 紧急通知实时推送
ALTER PUBLICATION supabase_realtime ADD TABLE alerts;

-- ========== 行级安全策略 ==========
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

-- 用户档案：用户只能看自己和配对的对方
CREATE POLICY "profiles_pair_view" ON profiles
    FOR SELECT USING (id = auth.uid() OR id IN (
        SELECT paired_with FROM profiles WHERE id = auth.uid()
    ));

CREATE POLICY "profiles_self_update" ON profiles
    FOR UPDATE USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- 位置：用户可以看自己或配对对象的位置
CREATE POLICY "locations_pair_view" ON locations
    FOR SELECT USING (
        user_id = auth.uid()
        OR user_id IN (SELECT paired_with FROM profiles WHERE id = auth.uid())
    );

CREATE POLICY "locations_self_insert" ON locations
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- 状态：用户可以看自己或配对对象的状态
CREATE POLICY "statuses_pair_view" ON statuses
    FOR SELECT USING (
        user_id = auth.uid()
        OR user_id IN (SELECT paired_with FROM profiles WHERE id = auth.uid())
    );

CREATE POLICY "statuses_self_insert" ON statuses
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- 消息：只能看和自己相关的消息
CREATE POLICY "messages_own_view" ON messages
    FOR SELECT USING (
        from_user_id = auth.uid() OR to_user_id = auth.uid()
    );

CREATE POLICY "messages_self_insert" ON messages
    FOR INSERT WITH CHECK (from_user_id = auth.uid());

CREATE POLICY "messages_mark_read" ON messages
    FOR UPDATE USING (to_user_id = auth.uid())
    WITH CHECK (to_user_id = auth.uid() AND is_read = TRUE);

-- 紧急通知：用户和其配对对象可查看
CREATE POLICY "alerts_pair_view" ON alerts
    FOR SELECT USING (
        user_id = auth.uid()
        OR user_id IN (SELECT paired_with FROM profiles WHERE id = auth.uid())
    );

CREATE POLICY "alerts_self_insert" ON alerts
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- ========== 函数和触发器 ==========
-- 自动生成6位配对码
CREATE OR REPLACE FUNCTION generate_pairing_code()
RETURNS TEXT AS $$
DECLARE
    code TEXT;
    done BOOLEAN;
BEGIN
    done := FALSE;
    WHILE NOT done LOOP
        code := upper(substr(md5(random()::text), 1, 6));
        done := NOT EXISTS (SELECT 1 FROM profiles WHERE pairing_code = code);
    END LOOP;
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- 注册时自动生成配对码
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profiles
    SET pairing_code = generate_pairing_code()
    WHERE id = NEW.id AND pairing_code IS NULL;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_user_created
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();
