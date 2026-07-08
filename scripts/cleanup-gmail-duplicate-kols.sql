-- Cleanup gmail duplicate KOL rows created before onboarding operator-name fix.
--
-- Problem: Gmail sync used to insert source=gmail rows for emails that already had
-- Feishu-backed KOL rows (same normalized_email), inflating owned counts and board totals.
--
-- This script:
--   1) Re-links emails / scheduled_emails / email_threads to the best Feishu sibling row
--   2) Soft-deletes the redundant source=gmail rows (sets deleted_at = now())
--
-- Prerequisites:
--   - Deploy backend fix (GmailPersistService + reconcileAndAssignKolsByOperatorName)
--   - Ask affected users to re-save profile (triggers reconcile) OR run this after deploy
--
-- Usage:
--   # Dry-run (default — read-only preview)
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/cleanup-gmail-duplicate-kols.sql
--
--   # Apply changes
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v APPLY=1 -f scripts/cleanup-gmail-duplicate-kols.sql
--
--   # Or via wrapper
--   ./scripts/cleanup-gmail-duplicate-kols.sh
--   ./scripts/cleanup-gmail-duplicate-kols.sh --apply

\set QUIET on
\pset footer off
\timing on

\if :{?APPLY}
\else
  \set APPLY 0
\endif

\echo ''
\echo '=== Gmail duplicate KOL cleanup (APPLY=' :APPLY ') ==='
\echo ''

\echo '--- Before: row counts ---'
SELECT source, COUNT(*) AS rows
FROM kols
WHERE deleted_at IS NULL
GROUP BY source
ORDER BY source;

\echo ''
\echo '--- Candidates: source=gmail with Feishu sibling (same normalized_email) ---'

WITH gmail_dupes AS (
    SELECT
        g.id,
        g.tenant_id,
        g.normalized_email,
        g.feishu_operator_name,
        g.owner_user_id,
        g.created_at
    FROM kols g
    WHERE g.deleted_at IS NULL
      AND g.source = 'gmail'
      AND EXISTS (
          SELECT 1
          FROM kols f
          WHERE f.deleted_at IS NULL
            AND f.tenant_id = g.tenant_id
            AND f.normalized_email = g.normalized_email
            AND f.id <> g.id
            AND (f.source = 'feishu' OR f.feishu_record_id IS NOT NULL)
      )
)
SELECT
    COUNT(*) AS gmail_duplicate_rows,
    COUNT(*) FILTER (WHERE owner_user_id IS NOT NULL) AS still_owned,
    COUNT(DISTINCT normalized_email) AS distinct_emails
FROM gmail_dupes;

\echo ''
\echo '--- Preview: first 20 duplicate rows ---'

WITH gmail_dupes AS (
    SELECT
        g.id,
        g.normalized_email,
        g.feishu_operator_name,
        g.owner_user_id,
        p.display_name AS owner_name
    FROM kols g
    LEFT JOIN profiles p ON p.id = g.owner_user_id
    WHERE g.deleted_at IS NULL
      AND g.source = 'gmail'
      AND EXISTS (
          SELECT 1
          FROM kols f
          WHERE f.deleted_at IS NULL
            AND f.tenant_id = g.tenant_id
            AND f.normalized_email = g.normalized_email
            AND f.id <> g.id
            AND (f.source = 'feishu' OR f.feishu_record_id IS NOT NULL)
      )
)
SELECT id, normalized_email, feishu_operator_name, owner_name
FROM gmail_dupes
ORDER BY normalized_email
LIMIT 20;

\if :APPLY
\echo ''
\echo '--- Applying cleanup (transaction) ---'

BEGIN;

CREATE TEMP TABLE _gmail_dup_cleanup ON COMMIT DROP AS
WITH gmail_dupes AS (
    SELECT
        g.id AS gmail_kol_id,
        g.tenant_id,
        g.normalized_email,
        g.feishu_operator_name,
        g.owner_user_id
    FROM kols g
    WHERE g.deleted_at IS NULL
      AND g.source = 'gmail'
      AND EXISTS (
          SELECT 1
          FROM kols f
          WHERE f.deleted_at IS NULL
            AND f.tenant_id = g.tenant_id
            AND f.normalized_email = g.normalized_email
            AND f.id <> g.id
            AND (f.source = 'feishu' OR f.feishu_record_id IS NOT NULL)
      )
),
targets AS (
    SELECT DISTINCT ON (d.gmail_kol_id)
        d.gmail_kol_id,
        f.id AS target_kol_id
    FROM gmail_dupes d
    JOIN kols f
      ON f.tenant_id = d.tenant_id
     AND f.normalized_email = d.normalized_email
     AND f.id <> d.gmail_kol_id
     AND f.deleted_at IS NULL
     AND (f.source = 'feishu' OR f.feishu_record_id IS NOT NULL)
    ORDER BY
        d.gmail_kol_id,
        CASE
            WHEN regexp_replace(
                     lower(replace(trim(f.feishu_operator_name), '@', '')),
                     '\s', '', 'g'
                 ) = regexp_replace(
                     lower(replace(trim(d.feishu_operator_name), '@', '')),
                     '\s', '', 'g'
                 )
            THEN 0 ELSE 1
        END,
        CASE WHEN f.owner_user_id IS NOT NULL THEN 0 ELSE 1 END,
        CASE WHEN trim(coalesce(f.feishu_operator_name, '')) <> '' THEN 0 ELSE 1 END,
        f.created_at ASC
)
SELECT * FROM targets;

\echo 'Rows to soft-delete:'
SELECT COUNT(*) FROM _gmail_dup_cleanup;

\echo 'Emails to re-link:'
SELECT COUNT(*)
FROM emails e
JOIN _gmail_dup_cleanup c ON c.gmail_kol_id = e.kol_id
WHERE e.deleted_at IS NULL;

UPDATE emails e
SET kol_id = c.target_kol_id,
    updated_at = now()
FROM _gmail_dup_cleanup c
WHERE e.kol_id = c.gmail_kol_id
  AND e.deleted_at IS NULL
  AND e.kol_id IS DISTINCT FROM c.target_kol_id;

UPDATE scheduled_emails s
SET kol_id = c.target_kol_id,
    updated_at = now()
FROM _gmail_dup_cleanup c
WHERE s.kol_id = c.gmail_kol_id
  AND s.kol_id IS DISTINCT FROM c.target_kol_id;

UPDATE email_threads t
SET kol_id = c.target_kol_id,
    updated_at = now()
FROM _gmail_dup_cleanup c
WHERE t.kol_id = c.gmail_kol_id
  AND t.kol_id IS DISTINCT FROM c.target_kol_id;

UPDATE kols g
SET owner_user_id = NULL,
    updated_at = now()
FROM _gmail_dup_cleanup c
WHERE g.id = c.gmail_kol_id
  AND g.owner_user_id IS NOT NULL;

UPDATE kols g
SET deleted_at = now(),
    updated_at = now()
FROM _gmail_dup_cleanup c
WHERE g.id = c.gmail_kol_id
  AND g.deleted_at IS NULL;

COMMIT;

\echo ''
\echo '--- After: row counts ---'
SELECT source, COUNT(*) AS rows
FROM kols
WHERE deleted_at IS NULL
GROUP BY source
ORDER BY source;

\else
\echo ''
\echo 'Dry-run only. Re-run with APPLY=1 or ./scripts/cleanup-gmail-duplicate-kols.sh --apply to execute.'
\endif

\echo ''
\echo 'Done.'
