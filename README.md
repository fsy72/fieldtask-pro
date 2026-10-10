# FieldTask Pro — commandes Git

Ce guide présente le flux Git de l'équipe pour travailler sur le dépôt. Exécutez les commandes depuis la racine `fieldtask-pro`.

## Récupérer les dernières modifications

Avant de commencer, vérifiez l'état de votre copie locale puis récupérez les changements de `main` :

```bash
git status
git pull --rebase origin main
```

## Enregistrer vos modifications

Ajoutez uniquement les fichiers concernés. Remplacez les chemins de l'exemple par ceux que vous avez réellement modifiés :

```bash
git add backend/routes/api.php backend/README.md
git status
git commit -m "docs(backend): mettre à jour le README"
```

Vérifiez la liste affichée par `git status` avant le commit. Ne validez jamais `.env`, des secrets, `vendor/` ou des fichiers générés.

Format conseillé pour les messages de commit : `type(scope): description courte`, par exemple `feat(backend): ajouter la liste des interventions` ou `fix(mobile): corriger la connexion`.

## Envoyer vos modifications

Avant chaque envoi, intégrez les changements récents puis poussez sur `main` :

```bash
git pull --rebase origin main
git push origin main
```

## Résoudre un conflit pendant le rebase

Corrigez les fichiers signalés, puis marquez-les comme résolus et reprenez le rebase :

```bash
git add <fichier-corrige>
git rebase --continue
```

Pour abandonner le rebase en cours :

```bash
git rebase --abort
```
