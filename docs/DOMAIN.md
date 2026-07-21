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
| `Invitation` | Pending invite of a `User` to an `Event`; grants private access until the invitee joins |
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
- Also: own `Event` records, `Event` records where they are `EventParticipant`, and `Event` records where they have an `Invitation`.

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

---

## Friendship

A `Friendship` connects two `User` records (`sender`, `receiver`). It is required for two MVP behaviors:

1. **See** private `Event` records from accepted friends who are `event.user` (see Visibility).
2. **Invite** accepted friends to an `Event` via `Invitation` + `Notification.invited` (see Invitations).

### Entry points

An authenticated `User` can send a `Friendship` request from:

- **Player search** — `FriendshipsController#search` (Ransack on `first_name`, `last_name`, `username`; scope `User.users_without_friendship`).
- **Player profile** — `GET /users/:id` with “add friend” → `FriendshipsController#create`.

Both paths create the same `Friendship` record (`sender` = current `User`, `receiver` = target `User`, `status: pending`).

### Lifecycle

| Action | Who | Result |
|--------|-----|--------|
| Send request | `sender` | `Friendship` with `status: pending`; **`friendship_requested` `Notification` to `receiver`** (hidden from inbox — see Notification) |
| Accept | `receiver` (pending only) | `status` → `accepted` |
| Decline | `receiver` (pending only) | `status` → `declined`; `friendship_requested` `Notification` removed |
| Cancel request | `sender` (pending) | `Friendship` destroyed |
| Unfriend | `sender` or `receiver` (accepted) | `Friendship` destroyed |
| Remove declined | `receiver` (declined only) | `Friendship` destroyed — either party may then send a new request |

`accept` and `decline` only apply from `pending`. A `declined` `Friendship` cannot become `accepted` without destroy + a new request.

### States

- **pending** — request sent; `receiver` can accept or decline.
- **accepted** — friends; enables private `Event` visibility and `Event` invitations.
- **declined** — soft reject. Visible **only to the `receiver`**. The `sender` sees no declined UI (soft-ghosted: pending sent disappears). Blocks search and reverse requests until the `receiver` removes it.

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
- `declined_received_friendships` — declined `Friendship` records where the `User` is `receiver`.
- `get_my_friends_but_not_participants(event)` — accepted friends who are not `EventParticipant` and have no `Invitation` for the `Event` (invite picker).

### Index

`FriendshipsController#index` lists accepted friends, pending sent requests, pending received requests, and **declined received** requests (receiver only) for the current `User`.

### Profile (`users#show`)

- **Declined, current `User` is `receiver`:** label that they declined the request + action to remove the declined `Friendship`.
- **Declined, current `User` is `sender`:** no friendship CTA (nothing shown).

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
| `latitude`, `longitude` | Required (set via Places autocomplete on web; needed for the future JSON API / map features). Model presence validation still missing — form HTML `required` only today |

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
- `User` records with an `Invitation` for this `Event`

All other `User` records cannot view or join.

### Listing (`Event.visible_to`)

An `Event` appears in browse/index when the `User` is authenticated and any of:

- `is_private: false`
- `user_id` = current `User`
- current `User` has an `EventParticipant`
- current `User` has an `Invitation`
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
- Leaving `team_one` or `team_two` (or moving countable → bench) emits `left` for other countable-squad **and bench** `User` records (excluding the actor). `joined` recipients stay countable-only.
- Creating an `EventParticipant` **destroys** that `User`'s `Invitation` for the `Event` (if any). The inbox `Notification.invited` is kept (history).
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
- Leaving `team_one` or `team_two` emits `left` `Notification` records for remaining countable **and bench** participants. Leaving `bench` does not.
- After leave, if `event.viewable_by?(user)` is false, redirect away from the `Event` page.

---

## Invitation

Source of truth for a pending invite to an `Event`. No accept / decline / status — the row **exists** until the invited `User` joins (then it is destroyed) or the `Event` is destroyed.

### Attributes

| Attribute | Rules |
|-----------|--------|
| `event` | Required; `belongs_to :event` |
| `user` | Required; invited `User` |
| Uniqueness | One `Invitation` per (`event_id`, `user_id`) |

### Who can invite
- Any `User` with an `EventParticipant` on the `Event` may invite (`Event#can_invite?` ⇔ `Event#in_this_event?`).
- Includes `event.user` and `User` records who joined — including `User` records **not** connected to `event.user` by accepted `Friendship`.

### Whom they can invite
- `User` records returned by `get_my_friends_but_not_participants(event)`: accepted `Friendship`, no `EventParticipant`, and no existing `Invitation` for that `Event`.

