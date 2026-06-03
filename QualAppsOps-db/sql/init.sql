-- =============================================================
-- QualAppsOps Database Schema
-- PostgreSQL 16
-- =============================================================

-- Create schema
CREATE SCHEMA IF NOT EXISTS "QualAppsOps";

-- Use the schema for all subsequent objects
SET search_path TO "QualAppsOps";

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- =============================================================
-- ENUMS
-- =============================================================

CREATE TYPE employment_type    AS ENUM ('permanent', 'part_time', 'intern', 'consultant');
CREATE TYPE employee_status    AS ENUM ('active', 'bench', 'offboarded');
CREATE TYPE address_type       AS ENUM ('home', 'office', 'mailing');
CREATE TYPE client_status      AS ENUM ('active', 'inactive', 'prospect');
CREATE TYPE vendor_type        AS ENUM ('staffing', 'software', 'both');
CREATE TYPE vendor_status      AS ENUM ('active', 'inactive');
CREATE TYPE vendor_inv_status  AS ENUM ('received', 'approved', 'paid', 'disputed');
CREATE TYPE billing_type       AS ENUM ('time_and_materials', 'fixed_price', 'non_billable');
CREATE TYPE project_status     AS ENUM ('active', 'paused', 'completed', 'cancelled');
CREATE TYPE timesheet_status   AS ENUM ('draft', 'submitted', 'approved', 'rejected');
CREATE TYPE deliverable_status AS ENUM ('pending', 'in_progress', 'completed', 'overdue');
CREATE TYPE invoice_status     AS ENUM ('draft', 'sent', 'paid', 'overdue', 'disputed');
CREATE TYPE user_status        AS ENUM ('active', 'pending', 'suspended');
CREATE TYPE permission_action  AS ENUM ('read', 'write', 'delete', 'approve');
CREATE TYPE contact_role       AS ENUM ('billing', 'technical', 'executive_sponsor');
CREATE TYPE role_name          AS ENUM ('admin', 'manager', 'employee', 'consultant', 'finance');


-- =============================================================
-- NOTE ON AUDIT COLUMNS
-- created_by / updated_by reference users(id).
-- Because users is created late in this script, those columns
-- are defined as plain UUID here. FK constraints are added at
-- the very bottom of this file after users exists.
-- =============================================================

COMMENT ON SCHEMA "QualAppsOps" IS 'Central schema for the QualAppsOps consultancy operations platform';


-- =============================================================
-- TABLE: employees
-- =============================================================

CREATE TABLE employees (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    phone           VARCHAR(30),
    employment_type employment_type NOT NULL,
    department      VARCHAR(100),
    job_title       VARCHAR(150),
    start_date      DATE,
    end_date        DATE,
    status          employee_status NOT NULL DEFAULT 'active',
    pay_rate        NUMERIC(10,2),
    bill_rate       NUMERIC(10,2),
    -- audit columns
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_by      UUID
);

COMMENT ON TABLE employees IS 'All people on the company payroll or engaged as consultants, including permanent staff, part-time, interns, and external consultants.';


-- =============================================================
-- TABLE: addresses
-- =============================================================

CREATE TABLE addresses (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id   UUID         NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    address_type  address_type NOT NULL,
    street_line_1 VARCHAR(255) NOT NULL,
    street_line_2 VARCHAR(255),
    city          VARCHAR(100) NOT NULL,
    state         VARCHAR(100),
    zip_code      VARCHAR(20),
    country       VARCHAR(100) NOT NULL DEFAULT 'United States',
    is_primary    BOOLEAN      NOT NULL DEFAULT FALSE,
    -- audit columns
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by    UUID
);

COMMENT ON TABLE addresses IS 'Physical addresses for employees. Separated from the employees table to support multiple address types (home, office, mailing) per person.';

CREATE INDEX idx_addresses_employee_id ON addresses(employee_id);


-- =============================================================
-- TABLE: clients
-- =============================================================

CREATE TABLE clients (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name    VARCHAR(255)  NOT NULL,
    industry        VARCHAR(100),
    website         VARCHAR(255),
    billing_address TEXT,
    status          client_status NOT NULL DEFAULT 'prospect',
    -- audit columns
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    created_by      UUID,
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_by      UUID
);

COMMENT ON TABLE clients IS 'Companies that engage QualApps for consultancy services. Drives project billing and invoicing.';


-- =============================================================
-- TABLE: client_contacts
-- =============================================================

