/*
-------------------------------------------------------
CAP-COLLEGE DATABASE
Version : 1.0.0
Fichier : 59_count_maths_6e_reviews.sql
Objet   : Compter les évaluations A/B/C/D des 80 questions de maths 6e
-------------------------------------------------------
*/

with maths_questions as (
  select
    q.id,
    q.legacy_id,
    qv.id as question_version_id
  from public.questions q
  join public.question_versions qv
    on qv.question_id = q.id
   and qv.version_number = q.current_version_number
  where q.legacy_id between 600001 and 600080
),
latest_reviews as (
  select
    mq.id as question_id,
    review.grade
  from maths_questions mq
  left join lateral (
    select qr.grade
    from public.question_reviews qr
    where qr.question_version_id = mq.question_version_id
      and qr.campaign_id is null
    order by qr.reviewed_at desc
    limit 1
  ) review on true
)
select
  count(*) as total_questions,
  count(*) filter (where grade = 'A') as grade_a,
  count(*) filter (where grade = 'B') as grade_b,
  count(*) filter (where grade = 'C') as grade_c,
  count(*) filter (where grade = 'D') as grade_d,
  count(*) filter (where grade is null) as without_grade,
  count(*) filter (where grade is not null) as reviewed_questions
from latest_reviews;
