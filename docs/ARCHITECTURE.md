# FlipFlapp Architecture

FlipFlapp is a Rails 8 application for organizing sports games with friends.

## Product Domain

The core domain includes:

- users and authentication
- events or games
- teams
- participants
- friendships
- notifications
- user profile data

When implementing a feature, identify which domain rule is changing before editing code. If the rule is not explicit, ask for examples and edge cases first.

## Architecture Principles

- Rails MVC is the default architecture.
- Models own domain behavior, validations, callbacks, and data side effects.
- Controllers coordinate requests with strong parameters and explicit authorization.
- Views render Rails-native ERB and Tailwind CSS.
- Hotwire and Stimulus are optional enhancement tools, not the default starting point.
- Avoid introducing service objects, form objects, presenters, decorators, or other layers unless explicitly requested.

## Domain Questions To Ask

Use these questions before implementing ambiguous features:

- Who is allowed to perform the action?
- Which records should be created, updated, or destroyed?
- Which validations must prevent invalid state?
- Should the behavior trigger notifications?
- Should friendships affect visibility or permissions?
- What happens when an event is full, cancelled, deleted, or edited?
- What happens when a user is unconfirmed, removed, or no longer friends with another user?
- Does the feature require a database change, or can it use the existing schema?

## Sensitive Areas

Treat these areas carefully and use tests to lock behavior:

- Devise authentication and confirmation
- friendship rules
- event participation rules
- team composition rules
- notification creation and cleanup
- file uploads and Cloudinary integration
- production deployment configuration
