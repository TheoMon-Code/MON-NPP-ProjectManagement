# Dashboard projet Nestlé — MON Logistics

Fichiers livrés :
- `index.html` — le dashboard (page unique, statique, interface en anglais)
- `schema.sql` — script à exécuter dans Supabase pour créer les tables
- `netlify.toml` — config de déploiement Netlify (publish + dossier de functions)
- `netlify/functions/config.js` — petite fonction serverless qui transmet l'URL/clé Supabase au dashboard depuis les variables d'environnement Netlify (rien de codé en dur, rien dans GitHub)

## Structure du dashboard

C'est un vrai outil de gestion de projet, pas un suivi par département :

- **Phases** → contiennent des **Tasks** → qui contiennent des **Subtasks**. Chaque subtask est liée à 1 task (via `task_id`), chaque task est liée à 1 phase (via `phase_id`), et chaque task/subtask peut être assignée à 1 membre de l'équipe (via `assignee_id`). Tout est bien relié par ces clés étrangères — rien n'est dupliqué entre les tables.
- **Team** : les membres du projet (nom, rôle, entreprise), avec leur charge de travail (tâches + sous-tâches assignées, terminées, en retard).
- **Objectives** : les objectifs du projet en tant que tel (ex: réduire la double saisie, réduire l'usage d'Excel, réduire le nombre de personnes impliquées par commande), avec valeur actuelle vs cible.

