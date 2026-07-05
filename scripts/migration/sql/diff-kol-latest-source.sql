-- Per-KOL latest inbound/outbound gmail_message_id for zero-tolerance diff.
SELECT k.id::text || '|' || COALESCE(
    (SELECT e.gmail_message_id
     FROM public.emails e
     WHERE e.kol_id = k.id
     ORDER BY e.sent_at DESC
     LIMIT 1),
    ''
) AS line
FROM public.kols k
ORDER BY k.id;
