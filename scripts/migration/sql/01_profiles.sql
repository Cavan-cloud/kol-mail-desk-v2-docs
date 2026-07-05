-- Profiles: preserve UUID ids; drop legacy plaintext token columns (migrated separately).
INSERT INTO profiles (
    id, tenant_id, display_name, email, role, status,
    mentor_user_id, feishu_operator_name,
    last_synced_history_id, last_synced_at,
    approved_at, approved_by, departed_at,
    created_at, updated_at, version
)
SELECT
    s.id,
    :'tenant_id'::uuid,
    s.display_name,
    s.email,
    s.role,
    s.status,
    s.mentor_user_id,
    s.feishu_operator_name,
    s.last_synced_history_id,
    s.last_synced_at,
    s.approved_at,
    s.approved_by,
    s.departed_at,
    COALESCE(s.created_at, now()),
    COALESCE(s.created_at, now()),
    0
FROM dblink(
    :'source_dsn',
    $$
    SELECT id, display_name, email, role, status,
           mentor_user_id, feishu_operator_name,
           last_synced_history_id, last_synced_at,
           approved_at, approved_by, departed_at, created_at
    FROM public.profiles
    $$
) AS s(
    id uuid,
    display_name text,
    email text,
    role text,
    status text,
    mentor_user_id uuid,
    feishu_operator_name text,
    last_synced_history_id text,
    last_synced_at timestamptz,
    approved_at timestamptz,
    approved_by uuid,
    departed_at timestamptz,
    created_at timestamptz
)
ON CONFLICT (id) DO NOTHING;
