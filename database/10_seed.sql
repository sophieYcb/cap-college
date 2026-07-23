/*
===============================================================================
 CAP-COLLEGE DATABASE
-------------------------------------------------------------------------------
 Version      : 1.0.0
 File         : database/10_seed.sql
 Purpose      : Stable reference data required by the application.
 Dependencies : 00_extensions.sql through 09_security.sql
 Idempotent   : Yes
===============================================================================
*/

begin;

insert into public.roles (code, name, description)
values
  ('student', 'Élève', 'Passe les diagnostics et suit sa progression.'),
  ('guardian', 'Parent', 'Suit les élèves qui lui sont rattachés.'),
  ('teacher', 'Enseignant', 'Suit ses classes et ses élèves.'),
  ('validator', 'Validateur', 'Teste et signale les contenus sans pouvoir les publier.'),
  ('administrator', 'Administrateur', 'Administre et publie les contenus.')
on conflict (code) do update
set name = excluded.name,
    description = excluded.description;

insert into public.education_cycles (code, name, sort_order)
values
  ('cycle_3', 'Cycle 3', 3),
  ('cycle_4', 'Cycle 4', 4)
on conflict (code) do update
set name = excluded.name,
    sort_order = excluded.sort_order;

insert into public.levels (cycle_id, code, name, sort_order)
select c.id, values_to_insert.code, values_to_insert.name, values_to_insert.sort_order
from (
  values
    ('cycle_3', 'cm1', 'CM1', 1),
    ('cycle_3', 'cm2', 'CM2', 2),
    ('cycle_3', '6e', '6e', 3),
    ('cycle_4', '5e', '5e', 4),
    ('cycle_4', '4e', '4e', 5),
    ('cycle_4', '3e', '3e', 6)
) as values_to_insert(cycle_code, code, name, sort_order)
join public.education_cycles c on c.code = values_to_insert.cycle_code
on conflict (code) do update
set cycle_id = excluded.cycle_id,
    name = excluded.name,
    sort_order = excluded.sort_order;

insert into public.subjects (code, name, sort_order)
values
  ('french', 'Français', 1),
  ('mathematics', 'Mathématiques', 2)
on conflict (code) do update
set name = excluded.name,
    sort_order = excluded.sort_order;

commit;
