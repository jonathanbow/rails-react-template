# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> This repo is a **template**: it is a starting point that people build their own apps on top of. Treat this file as a starter and extend it (domain model, conventions, deploy details) as the app grows. Note the README says the code originates from the [inertia-rails/generator](https://github.com/inertia-rails/generator); if you are working in the template repo itself, upstream syncs may overwrite generated files.

## Stack

Rails (PostgreSQL) backend + React 19 / TypeScript frontend wired together with Inertia.js (`inertia_rails`) and Vite (`rails_vite`). UI is shadcn/ui (Radix + Tailwind 4) in `app/javascript/components/ui`. Authentication is hand-rolled (Authentication Zero style, cookie-backed `Session` model, no Devise). Deploys with Kamal (`config/deploy.yml`, `.kamal/`).

## Commands

- `bin/setup` – install gems/npm packages, prepare DB, then start the server (`--skip-server`, `--reset` available)
- `bin/dev` – run Rails (port 3000) and Vite together via `Procfile.dev`
- `bin/rspec` – run all specs; single file/example: `bin/rspec spec/models/user_spec.rb:12`
- `bin/rubocop` – Ruby lint (`-a` to autocorrect)
- `npm run lint` / `npm run lint:fix` – ESLint
- `npm run format` / `npm run format:fix` – Prettier
- `npm run check` – TypeScript type check
- `bin/ci` – full CI pipeline (`config/ci.rb`): rubocop, JS lint/format/types, generated-types freshness, bundler-audit, npm audit, brakeman, rspec, seed check

## Architecture

**Inertia flow.** There is no separate API or client-side router. Controllers inherit from `InertiaController` (`app/controllers/inertia_controller.rb`), which sets `default_render: true`, so an action with no explicit `render` renders the page component at `app/javascript/pages/<controller_path>/<action>.tsx` (e.g. `DashboardController#index` → `pages/dashboard/index.tsx`). Props are passed from controllers; shared props (`auth.user`, `auth.session`) are defined via `inertia_share` in `InertiaController`. Routes can also be declared with `inertia :appearance` (see `config/routes.rb`) for controller-less pages.

**Frontend entry.** `app/javascript/entrypoints/inertia.tsx` boots `createInertiaApp`, resolving pages from `app/javascript/pages` and wrapping all of them in `layouts/persistent-layout.tsx` (toaster + flash handling via `use-flash`). Per-area layouts live in `layouts/{app,auth,settings}`. Use the `@/` alias for `app/javascript/*`.

**Generated TypeScript (do not edit).** `typelizer` generates the files in `app/javascript/routes/` (typed route helpers per controller, e.g. `import { dashboard } from "@/routes"`) and types in `app/javascript/types`. These carry a "DO NOT MODIFY" header. After changing `config/routes.rb` or controllers/serializers, regenerate with `bin/rails typelizer:generate:refresh` and commit the result; CI fails if they are stale.

**Auth.** `ApplicationController` runs `authenticate` on every request (redirects to `sign_in_path`); public controllers skip it and use `require_no_authentication`. `Current` (`app/models/current.rb`) holds the per-request session/user, found via the signed `session_token` cookie. `Current.user_agent`/`ip_address` are recorded for the settings → sessions page. Email verification and password reset live under the `Identity::` namespace; user settings under `Settings::`.

**SSR.** `config/initializers/inertia_rails.rb` has `ssr_enabled`; the Puma plugin runs the Node SSR renderer in-process, and Inertia falls back to client rendering on failure. Production images need `--build-arg SSR_ENABLED=true` (see README).

## Testing

RSpec with FactoryBot, shoulda-matchers, and SimpleCov (specs in `spec/{models,requests,mailers}`, factories in `spec/factories`). There are no system tests. `spec/factories_spec.rb` validates the factories.
