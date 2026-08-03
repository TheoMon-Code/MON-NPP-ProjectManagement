# Dashboard projet Nestlé — MON Logistics

Fichiers livrés :
- `index.html` — le dashboard (page unique, statique, interface en anglais)
- `schema.sql` — ⚠️ **à n'exécuter qu'une seule fois**, lors de la toute première mise en place de Supabase. Il supprime et recrée toutes les tables avec des données d'exemple — le relancer sur une base qui contient déjà de vraies données les efface définitivement.
- `migration-add-dependencies.sql` — à exécuter une fois dans Supabase si tes tables existent déjà (ajoute juste la colonne `depends_on_task_id`, sans rien effacer)
- `recover-real-data.sql` — script de récupération ponctuel (voir section "Incident du 30/07" plus bas)
- `schema-multi-project.sql` — **à exécuter une fois**, ajoute le login (email/mot de passe) et le support multi-projets (voir section "Login et multi-projets" plus bas)
- `backfill-existing-project.sql` — **à exécuter une fois, juste après** `schema-multi-project.sql` : range tes données Nestlé actuelles dans un premier projet
- `migration-claim-invites-function.sql` — **à exécuter une fois** : corrige la liaison automatique d'une invitation à un compte
- `migration-create-project-function.sql` — **à exécuter une fois** : corrige la création de projet
- `migration-roles-permissions.sql` — **à exécuter une fois, après tous les fichiers ci-dessus** : ajoute les rôles (Owner/Editor/Member/Viewer) et la liste des personnes autorisées à créer des projets (voir section "Rôles et permissions" plus bas)
- `migration-fix-can-create-projects.sql` — **à exécuter une fois** : corrige l'affichage du bouton "+ Create project" pour les personnes autorisées
- `migration-delete-project.sql` — **à exécuter une fois** : permet à un Owner de supprimer un projet entier (voir section "Rôles et permissions" plus bas)
- `migration-owner-update-role.sql` — **à exécuter une fois** : permet à un Owner de changer le rôle d'accès d'une personne déjà invitée, directement depuis Manage > Team
- `migration-restrict-team-member-add.sql` — **à exécuter une fois** : un Member ne peut plus ajouter de nouveaux Team Members (réservé à Owner/Editor)
- `migration-add-link-url.sql` — **à exécuter une fois** : ajoute un champ Link optionnel sur les tâches/sous-tâches
- `migration-prevent-circular-dependency.sql` — **à exécuter une fois** : empêche deux tâches de dépendre l'une de l'autre en boucle
- `migration-activity-log.sql` — **à exécuter une fois** : ajoute l'historique/journal d'activité (onglet Manage > History)
- `migration-comments.sql` — **à exécuter une fois** : ajoute les fils de commentaires par tâche/sous-tâche (voir section "Commentaires et rafraîchissement automatique" plus bas)
- `migration-attachments.sql` — **à exécuter une fois** : ajoute les pièces jointes (upload de fichiers) par tâche/sous-tâche, via Supabase Storage
- `migration-collaborators.sql` — **à exécuter une fois** : permet d'ajouter plusieurs personnes "aussi impliquées" sur une tâche/sous-tâche, en plus de l'Assignee principal
- `manifest.json` / `sw.js` / `icon-192.png` / `icon-512.png` — rendent le dashboard "installable" (ajout à l'écran d'accueil sur téléphone/ordinateur). Pas de SQL, juste des fichiers statiques à déployer aux côtés d'`index.html`
- `netlify.toml` — config de déploiement Netlify (publish + dossier de functions)
- `netlify/functions/config.js` — petite fonction serverless qui transmet l'URL/clé Supabase au dashboard depuis les variables d'environnement Netlify (rien de codé en dur, rien dans GitHub)

**Règle simple à retenir** : les fichiers `migration-*.sql` s'exécutent sans risque, autant de fois que nécessaire (ils n'ajoutent que ce qui manque). `schema.sql` ne se relance jamais une fois le projet réellement lancé — c'est un aller simple qui repart de zéro.

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

**Export** : bouton "Export CSV" dans les onglets Tasks et Subtasks (exporte la vue filtrée actuelle), et bouton "Export Excel" dans la barre latérale (exporte tout — Team, Phases, Tasks, Subtasks, Objectives — dans un seul fichier `.xlsx` à plusieurs feuilles).

