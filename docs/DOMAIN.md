# FlipFlapp Domain (MVP)

Business rules for the football match organizer. Product scope: [PROJECT.md](PROJECT.md).

This document is the **source of truth for behavior**. Model specs in `spec/models/` must match these rules. When code and this doc disagree, either fix the code (TDD) or update this doc after an explicit product decision.

Use **Active Record model names** in this doc and in specs — no parallel vocabulary.

---

## Models

| Model | Role |
|-------|------|
| `User` | Authenticated player; can create `Event` records, join via `EventParticipant`, and manage `Friendship` |
| `Event` | Football match; owned by `event.user`; public or private (`is_private`) |
| `EventTeam` | Fixed `slot` (`team_one`, `team_two`, `bench`) + renameable `label` per `Event` |
| `EventParticipant` | `User` joined to an `Event` on an `EventTeam` |
| `Friendship` | Link between two `User` records; enables private `Event` visibility and `Event` invitations |
| `Notification` | In-app record for a `User`; web inbox now, same payloads for iOS/Android push later |

---

## User

Every `User` is a **player** who can also **organize** `Event` records. There is no separate organizer account type.

### Authentication

- Email and password via Devise: **registerable**, **confirmable**, **recoverable**, **rememberable**, **validatable**.
- Follow the **current Devise flow** end to end (sign up, email confirmation, sign in, password reset, account update).
- Required profile fields: `first_name`, `last_name`, `username` (unique, case-insensitive).
- `username` is auto-generated on create if blank (`firstnamel#NNNN` pattern).
- `provider` / `uid`: email users use `provider: email`, `uid` synced with `email`.
- Optional `avatar` (CarrierWave / Cloudinary).
- **Google OAuth is out of scope** — remove residual OAuth code; email auth only.

### What an authenticated `User` sees

- **Public** `Event` records (`is_private: false`).
- **Private** `Event` records from accepted `Friendship` friends who are `event.user` (see Visibility).
- Also: own `Event` records, `Event` records where they are `EventParticipant`, and `Event` records where they have an `invited` `Notification`.

### Organizer (`event.user`)

- Any authenticated `User` can **create** an `Event`.
- Only `event.user` can **update** or **destroy** that `Event`.

### Invitations

- A `User` with an `EventParticipant` on an `Event` can invite accepted `Friendship` friends who are not yet participants (`get_my_friends_but_not_participants`). See Invitations.

### Friendship search

- A `User` can **Ransack** other `User` records to send a `Friendship` request.
- Search scope: `User.users_without_friendship(current_user)` — excludes self and any `User` with an existing `Friendship` (pending, accepted, or declined).
- **Ransackable attributes only:** `first_name`, `last_name`, `username`. Email is **not** searchable.

### Roles

- **player** (default) — full MVP player behavior above.
- **admin** — same player experience, plus unrestricted back-office access (see Admin). `role` on the same `User` record; not a separate account type.

### Removed from domain

- `User.status` (`private` / `public`) — **no longer used**; column to remove from the schema in a future migration.

---

## Friendship

A `Friendship` connects two `User` records (`sender`, `receiver`). It is required for two MVP behaviors:

1. **See** private `Event` records from accepted friends who are `event.user` (see Visibility).
2. **Invite** accepted friends to an `Event` via `Notification.invited` (see Invitations).

### Entry points

An authenticated `User` can send a `Friendship` request from:

- **Player search** — `FriendshipsController#search` (Ransack on `first_name`, `last_name`, `username`; scope `User.users_without_friendship`).
- **Player profile** — `GET /users/:id` with “add friend” → `FriendshipsController#create`.

Both paths create the same `Friendship` record (`sender` = current `User`, `receiver` = target `User`, `status: pending`).

### Lifecycle

| Action | Who | Result |
|--------|-----|--------|
| Send request | `sender` | `Friendship` with `status: pending`; **`Notification` to `receiver`** (see Notification) |
| Accept | `receiver` | `status` → `accepted` |
| Refuse | `receiver` | `Friendship` destroyed |
| Cancel request | `sender` (pending) | `Friendship` destroyed |
| Unfriend | `sender` or `receiver` (accepted) | `Friendship` destroyed |

### States

- **pending** — request sent; `receiver` can accept or refuse.
- **accepted** — friends; enables private `Event` visibility and `Event` invitations.
- **declined** — allowed by model validation; **not used** in the web flow (refuse destroys the record). Remove or repurpose in a future cleanup if unused.

### Validation rules

