INSERT INTO scheduled_emails (
    id, tenant_id, kol_id, user_id, template_id, to_email, cc_emails,
    subject, english_body, english_body_html, chinese_draft,
    scheduled_at, status, attempt_count, last_attempt_at,
    gmail_message_id, error, sent_at, cancelled_at,
    created_at, updated_at, version
)
SELECT
    s.id,
    :'tenant_id'::uuid,
    s.kol_id,
    s.user_id,
    s.template_id,
    s.to_email,
    COALESCE(s.cc_emails, '{}'),
    s.subject,
    s.english_body,
    s.english_body_html,
    s.chinese_draft,
    s.scheduled_at,
    CASE
        WHEN s.status = 'processing' THEN 'scheduled'
        ELSE s.status
    END,
    COALESCE(s.attempt_count, 0),
    s.last_attempt_at,
    s.gmail_message_id,
    s.error,
    s.sent_at,
    s.cancelled_at,
    COALESCE(s.created_at, now()),
    COALESCE(s.created_at, now()),
    0
FROM dblink(
    :'source_dsn',
    $$
    SELECT id, kol_id, user_id, template_id, to_email, cc_emails,
           subject, english_body, english_body_html, chinese_draft,
           scheduled_at, status, attempt_count, last_attempt_at,
           gmail_message_id, error, sent_at, cancelled_at, created_at
    FROM public.scheduled_emails
    $$
) AS s(
    id uuid,
    kol_id uuid,
    user_id uuid,
    template_id uuid,
    to_email text,
    cc_emails text[],
    subject text,
    english_body text,
    english_body_html text,
    chinese_draft text,
    scheduled_at timestamptz,
    status text,
    attempt_count integer,
    last_attempt_at timestamptz,
    gmail_message_id text,
    error text,
    sent_at timestamptz,
    cancelled_at timestamptz,
    created_at timestamptz
)
ON CONFLICT (id) DO NOTHING;
