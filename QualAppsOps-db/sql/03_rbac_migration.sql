-- =============================================================
-- QualAppsOps RBAC Migration
-- Run after init.sql + seed.sql, against an existing database.
--
-- WHAT THIS DOES
--   1. Adds three new values to the existing role_name enum:
--        global_admin, super_admin, user
--   2. Adds display_name / job_title / department to users —
--      azure_ad_object_id, email, and status (active/pending/suspended)
--      already exist and cover azure_object_id / is_active from the spec.
--   3. Seeds the three new roles into the roles table (idempotent).
--
-- IMPORTANT — ENUM VALUES AND TRANSACTIONS
--   PostgreSQL does not allow a newly-added enum value to be referenced
--   in the SAME transaction that added it (ALTER TYPE ... ADD VALUE takes
--   effect only after commit). DBeaver's "Execute SQL Script" and `psql`
--   both run with autocommit ON by default, so each statement below
--   commits independently and this file can be run top-to-bottom as-is.
--   If you wrap this whole file in an explicit BEGIN/COMMIT block, split
--   it into two runs: ALTER TYPE statements first, then everything else.
-- =============================================================

SET search_path TO "QualAppsOps";

-- ── 1. Extend the role_name enum ────────────────────────────────────────
ALTER TYPE role_name ADD VALUE IF NOT EXISTS 'global_admin';
ALTER TYPE role_name ADD VALUE IF NOT EXISTS 'super_admin';
ALTER TYPE role_name ADD VALUE IF NOT EXISTS 'user';

-- ── 2. Add RBAC profile columns to users ────────────────────────────────
-- azure_ad_object_id (existing) is the oid match key.
-- status (existing enum: active/pending/suspended) is the is_active flag —
-- AD4 treats status = 'active' as "active".
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS job_title    VARCHAR(150);
ALTER TABLE users ADD COLUMN IF NOT EXISTS department   VARCHAR(100);

-- ── 3. Seed the three RBAC roles (idempotent via UNIQUE role_name) ──────
INSERT INTO roles (role_name, description)
VALUES
    ('global_admin', 'Can approve users, add/remove super admins, and access /admin'),
    ('super_admin',  'Can search and approve users, and access /admin'),
    ('user',         'Access to the main application only; cannot access /admin')
ON CONFLICT (role_name) DO NOTHING;
