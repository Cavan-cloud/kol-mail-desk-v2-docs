INSERT INTO email_templates (
    id, tenant_id, name, scenario, subject, body,
    used_count, last_used_at, created_at, updated_at, created_by, version
)
SELECT
    s.id,
    :'tenant_id'::uuid,
    s.name,
    s.scenario,
    s.subject,
    s.body,
    COALESCE(s.used_count, 0),
    s.last_used_at,
    COALESCE(s.created_at, now()),
    COALESCE(s.created_at, now()),
    s.created_by,
    0
FROM dblink(
    :'source_dsn',
    $$
    SELECT id, name, scenario, subject, body, used_count, last_used_at, created_at, created_by
    FROM public.email_templates
    $$
) AS s(
    id uuid,
    name text,
    scenario text,
    subject text,
    body text,
    used_count integer,
    last_used_at timestamptz,
    created_at timestamptz,
    created_by uuid
)
ON CONFLICT (id) DO NOTHING;
