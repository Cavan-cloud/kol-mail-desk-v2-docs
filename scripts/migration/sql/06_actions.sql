INSERT INTO actions (
    id, tenant_id, actor_user_id, action_type, target_type, target_id, metadata,
    created_at, updated_at, version
)
SELECT
    s.id,
    :'tenant_id'::uuid,
    s.user_id,
    s.action::action_type,
    s.target_type,
    s.target_id,
    COALESCE(s.metadata, '{}'::jsonb),
    COALESCE(s.created_at, now()),
    COALESCE(s.created_at, now()),
    0
FROM dblink(
    :'source_dsn',
    $$
    SELECT id, user_id, action::text, target_type, target_id, metadata, created_at
    FROM public.actions
    $$
) AS s(
    id uuid,
    user_id uuid,
    action text,
    target_type text,
    target_id uuid,
    metadata jsonb,
    created_at timestamptz
)
ON CONFLICT (id) DO NOTHING;