Chaque task et subtask a maintenant un vrai détail de suivi, pas juste un statut :
- **Description** : ce qu'il faut faire
- **Notes** : commentaire libre (pourquoi c'est bloqué, décisions prises, contexte pour la prochaine personne)
- **Assignee** : qui s'en occupe
- **Start / Due / Completed date** : date prévue de début, échéance, et date réelle de complétion (pour voir l'écart entre prévu et réel)
- Un tag **Overdue** apparaît automatiquement si l'échéance est dépassée et que ce n'est pas encore terminé (visible dans Overview, Tasks, Subtasks et Team)

Onglets du dashboard : **Overview**, **Phases**, **Tasks**, **Subtasks**, **Team**, **Objectives**, **Manage**.

- **Phases** : vue hiérarchique en accordéon (phase → tâches → sous-tâches), avec la description/notes affichées directement sous chaque élément.
- **Tasks** / **Subtasks** : vue à plat de toutes les tâches / sous-tâches, filtrable par phase (ou tâche parente) et par statut — pratique pour voir "tout ce qui est en retard" ou "tout ce qui est assigné à telle personne" sans naviguer phase par phase.
- **Manage** : ajouter/modifier/supprimer des membres d'équipe, phases, tâches et sous-tâches directement depuis le dashboard (tableaux éditables avec tous les champs ci-dessus, sauvegarde directe dans Supabase). Objectives reste en lecture seule pour l'instant (modifiable via Supabase > Table Editor).

Petits automatismes côté Manage : en marquant une tâche/sous-tâche "Done" sans avoir rempli la date de complétion, le dashboard la remplit automatiquement avec la date du jour.

## 1. Mettre en place Supabase

1. Crée un projet sur [supabase.com](https://supabase.com) (gratuit pour démarrer).
2. Va dans **SQL Editor > New query**, colle le contenu de `schema.sql`, clique **Run**.
   - Ça crée les tables `team_members`, `phases`, `tasks`, `subtasks`, `objectives`
   - Ça ajoute des données d'exemple (4 phases, des tâches, sous-tâches, membres d'équipe et objectifs) pour tester le dashboard tout de suite
   - Ça configure la sécurité en lecture/écriture publique sur les 4 premières tables (voir section Sécurité plus bas)
   - Le script est **rejouable sans risque** : il supprime et recrée les tables à chaque exécution, donc tu peux le recoller n'importe quand pour repartir propre (attention, ça efface aussi les vraies données déjà saisies depuis la dernière exécution)
3. Va dans **Project Settings > API**, note :
   - `Project URL`
   - `anon public` key

## 2. Structure du repo GitHub

Mets tous les fichiers livrés dans un repo GitHub, en gardant l'arborescence telle quelle :

```
mon-repo/
├── index.html
├── schema.sql
├── netlify.toml
├── README.md
└── netlify/
    └── functions/
        └── config.js
```

**Aucun fichier ne contient l'URL ou la clé Supabase.** `index.html` va chercher ces valeurs au chargement en appelant `netlify/functions/config.js`, qui lui les lit depuis les variables d'environnement Netlify (étape suivante). Rien à coller à la main dans le code, rien de spécifique au projet dans l'historique Git.

## 3. Déployer sur Netlify (connecté à GitHub)

1. Sur [app.netlify.com](https://app.netlify.com) : **Add new site > Import an existing project** > connecte ton compte GitHub > choisis le repo.
2. Build settings : Build command = *(laisser vide)*, Publish directory = `.`. Netlify détecte automatiquement `netlify/functions/config.js` grâce au `netlify.toml`.
3. Avant (ou après) le premier déploiement, va dans **Site configuration > Environment variables** et ajoute :
   - `SUPABASE_URL` = ton Project URL (étape 1)
   - `SUPABASE_ANON_KEY` = ta clé `anon public` (étape 1)
4. Déploie (ou redéploie si tu as ajouté les variables après coup — un simple "Trigger deploy" suffit). Netlify te donne un lien public (ex: `random-name-123.netlify.app`) à partager à l'équipe.

Pour changer de projet Supabase plus tard (ex: passer de test à prod), il suffit de modifier les variables d'environnement dans Netlify et de redéployer — aucun changement de code, aucun commit.

## 4. Personnaliser les couleurs

Tout en haut du `<style>` dans `index.html` :

```css
:root {
  --color-primary: #0B2545;
  --color-secondary: #13315C;
  --color-accent: #E4572E;
  ...
}
```

Remplace ces codes hex par ceux du brand book MON Logistics — tout le dashboard se met à jour automatiquement (headers, onglet actif, graphiques, badges).

## Sécurité — à savoir

Le dashboard est accessible **sans login, via un simple lien**, comme demandé — y compris pour l'édition (onglet Manage), selon ton choix. Concrètement :
- La clé `anon` Supabase n'est plus codée en dur ni commitée dans GitHub — elle vit uniquement dans les variables d'environnement Netlify et transite via `netlify/functions/config.js`. Mais elle reste visible dans l'onglet réseau du navigateur de quiconque ouvre le dashboard (c'est normal, une clé `anon` est faite pour être publique) : ce qui a changé, c'est qu'elle n'est plus dans ton historique Git, pas qu'elle est devenue secrète.
- `schema.sql` autorise la clé `anon` à lire ET écrire (créer/modifier/supprimer) sur `team_members`, `phases`, `tasks`, `subtasks`. Ça veut dire que **n'importe qui avec le lien peut modifier ou supprimer ces données**, pas seulement les consulter. C'est un choix délibéré pour rester simple, mais garde ça en tête si le lien circule au-delà de l'équipe projet.
- `objectives` reste en lecture seule pour tout le monde via le dashboard.
- Ne mets jamais la clé `service_role` en variable d'environnement de ce site — elle donne un accès total et ne doit jamais être exposée côté client, y compris via une fonction serverless publique comme celle-ci.
- Si un jour tu veux restreindre l'édition à l'équipe (login par personne), on peut ajouter l'authentification Supabase — dis-le moi.

**Tester en local avant de déployer :** comme la config passe par une fonction Netlify, ouvrir `index.html` directement dans un navigateur ne suffit pas (la fonction n'existe pas en dehors de Netlify). Utilise la [Netlify CLI](https://docs.netlify.com/cli/get-started/) et lance `netlify dev` depuis le dossier du repo — ça simule les fonctions et les variables d'environnement en local.

## Prochaines étapes possibles

- Remplacer les données d'exemple (équipe, phases, tâches, sous-tâches, objectifs) par les vraies infos du projet, directement dans l'onglet **Manage** ou via Supabase > Table Editor
- Dépendances entre tâches (ex: "la tâche B ne peut pas commencer avant que A soit terminée") — utile vu que le projet touche justement à réduire les dépendances entre départements
- Historique/journal des changements (qui a modifié quoi, quand) — actuellement `updated_at` se met à jour automatiquement mais il n'y a pas de journal détaillé
- Notifications (courriel ou autre) quand une tâche devient en retard ou bloquée, plutôt que de devoir ouvrir le dashboard
- Restreindre l'édition à l'équipe (login par personne) si le lien venait à circuler plus largement que prévu