- `sender_id` cannot equal `receiver_id`.
- Only one `Friendship` per directed pair (`sender_id` + `receiver_id`); duplicate requests are rejected.
- Reverse-direction duplicate (`receiver` → `sender` when `sender` → `receiver` exists) is rejected.
- A `User` with any existing `Friendship` to another `User` (pending, accepted, or declined) does not appear in `User.users_without_friendship` search results.

### `User` helpers

- `is_friend_with?(other_user)` — accepted `Friendship`.
- `has_pending_request_from?(other_user)` — other `User` is `sender`, `status: pending`.
- `has_asked_to_be_friend_with?(other_user)` — current `User` is `sender`, `status: pending`.
- `accepted_friendships` — all accepted `Friendship` records involving the `User`.
- `get_my_friends_but_not_participants(event)` — accepted friends not yet on the `Event` (invite picker).

### Index

`FriendshipsController#index` lists accepted friends, pending sent requests, and pending received requests for the current `User`.

---

## Event

A football match scheduled by a `User`. The organizer is always `event.user` (`belongs_to :user`).

### Attributes

| Attribute | Rule |
|-----------|------|
| `title`, `location`, `start_time` | Required; `start_time` must be in the future |
| `number_of_participants` | Positive integer — **official player capacity** for `team_one` + `team_two` combined (e.g. 10 for 5v5, 11 for 11v11) |
| `price` | ≥ 0; whole euros only (step `1.00`); always displayed with 2 decimal places |
| `is_private` | Boolean; **defaults to `true`** |
| `description` | Optional |
| `latitude`, `longitude` | Optional; no model validation today |

### Official headcount (`Event#participants_count`)

- Counts `EventParticipant` records on **countable** `EventTeam` records (`slot` `team_one` or `team_two`).
- Does **not** count `EventParticipant` records on `slot: bench`.
- Compared to `number_of_participants` in the UI (`participants_count / number_of_participants`).

### Registrations (`Event#registrations_count`)

- Counts **every** `EventParticipant` on the `Event`, including bench.
- Not displayed in the slots UI; use for total attendance on the event.
- Bench `User` records follow `Event` updates via `Notification` but are not official players until they move to `team_one` or `team_two`.

### `event.user` (organizer)

- Any authenticated `User` can **create** an `Event`.
- Only `event.user` can **update** or **destroy** the `Event` (`Event#am_i_the_author?` ⇔ `event.user == user`).

### `after_create`

1. Create exactly three `EventTeam` records: `slot` `team_one`, `team_two`, `bench` with `label` from `I18n.t("event_team.slots.<slot>.default_label")` (see `config/locales/<locale>/event_team.yml`).
2. Create an `EventParticipant` for `event.user` on the `team_one` `EventTeam`.
3. Do **not** emit a `joined` `Notification` for `event.user`'s auto-registration.

### Scopes

