# Locust Architecture

Locust is a Godot 3 editor plugin. The design keeps the user-facing workflow inside the editor while using GitHub's HTTPS API for repository operations.

```text
Godot 3 Editor
      |
      v
Locust Plugin / UI
      |
      v
Sync Engine
  |-- Project Scanner
  |-- Snapshot / Change Detection
  |-- Conflict Classifier
  |-- Recovery / Backups
  |-- Asset Analyzer
  |
  v
GitHub Client ---- GitHub REST API
  |
  +---- Repository metadata
  +---- Git tree / blobs
  +---- Contents updates
  +---- Commits / collaborators / pull requests
```

## Sync model

Locust records a local snapshot of Git blob SHA-1 values. During a sync it compares three states:

- **Base:** the last snapshot known to Locust.
- **Local:** the current project on disk.
- **Remote:** the selected GitHub branch.

If only one side changed, Locust can synchronize automatically. If both sides changed the same path differently, the path becomes a conflict and the user chooses which version wins.

## Safety

Before a sync that modifies project files, Locust creates a local recovery backup under `.locust/backups/`.

Repository configuration is stored locally in `.locust/config.json`. Access tokens are intentionally not persisted by the plugin.

## Large assets

GitHub's Contents API is not a replacement for Git LFS. Locust detects large files and warns when Git LFS should be used. The asset manager can also generate recommended `.gitattributes` patterns.

## Godot version

The current project intentionally targets **Godot 3.x only**. Godot 4 compatibility is not part of this release.
