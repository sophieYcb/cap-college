/*
 CAP-COLLEGE DATABASE
 File: database/287_create_mathematics_5e_atomic_referential.sql
 Purpose: Create the atomic Mathematics 5e referential.
 Reference: BO no. 10 of 5 March 2026, Mathematics programme for cycle 4.
 Idempotent: Yes.
 Safety: Does not create, modify or reassign questions.
*/

begin;

do $block$
begin
  if not exists (select 1 from public.subjects where code = 'mathematics' and active) then
    raise exception 'Missing active subject: mathematics';
  end if;
  if not exists (select 1 from public.levels where code = '5e' and active) then
    raise exception 'Missing active level: 5e';
  end if;
end
$block$;

with domain_seed(code, name, description, sort_order) as (
  values
    ('cycle4_numbers_calculation', 'Nombres et calculs', 'Nombres, opérations et calcul algébrique du programme de mathématiques du cycle 4.', 10),
    ('cycle4_space_geometry', 'Espace et géométrie', 'Repérage, solides, transformations et géométrie plane du programme de cycle 4.', 20),
    ('cycle4_data_probability', 'Organisation et gestion de données et probabilités', 'Statistiques et probabilités du programme de cycle 4.', 30),
    ('cycle4_proportionality_functions', 'Proportionnalité et fonctions', 'Proportionnalité et premières dépendances fonctionnelles du programme de cycle 4.', 40),
    ('cycle4_computational_thinking', 'Pensée informatique', 'Algorithmique et programmation par blocs du programme de cycle 4.', 50)
)
insert into public.domains (id, subject_id, code, name, description, sort_order, active)
select
  md5('cap-college:mathematics-cycle4-domain:' || ds.code)::uuid,
  subject.id,
  ds.code,
  ds.name,
  ds.description,
  ds.sort_order,
  true
from domain_seed ds
join public.subjects subject on subject.code = 'mathematics'
on conflict (subject_id, code) do update
set name = excluded.name,
    description = excluded.description,
    sort_order = excluded.sort_order,
    active = true,
    updated_at = statement_timestamp();

with skill_seed(domain_code, code, name, sort_order) as (
  values
    ('cycle4_numbers_calculation', 'm5_operations', 'Opérations', 10),
    ('cycle4_numbers_calculation', 'm5_relative_numbers', 'Nombres relatifs', 20),
    ('cycle4_numbers_calculation', 'm5_rational_numbers', 'Nombres rationnels et fractions', 30),
    ('cycle4_numbers_calculation', 'm5_powers', 'Puissances', 40),
    ('cycle4_numbers_calculation', 'm5_algebra', 'Calcul littéral et algébrique', 50),
    ('cycle4_space_geometry', 'm5_coordinate_geometry', 'Repérage sur une droite et dans le plan', 10),
    ('cycle4_space_geometry', 'm5_space_representation', 'Représentation de l’espace', 20),
    ('cycle4_space_geometry', 'm5_transformations', 'Transformations', 30),
    ('cycle4_space_geometry', 'm5_angles', 'Angles', 40),
    ('cycle4_space_geometry', 'm5_triangles', 'Triangles', 50),
    ('cycle4_space_geometry', 'm5_parallelograms', 'Parallélogrammes', 60),
    ('cycle4_data_probability', 'm5_statistics', 'Statistiques', 10),
    ('cycle4_data_probability', 'm5_probability', 'Probabilités', 20),
    ('cycle4_proportionality_functions', 'm5_proportionality', 'Proportionnalité', 10),
    ('cycle4_proportionality_functions', 'm5_functions', 'Fonctions et dépendance entre grandeurs', 20),
    ('cycle4_computational_thinking', 'm5_computational_thinking', 'Algorithmique et programmation', 10)
)
insert into public.skills (id, domain_id, code, name, description, sort_order, active)
select
  md5('cap-college:mathematics-5e-skill:' || ss.code)::uuid,
  domain.id,
  ss.code,
  ss.name,
  'Sous-catégorie du référentiel atomique de mathématiques 5e, programme 2026.',
  ss.sort_order,
  true
from skill_seed ss
join public.domains domain on domain.code = ss.domain_code
join public.subjects subject on subject.id = domain.subject_id and subject.code = 'mathematics'
on conflict (domain_id, code) do update
set name = excluded.name,
    description = excluded.description,
    sort_order = excluded.sort_order,
    active = true,
    updated_at = statement_timestamp();

