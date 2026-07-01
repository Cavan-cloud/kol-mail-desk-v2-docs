-- Feishu stage mapping audit (P2-T09 / v3.3 §6 / F-STAGE-01)
--
-- Usage:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/feishu-stage-mapping-audit.sql
--
-- Part 1 — fixture diff: SQL CASE mirror of FeishuStageMapper.java vs canonical expected values.
-- Part 2 — live distribution of feishu-source KOL stages after a sync/backfill run.
-- Part 3 — anomalies (legacy enum values, empty stages on active rows).

\set QUIET on
\pset footer off
\timing off

\echo ''
\echo '=== Part 1: fixture mapping diff (expect 0 mismatches) ==='

WITH normalized AS (
    SELECT
        feishu_status,
        expected_stage,
        regexp_replace(feishu_status, '\s+', '', 'g') AS text_value
    FROM (
        VALUES
            -- outreach
            ('已询价', 'outreach'),
            ('询价', 'outreach'),
            ('追+', 'outreach'),
            ('二追', 'outreach'),
            ('追加', 'outreach'),
            ('其他追问', 'outreach'),
            -- negotiating
            ('议价中', 'negotiating'),
            ('议价', 'negotiating'),
            -- confirmed
            ('价格确定待合作', 'confirmed'),
            ('已合作待签合同', 'confirmed'),
            ('已合作', 'confirmed'),
            -- producing
            ('待脚本', 'producing'),
            ('脚本修改中', 'producing'),
            ('待初稿', 'producing'),
            ('修改视频中', 'producing'),
            -- reviewing
            ('已审核待发布', 'reviewing'),
            ('待发布', 'reviewing'),
            -- published / paying
            ('已发布待付款', 'published'),
            ('已付款', 'paying'),
            -- reinvest / declined
            ('合作过', 'reinvest'),
            ('已拒绝', 'declined'),
            ('剔除合作', 'declined'),
            ('放弃合作', 'declined'),
            -- administrative → preserve existing (NULL expected)
            ('未合作过', NULL),
            ('移至3月', NULL),
            ('转4月', NULL),
            -- unknown / empty
            (' ', NULL),
            ('未知状态XYZ', NULL)
    ) AS fixture(feishu_status, expected_stage)
),
computed AS (
    SELECT
        feishu_status,
        expected_stage,
        CASE
            WHEN text_value = '' THEN NULL
            WHEN text_value LIKE '%未合作过%'
              OR text_value LIKE '%移至%'
              OR (text_value LIKE '%转%' AND text_value LIKE '%月%') THEN NULL
            WHEN text_value LIKE '%拒绝%'
              OR text_value LIKE '%剔除%'
              OR text_value LIKE '%放弃%' THEN 'declined'
            WHEN text_value LIKE '%发布待付款%' THEN 'published'
            WHEN text_value LIKE '%已付款%' THEN 'paying'
            WHEN text_value LIKE '%已审核待发布%'
              OR text_value LIKE '%待发布%' THEN 'reviewing'
            WHEN text_value LIKE '%脚本%'
              OR text_value LIKE '%初稿%'
              OR text_value LIKE '%视频%' THEN 'producing'
            WHEN text_value LIKE '%待签合同%'
              OR text_value LIKE '%价格确定%'
              OR text_value LIKE '%已合作%' THEN 'confirmed'
            WHEN text_value LIKE '%议价%' THEN 'negotiating'
            WHEN text_value LIKE '%询价%'
              OR text_value LIKE '%追%' THEN 'outreach'
            WHEN text_value LIKE '%合作过%' THEN 'reinvest'
            ELSE NULL
        END AS computed_stage
    FROM normalized
)
SELECT
    feishu_status,
    expected_stage,
    computed_stage,
    CASE
        WHEN expected_stage IS NULL AND computed_stage IS NULL THEN 'ok'
        WHEN expected_stage IS NOT DISTINCT FROM computed_stage THEN 'ok'
        ELSE 'MISMATCH'
    END AS verdict
FROM computed
WHERE expected_stage IS DISTINCT FROM computed_stage
ORDER BY feishu_status;

