# Locust

Locust is a free and open-source Godot 3 editor plugin designed to make GitHub collaboration simple for game developers.

## Status

Early development. The repository contains the Godot 3 plugin foundation and editor UI. GitHub synchronization, conflict handling, asset workflows, history and recovery are being built incrementally.

## Goals

- One-click project synchronization
- Visual project change status
- GitHub repository connection
- Conflict detection and guided resolution
- Team activity information
- Asset-aware workflows
- Project history and recovery
- No terminal required for normal workflows

## Compatibility

**Godot 3.x only.** Godot 4 is intentionally not supported by this project.

## Installation

Copy the `addons/locust` directory into your Godot 3 project and enable **Locust** under **Project > Project Settings > Plugins**.

## Development

Locust is being developed as a free/open-source project. The architecture favors a small dependency footprint and works toward keeping Git complexity behind a simple Godot editor interface.

## License

MIT License. See `LICENSE`.
