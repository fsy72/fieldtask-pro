# FieldTask Pro — application mobile

Application Flutter de gestion des interventions terrain. Le mobile communique avec l'API Laravel du dossier `backend/`.

## Préparer le projet

Depuis ce dossier (`mobile/`) :

```powershell
flutter pub get
```

Lancez d'abord le backend Laravel et vérifiez qu'il répond sur le réseau utilisé par l'application.

## Configurer l'adresse de l'API

L'application lit l'URL de l'API depuis `API_BASE_URL`. La valeur par défaut convient à l'émulateur Android :

```text
http://10.0.2.2:8000/api/
```

Lancez l'application sur un émulateur Android avec cette valeur par défaut :

```powershell
flutter run
```

Pour un téléphone physique, remplacez `192.168.1.10` par l'adresse IP locale de l'ordinateur qui héberge Laravel. Le téléphone et l'ordinateur doivent être sur le même réseau :

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/
```

Ne mettez pas de secret ni de jeton dans `API_BASE_URL`. Pour une mise en production, utilisez une URL HTTPS.

## Compte local de démonstration

Après avoir initialisé le backend avec `php artisan migrate --seed` :

- E-mail : `test@example.com`
- Mot de passe : `password`

La connexion utilise `POST /api/auth/login`. Le jeton Sanctum et le profil technicien sont conservés dans le stockage sécurisé du système. Au redémarrage, le profil est validé par `GET /api/auth/me`; si l'API est indisponible, le profil sauvegardé permet d'ouvrir la liste locale. La déconnexion tente de révoquer le jeton auprès du backend, puis supprime le jeton et le profil du stockage sécurisé.

## Organisation du code

Le code mobile suit une séparation en couches, avec Riverpod pour l'état applicatif :

- `lib/features/<fonction>/domain/` : entités et contrats métier
- `lib/features/<fonction>/data/` : modèles, sources de données et implémentations des dépôts
- `lib/features/<fonction>/presentation/` : écrans et contrôleurs Riverpod
- `lib/core/` : réseau et stockage partagé

La connexion au backend et la restauration de session sont en place. La liste des interventions est chargée depuis l'API, puis mise en cache dans SQLite par technicien. En cas de coupure, la dernière liste locale reste affichée; le chargement est relancé quand le réseau revient. La file d'attente des modifications hors ligne, la fiche détaillée, la carte, les pièces jointes, la signature et les rappels restent à développer.
