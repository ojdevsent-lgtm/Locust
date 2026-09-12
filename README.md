# Locust

Locust is a free and open-source Godot 3 editor plugin that makes GitHub collaboration feel like part of the Godot editor instead of a terminal workflow.

## Current build

Locust currently includes:

- Godot 3 editor plugin integration
- GitHub repository connection
- In-editor GitHub token entry (kept in memory)
- Project file scanning and ignore rules
- Git-compatible file snapshots
- One-click synchronization
- Upload and download of project files through GitHub
- Remote deletion and local deletion handling
- Automatic conflict detection
- Automatic recovery backup before synchronization
- Local activity history
- Project configuration stored under `.locust`

## Roadmap

- Guided conflict resolution UI
- GitHub commit/history browser
- Team activity and contributor information
- Large-asset/LFS-aware workflows
- Milestones and named restore points
- Better first-time repository setup
- Godot Asset Library release

## Compatibility

**Godot 3.x only.** Godot 4 is intentionally not supported.

## Installation

Copy `addons/locust` into a Godot 3 project and enable **Locust** under **Project > Project Settings > Plugins**.

## GitHub access

Locust communicates with GitHub through its REST API. A GitHub access token is required for repository writes and private repositories. The current editor UI keeps the token in memory rather than writing it to the project configuration.

Never commit a personal access token to a project or Git repository.

## Sync model

Locust tracks a local snapshot of the last synchronized project state. During synchronization it compares:

1. The local project
2. The last Locust snapshot
3. The GitHub branch

When both local and remote sides changed the same file since the last synchronized state, Locust reports a conflict instead of silently overwriting work.

## Development

Locust is free/open-source and intentionally lightweight. The goal is to hide Git complexity behind a focused Godot editor workflow while retaining GitHub as the collaboration backend.

## License

MIT License. See `LICENSE`.
