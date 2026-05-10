-- Initial schema for budget-website D1.
-- Mirrors Dexie schema (see src/db/types.ts) plus user_email for future-proofing.

CREATE TABLE IF NOT EXISTS transactions (
  id           TEXT PRIMARY KEY,
  user_email   TEXT NOT NULL,
  date         TEXT NOT NULL,
  amount       REAL NOT NULL,
  category_id  TEXT NOT NULL,
  type         TEXT NOT NULL CHECK (type IN ('income','expense')),
  description  TEXT,
  import_hash  TEXT,
  created_at   INTEGER NOT NULL,
  updated_at   INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_email, date);
CREATE INDEX IF NOT EXISTS idx_transactions_user_updated ON transactions(user_email, updated_at);

CREATE TABLE IF NOT EXISTS categories (
  id          TEXT PRIMARY KEY,
  user_email  TEXT NOT NULL,
  name        TEXT NOT NULL,
  color       TEXT NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('income','expense')),
  icon        TEXT,
  is_default  INTEGER NOT NULL DEFAULT 0,
  updated_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_email);

CREATE TABLE IF NOT EXISTS investments (
  id              TEXT PRIMARY KEY,
  user_email      TEXT NOT NULL,
  asset_symbol    TEXT NOT NULL,
  asset_class     TEXT NOT NULL,
  quantity        REAL NOT NULL,
  purchase_price  REAL NOT NULL,
  purchase_date   TEXT NOT NULL,
  currency        TEXT NOT NULL,
  notes           TEXT,
  updated_at      INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_investments_user ON investments(user_email);

CREATE TABLE IF NOT EXISTS tombstones (
  id          TEXT PRIMARY KEY,        -- "${table}:${record_id}"
  user_email  TEXT NOT NULL,
  table_name  TEXT NOT NULL CHECK (table_name IN ('transactions','categories','investments')),
  record_id   TEXT NOT NULL,
  deleted_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_tombstones_user ON tombstones(user_email);