with micro_seed(skill_code, code, name, sort_order) as (
  values
    ('m5_operations','m5_calc_division_euclidean','Déterminer le quotient et le reste d’une division euclidienne',10),
    ('m5_operations','m5_calc_multiple_divisor','Reconnaître un multiple ou un diviseur',20),
    ('m5_operations','m5_calc_divisibility','Utiliser les critères de divisibilité par 2, 3, 5, 9 et 10',30),
    ('m5_operations','m5_calc_choose_operation','Choisir les opérations adaptées à un problème',40),
    ('m5_operations','m5_calc_check_plausibility','Contrôler la vraisemblance d’un résultat',50),
    ('m5_operations','m5_calc_divide_decimal','Diviser par un nombre décimal',60),
    ('m5_operations','m5_calc_translate_expression','Traduire un problème par une expression numérique',70),
    ('m5_operations','m5_calc_use_parentheses','Utiliser correctement les parenthèses',80),
    ('m5_operations','m5_calc_sum_product_vocabulary','Distinguer somme, produit, termes et facteurs',90),
    ('m5_operations','m5_calc_order_operations','Appliquer les priorités opératoires',100),
    ('m5_operations','m5_calc_distributivity_numeric','Utiliser la distributivité simple dans un calcul numérique',110),

    ('m5_relative_numbers','m5_rel_interpret','Reconnaître et interpréter un nombre relatif',10),
    ('m5_relative_numbers','m5_rel_opposite_absolute','Déterminer l’opposé et la valeur absolue d’un nombre',20),
    ('m5_relative_numbers','m5_rel_model_context','Modéliser une température, une altitude ou un déplacement',30),
    ('m5_relative_numbers','m5_rel_number_line','Lire et placer un nombre relatif sur une droite graduée',40),
    ('m5_relative_numbers','m5_rel_compare_order','Comparer et ranger des nombres relatifs',50),
    ('m5_relative_numbers','m5_rel_add','Additionner des nombres relatifs',60),
    ('m5_relative_numbers','m5_rel_subtract','Soustraire des nombres relatifs',70),
    ('m5_relative_numbers','m5_rel_simplify_parentheses','Simplifier une somme comportant des parenthèses',80),
    ('m5_relative_numbers','m5_rel_solve_problem','Résoudre un problème avec des nombres relatifs',90),

    ('m5_rational_numbers','m5_frac_quotient','Interpréter une fraction comme quotient',10),
    ('m5_rational_numbers','m5_frac_equivalent','Reconnaître et produire des fractions égales',20),
    ('m5_rational_numbers','m5_frac_compare','Comparer des fractions',30),
    ('m5_rational_numbers','m5_frac_common_denominator','Réduire des fractions au même dénominateur',40),
    ('m5_rational_numbers','m5_frac_add_subtract','Additionner et soustraire des fractions de dénominateurs quelconques',50),
    ('m5_rational_numbers','m5_frac_solve_problem','Résoudre un problème avec des additions ou soustractions de fractions',60),

    ('m5_powers','m5_pow_square_cube','Comprendre les notations carré et cube',10),
    ('m5_powers','m5_pow_squares_0_12','Connaître les carrés des entiers de 0 à 12',20),
    ('m5_powers','m5_pow_product_notation','Écrire un produit sous forme de carré ou de cube',30),
    ('m5_powers','m5_pow_evaluate_numeric','Calculer une expression numérique contenant une puissance simple',40),
    ('m5_powers','m5_pow_evaluate_literal','Calculer une expression littérale contenant une puissance simple',50),

    ('m5_algebra','m5_alg_pattern_conjecture','Identifier une régularité et formuler une conjecture',10),
    ('m5_algebra','m5_alg_produce_formula','Produire une formule littérale',20),
    ('m5_algebra','m5_alg_substitute','Calculer une expression littérale par substitution',30),
    ('m5_algebra','m5_alg_test_equality','Tester si une égalité est vraie pour une valeur donnée',40),
    ('m5_algebra','m5_alg_sum_product','Reconnaître si une expression est une somme ou un produit',50),
    ('m5_algebra','m5_alg_expand','Développer avec la distributivité simple',60),
    ('m5_algebra','m5_alg_factor','Factoriser avec la distributivité simple',70),
    ('m5_algebra','m5_alg_reduce_ax_b','Réduire une expression de la forme ax + b',80),
    ('m5_algebra','m5_alg_prove_refute','Valider ou réfuter une affirmation mathématique',90),
    ('m5_algebra','m5_alg_model_equation','Mettre un problème en équation simple',100),
    ('m5_algebra','m5_alg_solve_simple_equation','Résoudre une équation simple par les opérations inverses',110),

    ('m5_coordinate_geometry','m5_geo_number_line','Lire et placer une abscisse sur une droite graduée',10),
    ('m5_coordinate_geometry','m5_geo_read_coordinates','Lire les coordonnées d’un point dans un repère',20),
    ('m5_coordinate_geometry','m5_geo_plot_coordinates','Placer un point de coordonnées données',30),

    ('m5_space_representation','m5_geo_cube_views','Interpréter des vues et des empilements de cubes',10),
    ('m5_space_representation','m5_geo_identify_solid','Reconnaître un solide en perspective cavalière',20),
    ('m5_space_representation','m5_geo_solid_net','Relier un solide à son patron',30),
    ('m5_space_representation','m5_geo_volume_prism','Calculer le volume d’un cube, d’un pavé droit ou d’un prisme droit',40),
    ('m5_space_representation','m5_geo_convert_volume_capacity','Convertir des unités de volume et de capacité',50),
    ('m5_space_representation','m5_geo_area_disk','Calculer l’aire d’un disque',60),
    ('m5_space_representation','m5_geo_volume_cylinder','Calculer le volume d’un cylindre',70),

    ('m5_transformations','m5_geo_central_symmetry','Reconnaître une symétrie centrale ou un demi-tour',10),
    ('m5_transformations','m5_geo_central_symmetry_properties','Utiliser les propriétés de conservation de la symétrie centrale',20),

    ('m5_angles','m5_geo_angle_types','Reconnaître et nommer les différents types d’angles',10),
    ('m5_angles','m5_geo_angle_relations','Reconnaître des angles opposés, adjacents ou supplémentaires',20),
    ('m5_angles','m5_geo_parallel_angles','Utiliser les angles alternes-internes et correspondants',30),

    ('m5_triangles','m5_geo_triangle_types','Reconnaître les triangles particuliers à partir d’un codage',10),
    ('m5_triangles','m5_geo_triangle_angle_sum','Calculer un angle avec la somme des angles d’un triangle',20),
    ('m5_triangles','m5_geo_construct_triangle','Construire un triangle à partir de données partielles',30),
    ('m5_triangles','m5_geo_perpendicular_bisector_circumcircle','Utiliser les médiatrices et le cercle circonscrit',40),
    ('m5_triangles','m5_geo_triangle_area','Calculer l’aire d’un triangle',50),
    ('m5_triangles','m5_geo_triangle_heights','Reconnaître et tracer les hauteurs d’un triangle',60),
    ('m5_triangles','m5_geo_triangle_medians','Reconnaître et tracer les médianes d’un triangle',70),

    ('m5_parallelograms','m5_geo_identify_parallelogram','Définir et reconnaître un parallélogramme',10),
    ('m5_parallelograms','m5_geo_construct_parallelogram','Construire un parallélogramme',20),
    ('m5_parallelograms','m5_geo_parallelogram_sides','Utiliser les propriétés des côtés opposés',30),
    ('m5_parallelograms','m5_geo_parallelogram_diagonals','Utiliser les propriétés des diagonales',40),
    ('m5_parallelograms','m5_geo_characterize_parallelogram','Caractériser un parallélogramme à partir de ses propriétés',50),
    ('m5_parallelograms','m5_geo_special_parallelograms','Reconnaître rectangle, losange et carré grâce à leurs propriétés',60),
    ('m5_parallelograms','m5_geo_parallelogram_area','Calculer l’aire d’un parallélogramme',70),
    ('m5_parallelograms','m5_geo_complex_area_conversions','Calculer l’aire d’une figure complexe avec des conversions',80),

    ('m5_statistics','m5_data_collect_organize','Recueillir et organiser des données',10),
    ('m5_statistics','m5_data_counts_frequencies','Calculer des effectifs et des fréquences',20),
    ('m5_statistics','m5_data_read_interpret','Lire et interpréter un tableau, un diagramme ou un graphique',30),
    ('m5_statistics','m5_data_represent','Représenter des données sous une forme adaptée',40),
    ('m5_statistics','m5_data_choose_representation','Choisir la représentation la plus pertinente',50),
    ('m5_statistics','m5_data_mean','Calculer et interpréter une moyenne simple',60),

    ('m5_probability','m5_prob_vocabulary','Utiliser le vocabulaire des probabilités',10),
    ('m5_probability','m5_prob_scale_forms','Placer un événement sur une échelle de probabilités',20),
    ('m5_probability','m5_prob_equiprobability','Calculer une probabilité en situation d’équiprobabilité',30),
    ('m5_probability','m5_prob_repeat_frequency','Répéter une expérience et exploiter les fréquences observées',40),

    ('m5_proportionality','m5_prop_identify','Reconnaître une situation proportionnelle ou non proportionnelle',10),
    ('m5_proportionality','m5_prop_linearity','Utiliser les propriétés de linéarité',20),
    ('m5_proportionality','m5_prop_unit_rate','Résoudre un problème par retour à l’unité',30),
    ('m5_proportionality','m5_prop_percentage','Calculer et appliquer une proportion ou un pourcentage',40),
    ('m5_proportionality','m5_prop_coefficient','Utiliser un coefficient de proportionnalité',50),
    ('m5_proportionality','m5_prop_table','Représenter et reconnaître une proportionnalité dans un tableau',60),
    ('m5_proportionality','m5_prop_graph','Représenter et reconnaître une proportionnalité sur un graphique',70),

    ('m5_functions','m5_func_dependency','Comprendre l’expression « en fonction de »',10),
    ('m5_functions','m5_func_value_table','Produire et lire un tableau de valeurs',20),
    ('m5_functions','m5_func_plot_points','Placer les points correspondant à un tableau de valeurs',30),
    ('m5_functions','m5_func_read_graph','Lire et interpréter une courbe ou un nuage de points',40),
    ('m5_functions','m5_func_formula_table','Passer d’une formule simple à un tableau de valeurs et inversement',50),

    ('m5_computational_thinking','m5_info_sequence','Séquencer des instructions simples',10),
    ('m5_computational_thinking','m5_info_inputs_outputs','Identifier les entrées et les sorties d’un programme',20),
    ('m5_computational_thinking','m5_info_formula_blocks','Traduire une formule en instructions par blocs',30),
    ('m5_computational_thinking','m5_info_predict_result','Calculer ou prévoir le résultat d’une suite d’instructions',40),
    ('m5_computational_thinking','m5_info_analyze_modify','Analyser un programme et modifier ses paramètres',50),
    ('m5_computational_thinking','m5_info_loop','Comprendre et exécuter une boucle inconditionnelle simple',60)
)
insert into public.micro_skills (
  id, skill_id, code, teacher_name, student_name, description,
  mastery_criteria, sort_order, active
)
select
  md5('cap-college:mathematics-5e-micro-skill:' || seed.code)::uuid,
  skill.id,
  seed.code,
  seed.name,
  seed.name,
  'Micro-compétence atomique du programme de mathématiques 5e applicable à la rentrée 2026.',
  'Au moins 10 questions validées et des réussites suffisamment régulières.',
  seed.sort_order,
  true
from micro_seed seed
join public.skills skill on skill.code = seed.skill_code
join public.domains domain on domain.id = skill.domain_id
join public.subjects subject on subject.id = domain.subject_id and subject.code = 'mathematics'
on conflict (code) do update
set skill_id = excluded.skill_id,
    teacher_name = excluded.teacher_name,
    student_name = excluded.student_name,
    description = excluded.description,
    mastery_criteria = excluded.mastery_criteria,
    sort_order = excluded.sort_order,
    active = true,
    updated_at = statement_timestamp();

insert into public.micro_skill_levels (micro_skill_id, level_id, is_expected)
select micro_skill.id, level.id, true
from public.micro_skills micro_skill
cross join public.levels level
where micro_skill.code like 'm5\_%' escape '\'
  and level.code = '5e'
on conflict (micro_skill_id, level_id) do update
set is_expected = true;

commit;