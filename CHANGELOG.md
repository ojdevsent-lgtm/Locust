# Changelog

## 0.3.3 - Release hardening

- Aligned the plugin and manifest version with the current 0.3.x release line
- Hardened recovery backup naming and restore path validation
- Rejected uploads over GitHub's 100 MB file limit with a clear Git LFS message

## 0.3.2 - Sync robustness

- Improved GitHub URL/path percent-encoding for repository, branch, and file paths
- Added raw GitHub file downloads for large files when the Contents API does not return inline content
- Added large-file fallback coverage to the Godot 3 testing checklist

## 0.3.1 - Safety hardening

- Added `.import` to the default scanner ignore set
- Added project-path validation against absolute and parent-directory traversal
- Stopped synchronization when GitHub reports a truncated repository tree
- Added validation for remote paths before local writes/deletes
- Added safer queue error handling for unreadable local files
- Added Godot 3 release testing checklist

## 0.3.0 - Complete core development build

- Added Godot 3 editor dock workflow
- Added GitHub REST repository client
- Added branch-aware project synchronization
- Added three-way local/base/remote change classification
- Added automatic conflict detection
- Added in-editor Keep Mine / Use GitHub conflict choices
- Added recovery backup before modifying synchronization
- Added persistent activity history
- Added large-asset inspection and Git LFS guidance
- Added optional local Git command integration
- Added repository commits, collaborators and pull-request API helpers
- Added Godot 3 demo project
- Added architecture and security documentation
- Added conflict classification test fixture
- Added hardened GitHub URL/path handling
- Expanded README and installation guidance

## 0.2.0

- Added Godot 3 editor plugin UI
- Added GitHub REST API client
- Added repository connection
- Added local project scanning
- Added Git-compatible project snapshots
- Added one-click synchronization
- Added upload/download/delete operations
- Added automatic conflict detection
- Added automatic local recovery backups
- Added activity history
- Added project configuration

## 0.1.0

- Initial Locust plugin foundation
