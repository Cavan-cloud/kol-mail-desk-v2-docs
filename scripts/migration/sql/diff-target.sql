-- Metrics for diff.sh (maildesk v2 target). Filter by tenant_id.
SELECT 'kols_total' AS k, COUNT(*)::text AS v FROM kols WHERE tenant_id = :'tenant_id'::uuid AND deleted_at IS NULL
UNION ALL SELECT 'emails_total', COUNT(*)::text FROM emails WHERE tenant_id = :'tenant_id'::uuid AND deleted_at IS NULL
UNION ALL SELECT 'feishu_outreach_not_null', COUNT(*)::text FROM kols WHERE tenant_id = :'tenant_id'::uuid AND feishu_outreach_at IS NOT NULL AND deleted_at IS NULL
UNION ALL SELECT 'profiles_total', COUNT(*)::text FROM profiles WHERE tenant_id = :'tenant_id'::uuid AND deleted_at IS NULL
UNION ALL
SELECT 'stage:' || stage::text, COUNT(*)::text FROM kols WHERE tenant_id = :'tenant_id'::uuid AND deleted_at IS NULL GROUP BY stage
UNION ALL
SELECT 'owner:' || COALESCE(owner_user_id::text, 'null'), COUNT(*)::text FROM kols WHERE tenant_id = :'tenant_id'::uuid AND deleted_at IS NULL GROUP BY owner_user_id;
