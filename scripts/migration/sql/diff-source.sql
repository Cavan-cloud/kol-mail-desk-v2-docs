-- Metrics for diff.sh (legacy Supabase). One metric per line: key|count
SELECT 'kols_total' AS k, COUNT(*)::text AS v FROM public.kols
UNION ALL SELECT 'emails_total', COUNT(*)::text FROM public.emails
UNION ALL SELECT 'feishu_outreach_not_null', COUNT(*)::text FROM public.kols WHERE feishu_outreach_at IS NOT NULL
UNION ALL SELECT 'profiles_total', COUNT(*)::text FROM public.profiles
UNION ALL
SELECT 'stage:' || stage::text, COUNT(*)::text FROM public.kols GROUP BY stage
UNION ALL
SELECT 'owner:' || COALESCE(owner_user_id::text, 'null'), COUNT(*)::text FROM public.kols GROUP BY owner_user_id;
