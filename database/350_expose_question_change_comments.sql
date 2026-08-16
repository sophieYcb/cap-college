begin;

create or replace function public.get_validation_question_bank_v3()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    jsonb_agg(
      jsonb_set(
        enriched.item,
        '{current}',
        (enriched.item -> 'current') ||
          jsonb_build_object('changeComment', current_version.change_comment),
        true
      )
      order by source.ordinality
    ),
    '[]'::jsonb
  )
  from jsonb_array_elements(public.get_validation_question_bank_v2())
       with ordinality as source(item, ordinality)
  left join public.question_versions current_version
    on current_version.id = (source.item #>> '{current,id}')::uuid
  cross join lateral (
    select case
      when source.item -> 'previous' is null
        or source.item -> 'previous' = 'null'::jsonb
        then source.item
      else jsonb_set(
        source.item,
        '{previous}',
        (source.item -> 'previous') ||
        jsonb_build_object(
          'review',
          (
            select case
              when previous_review.id is null then null
              else jsonb_build_object(
                'id', previous_review.id,
                'grade', previous_review.grade,
                'status', previous_review.status,
                'comment', previous_review.comment,
                'reviewedAt', previous_review.reviewed_at
              )
            end
            from (
              select qr.*
              from public.question_reviews qr
              where qr.question_version_id =
                (source.item #>> '{previous,id}')::uuid
                and qr.campaign_id is null
                and (
                  qr.reviewer_id = auth.uid()
                  or public.has_role('administrator')
                )
              order by
                (qr.reviewer_id = auth.uid()) desc,
                qr.reviewed_at desc,
                qr.id desc
              limit 1
            ) previous_review
          )
        ),
        true
      )
    end as item
  ) enriched;
$function$;

revoke all on function public.get_validation_question_bank_v3() from public;
grant execute on function public.get_validation_question_bank_v3() to authenticated;

commit;