**Autres ajouts visuels/fonctionnels** :
- **Timeline des phases** sur Overview : frise horizontale montrant le début/fin de chaque phase, avec une ligne verticale pour "aujourd'hui" et une barre de remplissage pour l'avancement.
- **Activité récente** sur Overview : les 6 dernières tâches/sous-tâches modifiées, avec qui, quand ("2h ago"), et leur statut.
- **Couleur fixe par phase** : chaque phase a désormais une couleur stable (un petit point coloré), réutilisée partout où elle est référencée (Phases, Tasks, Subtasks, Manage, timeline) pour repérer visuellement sans lire le nom.
- **Objectives en jauge circulaire** : remplace les barres de progression par un anneau de progression, plus visuel.
- **Recherche globale** : barre de recherche dans la sidebar qui filtre les tâches/sous-tâches par titre ; cliquer un résultat ouvre le bon onglet et met en surbrillance la ligne correspondante.
- **États vides plus clairs** : quand un onglet est vide (Phases, Team, Tasks, Subtasks), un message et un bouton "Go to Manage" apparaissent au lieu d'un simple texte.
- **Impression / snapshot propre** : bouton "Print" dans la sidebar qui imprime l'onglet actuellement affiché sans la sidebar, les boutons d'édition ni l'onglet Manage — pratique pour partager un point d'avancement (ex. à Nestlé) sans montrer les contrôles.
- **Point rouge de retard** sur les icônes Tasks/Subtasks de la sidebar dès qu'un élément est en retard, visible sans changer d'onglet.
- **Filtre Assignee** ("mes tâches") sur Tasks et Subtasks, en plus de Phase/Status — pratique pour ne voir que ce qui est assigné à une personne donnée. Pris en compte aussi dans l'export CSV.
- **Badge "At risk"** sur l'en-tête d'une phase (onglet Phases) si elle contient une tâche ou sous-tâche bloquée ou en retard.
- **Dépendances entre tâches** : chaque tâche peut maintenant pointer vers une autre tâche dont elle dépend (champ "Depends on" dans Manage &gt; Tasks). Tant que la tâche dont elle dépend n'est pas "Done", un tag "⛔ Waiting on: ..." apparaît dans Phases et Tasks. Nécessite d'exécuter `migration-add-dependencies.sql` une fois dans Supabase (voir plus haut).

**Ajouts plus récents** :
- **Notifications** : icône cloche dans la sidebar, avec un compteur — liste tes tâches/sous-tâches assignées en retard ou dues dans les 3 prochains jours. Cliquer un élément ouvre le bon onglet et le met en surbrillance. Purement local (pas d'email envoyé), calculé à partir des données déjà chargées.
- **Actions en masse** : dans Tasks et Subtasks, une case à cocher par ligne fait apparaître une barre d'actions pour changer le statut ou l'assigné de plusieurs éléments d'un coup. Respecte les mêmes droits d'édition que d'habitude (un Member ne peut cocher que ce qu'il a le droit de modifier).
- **Champ Link** : dans Manage &gt; Tasks/Subtasks, un champ optionnel pour coller un lien (doc, feuille de calcul, email...). Affiché en 🔗 partout où la tâche/sous-tâche apparaît. Nécessite `migration-add-link-url.sql`.
- **Modèle de phases au démarrage** : à la création d'un nouveau projet, une case "Start with standard phases" (cochée par défaut) pré-remplit le projet avec 4 phases standards (Kickoff/Planning/Execution/Review) plutôt que de repartir totalement à vide.
- **Aperçu du portefeuille de projets** : sur l'écran "Your projects", chaque carte affiche maintenant un nombre d'éléments (tâches + sous-tâches) et un compteur en retard, pour un coup d'oeil rapide avant même d'entrer dans le projet.
- **Historique / journal d'activité** : nouvel onglet Manage &gt; History, en lecture seule — qui a créé/modifié/supprimé quoi, et quand. Alimenté automatiquement par la base de données (pas par le navigateur), donc impossible à contourner ou à oublier de logger. Nécessite `migration-activity-log.sql`.
- **Anti-boucle sur les dépendances** : impossible désormais de faire dépendre une tâche A d'une tâche B qui dépend elle-même (directement ou indirectement) de A — le dashboard affiche une erreur claire au lieu de créer un blocage permanent. Nécessite `migration-prevent-circular-dependency.sql`.

