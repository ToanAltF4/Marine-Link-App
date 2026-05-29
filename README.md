# Marine-Link-App

MarineLink is a Flutter Android MVP for B2B seafood ordering. The current repository surface is documentation-first: the main specification, frontend architecture, backend architecture, Supabase database design, and sprint plan live in `docs/`.

## Documentation Map

Read these files in order:

1. `docs/MarineLink_Main_Functions_Specification_v3.docx` - product scope and main user flows.
2. `docs/MarineLink_API_Documentation.md` - REST API contract, request/response examples, roles, errors, and API-to-table mapping.
3. `docs/MarineLink_FE_Architecture.md` - Flutter architecture, state management, API integration, and test strategy.
4. `docs/MarineLink_BE_Architecture.md` - Spring Boot REST API architecture, authorization, business rules, and backend test strategy.
5. `docs/MarineLink_Supabase_DB_Design.md` - Supabase/PostgreSQL schema, storage, RLS notes, migration plan, and API-to-table mapping.
6. `docs/MarineLink_Sprint_Planning.md` - sprint breakdown, capacity assumptions, risks, and Definition of Done.

## MVP Stack

- Frontend: Flutter Android with BLoC/Cubit.
- Backend: Spring Boot REST API with JWT Bearer authentication.
- Database: Supabase PostgreSQL accessed through the backend in the MVP.
- Storage: Supabase Storage for product images, avatars, and chat attachments when file upload is needed.

## Target Code Structure

Use one monorepo for the MVP so FE, BE, API contract, and DB docs stay in sync:

```text
Marine-Link-App/
  frontend/                 # Flutter Android app
    pubspec.yaml
    lib/
    test/
    integration_test/
    android/
  backend/                  # Spring Boot REST API
    pom.xml
    src/main/java/com/marinelink/
    src/main/resources/
    src/test/java/com/marinelink/
  docs/                     # Product, API, architecture, DB, sprint docs
  icon/                     # Brand and app icons
```

Frontend code must live under `frontend/`; backend code must live under `backend/`. Shared behavior is documented through `docs/MarineLink_API_Documentation.md`, not duplicated as ad hoc constants in both stacks.

## Code Requirements

- Flutter implements feature-first modules, BLoC/Cubit state, repository interfaces, mock repositories first, then remote repositories against Spring Boot.
- Spring Boot implements controllers, services, repositories, DTOs, validation, JWT security, and contract tests matching the API documentation.
- The root repo should keep generated build outputs ignored; commit source, tests, docs, migrations, and seed scripts only.
- Before demo or PR, run Flutter tests from `frontend/` and backend verification from `backend/`.

## Security Notes

- Do not commit Supabase keys, JWT secrets, API keys, database passwords, or demo plaintext passwords.
- Flutter must not call protected Supabase tables directly in the MVP; authorization is enforced through Spring Boot services.
- Demo users should be seeded with password hashes only.
