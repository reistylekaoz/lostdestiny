-- Vale Sombrio: schema inicial
-- Convenção: tudo que afeta economia/progresso vive aqui; o cliente nunca escreve direto.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS accounts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS maps (
  id    TEXT PRIMARY KEY,
  name  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS mob_templates (
  id        TEXT PRIMARY KEY,
  name      TEXT NOT NULL,
  base_hp   INT NOT NULL,
  base_xp   INT NOT NULL,
  gold_min  INT NOT NULL,
  gold_max  INT NOT NULL
);

CREATE TABLE IF NOT EXISTS spots (
  id              TEXT PRIMARY KEY,
  map_id          TEXT NOT NULL REFERENCES maps(id),
  name            TEXT NOT NULL,
  mob_template_id TEXT NOT NULL REFERENCES mob_templates(id),
  slot_count      INT NOT NULL DEFAULT 6,
  min_level       INT NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS item_templates (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  slot        TEXT NOT NULL, -- arma, escudo, elmo, armadura, luvas, botas, brinco, anel
  base_bonus  JSONB NOT NULL -- {"forca":1,"vit":2,"dano":0}
);

CREATE TABLE IF NOT EXISTS characters (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id  UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  slot_index  INT NOT NULL CHECK (slot_index BETWEEN 0 AND 4),
  name        TEXT NOT NULL,
  class       TEXT NOT NULL,
  level       INT NOT NULL DEFAULT 1,
  xp          INT NOT NULL DEFAULT 0,
  base_forca  INT NOT NULL DEFAULT 5,
  base_vit    INT NOT NULL DEFAULT 10,
  gold        BIGINT NOT NULL DEFAULT 0,
  hp_current  INT NOT NULL DEFAULT 40,
  current_spot_id TEXT REFERENCES spots(id),
  is_farming  BOOLEAN NOT NULL DEFAULT false,
  last_tick_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (account_id, slot_index)
);

CREATE TABLE IF NOT EXISTS item_instances (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id         TEXT NOT NULL REFERENCES item_templates(id),
  owner_character_id  UUID REFERENCES characters(id) ON DELETE CASCADE,
  quality             INT NOT NULL DEFAULT 0, -- 0,1,2,3 -> "", +1, +2, +3
  bonus               JSONB NOT NULL,
  equipped_slot       TEXT, -- NULL = na mochila; caso contrário = slot equipado
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_item_instances_owner ON item_instances(owner_character_id);
CREATE INDEX IF NOT EXISTS idx_characters_account ON characters(account_id);

-- Log de eventos relevantes (kills, drops, level up) — útil para auditoria/anti-cheat e histórico
CREATE TABLE IF NOT EXISTS event_log (
  id              BIGSERIAL PRIMARY KEY,
  character_id    UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  event_type      TEXT NOT NULL, -- kill, level_up, item_drop, item_equip
  payload         JSONB NOT NULL DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
