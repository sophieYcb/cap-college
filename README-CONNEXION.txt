CAP-COLLEGE — VERSION CONNECTÉE À SUPABASE
============================================

Cette version utilise le projet Supabase Cap-College.

Fonctionnement actuel
---------------------
- La connexion par e-mail et mot de passe est active.
- Le diagnostic charge uniquement les questions publiées dans Supabase.
- Les bonnes réponses ne sont pas incluses dans la banque envoyée au navigateur.
- Chaque réponse est vérifiée et enregistrée par une fonction sécurisée Supabase.
- Les séances suivantes privilégient les thèmes et les questions encore peu évalués.
- Les questions déjà rencontrées restent disponibles pour confirmer les acquis.
- Une sauvegarde locale reste active pour protéger la progression en cas de fermeture.
- Le mode Validation est réservé aux rôles validator et administrator.

Premier essai
-------------
1. Ouvrir index.html.
2. Cliquer sur « Se connecter ».
3. Utiliser le compte créé dans Supabase.
4. Lancer le diagnostic.

Important
---------
Le fichier supabase-config.js contient uniquement l’URL du projet et la clé
publique destinée au navigateur. Il ne contient aucune clé secrète.
