-- =============================================================
-- QualAppsOps Seed Data
-- Run after init.sql
-- =============================================================

SET search_path TO "QualAppsOps";

-- =============================================================
-- EMPLOYEES (3)
-- visa_type and visa_expiry_date removed from schema
-- =============================================================

INSERT INTO employees (id, first_name, last_name, email, phone, employment_type, department, job_title, start_date, status, pay_rate, bill_rate)
VALUES
    ('a1000000-0000-0000-0000-000000000001', 'Sarah', 'Mitchell', 'sarah.mitchell@qualapps.com', '555-101-0001', 'permanent',  'Engineering', 'Senior Software Engineer', '2022-03-01', 'active', 95.00, 145.00),
    ('a1000000-0000-0000-0000-000000000002', 'James', 'Okafor',   'james.okafor@qualapps.com',   '555-101-0002', 'consultant', 'Data',        'Data Analyst',            '2023-06-15', 'active', 70.00, 110.00),
    ('a1000000-0000-0000-0000-000000000003', 'Priya', 'Sharma',   'priya.sharma@qualapps.com',   '555-101-0003', 'permanent',  'Finance',     'Finance Manager',         '2021-01-10', 'active', 85.00, 0.00);

-- Addresses for Sarah
INSERT INTO addresses (employee_id, address_type, street_line_1, city, state, zip_code, country, is_primary)
VALUES
    ('a1000000-0000-0000-0000-000000000001', 'home',   '14 Maple Street', 'Austin', 'TX', '78701', 'United States', TRUE),
    ('a1000000-0000-0000-0000-000000000001', 'office', '200 Tech Blvd',   'Austin', 'TX', '78702', 'United States', FALSE);


-- =============================================================
-- CLIENTS (2)
-- =============================================================

INSERT INTO clients (id, company_name, industry, website, billing_address, status)
VALUES
    ('b2000000-0000-0000-0000-000000000001', 'Nexora Financial',  'Financial Services', 'https://nexorafinancial.com',  '500 Wall Street, New York, NY 10005', 'active'),
    ('b2000000-0000-0000-0000-000000000002', 'HealthBridge Corp', 'Healthcare',         'https://healthbridgecorp.com', '1 Medical Plaza, Houston, TX 77001',  'active');

-- Client contacts
INSERT INTO client_contacts (client_id, first_name, last_name, email, phone, role, is_primary)
VALUES
    ('b2000000-0000-0000-0000-000000000001', 'Robert', 'Chen',     'r.chen@nexorafinancial.com',     '212-555-0101', 'executive_sponsor', TRUE),
    ('b2000000-0000-0000-0000-000000000001', 'Lisa',   'Huang',    'l.huang@nexorafinancial.com',    '212-555-0102', 'billing',           FALSE),
    ('b2000000-0000-0000-0000-000000000002', 'Marcus', 'Williams', 'm.williams@healthbridgecorp.com','713-555-0201', 'technical',         TRUE);


-- =============================================================
-- VENDOR (1)
-- payment_terms, contract_start, contract_end removed from schema
-- =============================================================

INSERT INTO vendors (id, company_name, vendor_type, contact_name, contact_email, contact_phone, status)
VALUES
    ('c3000000-0000-0000-0000-000000000001', 'TalentBridge Staffing', 'staffing', 'Dana Foster', 'dana.foster@talentbridge.com', '800-555-0301', 'active');


-- =============================================================
-- PROJECTS (2)
-- =============================================================

INSERT INTO projects (id, name, description, client_id, department, purchase_order_number, billing_type, budget, start_date, end_date, status)
VALUES
    ('d4000000-0000-0000-0000-000000000001', 'Nexora Data Platform',      'Build a real-time data ingestion and analytics platform for trading operations.', 'b2000000-0000-0000-0000-000000000001', 'Engineering', 'PO-NX-2024-001', 'time_and_materials', 250000.00, '2024-02-01', '2024-10-31', 'active'),
    ('d4000000-0000-0000-0000-000000000002', 'HealthBridge EHR Migration', 'Migrate legacy EHR records to cloud-based system with HIPAA compliance.',         'b2000000-0000-0000-0000-000000000002', 'Data',        'PO-HB-2024-007', 'fixed_price',        180000.00, '2024-04-01', '2024-12-31', 'active');

