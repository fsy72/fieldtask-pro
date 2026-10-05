# FieldTask Pro

Application mobile de gestion d'interventions de terrain.

## Sommaire

1. [Structure du dépôt](#1-structure-du-dépôt)
2. [Prérequis](#2-prérequis)
3. [Premier clone : installation pas à pas](#3-premier-clone--installation-pas-à-pas)
4. [Travailler au quotidien](#4-travailler-au-quotidien)
5. [Conventions d'équipe](#5-conventions-déquipe)
6. [Avant de pousser : checklist](#6-avant-de-pousser--checklist)
7. [Versions (tags)](#7-versions-tags)
8. [Problèmes fréquents](#8-problèmes-fréquents)

---

## 1. Structure du dépôt

```
fieldtask-pro/
├── mobile/      → application Flutter
├── backend/     → API Laravel
├── docs/        → documentation (API, décisions techniques)
└── README.md
```

### Branche

Toute l'équipe travaille directement sur la branche **`main`**.

> **Règle d'or** : avant de commencer à travailler et avant chaque `git push`, on récupère d'abord les modifications des autres avec `git pull --rebase origin main`. On fait des commits petits et fréquents pour limiter les conflits.

---

## 2. Prérequis

Vérifie que ces outils sont installés :

| Outil | Vérification |
|---|---|
| Git | `git --version` |
| Flutter | `flutter doctor` (tout doit être en ✓ pour Android) |
| PHP (8.2 ou plus) | `php -v` |
| Composer | `composer -V` |
| Base de données (MySQL ou PostgreSQL) | selon la configuration du `.env` |

Si `flutter doctor` signale un problème de licences Android :

```bash
flutter doctor --android-licenses
```

---

## 3. Premier clone : installation pas à pas

### Étape 1 : accepter l'invitation

Le propriétaire du dépôt t'invite depuis GitHub. Accepte l'invitation reçue par e-mail (ou dans tes notifications GitHub). Sans cela, tu n'as aucun accès.

### Étape 2 : configurer Git (une seule fois par machine)

```bash
git config --global user.name "Ton Nom"
git config --global user.email "ton-email@exemple.com"
```

L'e-mail doit être celui de ton compte GitHub.

### Étape 3 : configurer l'authentification (une seule fois par machine)

Le dépôt est privé : GitHub doit pouvoir t'identifier quand tu fais `clone`, `pull` ou `push`. Choisis **une** des deux options.

**Option A : clé SSH (recommandée, pas de mot de passe à retaper)**

```bash
ssh-keygen -t ed25519 -C "ton-email@exemple.com"
cat ~/.ssh/id_ed25519.pub
```

Sous Windows PowerShell : `type $env:USERPROFILE\.ssh\id_ed25519.pub`

Copie le résultat (la clé **publique**, celle qui finit par `.pub`), puis sur GitHub : photo de profil → **Settings → SSH and GPG keys → New SSH key** (lien direct : https://github.com/settings/keys). Colle la clé et enregistre. Teste ensuite :

```bash
ssh -T git@github.com
```

**Option B : HTTPS avec token**

Génère un Personal Access Token (**Settings → Developer settings → Personal access tokens**, permission `repo`). Au premier `git push`, utilise ton nom d'utilisateur et le token à la place du mot de passe. Sous Windows, Git Credential Manager peut aussi gérer cela via une fenêtre de connexion.

> Chaque membre utilise **sa propre** clé ou son propre token. Ne partage jamais ta clé privée (le fichier sans `.pub`) ni ton token.

### Étape 4 : cloner le dépôt

```bash
# Avec SSH
git clone git@github.com:ORGANISATION-OU-USER/fieldtask-pro.git

# Ou avec HTTPS
git clone https://github.com/ORGANISATION-OU-USER/fieldtask-pro.git

cd fieldtask-pro
```

Tu es directement sur `main`.

### Étape 5 : installer la partie mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter doctor
```

Pour lancer l'application (émulateur démarré ou téléphone branché en mode développeur) :

```bash
flutter devices      # vérifier qu'un appareil est détecté
flutter run
```

### Étape 6 : installer la partie backend (Laravel)

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
```

Ouvre ensuite `backend/.env` et renseigne la connexion à ta base de données locale :

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=fieldtask_pro
DB_USERNAME=root
DB_PASSWORD=
```

Crée la base de données, puis :

```bash
php artisan migrate
php artisan db:seed      # si des seeders existent
php artisan serve
```

L'API est disponible sur http://127.0.0.1:8000.

> Le fichier `.env` n'est **jamais** versionné. Demande au responsable du projet les valeurs spécifiques (clés d'API, etc.) par un canal privé, jamais par Git.

### Étape 7 : vérifier que tout fonctionne

```bash
cd mobile && flutter analyze && flutter test
cd ../backend && php artisan test
```

Si tout passe, tu es prêt à travailler.

---

## 4. Travailler au quotidien

### 1. Début de journée ou avant de commencer une tâche

```bash
git pull --rebase origin main
```

Puis installe les éventuelles nouvelles dépendances :

```bash
cd mobile && flutter pub get
cd ../backend && composer install && php artisan migrate
```

### 2. Coder et committer

Commite régulièrement, par petites unités logiques :

```bash
git add .
git commit -m "feat(mobile): ajout de l'écran de connexion"
```

Avant de commiter, vérifie avec `git status` que tu n'ajoutes ni `.env`, ni clés de signature, ni dossiers `build/` ou `vendor/`.

### 3. Pousser ses modifications

```bash
git pull --rebase origin main     # récupérer ce que les autres ont poussé
git push origin main
```

Si le `push` est refusé (« rejected » / « non-fast-forward »), c'est que quelqu'un a poussé entre-temps : refais `git pull --rebase origin main`, résous les conflits éventuels, puis `git push origin main`.

### 4. En cas de conflit

```bash
git pull --rebase origin main
# Git signale les fichiers en conflit : ouvre-les, garde le bon code
git add fichier-resolu
git rebase --continue
git push origin main
```

Pour abandonner l'opération : `git rebase --abort`.

### Bonnes habitudes

- Prévenir l'équipe avant de modifier un gros fichier partagé (routes, thème, configuration).
- Se répartir les tâches par fichiers ou par écrans pour ne pas éditer les mêmes lignes en même temps.
- Pousser souvent (au moins une fois par jour), et jamais du code qui ne compile pas.

---

## 5. Conventions d'équipe

### Messages de commit

Format : `type(scope): description courte`

| Type | Usage |
|---|---|
| `feat` | nouvelle fonctionnalité |
| `fix` | correction de bug |
| `refactor` | réécriture sans changement de comportement |
| `docs` | documentation |
| `test` | ajout ou modification de tests |
| `chore` | maintenance, dépendances, configuration |

Scopes : `mobile` ou `backend`. Exemples :

```
feat(mobile): écran de liste des interventions
fix(backend): erreur 500 sur la route /api/interventions
chore(mobile): mise à jour des dépendances
```

### Code

- **Flutter** : `dart format .` et `flutter analyze` doivent passer sans erreur.
- **Laravel** : respecter PSR-12 (`./vendor/bin/pint` si Laravel Pint est installé).
- Ne jamais modifier à la main les fichiers générés (`*.g.dart`, `*.freezed.dart`). Pour les régénérer : `dart run build_runner build --delete-conflicting-outputs`.
- `pubspec.lock` et `composer.lock` sont versionnés : ne les supprime pas.

### API

Toute modification d'une route ou d'un format JSON doit être documentée dans `docs/` (ou dans la documentation OpenAPI du projet), et annoncée à l'équipe, afin que la partie mobile puisse s'y adapter.

### Secrets

Ne jamais commiter : `.env`, `*.jks`, `*.keystore`, `key.properties`, mots de passe, tokens. Si un secret a été commité par erreur, préviens immédiatement le responsable du projet : il faudra le **révoquer** et le régénérer, car le supprimer d'un commit ultérieur ne suffit pas.

---

## 6. Avant de pousser : checklist

- [ ] J'ai fait `git pull --rebase origin main`
- [ ] `flutter analyze` et `flutter test` passent (si j'ai touché à `mobile/`)
- [ ] `php artisan test` passe (si j'ai touché à `backend/`)
- [ ] Aucun secret ni fichier généré n'est inclus (`git status`)
- [ ] Le message de commit respecte la convention
- [ ] La documentation de l'API est à jour si nécessaire

---

## 7. Versions (tags)

Gérées par le responsable du projet. Quand une version stable est prête :

```bash
git pull origin main
git tag v1.0.0
git push origin v1.0.0
```

---

## 8. Problèmes fréquents

**`Permission denied (publickey)` au clone ou au push**
La clé SSH n'est pas ajoutée à ton compte GitHub, ou l'invitation au dépôt n'a pas été acceptée. Vérifie avec `ssh -T git@github.com`.

**`remote: Repository not found`**
Tu n'as pas accès au dépôt : invitation non acceptée, ou mauvaise URL.

**`! [rejected] main -> main (fetch first)`**
Quelqu'un a poussé avant toi. Fais `git pull --rebase origin main`, puis `git push origin main`.

**`flutter run` ne trouve aucun appareil**
Lance un émulateur ou branche un téléphone avec le débogage USB activé, puis vérifie avec `flutter devices`.

**Erreurs après un `git pull` côté Flutter**
Relance `flutter pub get`, puis `flutter clean` si le problème persiste.

**Erreurs après un `git pull` côté Laravel**
Lance `composer install` puis `php artisan migrate`. En dernier recours : `php artisan config:clear && php artisan cache:clear`.

**Conflit sur `pubspec.lock` ou `composer.lock`**
Résous d'abord le conflit dans `pubspec.yaml` (ou `composer.json`), puis régénère le fichier de verrouillage avec `flutter pub get` (ou `composer install`).

---

## Contacts

- Responsable du projet : _à compléter_
- Canal d'équipe : _à compléter_