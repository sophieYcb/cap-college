# Cap Collège

Cap Collège est une application de diagnostic progressif et de remise à niveau
pour le français en 6e.

## Version actuelle

Cette branche contient la V5.3.7 :

- authentification et profils Supabase ;
- banque de 590 questions ;
- diagnostic progressif par séances de 10, 20 ou 30 minutes ;
- reprise d’une séance interrompue ;
- suivi cumulatif des compétences ;
- bilan avec correction des erreurs ;
- proposition d’une compétence prioritaire à travailler ;
- remédiation guidée par micro-compétence ;
- mode Validateur connecté à Supabase ;
- comparaison d’une question avec sa version précédente.

## Organisation

- Les fichiers à la racine constituent l’application GitHub Pages.
- Le dossier `database/` contient les scripts PostgreSQL/Supabase, dans leur
  ordre d’installation.
- `README-CONNEXION.txt` décrit la configuration de la connexion Supabase.

La clé présente dans `supabase-config.js` est la clé publique destinée au
navigateur. Aucun mot de passe de base de données ni aucune clé `service_role`
ne doit être ajouté au dépôt.
