# Instructions for AI coding agents

Read this file before changing anything in this project.

## Protect existing work

- Inspect `git status` and the relevant files before editing.
- Preserve all existing user changes. Do not discard, reset, or reformat unrelated files.
- Make the smallest change that satisfies the request. Do not reorganize core files unless explicitly requested.
- Keep each `.gd.uid` beside its matching `.gd` file. Godot uses these IDs for stable resource references; do not delete or regenerate them as cleanup.
- Do not commit or push unless explicitly asked.

## Project layout and ownership

- `scripts/maps/campus_*.gd` is the original campus map implementation: campus data, setup/update, scenery, structures, and rendering. Its inheritance chain is intentional; check `extends` before changing or moving any part.
- `scripts/maps/` also contains map-specific modules such as `b42_lab.gd` and their registry.
- `scripts/features/` contains reusable gameplay systems, such as fishing, doors, quiz, HUD, and named-character behavior. A reusable system that happens to interact with the map still belongs here; put only location-specific content and behavior in `scripts/maps/`.
- `scripts/core/game_state.gd` holds shared runtime state. `scripts/draw/pen.gd` and `scripts/draw/characters.gd` provide reusable drawing helpers.
- `main.gd` is the composition/orchestration layer. Avoid putting map content or feature-specific behavior there.
- `scripts/draw/newcharacters.gd` is a compatibility layer in the inheritance chain. Named NPCs are implemented by `scripts/features/newcharacters.gd`; do not restore a second NPC implementation in the draw layer.

## Registry rules

There are two separate registries. Choose exactly one for each new module:

- Reusable gameplay feature: add its `.gd` path to `scripts/features/registry.gd`.
- Map-specific building or area module: add its `.gd` path to `scripts/maps/registry.gd`.

For either registry:

1. Keep the existing `res://` path format and use the exact case and filename on disk.
2. Add one entry at the end of the array, before its closing `]`. Do not replace, reorder, or reformat existing entries.
3. Check that the same path is not already registered.
4. Keep modules independent where possible. If initialization order is required, document the dependency and place the dependent module after its prerequisite.
5. On a merge conflict, preserve both distinct valid entries and remove only Git's conflict markers. Do not resolve a conflict by dropping another module.

Map modules are loaded before the original campus collision, NPC, and decoration setup. A map module that adds a normal building should register it in `game.BUILDINGS` during `_ready()` so the campus setup can derive collision and map display from that data. Add separate collision only for geometry not represented in shared map data. Reusable building-entry behavior belongs in the features registry, not once per building.

## Validation

- Search for stale `res://` paths after moving or renaming scripts; move the matching `.gd.uid` with its script.
- Check that GDScript contains no accidental merge markers and that `git diff --check` passes.
- When Godot is available, run an editor scan and a short headless project launch. Fix errors caused by the change; report unrelated existing errors separately.
- Update the relevant Vietnamese README or guide when workflows or folder ownership change.