-- Assign employees to projects
INSERT INTO project_assignments (project_id, employee_id, role_on_project, bill_rate, allocation_percentage, start_date, end_date)
VALUES
    ('d4000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Lead Engineer', 145.00, 80, '2024-02-01', '2024-10-31'),
    ('d4000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 'Data Analyst',  110.00, 50, '2024-02-15', '2024-10-31'),
    ('d4000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 'Data Lead',     110.00, 50, '2024-04-01', '2024-12-31');


-- =============================================================
-- DELIVERABLES (2) — needed so line items can reference them
-- =============================================================

INSERT INTO deliverables (id, project_id, name, description, due_date, assigned_to, status)
VALUES
    ('de000000-0000-0000-0000-000000000001', 'd4000000-0000-0000-0000-000000000001', 'API Gateway v1',         'Design and implement the REST API gateway with auth middleware', '2024-05-31', 'a1000000-0000-0000-0000-000000000001', 'completed'),
    ('de000000-0000-0000-0000-000000000002', 'd4000000-0000-0000-0000-000000000001', 'Data Pipeline — Phase 1','Kafka consumers and initial data pipeline wiring',              '2024-05-31', 'a1000000-0000-0000-0000-000000000002', 'in_progress');


-- =============================================================
-- TIMESHEETS (5 entries)
-- =============================================================

INSERT INTO timesheets (employee_id, project_id, date, hours, description, status, submitted_at, approved_by, approved_at)
VALUES
    ('a1000000-0000-0000-0000-000000000001', 'd4000000-0000-0000-0000-000000000001', '2024-05-06', 8.00, 'API gateway design and implementation',       'approved',  '2024-05-07 09:00:00+00', 'a1000000-0000-0000-0000-000000000003', '2024-05-08 10:00:00+00'),
    ('a1000000-0000-0000-0000-000000000001', 'd4000000-0000-0000-0000-000000000001', '2024-05-07', 7.50, 'Kafka consumer setup and unit tests',          'approved',  '2024-05-08 09:00:00+00', 'a1000000-0000-0000-0000-000000000003', '2024-05-09 10:00:00+00'),
    ('a1000000-0000-0000-0000-000000000001', 'd4000000-0000-0000-0000-000000000001', '2024-05-08', 8.00, 'Code review and PR feedback',                  'submitted', '2024-05-09 09:00:00+00', NULL, NULL),
    ('a1000000-0000-0000-0000-000000000002', 'd4000000-0000-0000-0000-000000000001', '2024-05-06', 6.00, 'Data pipeline schema analysis',                'approved',  '2024-05-07 09:30:00+00', 'a1000000-0000-0000-0000-000000000003', '2024-05-08 11:00:00+00'),
    ('a1000000-0000-0000-0000-000000000002', 'd4000000-0000-0000-0000-000000000002', '2024-05-06', 4.00, 'HealthBridge legacy schema discovery session', 'approved',  '2024-05-07 09:30:00+00', 'a1000000-0000-0000-0000-000000000003', '2024-05-08 11:00:00+00');


-- =============================================================
-- VENDOR INVOICE (1) — time and materials
-- =============================================================

INSERT INTO vendor_invoices (vendor_id, project_id, invoice_number, hours, rate, amount, invoice_date, due_date, status)
VALUES
    ('c3000000-0000-0000-0000-000000000001', 'd4000000-0000-0000-0000-000000000001', 'VND-TB-2024-001', 40.00, 85.00, 3400.00, '2024-05-31', '2024-06-30', 'approved');


-- =============================================================
-- CLIENT INVOICE (1) with LINE ITEMS
-- Renamed from invoices → client_invoices
-- Line items renamed from invoice_line_items → client_invoice_line_items
-- Each line item must reference project_id or deliverable_id
-- =============================================================

INSERT INTO client_invoices (id, client_id, project_id, invoice_number, billing_period_start, billing_period_end, subtotal, tax, total, status, sent_date, due_date)
VALUES
    ('e5000000-0000-0000-0000-000000000001', 'b2000000-0000-0000-0000-000000000001', 'd4000000-0000-0000-0000-000000000001', 'INV-2024-0001', '2024-05-01', '2024-05-31', 4612.50, 0.00, 4612.50, 'sent', '2024-06-01', '2024-07-01');

-- Line items: project_id or deliverable_id must be non-null (check constraint)
INSERT INTO client_invoice_line_items (invoice_id, employee_id, project_id, deliverable_id, description, hours, rate, amount)
VALUES
    -- tied to a specific deliverable
    ('e5000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'd4000000-0000-0000-0000-000000000001', 'de000000-0000-0000-0000-000000000001', 'Sarah Mitchell — API Gateway v1 delivery',              23.50, 145.00, 3407.50),
    -- tied to project only (pipeline work spans multiple deliverables)
    ('e5000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 'd4000000-0000-0000-0000-000000000001', NULL,                                   'James Okafor — Data analysis services May 2024',        10.00, 110.00, 1100.00),
    -- expense reimbursement: tied to project
    ('e5000000-0000-0000-0000-000000000001', NULL,                                   'd4000000-0000-0000-0000-000000000001', NULL,                                   'Reimbursable expenses — cloud compute (AWS)',            NULL,  NULL,   105.00);


-- =============================================================
-- ROLES
-- =============================================================

INSERT INTO roles (id, role_name, description)
VALUES
    ('f6000000-0000-0000-0000-000000000001', 'admin',      'Full platform access including user management and system configuration'),
    ('f6000000-0000-0000-0000-000000000002', 'manager',    'Can approve timesheets, view all project financials, and manage assignments'),
    ('f6000000-0000-0000-0000-000000000003', 'employee',   'Can log timesheets and view their own project assignments'),
    ('f6000000-0000-0000-0000-000000000004', 'consultant', 'External consultant access: log timesheets, view assigned projects only'),
    ('f6000000-0000-0000-0000-000000000005', 'finance',    'Can create and manage invoices, view billing data across all projects');

-- Permissions (sample subset)
INSERT INTO permissions (role_id, resource, action)
VALUES
    ('f6000000-0000-0000-0000-000000000001', 'employees',       'read'),
    ('f6000000-0000-0000-0000-000000000001', 'employees',       'write'),
    ('f6000000-0000-0000-0000-000000000001', 'employees',       'delete'),
    ('f6000000-0000-0000-0000-000000000001', 'client_invoices', 'approve'),
    ('f6000000-0000-0000-0000-000000000002', 'timesheets',      'approve'),
    ('f6000000-0000-0000-0000-000000000002', 'projects',        'read'),
    ('f6000000-0000-0000-0000-000000000003', 'timesheets',      'write'),
    ('f6000000-0000-0000-0000-000000000003', 'timesheets',      'read'),
    ('f6000000-0000-0000-0000-000000000005', 'client_invoices', 'write'),
    ('f6000000-0000-0000-0000-000000000005', 'client_invoices', 'read');


-- =============================================================
-- USERS (3 with different roles)
-- =============================================================

INSERT INTO users (id, employee_id, email, azure_ad_object_id, status, created_at)
VALUES
    ('e7000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000003', 'priya.sharma@qualapps.com',   'aad-priya-0001', 'active', NOW()),
    ('e7000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'sarah.mitchell@qualapps.com', 'aad-sarah-0002', 'active', NOW()),
    ('e7000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'james.okafor@qualapps.com',   'aad-james-0003', 'active', NOW());

-- Assign roles: Priya=manager+finance, Sarah=employee, James=consultant
INSERT INTO user_roles (user_id, role_id, assigned_by)
VALUES
    ('e7000000-0000-0000-0000-000000000001', 'f6000000-0000-0000-0000-000000000002', 'e7000000-0000-0000-0000-000000000001'),
    ('e7000000-0000-0000-0000-000000000001', 'f6000000-0000-0000-0000-000000000005', 'e7000000-0000-0000-0000-000000000001'),
    ('e7000000-0000-0000-0000-000000000002', 'f6000000-0000-0000-0000-000000000003', 'e7000000-0000-0000-0000-000000000001'),
    ('e7000000-0000-0000-0000-000000000003', 'f6000000-0000-0000-0000-000000000004', 'e7000000-0000-0000-0000-000000000001');
