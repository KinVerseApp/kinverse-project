-- ============================================================================
-- Kinship derivation queries
-- Usage: psql -v person_id="<uuid>" -f 003_kinship_queries.sql
-- ============================================================================

\echo 'Set person_id using psql -v person_id="<uuid>" before running this script.'
\if :{?person_id}
\else
  \echo 'ERROR: person_id is not set. Example: psql -v person_id="<uuid>" -f 003_kinship_queries.sql'
  \quit 2
\endif

WITH RECURSIVE ancestors AS (
  SELECT person_a_id AS ancestor_id, 1 AS depth
  FROM relationship_edge
  WHERE edge_type = 'parent_child' AND status = 'confirmed'
    AND person_b_id = :'person_id'::uuid
  UNION ALL
  SELECT re.person_a_id, a.depth + 1
  FROM relationship_edge re
  JOIN ancestors a ON re.person_b_id = a.ancestor_id
  WHERE re.edge_type = 'parent_child' AND re.status = 'confirmed'
)
SELECT p.first_name, p.last_name, a.depth,
       CASE a.depth WHEN 1 THEN 'parent' WHEN 2 THEN 'grandparent'
                    WHEN 3 THEN 'great-grandparent' ELSE a.depth || 'x-great-grandparent' END AS label
FROM ancestors a JOIN person p ON p.id = a.ancestor_id
ORDER BY a.depth;

WITH RECURSIVE descendants AS (
  SELECT person_b_id AS descendant_id, 1 AS depth
  FROM relationship_edge
  WHERE edge_type = 'parent_child' AND status = 'confirmed'
    AND person_a_id = :'person_id'::uuid
  UNION ALL
  SELECT re.person_b_id, d.depth + 1
  FROM relationship_edge re
  JOIN descendants d ON re.person_a_id = d.descendant_id
  WHERE re.edge_type = 'parent_child' AND re.status = 'confirmed'
)
SELECT p.first_name, p.last_name, d.depth
FROM descendants d JOIN person p ON p.id = d.descendant_id
ORDER BY d.depth;

SELECT p.first_name, p.last_name,
       COUNT(*) AS shared_parents,
       CASE WHEN COUNT(*) >= 2 THEN 'full sibling' ELSE 'half sibling' END AS label
FROM relationship_edge mine
JOIN relationship_edge theirs
  ON mine.person_a_id = theirs.person_a_id
 AND mine.edge_type = 'parent_child' AND theirs.edge_type = 'parent_child'
 AND mine.status = 'confirmed' AND theirs.status = 'confirmed'
 AND theirs.person_b_id <> mine.person_b_id
JOIN person p ON p.id = theirs.person_b_id
WHERE mine.person_b_id = :'person_id'::uuid
GROUP BY p.id, p.first_name, p.last_name;

SELECT p.first_name, p.last_name, re.partner_type
FROM relationship_edge re
JOIN person p ON p.id = CASE WHEN re.person_a_id = :'person_id'::uuid THEN re.person_b_id ELSE re.person_a_id END
WHERE re.edge_type = 'partner' AND re.status = 'confirmed'
  AND :'person_id'::uuid IN (re.person_a_id, re.person_b_id)
  AND re.end_date IS NULL;

WITH parents AS (
  SELECT person_a_id AS parent_id
  FROM relationship_edge
  WHERE edge_type = 'parent_child' AND status = 'confirmed' AND person_b_id = :'person_id'::uuid
),
grandparents AS (
  SELECT re.person_a_id AS gp_id
  FROM relationship_edge re
  JOIN parents ON re.person_b_id = parents.parent_id
  WHERE re.edge_type = 'parent_child' AND re.status = 'confirmed'
),
aunts_uncles AS (
  SELECT DISTINCT re.person_b_id AS person_id
  FROM relationship_edge re
  JOIN grandparents gp ON re.person_a_id = gp.gp_id
  WHERE re.edge_type = 'parent_child' AND re.status = 'confirmed'
    AND re.person_b_id NOT IN (SELECT parent_id FROM parents)
    AND re.person_b_id <> :'person_id'::uuid
)
SELECT p.first_name, p.last_name FROM aunts_uncles au JOIN person p ON p.id = au.person_id;

WITH parents AS (
  SELECT person_a_id AS parent_id FROM relationship_edge
  WHERE edge_type = 'parent_child' AND status = 'confirmed' AND person_b_id = :'person_id'::uuid
),
grandparents AS (
  SELECT re.person_a_id AS gp_id
  FROM relationship_edge re
  JOIN parents ON re.person_b_id = parents.parent_id
  WHERE re.edge_type = 'parent_child' AND re.status = 'confirmed'
),
aunts_uncles AS (
  SELECT DISTINCT re.person_b_id AS person_id
  FROM relationship_edge re
  JOIN grandparents gp ON re.person_a_id = gp.gp_id
  WHERE re.edge_type = 'parent_child' AND re.status = 'confirmed'
    AND re.person_b_id NOT IN (SELECT parent_id FROM parents)
    AND re.person_b_id <> :'person_id'::uuid
)
SELECT DISTINCT p.first_name, p.last_name
FROM relationship_edge re
JOIN aunts_uncles au ON re.person_a_id = au.person_id
JOIN person p ON p.id = re.person_b_id
WHERE re.edge_type = 'parent_child' AND re.status = 'confirmed';

WITH my_partner AS (
  SELECT CASE WHEN person_a_id = :'person_id'::uuid THEN person_b_id ELSE person_a_id END AS partner_id
  FROM relationship_edge
  WHERE edge_type = 'partner' AND status = 'confirmed' AND end_date IS NULL
    AND :'person_id'::uuid IN (person_a_id, person_b_id)
)
SELECT p.first_name, p.last_name, 'parent-in-law' AS label
FROM relationship_edge re
JOIN my_partner mp ON re.person_b_id = mp.partner_id
JOIN person p ON p.id = re.person_a_id
WHERE re.edge_type = 'parent_child' AND re.status = 'confirmed';
