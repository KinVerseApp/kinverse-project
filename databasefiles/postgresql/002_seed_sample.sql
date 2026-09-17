DO $$
DECLARE
  ramesh UUID; lakshmi UUID; john UUID; mary UUID; deepa UUID;
  sunil UUID; priya UUID; arjun UUID; meera UUID;
  sys_user UUID;
BEGIN
  INSERT INTO user_account (email, auth_provider, status)
  VALUES ('sunil@example.com', 'google', 'active') RETURNING id INTO sys_user;

  INSERT INTO person (first_name, last_name, created_by_user_account_id) VALUES ('Ramesh','Kumar', sys_user) RETURNING id INTO ramesh;
  INSERT INTO person (first_name, last_name, created_by_user_account_id) VALUES ('Lakshmi','Kumar', sys_user) RETURNING id INTO lakshmi;
  INSERT INTO person (first_name, last_name, created_by_user_account_id) VALUES ('John','Smith', sys_user) RETURNING id INTO john;
  INSERT INTO person (first_name, last_name, created_by_user_account_id) VALUES ('Mary','Smith', sys_user) RETURNING id INTO mary;
  INSERT INTO person (first_name, last_name, created_by_user_account_id) VALUES ('Deepa','Rao', sys_user) RETURNING id INTO deepa;
  INSERT INTO person (first_name, last_name, user_account_id, created_by_user_account_id) VALUES ('Sunil','Narayanan', sys_user, sys_user) RETURNING id INTO sunil;
  INSERT INTO person (first_name, last_name, created_by_user_account_id) VALUES ('Priya','Narayanan', sys_user) RETURNING id INTO priya;
  INSERT INTO person (first_name, last_name, created_by_user_account_id) VALUES ('Arjun','Narayanan', sys_user) RETURNING id INTO arjun;
  INSERT INTO person (first_name, last_name, created_by_user_account_id) VALUES ('Meera','Narayanan', sys_user) RETURNING id INTO meera;

  INSERT INTO relationship_edge (person_a_id, person_b_id, edge_type, partner_type, status)
  SELECT LEAST(ramesh,lakshmi), GREATEST(ramesh,lakshmi), 'partner','spouse','confirmed';
  INSERT INTO relationship_edge (person_a_id, person_b_id, edge_type, partner_type, status)
  SELECT LEAST(john,mary), GREATEST(john,mary), 'partner','spouse','confirmed';
  INSERT INTO relationship_edge (person_a_id, person_b_id, edge_type, partner_type, status)
  SELECT LEAST(sunil,priya), GREATEST(sunil,priya), 'partner','spouse','confirmed';

  INSERT INTO relationship_edge (person_a_id, person_b_id, edge_type, status) VALUES
    (ramesh, john, 'parent_child', 'confirmed'),
    (lakshmi, john, 'parent_child', 'confirmed'),
    (ramesh, deepa, 'parent_child', 'confirmed'),
    (lakshmi, deepa, 'parent_child', 'confirmed'),
    (john, sunil, 'parent_child', 'confirmed'),
    (mary, sunil, 'parent_child', 'confirmed'),
    (sunil, arjun, 'parent_child', 'confirmed'),
    (priya, arjun, 'parent_child', 'confirmed'),
    (sunil, meera, 'parent_child', 'confirmed'),
    (priya, meera, 'parent_child', 'confirmed');
END $$;
