/*
 CAP-COLLEGE DATABASE
 File: database/205_archive_empty_french_6e_legacy_micro_skills.sql
 Purpose: Remove empty legacy duplicates from the expected French 6e referential.
 Historical rows are preserved.
 Idempotent: Yes
*/

begin;

do $block$
declare
  legacy_expected_count integer;
  referenced_question_count integer;
begin
  select count(*) into legacy_expected_count
  from public.micro_skill_levels msl
  join public.micro_skills ms on ms.id = msl.micro_skill_id
  join public.skills sk on sk.id = ms.skill_id
  join public.domains d on d.id = sk.domain_id
  join public.subjects s on s.id = d.subject_id
  join public.levels l on l.id = msl.level_id
  where s.code = 'french'
    and l.code = '6e'
    and msl.is_expected
    and ms.code like 'legacy_%';

  if legacy_expected_count not in (0, 40) then
    raise exception
      'Cleanup cancelled: 0 or 40 expected legacy micro-skills required, % found.',
      legacy_expected_count;
  end if;

  select count(*) into referenced_question_count
  from public.questions q
  join public.micro_skills ms on ms.id = q.micro_skill_id
  where ms.code like 'legacy_%';

  if referenced_question_count <> 0 then
    raise exception
      'Cleanup cancelled: % questions still reference legacy micro-skills.',
      referenced_question_count;
  end if;
end;
$block$;

update public.micro_skill_levels msl
set is_expected = false
from public.micro_skills ms,
     public.skills sk,
     public.domains d,
     public.subjects s,
     public.levels l
where ms.id = msl.micro_skill_id
  and sk.id = ms.skill_id
  and d.id = sk.domain_id
  and s.id = d.subject_id
  and l.id = msl.level_id
  and s.code = 'french'
  and l.code = '6e'
  and msl.is_expected
  and ms.code like 'legacy_%';

commit;