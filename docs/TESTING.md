# Locust — Godot 3 Testing Checklist

Locust targets Godot 3.x only. Final runtime validation must be performed in a real Godot 3 editor.

## Plugin loading
- Copy `addons/locust` into a clean Godot 3 project.
- Enable Locust under Project > Project Settings > Plugins.
- Confirm the dock appears with no parser errors.

## Repository connection
- Enter owner, repository, branch, and a GitHub token.
- Click CHECK REPOSITORY and confirm success.
- Click CLEAR TOKEN and confirm the token is removed.
- Restart the editor and confirm the token is not restored from config.

## Initial sync
Use a disposable repository.
- Local-only file → uploaded.
- Remote-only file → downloaded.
- Matching file → unchanged.
- Snapshot is saved under `.locust/`.
- A recovery backup exists before local files are changed.

## Normal sync
Test local edits, remote edits, local deletion, and remote deletion. Run Sync again and confirm `Project is up to date`.

## Conflicts
1. Start synchronized.
2. Edit the same file locally and remotely in different ways.
3. Sync and confirm the conflict is listed.
4. Test KEEP MINE.
5. Repeat and test USE GITHUB.

## Safety
- Paths containing `../` must be rejected.
- Absolute paths must be rejected.
- `.godot`, `.import`, `.locust`, temporary files and logs must be ignored.
- Malformed GitHub data must fail without modifying local files.
- A truncated GitHub tree must stop the sync instead of causing false deletions.

## Large assets
Use CHECK ASSETS with a multi-megabyte asset. Confirm Locust reports large files and recommends Git LFS where appropriate. Do not use the GitHub Contents API as a replacement for Git LFS for a production asset pipeline.

## Error cases
Test invalid repository, invalid/expired token, wrong branch, offline connection, and a repository without write access. Locust should show a readable error and stop the current sync queue.

## Release gate
- No Godot 3 parser errors.
- Plugin enables/disables cleanly.
- Initial sync works both directions.
- Conflict resolution works both directions.
- Recovery backup works.
- Token is not persisted.
- Path traversal tests pass.
- No Godot 4-only APIs are introduced.
