SELECT k.id::text || '|' || COALESCE(
    (SELECT e.gmail_message_id
     FROM emails e
     WHERE e.kol_id = k.id AND e.tenant_id = :'tenant_id'::uuid AND e.deleted_at IS NULL
     ORDER BY e.sent_at DESC
     LIMIT 1),
    ''
) AS line
FROM kols k
WHERE k.tenant_id = :'tenant_id'::uuid AND k.deleted_at IS NULL
ORDER BY k.id;