CREATE TABLE client_contacts (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   UUID         NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(255),
    phone       VARCHAR(30),
    role        contact_role NOT NULL,
    is_primary  BOOLEAN      NOT NULL DEFAULT FALSE,
    -- audit columns
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by  UUID
);

COMMENT ON TABLE client_contacts IS 'Individual contacts at client companies, categorised by their relationship role (billing, technical, executive sponsor).';

CREATE INDEX idx_client_contacts_client_id ON client_contacts(client_id);


-- =============================================================
-- TABLE: vendors
-- payment_terms, contract_start, contract_end removed —
-- those are tracked on individual vendor_invoices instead.
-- =============================================================

CREATE TABLE vendors (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name  VARCHAR(255)  NOT NULL,
    vendor_type   vendor_type   NOT NULL,
    contact_name  VARCHAR(200),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(30),
    status        vendor_status NOT NULL DEFAULT 'active',
    -- audit columns
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    created_by    UUID,
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_by    UUID
);

COMMENT ON TABLE vendors IS 'Third-party suppliers — staffing agencies that place contractors, software vendors, or both.';


-- =============================================================
-- TABLE: projects
-- =============================================================

CREATE TABLE projects (
    id                    UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(255)   NOT NULL,
    description           TEXT,
    client_id             UUID           NOT NULL REFERENCES clients(id),
    department            VARCHAR(100),
    purchase_order_number VARCHAR(100),
    billing_type          billing_type   NOT NULL DEFAULT 'time_and_materials',
    budget                NUMERIC(14,2),
    start_date            DATE,
    end_date              DATE,
    status                project_status NOT NULL DEFAULT 'active',
    -- audit columns
    created_at            TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    created_by            UUID,
    updated_at            TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_by            UUID
);

COMMENT ON TABLE projects IS 'Engagements delivered for clients. Links employees via project_assignments and drives timesheet logging and client invoicing.';

CREATE INDEX idx_projects_client_id ON projects(client_id);


-- =============================================================
-- TABLE: vendor_invoices
-- Time-and-materials based: hours + rate added.
-- Amount is derived (hours * rate) but stored for auditability.
-- =============================================================

CREATE TABLE vendor_invoices (
    id             UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id      UUID              NOT NULL REFERENCES vendors(id),
    project_id     UUID              REFERENCES projects(id),
    invoice_number VARCHAR(100)      NOT NULL,
    hours          NUMERIC(7,2),
    rate           NUMERIC(10,2),
    amount         NUMERIC(12,2)     NOT NULL,
    invoice_date   DATE              NOT NULL,
    due_date       DATE,
    paid_date      DATE,
    status         vendor_inv_status NOT NULL DEFAULT 'received',
    notes          TEXT,
    -- audit columns
    created_at     TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    updated_by     UUID
);

COMMENT ON TABLE vendor_invoices IS 'Invoices received FROM vendors for time-and-materials work. hours * rate = amount. Distinct from client_invoices which are sent TO clients.';

CREATE INDEX idx_vendor_invoices_vendor_id  ON vendor_invoices(vendor_id);
CREATE INDEX idx_vendor_invoices_project_id ON vendor_invoices(project_id);


-- =============================================================
-- TABLE: project_assignments
-- =============================================================

CREATE TABLE project_assignments (
    id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id            UUID         NOT NULL REFERENCES projects(id)  ON DELETE CASCADE,
    employee_id           UUID         NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    role_on_project       VARCHAR(150),
    bill_rate             NUMERIC(10,2),
    allocation_percentage INTEGER      CHECK (allocation_percentage BETWEEN 0 AND 100),
    start_date            DATE,
    end_date              DATE,
    -- audit columns
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by            UUID,
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by            UUID
);

COMMENT ON TABLE project_assignments IS 'Tracks which employees work on which projects, their role, bill rate at time of assignment, and capacity allocation percentage. Supports many employees per project and employees working on multiple projects.';

CREATE INDEX idx_project_assignments_project_id  ON project_assignments(project_id);
CREATE INDEX idx_project_assignments_employee_id ON project_assignments(employee_id);


-- =============================================================
-- TABLE: timesheets
-- =============================================================

CREATE TABLE timesheets (
    id           UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id  UUID             NOT NULL REFERENCES employees(id),
    project_id   UUID             NOT NULL REFERENCES projects(id),
    date         DATE             NOT NULL,
    hours        NUMERIC(5,2)     NOT NULL CHECK (hours > 0),
    description  TEXT,
    status       timesheet_status NOT NULL DEFAULT 'draft',
    submitted_at TIMESTAMPTZ,
    approved_by  UUID             REFERENCES employees(id),
    approved_at  TIMESTAMPTZ,
    -- audit columns
    created_at   TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    created_by   UUID,
    updated_at   TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_by   UUID
);

