# Déploiement FlipFlapp (Kamal + GitHub Actions)

## Flux automatique

Sur chaque **push sur `master`** :

1. Brakeman, RuboCop, RSpec (PostgreSQL)
2. Si tout passe → `bin/kamal deploy` vers `flipflapp.fr`

## Bases de données (Neon)

| Variable | Environnement | Où la définir |
|----------|---------------|---------------|
| `DEVELOPMENT_NEON_DB` | `development` | `.env` (local) |
| `TEST_NEON_DB` | `test` | `.env` (local) ; secret GitHub optionnel pour CI |
| `PRODUCTION_NEON_DB` | `production` | `.kamal/secrets` (deploy local) ; secret GitHub `production` (CI deploy) |

Configuration : `config/database.yml`.

En CI, le job **test** définit `TEST_NEON_DB` sur le Postgres éphémère du workflow.

## Secrets GitHub (environment `production`)

| Secret | Description |
|--------|-------------|
| `SSH_PRIVATE_KEY` | Clé privée SSH (`ubuntu` sur le serveur) |
| `KAMAL_REGISTRY_PASSWORD` | Token Docker Hub |
| `RAILS_MASTER_KEY` | `config/master.key` |
| `PRODUCTION_NEON_DB` | URL Neon **production** |
| `CLOUDINARY_*` | Cloudinary |
| `GOOGLE_*` | OAuth + Maps |
| `SMTP_*` | E-mail |

```bash
gh secret set PRODUCTION_NEON_DB --env production --body "$(grep '^PRODUCTION_NEON_DB=' .kamal/secrets | cut -d= -f2-)"
# Remplacer l’ancien secret si présent :
# gh secret delete NEON_DB --env production
```

## Environnement GitHub `production`

Optionnel : approbation manuelle avant deploy (**Settings → Environments → production**).

## Déploiement manuel

```bash
cp .kamal/secrets.example .kamal/secrets   # PRODUCTION_NEON_DB + autres secrets
bin/kamal deploy
```

## Fichiers Kamal

- `config/deploy.yml` — injecte `PRODUCTION_NEON_DB` dans le conteneur
- `.kamal/secrets` — local (gitignored)
- `.kamal/secrets.cd` — modèle CI