### Effect (`Event#invite!`)
- Creates one `Invitation` per invited `User`.
- Creates one `Notification` per invited `User` (`kind: invited`, `notifiable: event`; `payload.sender` = inviter `first_name`).
- Duplicate invite for the same `user` + `Event` is rejected (uniqueness).
- Invited `User` records can view and join a private `Event` even without accepted `Friendship` with `event.user` (`Event#invited?` ⇔ `Invitation` exists for that `user`).

### Lifecycle
- **No** decline / cancel / expire actions in MVP.
- Destroyed when the invited `User` creates an `EventParticipant` on that `Event`.
- Destroyed when the `Event` is destroyed (`dependent: :destroy`).
- Inbox `Notification.invited` is **not** destroyed on join (history kept); click navigates to the `Event` via `notifiable: event`.

### UI
- Event show lists pending invited `User` records **below the bench**.
- Invite dialog: submit disabled until at least one friend is selected.

### HTTP (`Events::InvitationsController#create`)
- Empty selection (`user_ids` blank) must not succeed — UI blocks submit; controller rejects with alert.
- No broad `rescue` around invite delivery.

---

## Notification

### Purpose

`Notification` records are the **single source of truth** for user alerts. The web app implements the full inbox first so iOS and Android can mirror the same `kind`, `notifiable`, and `payload` as **push notifications** later.

Web today: inbox (`NotificationsController`), mark read / mark all read / destroy, navigate via `target_url`, and a **live toast** (flash-like) for connected users via Turbo Streams + Solid Cable.  
Mobile later: same records exposed via JSON API → APNs / FCM (Solid Queue).

Producers live in per-model modules: `Event::Notifications`, `EventParticipant::Notifications`, `Friendship::Notifications`. Fan-out goes through `Notification::Delivery`, which **enqueues** Active Job work (`Notifications::DeliverOneJob` / `Notifications::DeliverManyJob`) on Solid Queue. Jobs persist the row(s) then broadcast the toast + unread badge refresh to the recipient’s stream.

`Invitation` rows stay synchronous inside `Event#invite!` (private access). Only the companion `Notification` is jobified. Friendship notification cleanup (destroy on accept/decline/unfriend) stays synchronous. `DeliverOneJob` skips `friendship_requested` if the `Friendship` is no longer `pending` (accept/decline raced the job).

### MVP triggers

A `User` receives a `Notification` when:

| Trigger | `kind` | `notifiable` | Recipient | Inbox |
|---------|--------|--------------|-----------|-------|
| Pending `Friendship` request | `friendship_requested` | `Friendship` | `receiver` | **Hidden** — UX is the friends badge (`pending_received_friendships`) |
| Invited to an `Event` | `invited` | `Event` | invited `User` | Shown |
| Joins `EventTeam` `team_one` or `team_two` | `joined` | `Event` | other `User` records on official squads | Shown |
| Leaves `EventTeam` `team_one` or `team_two` | `left` | `Event` | other countable **and bench** `User` records | Shown |
| Tracked `Event` field changes | `updated` | `Event` | each `EventParticipant` `User` except `event.user` | Shown |
| `Event` destroyed | `canceled` | `nil` | each `EventParticipant` `User` except `event.user` | Shown |
| ~24h before `start_time` with open countable spots | `reminder` | `Event` | current bench `User` records | Shown |

Participation includes `bench` for `updated`, `canceled`, and as **recipients** of `left` / `reminder`. Emitting `joined` / `left` still keys off countable-team transitions only (not joining/leaving the bench itself).

`Notification.inbox` excludes `friendship_requested`. Header unread badge uses `notifications.inbox.unread`.

### `invited`

- Created by `Event#invite!(users:, sender:)` alongside each `Invitation` (one per invited `User`).
- `payload` includes `Event` context (`title`, `start_time`, sender name).
- `notifiable` is the `Event` so inbox click opens the `Event`.
- Private access is granted by the `Invitation` row, not by this `Notification` (see Visibility / Invitation).

### `updated`

- Created by `Event#notify_update` when tracked fields change: `title`, `start_time`, `price`, `number_of_participants`.
- One `Notification` **per changed field** per participating `User` (excluding `event.user`).
- Untracked `Event` attributes do **not** trigger `updated`.

### `canceled`

- Created by `Event#notify_cancellation` on destroy.
- Deletes existing `Notification` records linked to the `Event` (`notifiable` = `Event`).
- `notifiable: nil` — not clickable; `payload` retains match context.

### `friendship_requested`

- Created when a `Friendship` is created with `status: pending`.
- `notifiable` = `Friendship`; recipient = `receiver`.
- `payload` includes sender identity (`first_name`, etc.).
- **Not shown** in the notifications inbox or unread badge. Players act on requests via `/friendships` (red badge on friends link).
- Destroyed when the `Friendship` is accepted, declined, or destroyed (cancel / unfriend / remove declined).

### `joined`

