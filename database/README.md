# Base de données Cap-College

Schéma PostgreSQL/Supabase **1.0.0**, conçu à partir de Cap-College V5.1 et de
la feuille de route validée.

## Principes structurants

- La micro-compétence, et non la question, est au centre du suivi.
- Une question évalue exactement une micro-compétence.
- Les anciennes identités V5.1 sont conservées dans `questions.legacy_id`.
- Chaque modification crée une version chronologique comparable à N−1.
- Le diagnostic se construit au fil de séances d’une durée choisie.
- La rapidité de réponse n’entre jamais dans l’évaluation.
- Les campagnes de validation sont séparées des données réelles des élèves.
- Le rôle `validator` peut tester et signaler, mais pas publier.

## Ordre d’exécution

1. `00_extensions.sql`
2. `01_types.sql`
3. `02_users.sql`
4. `03_program.sql`
5. `04_questions.sql`
6. `05_learning.sql`
7. `06_diagnostics.sql`
8. `07_validation.sql`
9. `08_statistics.sql`
10. `09_security.sql`
11. `10_seed.sql`
12. `11_import_french_6e.sql`
13. `12_verify_french_6e_import.sql`
14. `13_cleanup_import_staging.sql`
15. `14_setup_first_administrator.sql`
16. `15_import_quality_reviews.sql`
17. `16_verify_quality_reviews.sql`
18. `17_cleanup_review_staging.sql`
19. `18_application_api.sql`
20. `19_verify_application_api.sql`
21. `20_verify_first_online_answer.sql`
22. `21_progressive_diagnostic_api.sql`
23. `22_progressive_session_lifecycle.sql`
24. `23_verify_progressive_session.sql`
25. `24_skill_profile_api.sql`
26. `25_remediation_api.sql`
27. `26_diagnose_answer_8.sql`
28. `27_resume_diagnostic_api.sql`
29. `28_active_diagnostic_session_api.sql`
30. `29_session_focus_and_home_resume.sql`
31. `30_validator_question_api.sql`
32. `31_apply_review_corrections.sql`
33. `32_verify_review_corrections.sql`
34. `33_cleanup_correction_staging.sql`
35. `34_error_notebook_api.sql`
36. `35_verify_error_notebook_api.sql`
37. `36_validation_campaign_management_api.sql`
38. `37_verify_validation_campaign_management.sql`
39. `38_validation_diagnostic_sessions.sql`
40. `39_verify_validation_diagnostic_isolation.sql`
41. `40_question_flag_api.sql`
42. `41_verify_question_flag_api.sql`
43. `42_open_question_flags_api.sql`
44. `43_verify_open_question_flags_api.sql`
45. `44_resolve_question_flags_api.sql`
46. `45_verify_resolve_question_flags_api.sql`

Exécuter les fichiers dans cet ordre depuis le SQL Editor de Supabase. Ne pas
exécuter le pack avant la validation finale et la sauvegarde du projet.

## Import de la banque française de 6e

- `11_import_french_6e.sql` importe la banque V5.1 corrigée et son complément
  couvrant le programme de 6e.
- Les 590 identifiants historiques sont conservés.
- Les étapes de correction reconstruisent 982 versions chronologiques.
- Les questions restent en statut `in_review` jusqu’à leur validation.
- `12_verify_french_6e_import.sql` effectue un contrôle final en lecture seule.
- `13_cleanup_import_staging.sql` supprime la table de transit protégée après
  validation des totaux.

## Ce que ce pack ne fait pas encore

- Il n’attribue pas automatiquement le rôle administrateur au premier compte.
- Il ne remplace pas encore le stockage local dans l’application.

Ces opérations feront l’objet de migrations séparées afin de rester vérifiables
et réversibles.