\echo ''
\echo '=== Part 1 summary ==='
WITH normalized AS (
    SELECT
        feishu_status,
        expected_stage,
        regexp_replace(feishu_status, '\s+', '', 'g') AS text_value
    FROM (
        VALUES
            ('已询价', 'outreach'),
            ('询价', 'outreach'),
            ('追+', 'outreach'),
            ('二追', 'outreach'),
            ('追加', 'outreach'),
            ('其他追问', 'outreach'),
            ('议价中', 'negotiating'),
            ('议价', 'negotiating'),
            ('价格确定待合作', 'confirmed'),
            ('已合作待签合同', 'confirmed'),
            ('已合作', 'confirmed'),
            ('待脚本', 'producing'),
            ('脚本修改中', 'producing'),
            ('待初稿', 'producing'),
            ('修改视频中', 'producing'),
            ('已审核待发布', 'reviewing'),
            ('待发布', 'reviewing'),
            ('已发布待付款', 'published'),
            ('已付款', 'paying'),
            ('合作过', 'reinvest'),
            ('已拒绝', 'declined'),
            ('剔除合作', 'declined'),
            ('放弃合作', 'declined'),
            ('未合作过', NULL),
            ('移至3月', NULL),
            ('转4月', NULL),
            (' ', NULL),
            ('未知状态XYZ', NULL)
    ) AS fixture(feishu_status, expected_stage)
),
computed AS (
    SELECT
        expected_stage,
        CASE
            WHEN text_value = '' THEN NULL
            WHEN text_value LIKE '%未合作过%'
              OR text_value LIKE '%移至%'
              OR (text_value LIKE '%转%' AND text_value LIKE '%月%') THEN NULL
            WHEN text_value LIKE '%拒绝%'
              OR text_value LIKE '%剔除%'
              OR text_value LIKE '%放弃%' THEN 'declined'
            WHEN text_value LIKE '%发布待付款%' THEN 'published'
            WHEN text_value LIKE '%已付款%' THEN 'paying'
            WHEN text_value LIKE '%已审核待发布%'
              OR text_value LIKE '%待发布%' THEN 'reviewing'
            WHEN text_value LIKE '%脚本%'
              OR text_value LIKE '%初稿%'
              OR text_value LIKE '%视频%' THEN 'producing'
            WHEN text_value LIKE '%待签合同%'
              OR text_value LIKE '%价格确定%'
              OR text_value LIKE '%已合作%' THEN 'confirmed'
            WHEN text_value LIKE '%议价%' THEN 'negotiating'
            WHEN text_value LIKE '%询价%'
              OR text_value LIKE '%追%' THEN 'outreach'
            WHEN text_value LIKE '%合作过%' THEN 'reinvest'
            ELSE NULL
        END AS computed_stage
    FROM normalized
)
SELECT
    count(*) FILTER (
        WHERE expected_stage IS NOT DISTINCT FROM computed_stage
    ) AS fixture_ok,
    count(*) FILTER (
        WHERE expected_stage IS DISTINCT FROM computed_stage
    ) AS fixture_mismatch,
    count(*) AS fixture_total
FROM computed;

\echo ''
\echo '=== Part 2: feishu-source KOL stage distribution ==='
SELECT
    stage::text AS stage,
    count(*) AS kol_count
FROM kols
WHERE source = 'feishu'
  AND deleted_at IS NULL
GROUP BY stage
ORDER BY kol_count DESC, stage;

\echo ''
\echo '=== Part 2b: v3.3 funnel stages present? (10 stages, excl. legacy replied) ==='
WITH funnel(stage) AS (
    VALUES
        ('outreach'),
        ('negotiating'),
        ('confirmed'),
        ('producing'),
        ('reviewing'),
        ('published'),
        ('paying'),
        ('reinvest'),
        ('declined')
),
present AS (
    SELECT DISTINCT stage::text AS stage
    FROM kols
    WHERE source = 'feishu'
      AND deleted_at IS NULL
)
SELECT
    funnel.stage,
    CASE WHEN present.stage IS NOT NULL THEN 'present' ELSE 'missing' END AS status
FROM funnel
LEFT JOIN present ON present.stage = funnel.stage
ORDER BY funnel.stage;

\echo ''
\echo '=== Part 3: anomalies (legacy replied stage on feishu rows) ==='
SELECT
    id,
    email,
    stage::text AS stage,
    feishu_operator_name,
    last_feishu_synced_at
FROM kols
WHERE source = 'feishu'
  AND deleted_at IS NULL
  AND stage = 'replied'
ORDER BY last_feishu_synced_at DESC NULLS LAST
LIMIT 20;

\echo ''
\echo 'Audit complete.'
