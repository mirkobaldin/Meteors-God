# Meteor Gods — notes for Claude

Roblox game managed with Rojo (`default.project.json`). Luau, no external packages.

- Design doc (Italian): `docs/GDD.md`. Keep it in sync when changing mechanics or numbers.
- All tuning lives in `src/shared/Config/*`. Prefer adding content as config entries over new code.
- Server: `src/server/Main.server.lua` requires every module in `Services/` (in ORDER), calls `Init(services)` then `Start()`.
  Services talk to each other through the `services` table, never by requiring each other directly.
- Client: `src/client/Main.client.lua` does the same with `Controllers/`. UI is built from code via `Controllers/UI.lua`.
- Networking: every remote is declared in `src/shared/Remotes.lua`. The server is authoritative for currencies,
  meteors, damage and trades; validate every client argument and rate-limit handlers (`src/server/RateLimit.lua`).
- Player data: `DataService` (session-locked UpdateAsync). Add new fields to `defaultData()`; `reconcile` fills them in.
- Visuals are generated (parts, Fire, particles, BillboardGui faces). Don't add asset IDs without a config entry.
- Player-facing text is English (docs for the owner are in Italian).
- No Studio in the cloud container: code can't be run here. Keep changes small and reviewable, and ask the user
  for Studio Output errors after they test.
