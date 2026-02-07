-- mac_file.sql
-- Example SQL schema + inline sample queries (PostgreSQL-compatible)

BEGIN;

-- Tables
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    owner_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(owner_id, name)
);

CREATE TABLE commits (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    author_id INT NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    message TEXT NOT NULL,
    sha CHAR(40) NOT NULL UNIQUE,
    committed_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for common lookups
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_commits_project ON commits(project_id);
CREATE INDEX idx_commits_author ON commits(author_id);
§
-- Sample data (inline inserts)
INSERT INTO users (username, email) VALUES
  ('alice', 'alice@example.com'),
  ('bob',   'bob@example.com');

INSERT INTO projects (owner_id, name, description) VALUES
  (1, 'mac_demo', 'Demo repository for mac'),
  (2, 'tools',    'Utility tools');

INSERT INTO commits (project_id, author_id, message, sha) VALUES
  (1, 1, 'Initial commit', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
  (1, 2, 'Add README',    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'),
  (2, 2, 'Start tools',   'cccccccccccccccccccccccccccccccccccccccc');

COMMIT;

-- Inline queries / examples

-- 1) List projects with owner username and commit count (CTE + inline aggregation)
WITH last_commits AS (
  SELECT project_id, COUNT(*) AS commit_count, MAX(committed_at) AS last_commit
  FROM commits
  GROUP BY project_id
)
SELECT p.id, p.name, u.username AS owner, co.commit_count, co.last_commit
FROM projects p
JOIN users u ON p.owner_id = u.id
LEFT JOIN last_commits co ON co.project_id = p.id
ORDER BY co.last_commit DESC NULLS LAST;

-- 2) Search commits by message text (case-insensitive)
SELECT c.id, p.name AS project, u.username AS author, c.message, c.committed_at
FROM commits c
JOIN projects p ON c.project_id = p.id
JOIN users u ON c.author_id = u.id
WHERE c.message ILIKE '%readme%'
ORDER BY c.committed_at DESC;

-- 3) Example of safe update inside a transaction (incremental rename of a project)
BEGIN;
UPDATE projects
SET name = name || '_archived', description = description || ' (archived)'
WHERE id = 2 AND NOT name LIKE '%_archived';
-- verify row count before commit
-- SELECT FOUND; -- use client to check
COMMIT;