- `Event.upcoming` — `start_time` in the future, ordered by `start_time` (used on index).
- `Event.visible_to(user)` — browse list for an authenticated `User` (public + own + participant + invited + accepted friends' private `Event` records). Friend authors via `Friendship.accepted_friend_ids_for` subquery (no Ruby `pluck`).
- `Event.private_visible_to(user)` — **only** private `Event` records authored by the `User` or by accepted `Friendship` friends (`event.user`). Excludes public `Event` records and private `Event` records reached only via participant/invite paths.
- `Event.with_countable_participants_count` — annotates each row with countable-headcount SQL (used by index to avoid N+1 `participants_count`).
- `Event#fill_level` — `:open` / `:tight` / `:full` for UI occupancy badges.

### `Notification` side effects

**`updated`** — when `title`, `start_time`, `price`, or `number_of_participants` change:
- One `Notification` per changed field per `EventParticipant` `User` (including bench), excluding `event.user`.
- Untracked fields (`description`, `location`, `is_private`, `latitude`, `longitude`) do **not** trigger `updated`.

**`canceled`** — on destroy:
- Notify all `EventParticipant` `User` records except `event.user`.
- Delete all `Notification` records with `notifiable` = this `Event`.
- `canceled` notifications use `notifiable: nil`.

### Access helpers

- `Event#viewable_by?(user)` / `Event#joinable_by?(user)` — see Visibility.
- `Event#can_invite?(user)` ⇔ `Event#in_this_event?(user)` — any `EventParticipant` can invite. See Invitations.

---

## EventTeam

- Each `Event` has **exactly three** `EventTeam` records at creation (`Event::TEAM_SLOTS`). No fourth team per event.

### Schema (target)

| Column | Purpose |
|--------|---------|
| `slot` | **Immutable** squad identity: `team_one`, `team_two`, or `bench` |
| `label` | **Display name** shown in the UI (renameable on countable teams). Max **24** characters; letters, digits, and spaces only. |

One row per `slot` per `Event` (unique `event_id` + `slot`). `label` must be unique within the `Event`.

### Default labels at `Event` creation

Default `label` strings are set from **I18n** when the `Event` is created — not hardcoded in the model:

```text
config/locales/<locale>/event_team.yml  →  event_team.slots.<slot>.default_label
```

French ships first (`fr`); adding English is a new locale file with the same keys. **`slot` is locale-independent**; only `label` varies by locale or custom rename.

| `slot` | FR default `label` (example) | Countable toward `participants_count` |
|--------|-------------------------------|--------------------------------------|
| `team_one` | `Equipe 1` | Yes |
| `team_two` | `Equipe 2` | Yes |
| `bench` | `Sur le Banc` | No |

**Countable teams** — `EventTeam` records with `slot` `team_one` or `team_two`. Players on these teams count toward `Event#participants_count` and `number_of_participants`. The **bench** team is not countable.

Example: `slot: team_one`, `label: Real Madrid` — still **team one** for headcount, `Notification` rules, and domain logic.

### Rules

- `slot` never changes after create.
- Each `EventParticipant` belongs to one `EventTeam`.
- A `User` on `slot: bench` is an `EventParticipant` but **not** an official player: availability is uncertain; they follow `Event` activity (`Notification.updated`, etc.) to decide whether to commit to playing.
- Moving between `EventTeam` records is an update to `EventParticipant` (not a separate domain object). Switching to a countable team emits `joined`; leaving a countable team emits `left`.
- `Event#participants_count` — players on **countable** teams only (displayed as available slots vs `number_of_participants`).
- `Event#registrations_count` — every `EventParticipant`, including bench (not shown in the slots UI).
- Domain logic (`participants_count`, `joined` / `left` `Notification`, capacity) keys off **`slot`** (countable teams = `team_one` and `team_two`), never off `label`.
- `EventTeam.countable_teams` scope / `#countable?` — `team_one` and `team_two` only; bench is excluded.

### Rename (`EventTeamsController#edit` / `#update`)

- Any `User` with an `EventParticipant` on the `Event` may update **`label`** on `team_one` or `team_two` only.
- Custom labels allowed (e.g. `Barcelone`, `Équipe des nuls`, `Real Madrid`). Labels are trimmed; repeated spaces collapse to one; no leading or trailing spaces.
- `bench` — `label` stays `Sur le Banc`; not renameable.
- Renaming does **not** change `slot`, headcount, or emit `Notification` records (rename is cosmetic only).

---

## Visibility and access

### Public `Event` (`is_private: false`)

- Listed for any authenticated `User` in `Event.visible_to` / `Event.upcoming`.
- Any authenticated `User` who can see the `Event` may create an `EventParticipant`.

### Private `Event` (`is_private: true`)

A private `Event` is visible and joinable for:

- `event.user`
- `User` records with **accepted** `Friendship` to `event.user`
- `User` records with an `EventParticipant` on the `Event` (including `Sur le Banc`)
- `User` records with `Notification.invited` for this `Event`

All other `User` records cannot view or join.

### Listing (`Event.visible_to`)

An `Event` appears in browse/index when the `User` is authenticated and any of:

- `is_private: false`
- `user_id` = current `User`
- current `User` has an `EventParticipant`
- current `User` has `Notification.invited`
- current `User` has accepted `Friendship` with `event.user`

### View / join (`Event#viewable_by?` / `Event#joinable_by?`)

Same rules as private access above; for public `Event` records, any authenticated `User` passes.

---

## EventParticipant

### Join

- `User` must pass `event.joinable_by?(user)`.
- One `EventParticipant` per `User` per `Event`.
- `User` selects an `EventTeam` (`event_team_id`) by `slot`: `team_one`, `team_two`, or `bench`.
- Joining `team_one` or `team_two` emits `joined` `Notification` records for other countable-squad `User` records. Joining `bench` does not.
- **Capacity:** `number_of_participants` caps the total on **countable** teams (`participants_count`). When full, new joins to countable teams are rejected; **bench** remains available.
- **Per-team cap:** `Event#countable_slots_for(team)` — `team_one` gets `number_of_participants / 2` (floor), `team_two` gets `(number_of_participants + 1) / 2` (ceil). Example: capacity `11` → `5` + `6`. `EventTeam#full?` when at cap; join button hidden when `!joinable?` (`bench` is always joinable).

### Participation notifications (Z1)

Emit `joined` / `left` only for these transitions:

| Transition | Notification |
|------------|--------------|
| Join event on `team_one` or `team_two` | `joined` |
| Leave event from `team_one` or `team_two` | `left` |
| `bench` → countable team | `joined` |
| countable team → `bench` | `left` |
| countable ↔ countable (switch teams) | **none** |
| Rename `label` | **none** |

### Leave

- `User` destroys their own `EventParticipant`.
- Leaving `team_one` or `team_two` emits `left` `Notification` records. Leaving `bench` does not.
- After leave, if `event.viewable_by?(user)` is false, redirect away from the `Event` page.

---

## Invitations

### Who can invite
- Any `User` with an `EventParticipant` on the `Event` may invite (`Event#can_invite?` ⇔ `Event#in_this_event?`).
- Includes `event.user` and `User` records who joined — including `User` records **not** connected to `event.user` by accepted `Friendship`.

### Whom they can invite
- `User` records returned by `get_my_friends_but_not_participants(event)` (accepted `Friendship`, no `EventParticipant` yet).

### Effect
- Creates one `Notification` per invited `User` (`kind: invited`, `notifiable: event`).
- Invited `User` records can view and join a private `Event` even without accepted `Friendship` with `event.user`.

---

## Notification

### Purpose

`Notification` records are the **single source of truth** for user alerts. The web app implements the full inbox first so iOS and Android can mirror the same `kind`, `notifiable`, and `payload` as **push notifications** later.

Web today: list (`NotificationsController#index`), mark read (`#read`), navigate via `target_url`.  
Mobile later: same records exposed via JSON API → APNs / FCM.

### MVP triggers

**Every `Notification` kind below is in scope for web inbox and future push (iOS / Android).**

A `User` receives a `Notification` when:

| Trigger | `kind` | `notifiable` | Recipient |
|---------|--------|--------------|-----------|
| Pending `Friendship` request | `friendship_requested` *(target)* | `Friendship` | `receiver` |
| Invited to an `Event` | `invited` | `Event` | invited `User` |
| Joins `EventTeam` `team_one` or `team_two` | `joined` | `Event` | other `User` records on official squads |
| Leaves `EventTeam` `team_one` or `team_two` | `left` | `Event` | other `User` records on official squads |
| Tracked `Event` field changes | `updated` | `Event` | each `EventParticipant` `User` except `event.user` |
| `Event` destroyed | `canceled` | `nil` | each `EventParticipant` `User` except `event.user` |

Participation includes `bench` for `updated` and `canceled`. `joined` / `left` apply only to `team_one` and `team_two`, not `bench`.

### `invited`

- Created by `Events::InvitationsController#create` (one per invited `User`).
- `payload` includes `Event` context (`title`, `start_time`, sender name).
- Grants access to private `Event` records (see Visibility).

### `updated`

- Created by `Event#notify_update` when tracked fields change: `title`, `start_time`, `price`, `number_of_participants`.
- One `Notification` **per changed field** per participating `User` (excluding `event.user`).
- Untracked `Event` attributes do **not** trigger `updated`.

### `canceled`

- Created by `Event#notify_cancellation` on destroy.
- Deletes existing `Notification` records linked to the `Event` (`notifiable` = `Event`).
- `notifiable: nil` — not clickable; `payload` retains match context.

### `friendship_requested` *(target MVP)*

- Created when a `Friendship` is created with `status: pending`.
- `notifiable` = `Friendship`; recipient = `receiver`.
- `payload` includes sender identity (`first_name`, etc.).

> **Gap:** No `Notification` on `Friendship` create today — only `Friendship` record + UI on profile.

### `joined`

- Created when a `User` creates an `EventParticipant` on `EventTeam` with `slot` `team_one` or `team_two`.
- Not created for `bench`, or for `event.user`'s auto-registration on `Event` create.
- Recipients: other `User` records on official squads (`team_one`, `team_two`).
- `payload` includes `Event` title, `start_time`, joining player's `first_name`.

### `left`

- Created when a `User` destroys an `EventParticipant` on `slot` `team_one` or `team_two`.
- Not created for `bench`.
- Recipients: remaining `User` records on official squads.

### Unused enum values

- `created`, `reminder` — reserved; no MVP behavior. Remove or implement explicitly later.

### Read state & navigation

- `Notification#mark_as_read!` sets `read: true`.
- `clickable?` when `notifiable` is present → `target_url` (e.g. `/events/:id`, `/friendships`).
- `canceled` and some edge cases use `notifiable: nil` → fallback to notifications list.

---

## Admin

An **admin** is a `User` with `role: admin`. Admins use the same app as players — they can create `Event` records, join matches, send `Friendship` requests, and receive `Notification` records like any other `User`.

### MVP: full CRUD

An admin can **create, read, update, and destroy** any MVP record, bypassing normal ownership rules:

| Model | Admin access |
|-------|----------------|
| `User` | Full CRUD |
| `Event` | Full CRUD (any `event.user`) |
| `EventTeam` | Full CRUD (including `slot` and `label`) |
| `EventParticipant` | Full CRUD |
| `Friendship` | Full CRUD |
| `Notification` | Full CRUD |

No guardrails: an admin may edit or delete data that breaks realistic state (wrong counts, orphaned links, inconsistent notifications). That is **intentional** for testing, debugging, and support.

Player rules still apply when an admin acts **as a player** (e.g. only `event.user` updates their own `Event` unless using admin tools).

### Web UI (target)

- Admin-only routes / controllers (namespace or `before_action` on `current_user.role`).
- Entry point: link visible only when `current_user.admin?` (or `role == "admin"`).
- MVP: CRUD screens for all models above.

### Later (not MVP)

- **Dashboard** — extra admin link with aggregate stats (user counts, event counts, etc.). Document when scoped; not required for first admin CRUD pass.

> **Gap:** `role: admin` exists on `User` but admin authorization and CRUD UI are **not implemented** yet.

---

## Authorization summary

Normal `User` (`role: player`) rules:

| Action | `User` |
|--------|--------|
| Create `Event` | Any authenticated `User` |
| Update / destroy `Event` | `event.user` only |
| View `Event` | Per visibility rules above |
| Create `Notification` (invite) | Any `User` with `EventParticipant` on the `Event` |
| Create / destroy `EventParticipant` | Per join rules above |
| Update `EventTeam` `label` (countable teams) | Any `User` with `EventParticipant` on the `Event` |

**Admin override:** a `User` with `role: admin` may CRUD any MVP record via admin tools, regardless of the rules above. See Admin.

---

## Build order

1. **Web** — full MVP behavior for all models above.
2. **JSON API** — same behavior for iOS/Android repos once web flows are reliable.

Out of scope: payments, chat, rankings, Google OAuth. See [PROJECT.md](PROJECT.md).

---

## TDD workflow

See [TESTING.md](TESTING.md) — feature workflow is: clarify → domain → migrations (if approved) → failing model specs → implementation.

---

## Questions before coding

- Public or private `Event`?
- Which `User` records should see, join, or invite?
- Which `EventTeam` and `EventParticipant` records change?
- Which `Notification` records are created or removed?
- Admin-only or schema change needed?

---

## Known gaps (code → domain)

| Rule | Status |
|------|--------|
| Private `Event` in `Event.visible_to` for `event.user`'s accepted `Friendship` friends | **Implemented** |
| Private `Event` in `Event#viewable_by?` for `event.user`'s accepted `Friendship` friends | **Implemented** |
| `Event.private_visible_to(user)` (author + accepted friends only) | **Implemented** |
| `number_of_participants` enforced on join (`countable_teams` only; bench when full) | **Implemented** |
| Odd capacity split (`floor` / `ceil` via `countable_slots_for`) | **Implemented** — `11` → `5` + `6` |
| `EventTeamsController#edit` / `#update` (rename countable `EventTeam` `label`) | **Implemented** — participants only; bench blocked |
| `EventTeam` `slot` + `label` columns | **Implemented** |
| `EventParticipant` `joined` / `left` keyed on `slot` via `countable_teams` | **Implemented** |
| `Event` validation messages | **Implemented** — I18n (`config/locales/<locale>/event.yml`) |
| `Event` create/update strong params include `latitude` / `longitude` | **Implemented** |
| `Notification` on pending `Friendship` (`friendship_requested`) | **Not implemented** — `kind` not in enum yet |
| Push delivery (APNs / FCM) | **Not implemented** — web inbox + JSON API first |
| `reminder` / `created` `Notification` kinds | Enum defined; **no behavior** |
| Admin CRUD + admin UI | **Not implemented** — `role: admin` column only |
| Admin stats dashboard | **Later** — out of MVP admin CRUD pass |
| JSON API | **Not implemented** |
| `User.status` column | **To remove** — no domain rule |
| Google OAuth remnants | **To remove** — email auth only |
| `Friendship#decline` / `status: declined` | Model supports it; web flow destroys on refuse instead |
