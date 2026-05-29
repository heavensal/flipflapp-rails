# FlipFlapp Rails — instructions pour agents IA

FlipFlapp est une application Rails pour organiser des matchs sportifs entre amis (événements, équipes, participants, amitiés, notifications). Interface en français ; code et commits en anglais sauf texte utilisateur (I18n si possible).

## Stack

- Rails 8, PostgreSQL, Devise (+ confirmable)
- Hotwire (Turbo, Stimulus), Tailwind CSS 4, esbuild, Propshaft
- Carrierwave + Cloudinary, Ransack
- Déploiement : Docker + Kamal → `flipflapp.fr`

## Commandes locales

```bash
bundle install && npm install
bin/rails db:prepare
bin/dev                    # serveur + watch JS/CSS
bundle exec rspec
bin/rubocop
bin/brakeman --no-pager
```

## TDD (RSpec)

- **Toujours** écrire ou mettre à jour des specs model avec le code métier.
- **Uniquement** `spec/models/` : validations DB, unicité, callbacks CRUD, effets sur les données (ex. notifications).
- **Pas** de request specs, view specs ni tests d’affichage — ils ne bloquent pas le deploy.
- Utiliser **Factory Bot** (`spec/factories/`) — pas de fixtures YAML.
- Ne pas laisser d’exemples `pending` sans issue.

## Conventions Rails

- MVC REST, strong parameters, logique métier dans les modèles (pas les helpers).
- Stimulus : `app/javascript/controllers/`, enregistrer dans `app/javascript/controllers/index.js`.
- Partials partagés : `app/views/**/components/`.
- Ne pas committer `.env`, `config/master.key`, `.kamal/secrets`.

## Git & CI

- Branche de production : **`master`**.
- Push sur `master` → CI (Brakeman, RuboCop, RSpec) puis **Kamal deploy** si vert.
- Ne pas commit / push sauf demande explicite de l’utilisateur.

## Déploiement

Voir `docs/DEPLOYMENT.md` pour les secrets GitHub et le flux Kamal.

## Fichiers de référence

| Sujet | Fichier |
|-------|---------|
| Routes | `config/routes.rb` |
| Kamal | `config/deploy.yml` |
| CI/CD | `.github/workflows/ci.yml` |
| Cursor | `.cursor/rules/` |
| Copilot | `.github/copilot-instructions.md` |
