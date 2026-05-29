# Tests (RSpec)

Les specs **bloquent le deploy** (job CI `test` sur `master`). Elles couvrent uniquement :

- **Règles métier / validations** (données invalides refusées)
- **Intégrité CRUD** (unicité, callbacks qui modifient la data, notifications liées aux enregistrements)

Pas de tests de vues, helpers ni request specs (affichage HTTP).

## Run

```bash
bundle exec rspec
bundle exec rspec spec/models/event_spec.rb
```

## Layout

| Directory | Purpose |
|-----------|---------|
| `spec/models/` | Validations, contraintes logiques, effets CRUD sur la DB |
| `spec/factories/` | Factory Bot |

## TDD workflow

1. Écrire un exemple model qui échoue (validation ou effet data).
2. Implémenter le minimum dans `app/models/`.
3. `bundle exec rspec` + `bin/rubocop`.
