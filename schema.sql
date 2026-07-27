-- ============================================================================
-- MON Logistics — Nestlé flow-improvement project
-- Project management schema: Phases > Tasks > Subtasks, Team, Objectives
-- ============================================================================
-- Run in Supabase: Dashboard > SQL Editor > New query > paste > Run
--
-- This script is safe to re-run: it drops and recreates everything, so you
-- can paste it again any time you want to reset to a clean state (careful —
-- that also wipes any real data you've entered since the last run).
-- ============================================================================

drop table if exists subtasks cascade;
drop table if exists tasks cascade;
drop table if exists phases cascade;
drop table if exists team_members cascade;
drop table if exists objectives cascade;
drop type if exists item_status cascade;
drop type if exists item_priority cascade;

create type item_status as enum ('not_started', 'in_progress', 'blocked', 'done');
create type item_priority as enum ('high', 'medium', 'low');

-- ----------------------------------------------------------------------------
-- 1. Team members
-- ----------------------------------------------------------------------------
create table team_members (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role text,                      -- e.g. "Project Lead", "Planning Coordinator"
  company text default 'MON Logistics',  -- 'MON Logistics' or 'Nestlé'
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 2. Phases — the top-level structure of the project
-- ----------------------------------------------------------------------------
create table phases (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  sort_order int default 0,
  start_date date,
  end_date date,
  status item_status not null default 'not_started',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 3. Tasks — each task belongs to exactly one phase, and has one owner.
-- description = what needs to be done. notes = running commentary
-- (why it's blocked, decisions made, context for whoever picks it up next).
-- start_date/due_date = planned. completed_date = when it actually finished,
-- so you can see planned vs. actual and catch slipping deadlines.
-- ----------------------------------------------------------------------------
create table tasks (
  id uuid primary key default gen_random_uuid(),
  phase_id uuid not null references phases(id) on delete cascade,
  title text not null,
  description text,
  notes text,
  assignee_id uuid references team_members(id) on delete set null,
  status item_status not null default 'not_started',
  priority item_priority not null default 'medium',
  start_date date,
  due_date date,
  completed_date date,
  sort_order int default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 4. Subtasks — each subtask belongs to exactly one task, and has one owner.
-- Same detail fields as tasks (description, notes, full set of dates) so a
-- subtask is a first-class trackable item, not just a checklist line.
-- ----------------------------------------------------------------------------
create table subtasks (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks(id) on delete cascade,
  title text not null,
  description text,
  notes text,
  assignee_id uuid references team_members(id) on delete set null,
  status item_status not null default 'not_started',
  start_date date,
  due_date date,
  completed_date date,
  sort_order int default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 5. Objectives — project-level goals, independent of the phase structure
-- ----------------------------------------------------------------------------
create table objectives (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  metric_label text,          -- e.g. "Manual re-entries per order"
  unit text,                  -- e.g. "%", "steps", "people"
  current_value numeric,
  target_value numeric,
  status item_status not null default 'in_progress',
  sort_order int default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 6. Security — dashboard is shared via a public link, no login.
--
-- Team members, phases, tasks and subtasks are managed from the dashboard's
-- "Manage" tab, so anon gets full read/write (insert/update/delete) on
-- those four tables. Objectives stay read-only for now (edit them directly
-- in Supabase Table Editor if needed).
--
-- IMPORTANT: because there's no login, ANYONE with the dashboard link can
-- create, edit, or delete phases/tasks/subtasks/team members. That was a
-- deliberate choice for simplicity — if this ever needs to be restricted,
-- swap these policies for ones scoped to `auth.uid()` once Supabase Auth
-- is added (ask for help wiring that up if needed).
-- ----------------------------------------------------------------------------
alter table team_members enable row level security;
alter table phases enable row level security;
alter table tasks enable row level security;
alter table subtasks enable row level security;
alter table objectives enable row level security;

create policy "public read" on team_members for select using (true);
create policy "public write" on team_members for insert with check (true);
create policy "public update" on team_members for update using (true) with check (true);
create policy "public delete" on team_members for delete using (true);

create policy "public read" on phases for select using (true);
create policy "public write" on phases for insert with check (true);
create policy "public update" on phases for update using (true) with check (true);
create policy "public delete" on phases for delete using (true);

create policy "public read" on tasks for select using (true);
create policy "public write" on tasks for insert with check (true);
create policy "public update" on tasks for update using (true) with check (true);
create policy "public delete" on tasks for delete using (true);

create policy "public read" on subtasks for select using (true);
create policy "public write" on subtasks for insert with check (true);
create policy "public update" on subtasks for update using (true) with check (true);
create policy "public delete" on subtasks for delete using (true);

create policy "public read" on objectives for select using (true);

-- ----------------------------------------------------------------------------
-- 7. Example data so the dashboard shows something right away.
-- Replace with the real project team/phases once known
-- (or just re-run this whole script from the top to reset everything).
-- ----------------------------------------------------------------------------
insert into team_members (name, role, company, email) values
('Théo B.', 'Project Lead', 'MON Logistics', 'theo.b@monlogistics.com'),
('Alex Tremblay', 'Planning Coordinator', 'MON Logistics', null),
('Sam Roy', 'Production Supervisor', 'MON Logistics', null),
('Jordan Leblanc', 'Shipping Coordinator', 'MON Logistics', null),
('Chris Dubois', 'Customs Broker', 'MON Logistics', null),
('Nestlé Contact', 'Account Manager', 'Nestlé', null);

insert into phases (name, description, sort_order, start_date, end_date, status) values
('Planning', 'Align how orders are planned so data is entered once', 1, '2026-07-01', '2026-08-31', 'in_progress'),
('Production', 'Remove manual re-entry between planning and the production floor', 2, '2026-08-01', '2026-09-30', 'not_started'),
('Shipping', 'Auto-generate shipping documents from existing order data', 3, '2026-09-01', '2026-10-31', 'not_started'),
('Brokerage', 'Give the broker read access instead of re-requesting documents', 4, '2026-10-01', '2026-11-30', 'not_started');

-- Tasks (linked to the phases just created, matched by name)
insert into tasks (phase_id, title, description, notes, assignee_id, status, priority, start_date, due_date, completed_date, sort_order)
select ph.id, t.title, t.description, t.notes, tm.id, t.status::item_status, t.priority::item_priority, t.start_date::date, t.due_date::date, t.completed_date::date, t.sort_order
from (values
  ('Planning', 'Map the current planning process', 'Document every manual step and Excel file in use today', null, 'Alex Tremblay', 'in_progress', 'high', '2026-07-01', '2026-07-20', null, 1),
  ('Planning', 'Design the shared planning table in Supabase', 'Replace the planning Excel file with a single source of truth', null, 'Alex Tremblay', 'not_started', 'high', '2026-07-21', '2026-08-15', null, 2),
  ('Production', 'Connect production floor to planning data', 'Production reads the plan instead of re-typing it', null, 'Sam Roy', 'not_started', 'high', '2026-08-01', '2026-09-10', null, 1),
  ('Shipping', 'Auto-generate shipping documents', 'Pull order data automatically instead of recreating it', null, 'Jordan Leblanc', 'not_started', 'medium', '2026-09-01', '2026-10-01', null, 1),
  ('Brokerage', 'Set up read-only document access for the broker', 'Stop re-sending documents already available elsewhere', 'Waiting on IT to confirm access levels', 'Chris Dubois', 'blocked', 'medium', '2026-10-01', '2026-10-25', null, 1)
) as t(phase_name, title, description, notes, assignee_name, status, priority, start_date, due_date, completed_date, sort_order)
join phases ph on ph.name = t.phase_name
left join team_members tm on tm.name = t.assignee_name;

-- Subtasks (linked to the tasks just created, matched by title)
insert into subtasks (task_id, title, description, notes, assignee_id, status, start_date, due_date, completed_date, sort_order)
select tk.id, s.title, s.description, s.notes, tm.id, s.status::item_status, s.start_date::date, s.due_date::date, s.completed_date::date, s.sort_order
from (values
  ('Map the current planning process', 'Interview planning team about current steps', 'Covered all 3 planners', null, 'Alex Tremblay', 'done', '2026-07-01', '2026-07-08', '2026-07-07', 1),
  ('Map the current planning process', 'List every Excel file currently used', 'Found 6 files so far, still checking with production', null, 'Alex Tremblay', 'in_progress', '2026-07-08', '2026-07-15', null, 2),
  ('Design the shared planning table in Supabase', 'Define required fields with production team', null, null, 'Sam Roy', 'not_started', '2026-07-25', '2026-08-05', null, 1),
  ('Connect production floor to planning data', 'Test data sync with one production line', null, null, 'Sam Roy', 'not_started', '2026-08-20', '2026-09-01', null, 1)
) as s(task_title, title, description, notes, assignee_name, status, start_date, due_date, completed_date, sort_order)
join tasks tk on tk.title = s.task_title
left join team_members tm on tm.name = s.assignee_name;

insert into objectives (title, description, metric_label, unit, current_value, target_value, status, sort_order) values
('Eliminate duplicate data entry', 'Reduce how many times the same order information is typed manually', 'Manual re-entries per order', 'entries', 3, 0, 'in_progress', 1),
('Reduce Excel dependency', 'Move critical tracking files from Excel into Supabase', 'Excel files still in active use', 'files', 6, 1, 'in_progress', 2),
('Reduce people involved per order', 'Simplify handoffs between planning, production, shipping and brokerage', 'People touching one order', 'people', 5, 2, 'not_started', 3);
