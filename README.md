# Locust

Locust is a free and open-source **Godot 3** editor plugin that makes GitHub collaboration feel like part of the Godot editor instead of a terminal workflow.

## What is included

- Godot 3 editor plugin and dock UI
- GitHub repository connection and branch selection
- In-editor GitHub token entry (kept in memory)
- Project scanning with configurable ignore rules
- Git-compatible file snapshots for three-way change detection
- One-click synchronization through GitHub's API
- Upload, download, local deletion and remote deletion handling
- Automatic conflict detection
- In-editor conflict choice: **Keep Mine** or **Use GitHub**
- Automatic local recovery backup before a modifying sync
- Persistent local activity history
- Large-asset inspection and Git LFS guidance
- Optional local Git command integration for environments that already have Git installed
- Demo Godot 3 project
- Architecture and security documentation

## How synchronization works

Locust compares three states:

1. **Local** — the files currently on disk.
2. **Base** — the last Locust snapshot.
3. **Remote** — the selected GitHub branch.

If only one side changed, Locust synchronizes automatically. If both sides changed the same path differently, Locust stops and asks the developer to choose which version should win.

Before a modifying synchronization, Locust creates a local recovery backup under `.locust/backups/`.

## Installation

1. Copy `addons/locust` into a Godot 3 project.
2. Open **Project > Project Settings > Plugins**.
3. Enable **Locust**.
4. Enter the GitHub owner, repository, branch and an appropriate GitHub access token.
5. Select **CHECK REPOSITORY**, then **SYNC PROJECT**.

The `demo/` folder contains a minimal Godot 3 project for trying the plugin.

## Security

Locust does not save the GitHub access token in `.locust/config.json`. The token is kept in memory for the current editor session. Use the minimum GitHub permissions required for the repositories you manage.

Local Locust state and recovery files are ignored by the repository's `.gitignore`.

## Large assets

GitHub's Contents API is intended for normal repository files, not as a replacement for Git LFS. Locust detects large files and warns when LFS is appropriate. See `docs/ARCHITECTURE.md` for the current architecture and `docs/SECURITY.md` for security notes.

## Compatibility

**Godot 3.x only.** Godot 4 is intentionally not supported by this project.

## Project status

This is an early open-source release. The architecture and core workflows are implemented, but the final validation must be performed inside a real Godot 3 installation across different project types and GitHub repository configurations.

## License

MIT License. See `LICENSE`.
