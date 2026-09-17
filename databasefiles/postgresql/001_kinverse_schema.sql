-- ============================================================================
-- KinVerse — PostgreSQL schema (MVP, sized for ~10,000 users)
-- Graph-friendly family relationship model
-- ============================================================================
-- Design principle: store only two atomic edge types (parent_child, partner).
-- Every named relationship a user sees (grandparent, sibling, cousin, in-law,
-- aunt/uncle) is DERIVED at query time by walking these edges, not stored.
-- This avoids a schema change every time a new relationship label is needed
-- and mirrors the model used by Ancestry / FamilySearch / MyHeritage.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- fuzzy name search (Discovery Method 2)
CREATE EXTENSION IF NOT EXISTS citext;     -- case-insensitive email

CREATE TYPE auth_provider_enum      AS ENUM ('google', 'apple', 'microsoft', 'email');
CREATE TYPE account_status_enum     AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE gender_enum             AS ENUM ('female', 'male', 'non_binary', 'unspecified');
CREATE TYPE dob_precision_enum      AS ENUM ('exact', 'year_only', 'unknown');

CREATE TYPE edge_type_enum          AS ENUM ('parent_child', 'partner');
CREATE TYPE partner_type_enum       AS ENUM ('spouse', 'partner', 'ex_spouse', 'ex_partner');
CREATE TYPE edge_status_enum        AS ENUM ('pending', 'confirmed', 'rejected');
CREATE TYPE edge_source_enum        AS ENUM ('manual', 'invite_accept', 'search_match', 'ai_suggested');

CREATE TYPE visibility_enum         AS ENUM ('public', 'family_network', 'direct_relatives', 'private');
CREATE TYPE privacy_field_enum      AS ENUM ('email', 'phone', 'date_of_birth', 'address', 'heritage_info', 'biography');

CREATE TYPE invitation_scope_enum   AS ENUM ('person', 'tree');
CREATE TYPE invitation_method_enum  AS ENUM ('sms', 'email', 'link', 'qr', 'whatsapp');
CREATE TYPE invitation_status_enum  AS ENUM ('pending', 'sent', 'opened', 'accepted', 'declined', 'expired');

CREATE TYPE notification_type_enum  AS ENUM
  ('invite_accepted', 'relationship_confirmed', 'relationship_request',
   'birthday', 'new_family_member');

CREATE TABLE user_account (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email                   CITEXT NOT NULL UNIQUE,
  auth_provider           auth_provider_enum NOT NULL,
  auth_provider_subject   TEXT,
  email_verified_at       TIMESTAMPTZ,
  status                  account_status_enum NOT NULL DEFAULT 'active',
  last_login_at           TIMESTAMPTZ,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (auth_provider, auth_provider_subject)
);

CREATE TABLE person (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_account_id             UUID UNIQUE REFERENCES user_account(id) ON DELETE SET NULL,
  created_by_user_account_id  UUID REFERENCES user_account(id),

  first_name                  TEXT NOT NULL,
  last_name                   TEXT NOT NULL,
  date_of_birth                DATE,
  dob_precision                dob_precision_enum NOT NULL DEFAULT 'unknown',
  gender                       gender_enum,
  profile_photo_url            TEXT,
  biography                    TEXT,
  phone_number                 TEXT,
  contact_email                TEXT,
  native_country                TEXT,
  native_state                  TEXT,
  native_district                TEXT,
  native_village                TEXT,
  is_deceased                    BOOLEAN NOT NULL DEFAULT false,
  deceased_on                    DATE,
  default_visibility              visibility_enum NOT NULL DEFAULT 'family_network',
  created_at                       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_person_user_account ON person(user_account_id) WHERE user_account_id IS NOT NULL;
CREATE INDEX idx_person_created_by   ON person(created_by_user_account_id);
CREATE INDEX idx_person_name_trgm ON person USING gin ((first_name || ' ' || last_name) gin_trgm_ops);

CREATE TABLE relationship_edge (
  id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_a_id                   UUID NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  person_b_id                   UUID NOT NULL REFERENCES person(id) ON DELETE CASCADE,

  edge_type                     edge_type_enum NOT NULL,
  partner_type                  partner_type_enum,

  status                        edge_status_enum NOT NULL DEFAULT 'pending',
  source                        edge_source_enum NOT NULL DEFAULT 'manual',

  created_by_user_account_id    UUID REFERENCES user_account(id),
  confirmed_by_person_id        UUID REFERENCES person(id),
  confirmed_at                  TIMESTAMPTZ,

  start_date                    DATE,
  end_date                      DATE,

  created_at                    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_edge_not_self CHECK (person_a_id <> person_b_id),
  CONSTRAINT chk_partner_type_set CHECK (
    (edge_type = 'partner' AND partner_type IS NOT NULL) OR
    (edge_type = 'parent_child' AND partner_type IS NULL)
  ),
  CONSTRAINT chk_partner_canonical_order CHECK (
    edge_type <> 'partner' OR person_a_id < person_b_id
  ),
  UNIQUE (person_a_id, person_b_id, edge_type)
);

CREATE INDEX idx_edge_a ON relationship_edge(person_a_id, edge_type) WHERE status = 'confirmed';
CREATE INDEX idx_edge_b ON relationship_edge(person_b_id, edge_type) WHERE status = 'confirmed';
CREATE INDEX idx_edge_pending ON relationship_edge(person_b_id) WHERE status = 'pending';

CREATE TABLE privacy_setting (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id    UUID NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  field_key    privacy_field_enum NOT NULL,
  visibility   visibility_enum NOT NULL DEFAULT 'family_network',
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (person_id, field_key)
);

CREATE TABLE invitation (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_user_account_id    UUID NOT NULL REFERENCES user_account(id),
  invitee_person_id          UUID REFERENCES person(id) ON DELETE CASCADE,

  scope                      invitation_scope_enum NOT NULL DEFAULT 'person',
  method                     invitation_method_enum NOT NULL,
  channel_value              TEXT,
  invite_code                TEXT NOT NULL UNIQUE,

  status                     invitation_status_enum NOT NULL DEFAULT 'pending',
  sent_at                    TIMESTAMPTZ,
  opened_at                  TIMESTAMPTZ,
  responded_at               TIMESTAMPTZ,
  expires_at                 TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '14 days'),
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_invitation_inviter ON invitation(inviter_user_account_id);
CREATE INDEX idx_invitation_invitee ON invitation(invitee_person_id);

CREATE TABLE notification (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_user_account_id   UUID NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
  type                        notification_type_enum NOT NULL,
  payload                     JSONB NOT NULL DEFAULT '{}',
  is_read                     BOOLEAN NOT NULL DEFAULT false,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notification_recipient ON notification(recipient_user_account_id, is_read, created_at DESC);

CREATE TABLE contact_match (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_account_id          UUID NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
  contact_hash             TEXT NOT NULL,
  matched_user_account_id  UUID REFERENCES user_account(id),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_account_id, contact_hash)
);

CREATE TABLE story (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id                UUID REFERENCES person(id) ON DELETE CASCADE,
  author_user_account_id   UUID REFERENCES user_account(id),
  title                    TEXT,
  body                     TEXT,
  media_url                TEXT,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_account_updated     BEFORE UPDATE ON user_account     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_person_updated           BEFORE UPDATE ON person           FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_relationship_updated     BEFORE UPDATE ON relationship_edge FOR EACH ROW EXECUTE FUNCTION set_updated_at();