**Refonte visuelle (dernière vague) — aucun fichier SQL à exécuter, uniquement `index.html` à redéployer :**
- **Mode sombre** : bouton "Dark mode" en bas de la sidebar. Préférence retenue automatiquement (même après fermeture du navigateur), graphiques et icônes s'adaptent aussi.
- **Avatars en dégradé** : chaque personne a désormais un avatar en dégradé de couleur (au lieu d'une couleur unie), stable d'une session à l'autre, visible dans Team ainsi qu'à côté de chaque assigné dans Phases/Tasks/Subtasks/Activité récente.
- **Icônes flèches vectorielles** : les petites flèches "▶" pour déplier une phase/tâche sont maintenant de vraies icônes qui pivotent proprement, plus nettes sur tous les écrans.
- **En-têtes de tableau fixes** : dans Tasks, Subtasks et Manage, l'en-tête du tableau reste visible en haut quand tu défiles une longue liste.
- **Chargement plus fluide** : à l'ouverture d'un projet, les cartes de statistiques (Overview) affichent un effet de "squelette" animé pendant la fraction de seconde où les données arrivent, plutôt qu'un vide brut.
- **Petite animation sur "Done"** : le badge "Done" affiche désormais une coche qui apparaît avec un léger effet de rebond.
- **Raccourcis clavier** : touche `/` pour sauter directement dans la recherche globale, `Échap` pour fermer recherche/notifications ou sortir d'un champ de saisie.
- **Suppression en masse** : dans Tasks et Subtasks, une fois plusieurs lignes cochées, un bouton "Delete selected" (réservé à l'Owner, avec confirmation) apparaît à côté des actions de statut/assigné en masse déjà existantes.
- **Favicon MON Logistics** : petite icône de navigateur aux couleurs de la marque.

**Ajouts les plus récents :**
- **Commentaires par tâche/sous-tâche** : dans l'onglet Phases, chaque tâche et sous-tâche a maintenant un petit "💬 Comment" qui ouvre un fil de discussion propre à cet élément — pratique pour discuter d'un point précis sans polluer le champ "Notes". Nécessite `migration-comments.sql`. Voir section dédiée plus bas.
- **Rafraîchissement automatique** : le dashboard se met à jour tout seul toutes les 25 secondes (silencieusement, sans l'écran "Loading…") tant que l'onglet est ouvert et que tu n'es pas en train de taper dans un champ — utile pour voir les changements des autres sans avoir à cliquer sur "Refresh".

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

**Mise à jour** : depuis l'ajout du login (voir section "Login et multi-projets" ci-dessus), le dashboard n'est plus un lien ouvert à tous — il faut un compte pour y accéder, et chacun ne voit que les projets où il a été invité. Ce qui suit reste vrai pour la partie technique :
- La clé `anon` Supabase n'est plus codée en dur ni commitée dans GitHub — elle vit uniquement dans les variables d'environnement Netlify et transite via `netlify/functions/config.js`. Elle reste visible dans l'onglet réseau du navigateur (normal, une clé `anon` est faite pour être publique) : ce qui compte, c'est que l'accès aux données est maintenant contrôlé par les policies RLS (qui vérifient l'utilisateur connecté), pas par le secret de cette clé.
- `objectives` reste en lecture seule pour tout le monde via le dashboard, même pour les membres d'un projet.
- Ne mets jamais la clé `service_role` en variable d'environnement de ce site — elle donne un accès total et ne doit jamais être exposée côté client, y compris via une fonction serverless publique comme celle-ci.
- Le mot de passe générique de départ (`MonLogistics2026!`) n'est sécurisant que le temps que chacun le change — encourage les nouveaux membres à le faire dès leur première connexion (Manage > Access > "Your account").

**Tester en local avant de déployer :** comme la config passe par une fonction Netlify, ouvrir `index.html` directement dans un navigateur ne suffit pas (la fonction n'existe pas en dehors de Netlify). Utilise la [Netlify CLI](https://docs.netlify.com/cli/get-started/) et lance `netlify dev` depuis le dossier du repo — ça simule les fonctions et les variables d'environnement en local.

## Login et multi-projets

Le dashboard n'est plus un lien ouvert sans compte : chacun a maintenant un vrai compte (email + mot de passe), et un même dashboard peut héberger plusieurs projets séparés (chacun ne voit que les projets où il a été invité). Tout se passe **dans l'app, sans email à envoyer ou confirmer** — voir la config à faire ci-dessous.

**Mise en place (une seule fois) :**
1. Dans Supabase > SQL Editor, exécute `schema-multi-project.sql`, puis juste après `backfill-existing-project.sql`. Ça ajoute les tables `projects`/`project_members`, la sécurité par projet, et range tes données Nestlé actuelles dans un premier projet ("MON Logistics - Nestle Flow Project") avec `theo.b@monlogistics.com` comme owner en attente.
2. Dans Supabase > **Authentication > Sign In / Providers > Email**, désactive l'option **"Confirm email"** (parfois listée sous "Secure email change" / "Email confirmation"). Comme ça, l'inscription connecte directement, sans email à envoyer ni lien à cliquer.
3. Ouvre le dashboard, clique "Sign up", entre `theo.b@monlogistics.com` et le mot de passe générique de départ : **`MonLogistics2026!`** — tu es connecté immédiatement.
4. Tu arrives sur l'écran "Your projects" avec ton projet Nestlé dedans — clique dessus pour entrer.
5. Change ton mot de passe quand tu veux depuis Manage > Access > "Your account".

**Inviter quelqu'un** : dans Manage > Access, tape son email, choisis son rôle (member/owner), clique "+ Invite". Préviens-le en dehors du dashboard qu'il doit aller sur le lien, s'inscrire avec **exactement cet email** et le mot de passe générique `MonLogistics2026!` — il verra alors apparaître le projet automatiquement, sans étape supplémentaire.

**Créer un nouveau projet** : sur l'écran "Your projects", tape un nom dans "New project name" et clique "+ Create project". Tu en deviens automatiquement owner ; les phases/tâches/équipe de ce nouveau projet démarrent vides, indépendamment des autres projets.

**Compromis de sécurité à connaître** : sans confirmation d'email, rien ne prouve qu'une personne qui s'inscrit avec une adresse email est réellement propriétaire de cette adresse — elle doit juste connaître l'email exact qui a été invité et le mot de passe générique. C'est moins strict qu'une vraie vérification par email, mais reste bien plus sécurisé que l'ancien lien ouvert à tous : il faut connaître à la fois l'email invité ET le mot de passe, et la clé `anon` ne donne plus aucun accès par défaut (RLS vérifie `auth.uid()` sur chaque lecture/écriture). Pense à faire changer le mot de passe générique à chaque personne dès sa première connexion.

## Rôles et permissions

Chaque personne a un rôle par projet (visible sur l'écran "Your projects" et dans Manage > Access) :

- **Owner** : contrôle total — crée/modifie/supprime n'importe quoi, invite ou retire des gens du projet, et peut supprimer le projet entier.
- **Editor** : peut créer et modifier n'importe quel élément (phases, tâches, sous-tâches, équipe), mais ne peut jamais rien supprimer, et ne gère pas les accès.
- **Member** : peut créer de nouvelles tâches/sous-tâches, mais ne peut modifier que celles qu'il a créées lui-même ou qui lui sont assignées. Ne peut jamais supprimer, et ne peut pas ajouter de nouveaux Team Members (ça reste réservé à Owner/Editor — ajouter quelqu'un au projet est une décision différente que créer une tâche).
- **Viewer** : lecture seule — ne peut rien créer, modifier ou supprimer.

Le rôle se choisit au moment d'inviter quelqu'un (Manage > Access), et seul un Owner peut inviter ou retirer des gens.

**Qui peut créer un nouveau projet** : seules les personnes listées dans la table Supabase `project_creators` (gérée directement dans Supabase > Table Editor, pas depuis le dashboard). Pour autoriser quelqu'un d'autre à créer des projets, ajoute son email dans cette table. `theo.b@monlogistics.com` y est déjà.

Techniquement, ces droits sont appliqués par les policies RLS dans `migration-roles-permissions.sql`, pas seulement côté interface — même quelqu'un qui bricolerait des requêtes directement ne pourrait pas contourner ces règles.

**Supprimer un projet** : depuis l'écran "Your projects", un bouton "Delete" apparaît sur les projets où tu es Owner. Il demande de retaper le nom exact du projet pour confirmer (vu l'incident du 30/07, mieux vaut une double confirmation qu'un clic accidentel) — ça supprime définitivement le projet et tout ce qu'il contient (phases, tâches, sous-tâches, équipe, objectifs, accès) pour tout le monde. Nécessite `migration-delete-project.sql`.

**Changer le rôle d'accès de quelqu'un** : dans Manage > Team, la colonne "App access" est un menu déroulant (No access / Viewer / Member / Editor / Owner), visible et modifiable seulement par un Owner, et seulement si la personne a un email renseigné (c'est cet email qui la relie à son compte). Choisir un rôle pour quelqu'un qui n'a pas encore d'accès l'invite directement (comme dans Manage > Access) ; changer le rôle de quelqu'un qui a déjà accès met à jour son rôle ; repasser sur "No access" révoque son accès (avec confirmation). Le dashboard empêche de retirer le rôle Owner au seul Owner restant du projet, et demande une confirmation supplémentaire si tu changes ton propre rôle. Nécessite `migration-owner-update-role.sql`.

## Commentaires et rafraîchissement automatique

**Commentaires par tâche/sous-tâche** : dans l'onglet Phases, chaque tâche et sous-tâche affiche un petit bouton "💬 Comment" (ou "💬 N comments" s'il y en a déjà). Cliquer dessus ouvre un mini fil de discussion propre à cet élément, avec un champ pour en écrire un nouveau (Entrée ou bouton "Post" pour envoyer). Contrairement au champ "Notes" (un seul texte libre, écrasé à chaque modification), chaque commentaire garde son auteur et son horodatage, et s'additionne aux précédents — pratique quand plusieurs personnes discutent d'un même point dans le temps. N'importe quel membre du projet peut lire et écrire des commentaires (y compris un Viewer, puisque discuter n'est pas modifier des données), mais on ne peut supprimer que ses propres commentaires (ou, pour un Owner, n'importe lequel). Nécessite `migration-comments.sql` — tant que ce n'est pas exécuté, le bouton "💬 Comment" n'apparaît simplement pas (pas d'erreur affichée).

**Rafraîchissement automatique** : le dashboard recharge silencieusement les données du projet ouvert toutes les 25 secondes (sans afficher "Loading…", pour ne pas gêner), tant que l'onglet du navigateur est actif et que personne n'est en train de taper dans un champ à ce moment précis (le rafraîchissement suivant, 25 secondes plus tard, se fera normalement). Les phases/tâches actuellement dépliées et les fils de commentaires ouverts restent ouverts après un rafraîchissement automatique — seul le contenu se met à jour. Ce n'est pas du "temps réel" instantané (il faut jusqu'à 25 secondes pour voir le changement d'un collègue), mais ça évite d'avoir à cliquer sur "Refresh" pour voir les commentaires ou changements de statut des autres.

**Notifications de commentaires** : la cloche de notifications inclut maintenant les commentaires récents (dernières 48h) laissés par quelqu'un d'autre sur une tâche/sous-tâche que tu as créée ou qui t'est assignée — plus la peine d'ouvrir chaque tâche pour voir si on t'a répondu.

## Pièces jointes et personnes supplémentaires sur une tâche

**Pièces jointes** : dans l'onglet Phases, à côté de "💬 Comment", un bouton "📎 Attachments" permet d'uploader un fichier directement sur une tâche/sous-tâche (jusqu'à 15 Mo), de voir la liste de ce qui a déjà été ajouté, de le télécharger ou de le supprimer. Contrairement au champ "Link" existant (qui pointe vers un lien externe), ceci héberge le fichier lui-même dans Supabase Storage. Les fichiers sont privés — seul quelqu'un qui a accès au projet peut les voir, et un fichier ne peut être supprimé que par celui qui l'a uploadé ou par un Owner. Nécessite `migration-attachments.sql`.

**Plusieurs personnes sur une tâche** : le champ "Assignee" (une seule personne) ne change pas — c'est toujours lui qui apparaît dans les filtres, les notifications, le calcul de charge de travail (Team) et les exports. Mais dans l'onglet Phases, une ligne "Also involved: ..." permet d'ajouter d'autres personnes concernées par une tâche/sous-tâche, avec un bouton pour en retirer. Utile quand une tâche demande une vraie collaboration plutôt qu'un seul responsable. Nécessite `migration-collaborators.sql`.

## Application installable (PWA)

Le dashboard peut maintenant être "installé" comme une app, depuis Chrome/Edge (icône d'installation dans la barre d'adresse, ou menu > "Installer MON Dashboard") ou depuis Safari sur iPhone (Partager > "Sur l'écran d'accueil"). Une fois installé, il s'ouvre en plein écran, sans la barre d'adresse du navigateur, avec sa propre icône. Ça reste exactement le même site (mêmes données, même besoin de connexion internet pour Supabase) — c'est juste plus rapide à ouvrir et plus agréable sur téléphone. Nécessite que `manifest.json`, `sw.js`, `icon-192.png` et `icon-512.png` soient déployés à la racine du site, à côté d'`index.html` (aucune configuration Netlify supplémentaire — ce sont juste des fichiers statiques de plus).

## Version en thaï

Un petit bouton "TH" à côté du bouton mode sombre (bas de la sidebar) bascule toute l'interface en thaï — navigation, en-têtes, boutons, statuts/priorités, filtres, messages des onglets Manage, écrans de connexion et de sélection de projet. Le choix de langue est mémorisé par navigateur (comme le mode sombre), donc **chaque personne choisit sa langue sur son propre appareil** — ça ne se synchronise pas entre les comptes.

Ce qui reste volontairement en anglais, par choix :
- Le contenu que les gens tapent eux-mêmes (titres de tâches, notes, commentaires) — la traduction ne touche que l'habillage de l'interface, jamais les données.
- Les en-têtes de colonnes des exports CSV/Excel, pour que les fichiers exportés restent cohérents peu importe qui les génère.
- Les noms de rôles (Owner/Editor/Member/Viewer) et les messages d'erreur bruts renvoyés par Supabase.

Si jamais un texte apparaît encore en anglais en mode thaï quelque part d'inattendu, c'est probablement un recoin pas encore couvert — dis-le moi et je l'ajoute (tout est centralisé dans un seul dictionnaire dans `index.html`, facile à compléter).

## Incident du 30/07 — réinitialisation accidentelle

`schema.sql` a été relancé alors que le projet contenait déjà de vraies données (équipe, Phase 1 et ses tâches), ce qui a tout remplacé par les données d'exemple (Alex Tremblay, Sam Roy, Planning/Production/Shipping/Brokerage...).

`recover-real-data.sql` reconstruit ce qu'on avait en mémoire de la conversation : les 3 membres de l'équipe (Karsten Thrane, Prapaphan Stienmonkong, Theo Boussemart — rôle/email à compléter pour les deux premiers), la Phase 1 avec ses 6 tâches et 4 sous-tâches, et les 3 objectifs. Il nettoie aussi les lignes d'exemple avant de les réinsérer. Les Phases 2, 3 et 4 (noms exacts non conservés côté conversation) et tout changement de statut/date fait depuis la mise en place initiale ne sont pas récupérables par ce script — à re-saisir à la main dans Manage si besoin, ou à restaurer via Supabase &gt; Database &gt; Backups si un point de sauvegarde existe sur ton plan.

## Prochaines étapes possibles

Déjà fait (voir plus haut pour le détail) : dépendances entre tâches + anti-boucle, historique/journal des changements, notifications de tâches en retard, login par personne avec rôles, commentaires par tâche/sous-tâche, rafraîchissement automatique, notifications de commentaires, pièces jointes, personnes supplémentaires sur une tâche, application installable (PWA), version en thaï.

Ce qui reste, si utile un jour :
- Vrai temps réel (Supabase Realtime) au lieu du rafraîchissement toutes les 25 secondes — demanderait d'activer la réplication sur les tables concernées côté Supabase, actuellement pas nécessaire vu la taille de l'équipe.
- Recherche qui couvre tous tes projets d'un coup, pas juste celui ouvert — demanderait de charger les données de plusieurs projets à la fois, actuellement l'app n'en charge qu'un.
- Remplacer le mot de passe générique partagé par un mot de passe temporaire unique par invitation — bloqué tant qu'il n'y a pas de moyen de l'envoyer automatiquement (pas d'email sortant configuré, par choix).
- Activer les sauvegardes automatiques Supabase (Database > Backups) — pure précaution après l'incident du 30/07, ça se fait directement dans Supabase, pas dans le code.
