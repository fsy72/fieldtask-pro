# FieldTask Pro
Application mobile de gestion d'interventions de terrain.

## Structure
- `mobile/` : application Flutter
- `backend/` : API Laravel

## Installation
### Mobile
cd mobile && flutter pub get && flutter run

### Backend
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve

## Workflow Git
- `main` : versions stables
- `dev` : intégration
- `feature/*`, `fix/*` : branches de travail, à merger dans `dev` via Pull Request