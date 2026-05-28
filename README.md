# Marine-Link-App

MarineLink is a Flutter Android MVP for B2B seafood ordering. The current repository surface is documentation-first: the main specification, frontend architecture, backend architecture, Supabase database design, and sprint plan live in `docs/`.

## Documentation Map

Read these files in order:

1. `docs/MarineLink_Main_Functions_Specification_v2.docx` - product scope and main user flows.
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

## Security Notes

- Do not commit Supabase keys, JWT secrets, API keys, database passwords, or demo plaintext passwords.
- Flutter must not call protected Supabase tables directly in the MVP; authorization is enforced through Spring Boot services.
- Demo users should be seeded with password hashes only.