- Created when a `User` creates an `EventParticipant` on `EventTeam` with `slot` `team_one` or `team_two`.
- Not created for `bench`, or for `event.user`'s auto-registration on `Event` create.
- Recipients: other `User` records on official squads (`team_one`, `team_two`).
- `payload` includes `Event` title, `start_time`, joining player's `first_name`.

### `left`

- Created when a `User` destroys an `EventParticipant` on `slot` `team_one` or `team_two`, or moves countable → bench.
- Not created when leaving the bench itself.
- Recipients: remaining `User` records on official squads **and** the bench (excluding the actor). This is how bench players learn a countable spot opened after a silent T−24h reminder — not a second `reminder`.

### `reminder`

- Scheduled by `Event` on create and whenever `start_time` changes: `Events::BenchReminderJob` at `max(start_time - 24.hours, Time.current)`.
- `events.bench_reminder_job_id` stores the Active Job id; previous job is **discarded** on reschedule and on `Event` destroy.
- At perform time: no-op if event missing, `start_time` ≠ enqueued expectation, `spots_remaining == 0`, or bench empty; otherwise `deliver_many!` to current bench users.
- Idempotent per `(event, start_time)` — a reminder already sent for that start does not send again; a **new** `start_time` schedules a new cycle even if an older reminder exists.
- `payload`: `title`, `author` (`event.user.first_name`), `start_time`, `spots_remaining`.
- Not a retry when spots open after a silent T−24h run (`left` covers that). Users who join the bench after the fire do not get a late reminder.

### Reserved enum values

- `created` — **removed** (unused).

### Read state & navigation

- `Notification#mark_as_read!` sets `read: true` (per row icon, body navigate, or live toast click).
- `Notification.mark_all_as_read_for!(user)` marks all inbox unread as read.
- `User` may destroy their own `Notification`.
- `clickable?` when `notifiable` is present → `target_url` (`Event` → `/events/:id`, `Friendship` → `/friendships`).
- `canceled` and some edge cases use `notifiable: nil` → fallback to notifications list; still markable as read / deletable.

### Live toast (connected web)

- After a job creates a `Notification`, Turbo Streams appends a top-of-screen toast (same visual language as flash) on that `User`'s Action Cable stream.
- Toast shows for inbox kinds and `friendship_requested`.
- Click marks the row read and navigates via `target_url` when clickable (same as inbox).
- Header unread badge (inbox only) refreshes over the same stream.

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

### Web UI

- Admin-only routes / controllers (`Admin::BaseController` + `require_admin!`).
- Entry point: link visible only when `current_user.admin?`.
- CRUD screens for all models above via `Admin::Resourceful`.

### Later (not MVP)

- **Dashboard stats** — aggregate counts (users, events, etc.). Document when scoped.

---

## Authorization summary

Normal `User` (`role: player`) rules:

| Action | `User` |
|--------|--------|
| Create `Event` | Any authenticated `User` |
| Update / destroy `Event` | `event.user` only |
| View `Event` | Per visibility rules above |
| Create `Invitation` (+ `Notification.invited`) | Any `User` with `EventParticipant` on the `Event` |
| Create / destroy `EventParticipant` | Per join rules above |
| Update `EventTeam` `label` (countable teams) | Any `User` with `EventParticipant` on the `Event` |

**Admin override:** a `User` with `role: admin` may CRUD any MVP record via admin tools, regardless of the rules above. See Admin.

---

## Build order

1. **Web** — full MVP behavior for all models above.
2. **JSON API** — `/api/v1` with Devise JWT; same domain rules for iOS/Android. See [API.md](API.md).

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
| `Event` `latitude` / `longitude` presence (model + I18n) | **Not implemented** — HTML `required` on form only; columns still nullable in schema |
| `Notification` on pending `Friendship` (`friendship_requested`) | **Implemented** — hidden from inbox; friends badge UX |
| Push delivery (APNs / FCM) | **Not implemented** — web inbox + live toast first; Solid Queue later for push |
| Solid Queue + Solid Cable | **Implemented** — notification jobs, Devise mail via Active Job, live toasts |
| `reminder` `Notification` kind | **Implemented** — Solid Queue delayed job; `events.bench_reminder_job_id` for discard |
| `left` recipients include bench | **Implemented** — countable leave / countable→bench |
| `created` `Notification` kind | **Removed** |
| Admin stats dashboard | **Later** — out of MVP admin CRUD pass |
| JSON API | **Implemented** — `/api/v1` (Devise JWT, Alba, OpenAPI/rswag). See [API.md](API.md) |
| Google OAuth remnants (`users.tokens`, deploy `GOOGLE_CLIENT_*`) | **Removed** — email auth only; `provider`/`uid` kept for future OAuth |
| `Friendship#decline` / `status: declined` | **Implemented** — receiver-only visibility; remove declined to allow re-request |
| `Invitation` table (pending invite; unique per event + user) | **Implemented** — access via `Invitation`; `Notification.invited` for inbox only |
