# FieldTask Pro - Backend Laravel

API REST du projet mobile FieldTask Pro. Elle gère la connexion des techniciens, leurs interventions, la synchronisation des modifications et les pièces jointes (photos et signatures).

## Prérequis

- PHP 8.3 ou plus récent
- Composer
- MySQL démarré en local, ou une base configurée dans `.env`

## Installation locale

Depuis le dossier `backend/` :

```powershell
composer install
Copy-Item .env.example .env
```

`.env.example` est le modèle versionné. Copiez-le en `.env`, puis modifiez **`.env` uniquement** avec les paramètres de votre machine. Ne modifiez pas `.env.example` pour y mettre vos identifiants personnels. Si vous avez déjà un `.env`, conservez-le et adaptez ses paramètres au lieu de l'écraser.

Vérifiez au minimum les valeurs locales de l'application et de MySQL dans `.env` :

```dotenv
APP_NAME="FieldTask Pro"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=fieldtask_pro
DB_USERNAME=root
DB_PASSWORD=mot_de_passe_mysql_local
```

Remplacez `mot_de_passe_mysql_local` par le mot de passe réel de votre MySQL local. Créez la base de données correspondante et démarrez MySQL avant la migration. Ensuite, générez la clé Laravel (à faire une fois par installation locale) :

```powershell
php artisan key:generate
```

Initialisez ensuite le schéma et les données de démonstration, puis démarrez l'API :

```powershell
php artisan migrate --seed
php artisan serve
```

Le serveur écoute par défaut sur `http://127.0.0.1:8000`. Vérifiez les routes avec :

```powershell
php artisan route:list --path=api
```

Ne partagez pas `.env` et ne commitez jamais ses secrets. Chaque membre configure sa propre base locale.

### URL depuis Flutter

- Navigateur ou client HTTP sur le même ordinateur : `http://127.0.0.1:8000`
- Émulateur Android : `http://10.0.2.2:8000`
- Téléphone physique : utilisez l'adresse IP locale de l'ordinateur et assurez-vous qu'ils sont sur le même réseau.

## Données de démonstration

`php artisan migrate --seed` crée quatre comptes de démonstration et quinze interventions :

- Fieldtask Pro — `fieldtask.pro@gmail.com` / `password_pro@123` — 5 interventions
- Fallou SY — `fallou.sy@gmail.com` / `technicien123` — 3 interventions
- Khadidiatou NDIAYE — `khadidiatou.ndiaye@gmail.com` / `technicien123` — 4 interventions
- Cheikh Tidiane — `cheikh.tidiane@gmail.com` / `technicien123` — 3 interventions

Ces comptes sont réservés au développement local. Ne réutilisez pas ces identifiants en production. Pour insérer ou actualiser les comptes et les interventions dans une base existante, exécutez `php artisan db:seed` depuis `backend/`.

## Authentification

La connexion renvoie un jeton Sanctum. Envoyez ce jeton dans chaque appel protégé :

```http
Authorization: Bearer <access_token>
Accept: application/json
```

Dans Thunder Client, utilisez **Auth > Bearer** et collez le jeton obtenu à la connexion. Il n'est pas nécessaire de créer un environnement.

## Routes API

Les routes sont préfixées par `/api`. Le segment `v1` a été retiré.

| Méthode | Chemin | Authentification | Rôle |
|---|---|---|---|
| `POST` | `/api/auth/login` | Non | Connexion et émission d'un jeton |
| `GET` | `/api/auth/me` | Bearer | Profil du technicien connecté |
| `DELETE` | `/api/auth/logout` | Bearer | Révoquer le jeton courant |
| `GET` | `/api/interventions` | Bearer | Lister ses interventions |
| `POST` | `/api/interventions` | Bearer | Créer une intervention |
| `GET` | `/api/interventions/{id}` | Bearer | Consulter une intervention |
| `PUT` ou `PATCH` | `/api/interventions/{id}` | Bearer | Modifier une intervention |
| `POST` | `/api/interventions/{id}/attachments` | Bearer | Envoyer une photo ou une signature |
| `GET` | `/api/interventions/{id}/attachments/{attachment}` | Bearer | Télécharger une pièce jointe |

### Connexion

`POST http://127.0.0.1:8000/api/auth/login` avec un corps JSON :

```json
{
  "email": "test@gmail.com",
  "password": "password",
  "device_name": "Thunder Client"
}
```

La réponse contient `access_token`. Copiez sa valeur dans **Auth > Bearer** pour les autres requêtes.

### Liste, recherche et tri

Exemple :

```http
GET /api/interventions?status=pending&search=Diamniadio&priority=desc&per_page=20
```

Paramètres facultatifs :

- `status` : `pending`, `in_progress` ou `completed`
- `search` : recherche dans le client, l'adresse, la description et l'équipement
- `priority` : `asc` ou `desc` (par défaut `desc`)
- `per_page` : de 1 à 100 (par défaut 20)

La liste est paginée et limitée aux interventions du technicien authentifié.

### Créer une intervention

`POST /api/interventions` accepte un corps JSON. `client_uuid` est facultatif; l'application mobile peut le générer avant une création hors ligne. Répéter la création avec le même identifiant pour le même technicien évite de créer un doublon.

```json
{
  "client_uuid": "10000000-0000-4000-8000-000000000010",
  "client": "Atelier de Dakar",
  "address": "Dakar, Sénégal",
  "description": "Contrôle de l'installation électrique.",
  "equipment": "Armoire électrique A-12",
  "status": "pending",
  "priority": 2,
  "latitude": 14.7167,
  "longitude": -17.4677,
  "scheduled_at": "2026-10-12T09:00:00Z",
  "notes": "Appeler le client avant l'arrivée."
}
```

Champs requis : `client`, `address`, `description`, `equipment`. Les statuts valides sont `pending`, `in_progress` et `completed`; la priorité va de 1 à 3.

### Modifier une intervention et synchroniser

Chaque `PUT` ou `PATCH` doit inclure le `sync_version` reçu avec l'intervention. Après une mise à jour, le serveur incrémente cette version. Si la version envoyée est périmée, l'API répond `409 Conflict` avec l'état serveur courant.

```json
{
  "sync_version": 1,
  "status": "in_progress",
  "notes": "Diagnostic commencé."
}
```

La file d'attente hors ligne et les nouvelles tentatives réseau sont gérées par l'application mobile; l'API fournit l'idempotence de création et la détection des conflits de mise à jour.

### Envoyer une photo ou une signature

`POST /api/interventions/{id}/attachments` utilise `multipart/form-data` :

- `type` : `photo` ou `signature`
- `file` : image JPG, PNG ou WebP, maximum 10 Mo
- `caption` : texte facultatif, maximum 255 caractères

Les fichiers sont stockés sur le disque privé local. L'API renvoie une URL de téléchargement; le jeton Bearer reste requis pour la récupérer.

## Structure du backend

- `routes/api.php` : routes de l'API
- `app/Http/Controllers/` : contrôleurs HTTP
- `app/Http/Requests/` : validation des entrées
- `app/Http/Resources/` : format des réponses JSON
- `app/Models/` : modèles et relations Eloquent
- `database/migrations/` : schéma de la base
- `database/factories/` et `database/seeders/` : données de développement