COMMENT ON TABLE timesheets IS 'Daily time entries logged by employees against a specific project. Approved timesheets feed into client invoice generation.';

CREATE INDEX idx_timesheets_employee_id ON timesheets(employee_id);
CREATE INDEX idx_timesheets_project_id  ON timesheets(project_id);


-- =============================================================
-- TABLE: deliverables
-- =============================================================

CREATE TABLE deliverables (
    id             UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id     UUID               NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name           VARCHAR(255)       NOT NULL,
    description    TEXT,
    due_date       DATE,
    completed_date DATE,
    assigned_to    UUID               REFERENCES employees(id),
    status         deliverable_status NOT NULL DEFAULT 'pending',
    -- audit columns
    created_at     TIMESTAMPTZ        NOT NULL DEFAULT NOW(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ        NOT NULL DEFAULT NOW(),
    updated_by     UUID
);

COMMENT ON TABLE deliverables IS 'Trackable work products or milestones within a project, each assigned to an employee with a due date and completion status.';

CREATE INDEX idx_deliverables_project_id ON deliverables(project_id);


-- =============================================================
-- TABLE: client_invoices  (renamed from invoices)
-- Sent TO clients; delivery based.
-- =============================================================

CREATE TABLE client_invoices (
    id                   UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id            UUID           NOT NULL REFERENCES clients(id),
    project_id           UUID           NOT NULL REFERENCES projects(id),
    invoice_number       VARCHAR(100)   NOT NULL UNIQUE,
    billing_period_start DATE,
    billing_period_end   DATE,
    subtotal             NUMERIC(14,2)  NOT NULL DEFAULT 0,
    tax                  NUMERIC(14,2)  NOT NULL DEFAULT 0,
    total                NUMERIC(14,2)  NOT NULL DEFAULT 0,
    status               invoice_status NOT NULL DEFAULT 'draft',
    sent_date            DATE,
    due_date             DATE,
    paid_date            DATE,
    notes                TEXT,
    -- audit columns
    created_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    created_by           UUID,
    updated_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_by           UUID
);

COMMENT ON TABLE client_invoices IS 'Invoices sent TO clients for deliverables completed. Each invoice is broken into line items tied to a project or specific deliverable. Separate from vendor_invoices which are received FROM suppliers.';

CREATE INDEX idx_client_invoices_client_id  ON client_invoices(client_id);
CREATE INDEX idx_client_invoices_project_id ON client_invoices(project_id);


-- =============================================================
-- TABLE: client_invoice_line_items  (renamed from invoice_line_items)
-- Delivery based: each line must be tied to a project, a
-- deliverable, or both. The check constraint enforces this.
-- =============================================================

CREATE TABLE client_invoice_line_items (
    id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id     UUID          NOT NULL REFERENCES client_invoices(id) ON DELETE CASCADE,
    employee_id    UUID          REFERENCES employees(id),
    project_id     UUID          REFERENCES projects(id),
    deliverable_id UUID          REFERENCES deliverables(id),
    description    TEXT          NOT NULL,
    hours          NUMERIC(7,2),
    rate           NUMERIC(10,2),
    amount         NUMERIC(12,2) NOT NULL,
    -- audit columns
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    created_by     UUID,
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_by     UUID,
    -- at least one of project_id or deliverable_id must be set
    CONSTRAINT chk_line_item_context
        CHECK (project_id IS NOT NULL OR deliverable_id IS NOT NULL)
);

COMMENT ON TABLE client_invoice_line_items IS 'Individual line items on a client invoice. Delivery based — every line must reference a project, a deliverable, or both. project_id and deliverable_id may not both be NULL.';

CREATE INDEX idx_cli_line_items_invoice_id     ON client_invoice_line_items(invoice_id);
CREATE INDEX idx_cli_line_items_employee_id    ON client_invoice_line_items(employee_id);
CREATE INDEX idx_cli_line_items_project_id     ON client_invoice_line_items(project_id);
CREATE INDEX idx_cli_line_items_deliverable_id ON client_invoice_line_items(deliverable_id);


-- =============================================================
-- TABLE: roles
-- =============================================================

CREATE TABLE roles (
    id          UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name   role_name NOT NULL UNIQUE,
    description TEXT,
    -- audit columns
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by  UUID
);

COMMENT ON TABLE roles IS 'Named permission groups within the platform (admin, manager, employee, consultant, finance). Assigned to users via user_roles.';


-- =============================================================
-- TABLE: users
-- =============================================================

CREATE TABLE users (
    id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id        UUID         REFERENCES employees(id),
    email              VARCHAR(255) NOT NULL UNIQUE,
    azure_ad_object_id VARCHAR(255) UNIQUE,
    status             user_status  NOT NULL DEFAULT 'pending',
    last_login         TIMESTAMPTZ,
    -- audit columns
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by         UUID,
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by         UUID
);

COMMENT ON TABLE users IS 'Platform login accounts. Optionally linked to an employee record. Supports Azure AD SSO via azure_ad_object_id.';

CREATE INDEX idx_users_email       ON users(email);
CREATE INDEX idx_users_employee_id ON users(employee_id);


-- =============================================================
-- TABLE: user_roles
-- =============================================================

CREATE TABLE user_roles (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id     UUID        NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by UUID        REFERENCES users(id),
    -- audit columns
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by  UUID,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by  UUID,
    UNIQUE (user_id, role_id)
);

COMMENT ON TABLE user_roles IS 'Assigns one or more roles to each user. A user can hold multiple roles (e.g. both manager and finance).';


-- =============================================================
-- TABLE: permissions
-- =============================================================

CREATE TABLE permissions (
    id         UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id    UUID              NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    resource   VARCHAR(100)      NOT NULL,
    action     permission_action NOT NULL,
    -- audit columns
    created_at TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    created_by UUID,
    updated_at TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    updated_by UUID,
    UNIQUE (role_id, resource, action)
);

COMMENT ON TABLE permissions IS 'Granular resource-level permissions attached to a role. Defines what actions (read/write/delete/approve) each role can perform on each named resource.';

CREATE INDEX idx_permissions_role_id ON permissions(role_id);


-- =============================================================
-- AUDIT FK CONSTRAINTS
-- Now that users exists, wire up all created_by / updated_by
-- columns across every table.
-- =============================================================

ALTER TABLE employees               ADD CONSTRAINT fk_employees_created_by               FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE employees               ADD CONSTRAINT fk_employees_updated_by               FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE addresses               ADD CONSTRAINT fk_addresses_created_by               FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE addresses               ADD CONSTRAINT fk_addresses_updated_by               FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE clients                 ADD CONSTRAINT fk_clients_created_by                 FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE clients                 ADD CONSTRAINT fk_clients_updated_by                 FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE client_contacts         ADD CONSTRAINT fk_client_contacts_created_by         FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE client_contacts         ADD CONSTRAINT fk_client_contacts_updated_by         FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE vendors                 ADD CONSTRAINT fk_vendors_created_by                 FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE vendors                 ADD CONSTRAINT fk_vendors_updated_by                 FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE projects                ADD CONSTRAINT fk_projects_created_by                FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE projects                ADD CONSTRAINT fk_projects_updated_by                FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE vendor_invoices         ADD CONSTRAINT fk_vendor_invoices_created_by         FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE vendor_invoices         ADD CONSTRAINT fk_vendor_invoices_updated_by         FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE project_assignments     ADD CONSTRAINT fk_project_assignments_created_by     FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE project_assignments     ADD CONSTRAINT fk_project_assignments_updated_by     FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE timesheets              ADD CONSTRAINT fk_timesheets_created_by              FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE timesheets              ADD CONSTRAINT fk_timesheets_updated_by              FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE deliverables            ADD CONSTRAINT fk_deliverables_created_by            FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE deliverables            ADD CONSTRAINT fk_deliverables_updated_by            FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE client_invoices         ADD CONSTRAINT fk_client_invoices_created_by         FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE client_invoices         ADD CONSTRAINT fk_client_invoices_updated_by         FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE client_invoice_line_items ADD CONSTRAINT fk_cli_line_items_created_by        FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE client_invoice_line_items ADD CONSTRAINT fk_cli_line_items_updated_by        FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE roles                   ADD CONSTRAINT fk_roles_created_by                   FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE roles                   ADD CONSTRAINT fk_roles_updated_by                   FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE users                   ADD CONSTRAINT fk_users_created_by                   FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE users                   ADD CONSTRAINT fk_users_updated_by                   FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE user_roles              ADD CONSTRAINT fk_user_roles_created_by              FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE user_roles              ADD CONSTRAINT fk_user_roles_updated_by              FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE permissions             ADD CONSTRAINT fk_permissions_created_by             FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE permissions             ADD CONSTRAINT fk_permissions_updated_by             FOREIGN KEY (updated_by) REFERENCES users(id);
