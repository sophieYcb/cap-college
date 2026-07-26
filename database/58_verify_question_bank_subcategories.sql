/*
-------------------------------------------------------
CAP-COLLEGE DATABASE
Version : 1.0.0
Fichier : 58_verify_question_bank_subcategories.sql
Objet   : Vérifier l’exposition des sous-catégories
-------------------------------------------------------
*/

select jsonb_build_object(
  'validation_subcategories_ready',
  to_regprocedure('public.get_validation_question_bank_v2()') is not null,
  'published_subcategories_ready',
  to_regprocedure('public.get_published_question_bank_v2()') is not null,
  'mathematics_numeration_ready',
  exists (
    select 1
    from public.skills skill
    join public.domains domain on domain.id = skill.domain_id
    join public.subjects subject on subject.id = domain.subject_id
    where subject.code = 'mathematics'
      and domain.code = 'numbers_calculation'
      and skill.code = 'numeration'
      and skill.active
  )
) as verification;
