# Déploiement FlipFlapp (Kamal + GitHub Actions)

## Flux automatique

Sur chaque **push sur `master`** :

1. Brakeman, RuboCop, RSpec (PostgreSQL + build assets)
2. Si tout passe → `bin/kamal deploy` vers `flipflapp.fr`

## Secrets GitHub (Settings → Secrets and variables → Actions)

| Secret | Description |
|--------|-------------|
| `SSH_PRIVATE_KEY` | Clé privée SSH pour l’utilisateur `ubuntu` sur le serveur |
| `KAMAL_REGISTRY_PASSWORD` | Token / mot de passe Docker Hub (`adam1344`) |
| `RAILS_MASTER_KEY` | Contenu de `config/master.key` |
| `NEON_DB` | URL PostgreSQL production |
| `CLOUDINARY_*` | Credentials Cloudinary |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` / `GOOGLE_MAPS_KEY` | OAuth + Maps |
| `SMTP_USERNAME` / `SMTP_PASSWORD` | Envoi d’e-mails |

Configurer avec la CLI :

```bash
gh secret set SSH_PRIVATE_KEY < ~/.ssh/id_ed25519
gh secret set RAILS_MASTER_KEY < config/master.key
# … répéter pour chaque secret
```

## Environnement GitHub `production`

Créer un environment **production** (optionnel mais recommandé) pour exiger une approbation manuelle avant deploy.

## Déploiement manuel

```bash
cp .kamal/secrets.example .kamal/secrets   # puis éditer
bin/kamal deploy
```

## Fichiers Kamal

- `config/deploy.yml` — cible, registry, secrets injectés
- `.kamal/secrets` — local uniquement (gitignored)
- `.kamal/secrets.cd` — modèle CI (variables d’environnement)
